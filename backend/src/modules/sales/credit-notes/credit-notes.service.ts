import {
  BadRequestException,
  ConflictException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from "@nestjs/common";
import { db } from "../../../db/db";
import { sql, SQL } from "drizzle-orm";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../supabase/supabase.service";
import { CreateCreditNoteDto } from "./dto/create-credit-note.dto";
import { ApplyCreditNoteToInvoicesDto } from "./dto/apply-credit-note-to-invoices.dto";

export { CreateCreditNoteDto };
type CreditNoteApplicationRecord = {
  id: string;
  customerId: string;
  creditNoteNumber: string;
  grandTotal: number;
  status: string;
};

type OutstandingInvoiceRecord = {
  invoiceId: string;
  invoiceNumber: string;
  invoiceDate: string | null;
  dueDate: string | null;
  invoiceAmount: number;
  allocatedAmount: number;
  outstandingAmount: number;
};

type CreditApplicationRecord = {
  id?: string;
  invoiceId: string;
  invoiceNumber?: string;
  appliedOn?: string | null;
  allocatedAmount: number;
};

type CreditNoteJournalAccount = {
  id: string;
  name: string;
  accountType: string;
};

type CreditNoteJournalLine = {
  accountId: string;
  account: string;
  debit: number;
  credit: number;
};

import { SequencesService } from '../../../sequences/sequences.service';
import { WarehousesSettingsService } from '../../warehouses-settings/warehouses-settings.service';

@Injectable()
export class CreditNotesService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly sequencesService: SequencesService,
    private readonly warehousesSettingsService: WarehousesSettingsService,
  ) {}

  private escapeRegExp(string: string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
  }


  private async backfillMissingCreditNoteJournals(tenant: TenantContext) {
    if (!tenant.entityId) return;

    const missing = this.rows<{ id: string }>(
      await db.execute(sql`
        SELECT cn.id::text AS "id"
        FROM credit_notes cn
        WHERE cn.entity_id = ${tenant.entityId}::uuid
          AND COALESCE(cn.is_delete, false) = false
          AND NOT EXISTS (
            SELECT 1
            FROM journal_entries je
            WHERE je.entity_id = cn.entity_id
              AND je.source_document_type = 'CREDIT_NOTE'
              AND je.source_document_id = cn.id
          )
      `),
    );

    for (const creditNote of missing) {
      await this.syncCreditNoteJournal(creditNote.id, tenant);
    }
  }

  async getWarehouses(tenant: TenantContext) {
    const data = await this.warehousesSettingsService.findAll(tenant);
    return { data };
  }

  async findAll(
    tenant: TenantContext,
    page = 1,
    limit = 100,
    search?: string,
    status?: string,
  ) {
    await this.backfillMissingCreditNoteJournals(tenant);

    let query = this.supabaseService
      .getClient()
      .from("credit_notes")
      .select(
        `
        id,
        credit_note_number,
        reference_number,
        credit_note_date,
        status,
        grand_total,
        subtotal,
        tax_total,
        source_type,
        source_id,
        created_at,
        salesperson_id,

        customer:customers(id, display_name, customer_number),
        items:credit_note_items(
          id,
          quantity,
          rate,
          line_total,
          description,
          product:products(id, product_name, item_code)
        )
      `,
        { count: "exact" },
      )
      .eq("entity_id", tenant.entityId)
      .eq("is_delete", false)
      .order("credit_note_date", { ascending: false })
      .range((page - 1) * limit, page * limit - 1);

    if (status) {
      query = query.eq("status", status.toUpperCase());
    }

    if (search) {
      query = query.or(
        `credit_note_number.ilike.%${search}%,reference_number.ilike.%${search}%`,
      );
    }

    const { data, error, count } = await query;
    if (error) throw new InternalServerErrorException(error.message);

    return { data: data ?? [], total: count ?? 0, page, limit };
  }

  /** Uses the tenant middleware's validated selected entity and the credit
   * note's stored customer; callers cannot widen either scope. */
  async getEligibleInvoices(id: string, tenant: TenantContext) {
    const creditNote = await this.getApplicationCreditNote(id, tenant);
    const invoices = await this.getOutstandingInvoices(
      creditNote.customerId,
      tenant.entityId as string,
    );
    const applications = await this.getCreditApplications(
      creditNote.creditNoteNumber,
      tenant.entityId as string,
      creditNote.customerId,
    );
    const totalApplied = applications.reduce(
      (sum, application) => sum + application.allocatedAmount,
      0,
    );

    return {
      invoices,
      applications,
      totalApplied,
      remainingCredit: Math.max(creditNote.grandTotal - totalApplied, 0),
      status: creditNote.status,
    };
  }

  async applyToInvoices(
    id: string,
    dto: ApplyCreditNoteToInvoicesDto,
    tenant: TenantContext,
  ) {
    if (!tenant.entityId) {
      throw new BadRequestException("An active entity is required");
    }

    const requestedByInvoice = new Map<string, number>();
    for (const allocation of dto.allocations) {
      const amount = Number(allocation.amount);
      if (!Number.isFinite(amount) || amount <= 0) {
        throw new BadRequestException("Allocation amounts must be positive");
      }
      if (requestedByInvoice.has(allocation.invoiceId)) {
        throw new BadRequestException(
          "Each invoice can only be allocated once per submission",
        );
      }
      requestedByInvoice.set(allocation.invoiceId, amount);
    }

    const entityId = tenant.entityId;
    const appliedOn = dto.appliedOn ?? new Date().toISOString().slice(0, 10);

    await db.transaction(async (tx) => {
      // Lock the note first to serialize concurrent Apply submissions.
      await tx.execute(sql`
        SELECT id FROM credit_notes
        WHERE id = ${id}::uuid AND entity_id = ${entityId}::uuid
          AND is_delete = false
        FOR UPDATE
      `);
      const notes = this.rows<CreditNoteApplicationRecord>(
        await tx.execute(sql`
          SELECT id::text AS "id", customer_id::text AS "customerId",
                 credit_note_number AS "creditNoteNumber",
                 COALESCE(grand_total, 0)::numeric AS "grandTotal",
                 COALESCE(status, 'OPEN') AS "status"
          FROM credit_notes
          WHERE id = ${id}::uuid AND entity_id = ${entityId}::uuid
            AND is_delete = false
          LIMIT 1
        `),
      );
      const creditNote = notes[0];
      if (!creditNote) throw new NotFoundException("Credit note not found");
      if (creditNote.status.toUpperCase() === "CLOSED") {
        throw new BadRequestException(
          "A closed credit note cannot be applied to invoices",
        );
      }

      const accountRows = this.rows<{ id: string }>(
        await tx.execute(sql`
          SELECT id::text AS "id"
          FROM accounts
          WHERE entity_id = ${entityId}::uuid
            AND is_active = true AND is_deleted = false
            AND account_type = 'Accounts Receivable'
          ORDER BY is_system DESC NULLS LAST, created_at ASC
          LIMIT 1
          FOR UPDATE
        `),
      );
      const receivablesAccount = accountRows[0];
      if (!receivablesAccount) {
        throw new BadRequestException(
          "An active Accounts Receivable account is required to apply this credit note",
        );
      }

      const invoiceIds = [...requestedByInvoice.keys()];
      const invoiceIdList = this.uuidList(invoiceIds);
      await tx.execute(sql`
        SELECT id FROM invoice_master
        WHERE entity_id = ${entityId}::uuid
          AND customer_id = ${creditNote.customerId}::uuid
          AND is_delete = false
          AND id IN (${invoiceIdList})
        FOR UPDATE
      `);
      const invoices = this.rows<OutstandingInvoiceRecord>(
        await tx.execute(sql`
          SELECT im.id::text AS "invoiceId", im.invoice_number AS "invoiceNumber",
                 im.invoice_date::text AS "invoiceDate", im.due_date::text AS "dueDate",
                 COALESCE(im.grand_total, 0)::numeric AS "invoiceAmount",
                 COALESCE(SUM(pra.allocated_amount), 0)::numeric AS "allocatedAmount",
                 GREATEST(COALESCE(im.grand_total, 0)::numeric -
                   COALESCE(SUM(pra.allocated_amount), 0)::numeric, 0) AS "outstandingAmount"
          FROM invoice_master im
          LEFT JOIN payment_received_allocations pra
            ON pra.invoice_id = im.id AND pra.entity_id = ${entityId}::uuid
          WHERE im.entity_id = ${entityId}::uuid
            AND im.customer_id = ${creditNote.customerId}::uuid
            AND im.is_delete = false
            AND im.id IN (${invoiceIdList})
          GROUP BY im.id, im.invoice_number, im.invoice_date, im.due_date, im.grand_total
        `),
      );
      if (invoices.length !== invoiceIds.length) {
        throw new BadRequestException(
          "One or more invoices do not belong to this credit note customer",
        );
      }

      const paymentRows = this.rows<{ id: string }>(
        await tx.execute(sql`
          SELECT id::text AS "id" FROM payments_received
          WHERE entity_id = ${entityId}::uuid
            AND customer_id = ${creditNote.customerId}::uuid
            AND payment_type = 'CREDIT_NOTE'
            AND reference_number = ${creditNote.creditNoteNumber}
            AND COALESCE(is_delete, false) = false
          LIMIT 1
          FOR UPDATE
        `),
      );
      let paymentReceivedId = paymentRows[0]?.id;
      if (!paymentReceivedId) {
        const created = this.rows<{ id: string }>(
          await tx.execute(sql`
            INSERT INTO payments_received (
              entity_id, customer_id, payment_number, payment_type,
              payment_date, deposit_account_id, reference_number,
              amount_received, amount_used_for_payments, excess_amount,
              status, notes, is_delete
            ) VALUES (
              ${entityId}::uuid, ${creditNote.customerId}::uuid,
              ${creditNote.creditNoteNumber}, 'CREDIT_NOTE', ${appliedOn}::date,
              ${receivablesAccount.id}::uuid, ${creditNote.creditNoteNumber},
              ${creditNote.grandTotal}, 0, ${creditNote.grandTotal}, 'APPROVED',
              ${`Credit note ${creditNote.creditNoteNumber} applied to invoices`}, false
            ) RETURNING id::text AS "id"
          `),
        );
        paymentReceivedId = created[0]?.id;
      }
      if (!paymentReceivedId) {
        throw new InternalServerErrorException(
          "Unable to create the credit note payment record",
        );
      }

      const existing = this.rows<CreditApplicationRecord>(
        await tx.execute(sql`
          SELECT invoice_id::text AS "invoiceId",
                 COALESCE(allocated_amount, 0)::numeric AS "allocatedAmount"
          FROM payment_received_allocations
          WHERE payment_received_id = ${paymentReceivedId}::uuid
            AND entity_id = ${entityId}::uuid
          FOR UPDATE
        `),
      );
      const allocatedInvoiceIds = new Set(existing.map((row) => row.invoiceId));
      if (invoiceIds.some((invoiceId) => allocatedInvoiceIds.has(invoiceId))) {
        throw new ConflictException(
          "This credit note has already been applied to one or more selected invoices",
        );
      }

      const existingApplied = existing.reduce(
        (sum, row) => sum + Number(row.allocatedAmount),
        0,
      );
      const requestedTotal = [...requestedByInvoice.values()].reduce(
        (sum, amount) => sum + amount,
        0,
      );
      if (requestedTotal > creditNote.grandTotal - existingApplied + 0.005) {
        throw new BadRequestException(
          "The allocation exceeds the remaining credit note amount",
        );
      }
      for (const invoice of invoices) {
        const amount = requestedByInvoice.get(invoice.invoiceId)!;
        if (amount > Number(invoice.outstandingAmount) + 0.005) {
          throw new BadRequestException(
            `The allocation for invoice ${invoice.invoiceNumber} exceeds its outstanding amount`,
          );
        }
      }

      for (const invoice of invoices) {
        await tx.execute(sql`
          INSERT INTO payment_received_allocations (
            entity_id, payment_received_id, invoice_id, invoice_amount,
            amount_due, allocated_amount, payment_received_on
          ) VALUES (
            ${entityId}::uuid, ${paymentReceivedId}::uuid,
            ${invoice.invoiceId}::uuid, ${Number(invoice.invoiceAmount)},
            ${Number(invoice.outstandingAmount)},
            ${requestedByInvoice.get(invoice.invoiceId)!}, ${appliedOn}::date
          )
        `);
      }

      const appliedTotal = existingApplied + requestedTotal;
      const remaining = Math.max(creditNote.grandTotal - appliedTotal, 0);
      await tx.execute(sql`
        UPDATE payments_received
        SET amount_used_for_payments = ${appliedTotal}, excess_amount = ${remaining}
        WHERE id = ${paymentReceivedId}::uuid
      `);
      if (remaining <= 0.005) {
        await tx.execute(sql`
          UPDATE credit_notes SET status = 'CLOSED'
          WHERE id = ${creditNote.id}::uuid AND entity_id = ${entityId}::uuid
        `);
      }
    });

    return this.getEligibleInvoices(id, tenant);
  }

  private async getApplicationCreditNote(id: string, tenant: TenantContext) {
    if (!tenant.entityId) {
      throw new BadRequestException("An active entity is required");
    }
    const rows = this.rows<CreditNoteApplicationRecord>(
      await db.execute(sql`
        SELECT id::text AS "id", customer_id::text AS "customerId",
               credit_note_number AS "creditNoteNumber",
               COALESCE(grand_total, 0)::numeric AS "grandTotal",
               COALESCE(status, 'OPEN') AS "status"
        FROM credit_notes
        WHERE id = ${id}::uuid AND entity_id = ${tenant.entityId}::uuid
          AND is_delete = false
        LIMIT 1
      `),
    );
    const record = rows[0];
    if (!record) throw new NotFoundException("Credit note not found");
    return record;
  }

  private async getOutstandingInvoices(customerId: string, entityId: string) {
    return this.rows<OutstandingInvoiceRecord>(
      await db.execute(sql`
        SELECT im.id::text AS "invoiceId", im.invoice_number AS "invoiceNumber",
               im.invoice_date::text AS "invoiceDate", im.due_date::text AS "dueDate",
               COALESCE(im.grand_total, 0)::numeric AS "invoiceAmount",
               COALESCE(SUM(pra.allocated_amount), 0)::numeric AS "allocatedAmount",
               GREATEST(COALESCE(im.grand_total, 0)::numeric -
                 COALESCE(SUM(pra.allocated_amount), 0)::numeric, 0) AS "outstandingAmount"
        FROM invoice_master im
        LEFT JOIN payment_received_allocations pra
          ON pra.invoice_id = im.id AND pra.entity_id = ${entityId}::uuid
        WHERE im.entity_id = ${entityId}::uuid
          AND im.customer_id = ${customerId}::uuid
          AND im.is_delete = false
        GROUP BY im.id, im.invoice_number, im.invoice_date, im.due_date, im.grand_total
        HAVING COALESCE(im.grand_total, 0)::numeric - COALESCE(SUM(pra.allocated_amount), 0) > 0
        ORDER BY im.invoice_date ASC, im.invoice_number ASC
      `),
    );
  }

  private async getCreditApplications(
    creditNoteNumber: string,
    entityId: string,
    customerId: string,
  ) {
    return this.rows<CreditApplicationRecord>(
      await db.execute(sql`
        SELECT pra.id::text AS "id", pra.invoice_id::text AS "invoiceId",
               im.invoice_number AS "invoiceNumber",
               pra.payment_received_on::text AS "appliedOn",
               COALESCE(pra.allocated_amount, 0)::numeric AS "allocatedAmount"
        FROM payments_received pr
        INNER JOIN payment_received_allocations pra
          ON pra.payment_received_id = pr.id AND pra.entity_id = ${entityId}::uuid
        INNER JOIN invoice_master im ON im.id = pra.invoice_id
        WHERE pr.entity_id = ${entityId}::uuid
          AND pr.customer_id = ${customerId}::uuid
          AND pr.payment_type = 'CREDIT_NOTE'
          AND pr.reference_number = ${creditNoteNumber}
          AND COALESCE(pr.is_delete, false) = false
        ORDER BY pra.payment_received_on ASC, pra.id ASC
      `),
    );
  }

  private uuidList(ids: string[]): SQL {
    return sql.join(
      ids.map((id) => sql`${id}::uuid`),
      sql`, `,
    );
  }

  private rows<T>(result: unknown): T[] {
    if (Array.isArray(result)) return result as T[];
    const rows = (result as { rows?: unknown })?.rows;
    return Array.isArray(rows) ? (rows as T[]) : [];
  }

  async create(dto: CreateCreditNoteDto, tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();

    let sourceId: string | null = null;
    let sourceType: string | null = null;
    if (dto.fromRmaNumber) {
      const { data: sr } = await supabase
        .from("sales_returns")
        .select("id")
        .eq("rma_number", dto.fromRmaNumber)
        .eq("entity_id", tenant.entityId)
        .maybeSingle();
      if (sr) {
        sourceId = sr.id;
        sourceType = "SALES_RETURN";
      }
    }

    const { data: cn, error: cnError } = await supabase
      .from("credit_notes")
      .insert({
        entity_id: tenant.entityId,
        customer_id: dto.customerId,
        warehouse_id: dto.warehouseId ?? null,
        created_by: tenant.userId,
        credit_note_number: dto.creditNoteNumber,
        reference_number: dto.referenceNumber ?? null,
        credit_note_date:
          dto.creditNoteDate ?? new Date().toISOString().split("T")[0],
        status: dto.status,
        grand_total: dto.grandTotal,
        subtotal: dto.subTotal ?? 0,
        tax_total: dto.taxTotal ?? 0,
        shipping_charges: dto.shippingAmount ?? 0,
        adjustment_amount: dto.adjustmentAmount ?? 0,
        salesperson_id: dto.salespersonId ?? null,

        tds_total: dto.tdsTotal ?? 0,
        tcs_total: dto.tcsTotal ?? 0,
        customer_notes: dto.customerNotes ?? null,
        terms_conditions: dto.termsAndConditions ?? null,
        source_type: sourceType,
        source_id: sourceId,
      })
      .select("id")
      .single();

    if (cnError) {
      throw new Error(`Failed to create credit note: ${cnError.message}`);
    }

    const validItems = (dto.items ?? []).filter((item) => item.productId);
    if (validItems.length > 0) {
      const itemRows = validItems.map((item) => ({
        credit_note_id: cn.id,
        product_id: item.productId,
        description: item.description ?? null,
        quantity: item.quantity,
        rate: item.rate,
        discount_type: item.discountType ?? "PERCENTAGE",
        discount_value: item.discountValue ?? 0,
        discount_amount: item.discountAmount ?? 0,
        taxable_amount: item.taxableAmount ?? item.lineTotal,
        tax_percentage: item.taxPercentage ?? 0,
        tax_amount: item.taxAmount ?? 0,
        line_total: item.lineTotal,
        account_id: item.accountId ?? null,
      }));

      const { error: itemsError } = await supabase
        .from("credit_note_items")
        .insert(itemRows);

      if (itemsError) {
        throw new Error(
          `Failed to create credit note items: ${itemsError.message}`,
        );
      }
    }

    // An approved credit note is an accounting event: goods come back on the
    // books. Draft and open notes remain unposted.
    if (dto.status === "APPROVED") {
      await this.postAccountingLedger(cn.id, dto, tenant);
    }

    await this.syncCreditNoteJournal(cn.id, tenant);

    await this.sequencesService.incrementSequence("credit_note", tenant, dto.creditNoteNumber);

    return { id: cn.id, status: dto.status };
  }

  /**
   * Writes the credit note into `batch_transactions` as `CREDIT_NOTE` rows.
   *
   * That table is the accounting ledger behind `v_accounting_stock`, which sums
   * `qty_in - qty_out` over BILL / INVOICE / CREDIT_NOTE / VENDOR_CREDIT /
   * ADJUSTMENT / TRANSFER_*. A credit note reverses an INVOICE (which posts
   * `qty_out`), so it posts `qty_in`.
   *
   * This is deliberately separate from physical stock: the sales return receive
   * already added the goods to `batch_stock_layers` under
   * `SALES_RETURN_RECEIVES`, a type the accounting view excludes. The two
   * ledgers do not double count.
   *
   * A credit note carries no batch detail, but `batch_transactions.batch_id` is
   * NOT NULL â€” so the batches are taken from the originating return's receive.
   * Failures here are logged rather than thrown: the credit note itself is
   * already committed, and losing it would be worse than a missing ledger row
   * that can be reposted.
   */
  private async postAccountingLedger(
    creditNoteId: string,
    dto: CreateCreditNoteDto,
    tenant: TenantContext,
  ) {
    try {
      const supabase = this.supabaseService.getClient();
      const allocations = await this.resolveBatchAllocations(dto, tenant);
      if (allocations.length === 0) return;

      const rows = allocations.map((a) => ({
        batch_id: a.batchId,
        layer_id: a.layerId ?? null,
        product_id: a.productId,
        entity_id: tenant.entityId,
        warehouse_id: a.warehouseId,
        bin_id: a.binId ?? null,
        trans_type: "CREDIT_NOTE",
        qty_in: a.quantity,
        qty_out: 0,
        rate: a.rate,
        ref_id: creditNoteId,
        ref_no: dto.creditNoteNumber,
      }));

      const { error } = await supabase.from("batch_transactions").insert(rows);
      if (error) {
        console.error(
          `Credit note ${dto.creditNoteNumber}: failed to post accounting ledger â€” ${error.message}`,
        );
      }

      // If this is a standalone credit note (no RMA), we must also increment physical stock.
      // Sales Returns update physical stock via createReceive, but here there is no receive.
      if (!dto.fromRmaNumber) {
        for (const a of allocations) {
          if (a.layerId) {
            const { data: existingLayer } = await supabase
              .from("batch_stock_layers")
              .select("qty")
              .eq("id", a.layerId)
              .single();
            if (existingLayer) {
              const currentQty = Number(existingLayer.qty) || 0;
              await supabase
                .from("batch_stock_layers")
                .update({
                  qty: currentQty + a.quantity,
                  updated_at: new Date().toISOString(),
                })
                .eq("id", a.layerId);
            }
          } else if (a.batchId && a.warehouseId) {
            // No existing layer, create one
            const { data: newLayer } = await supabase
              .from("batch_stock_layers")
              .insert({
                batch_id: a.batchId,
                product_id: a.productId,
                entity_id: tenant.entityId,
                warehouse_id: a.warehouseId,
                bin_id: a.binId ?? null,
                qty: a.quantity,
                foc_qty: 0,
                purchase_rate: a.rate,
                mrp: 0,
                ref_type: "CREDIT_NOTE",
                ref_id: creditNoteId,
              })
              .select("id")
              .single();

            // Update the transaction we just inserted to link the new layer
            if (newLayer?.id) {
              await supabase
                .from("batch_transactions")
                .update({ layer_id: newLayer.id })
                .eq("ref_id", creditNoteId)
                .eq("batch_id", a.batchId)
                .eq("trans_type", "CREDIT_NOTE");
            }
          }
        }
      }
    } catch (e) {
      console.error(
        `Credit note ${dto.creditNoteNumber}: failed to post accounting ledger`,
        e,
      );
    }
  }

  /**
   * Maps each credited line onto the batches it came back on.
   *
   * Quantities are drawn from the receive batches for that product in order,
   * so crediting less than was received consumes the earliest batches first and
   * never posts more than actually came back.
   */
  private async resolveBatchAllocations(
    dto: CreateCreditNoteDto,
    tenant: TenantContext,
  ): Promise<
    Array<{
      batchId: string;
      layerId?: string | null;
      binId?: string | null;
      warehouseId: string;
      productId: string;
      quantity: number;
      rate: number;
    }>
  > {
    const supabase = this.supabaseService.getClient();
    const result: Array<{
      batchId: string;
      layerId?: string | null;
      binId?: string | null;
      warehouseId: string;
      productId: string;
      quantity: number;
      rate: number;
    }> = [];

    if (!dto.fromRmaNumber) {
      // If it's a standalone credit note, rely on explicitly provided batches
      for (const line of dto.items ?? []) {
        const remaining = Number(line.quantity ?? 0);
        if (remaining <= 0 || !line.batchId) continue;

        // Find existing layer info if possible
        const { data: layer } = await supabase
          .from("batch_stock_layers")
          .select("id, bin_id")
          .eq("batch_id", line.batchId)
          .eq("product_id", line.productId)
          .eq("entity_id", tenant.entityId)
          .maybeSingle();

        result.push({
          batchId: line.batchId,
          layerId: layer?.id,
          binId: layer?.bin_id,
          warehouseId: dto.warehouseId ?? "",
          productId: line.productId,
          quantity: remaining,
          rate: line.rate ?? 0,
        });
      }
      return result;
    }

    const { data: salesReturn } = await supabase
      .from("sales_returns")
      .select("id")
      .eq("rma_number", dto.fromRmaNumber)
      .eq("entity_id", tenant.entityId)
      .maybeSingle();

    if (!salesReturn) return result;

    const { data: receives } = await supabase
      .from("sales_return_receives")
      .select(
        "id, items:sales_return_receive_items(product_id, batches:sales_return_receive_batches(*))",
      )
      .eq("sales_return_id", salesReturn.id)
      .eq("entity_id", tenant.entityId);

    // product_id -> the batches it was received on, oldest receive first.
    const batchesByProduct = new Map<string, any[]>();
    for (const receive of receives ?? []) {
      for (const item of (receive as any).items ?? []) {
        const productId = item.product_id as string;
        const list = batchesByProduct.get(productId) ?? [];
        list.push(...(item.batches ?? []));
        batchesByProduct.set(productId, list);
      }
    }

    for (const line of dto.items ?? []) {
      let remaining = Number(line.quantity ?? 0);
      if (remaining <= 0) continue;

      // An explicitly supplied batch wins over the receive lookup.
      const candidates = line.batchId
        ? (batchesByProduct.get(line.productId) ?? []).filter(
            (b) => b.batch_id === line.batchId,
          )
        : (batchesByProduct.get(line.productId) ?? []);

      for (const batch of candidates) {
        if (remaining <= 0) break;
        const warehouseId = batch.warehouse_id ?? dto.warehouseId;
        if (!batch.batch_id || !warehouseId) continue;

        const available =
          Number(batch.quantity ?? 0) + Number(batch.foc_quantity ?? 0);
        if (available <= 0) continue;

        const take = Math.min(remaining, available);
        result.push({
          batchId: batch.batch_id,
          layerId: batch.layer_id,
          binId: batch.bin_id,
          warehouseId,
          productId: line.productId,
          quantity: take,
          rate: Number(batch.purchase_rate ?? line.rate ?? 0),
        });
        remaining -= take;
      }
    }

    return result;
  }

  async findOne(id: string, tenant: TenantContext) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("credit_notes")
      .select(
        `
        *,
        customer:customers(
          id, 
          display_name, 
          customer_number, 
          email, 
          phone
        ),
        items:credit_note_items(
          id,
          product_id,
          quantity,
          rate,
          discount_type,
          discount_value,
          discount_amount,
          tax_percentage,
          tax_amount,
          line_total,
          description,
          product:products(id, product_name, item_code, sku, hsn_sac_code, sales_description, selling_price, cost_price)
        )
      `,
      )
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .single();

    if (error) throw new InternalServerErrorException(error.message);

    if (data && data.source_type === "INVOICE" && data.source_id) {
      const { data: invoice } = await this.supabaseService
        .getClient()
        .from("invoice_master")
        .select("invoice_number")
        .eq("id", data.source_id)
        .single();

      if (invoice) {
        data.invoice_number = invoice.invoice_number;
      }
    }

    return data;
  }

  async update(id: string, dto: CreateCreditNoteDto, tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();

    // Confirm ownership before touching anything â€” the item/ledger deletes key
    // off ids alone and would otherwise reach across tenants.
    const { data: owned, error: ownerError } = await supabase
      .from("credit_notes")
      .select("id")
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .maybeSingle();

    if (ownerError) throw new InternalServerErrorException(ownerError.message);
    if (!owned) throw new NotFoundException(`Credit Note ${id} not found`);

    let sourceId: string | null = null;
    let sourceType: string | null = null;
    if (dto.fromRmaNumber) {
      const { data: sr } = await supabase
        .from("sales_returns")
        .select("id")
        .eq("rma_number", dto.fromRmaNumber)
        .eq("entity_id", tenant.entityId)
        .maybeSingle();
      if (sr) {
        sourceId = sr.id;
        sourceType = "SALES_RETURN";
      }
    }

    const { error: headerError } = await supabase
      .from("credit_notes")
      .update({
        customer_id: dto.customerId,
        warehouse_id: dto.warehouseId ?? null,
        credit_note_number: dto.creditNoteNumber,
        reference_number: dto.referenceNumber ?? null,
        credit_note_date:
          dto.creditNoteDate ?? new Date().toISOString().split("T")[0],
        status: dto.status,
        grand_total: dto.grandTotal,
        subtotal: dto.subTotal ?? 0,
        tax_total: dto.taxTotal ?? 0,
        shipping_charges: dto.shippingAmount ?? 0,
        adjustment_amount: dto.adjustmentAmount ?? 0,
        salesperson_id: dto.salespersonId ?? null,

        tds_total: dto.tdsTotal ?? 0,
        tcs_total: dto.tcsTotal ?? 0,
        customer_notes: dto.customerNotes ?? null,
        terms_conditions: dto.termsAndConditions ?? null,
        source_type: sourceType,
        source_id: sourceId,
      })
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (headerError) {
      throw new InternalServerErrorException(
        `Failed to update credit note: ${headerError.message}`,
      );
    }

    // Replace the line set wholesale â€” simplest way to reconcile added,
    // removed and edited lines in one pass.
    const { error: delItemsError } = await supabase
      .from("credit_note_items")
      .delete()
      .eq("credit_note_id", id);

    if (delItemsError) {
      throw new InternalServerErrorException(
        `Failed to update credit note items: ${delItemsError.message}`,
      );
    }

    const validItems = (dto.items ?? []).filter((item) => item.productId);
    if (validItems.length > 0) {
      const itemRows = validItems.map((item) => ({
        credit_note_id: id,
        product_id: item.productId,
        description: item.description ?? null,
        quantity: item.quantity,
        rate: item.rate,
        discount_type: item.discountType ?? "PERCENTAGE",
        discount_value: item.discountValue ?? 0,
        discount_amount: item.discountAmount ?? 0,
        taxable_amount: item.taxableAmount ?? item.lineTotal,
        tax_percentage: item.taxPercentage ?? 0,
        tax_amount: item.taxAmount ?? 0,
        line_total: item.lineTotal,
        account_id: item.accountId ?? null,
      }));

      const { error: itemsError } = await supabase
        .from("credit_note_items")
        .insert(itemRows);

      if (itemsError) {
        throw new InternalServerErrorException(
          `Failed to update credit note items: ${itemsError.message}`,
        );
      }
    }

    // Re-post the accounting ledger: drop the note's prior CREDIT_NOTE rows,
    // then repost only if the edited note is approved. A draft posts nothing.
    const { data: oldLedger } = await supabase
      .from("batch_transactions")
      .select("layer_id, qty_in")
      .eq("ref_id", id)
      .eq("trans_type", "CREDIT_NOTE")
      .eq("entity_id", tenant.entityId);

    // Reverse physical stock increment if this was a standalone credit note
    const { data: oldCn } = await supabase
      .from("credit_notes")
      .select("source_type")
      .eq("id", id)
      .single();

    if (
      oldCn?.source_type !== "SALES_RETURN" &&
      oldLedger &&
      oldLedger.length > 0
    ) {
      for (const tx of oldLedger) {
        if (!tx.layer_id) continue;
        const { data: currentLayer } = await supabase
          .from("batch_stock_layers")
          .select("qty")
          .eq("id", tx.layer_id)
          .single();
        if (currentLayer) {
          const newQty = Math.max(
            0,
            (Number(currentLayer.qty) || 0) - Number(tx.qty_in),
          );
          await supabase
            .from("batch_stock_layers")
            .update({ qty: newQty, updated_at: new Date().toISOString() })
            .eq("id", tx.layer_id);
        }
      }
    }

    const { error: ledgerDelError } = await supabase
      .from("batch_transactions")
      .delete()
      .eq("ref_id", id)
      .eq("trans_type", "CREDIT_NOTE")
      .eq("entity_id", tenant.entityId);

    if (ledgerDelError) {
      throw new InternalServerErrorException(
        `Failed to reset credit note ledger: ${ledgerDelError.message}`,
      );
    }

    if (dto.status === "APPROVED") {
      await this.postAccountingLedger(id, dto, tenant);
    }

    await this.syncCreditNoteJournal(id, tenant);

    return { id, status: dto.status };
  }

  async remove(id: string, tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();

    // Confirm the note belongs to this tenant before deleting anything. The
    // child deletes below key off credit_note_id / ref_id alone, so without
    // this an id from another org would have its items and ledger rows removed
    // even though the header delete would then match nothing.
    const { data: owned, error: ownerError } = await supabase
      .from("credit_notes")
      .select("id, source_type")
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .maybeSingle();

    if (ownerError) {
      throw new InternalServerErrorException(ownerError.message);
    }
    if (!owned) {
      throw new NotFoundException(`Credit Note ${id} not found`);
    }

    // Reverse the accounting ledger this note posted when approved. Scoped by
    // trans_type so only the credit note's own rows go, never another doc's.
    const { data: oldLedger } = await supabase
      .from("batch_transactions")
      .select("layer_id, qty_in")
      .eq("ref_id", id)
      .eq("trans_type", "CREDIT_NOTE")
      .eq("entity_id", tenant.entityId);

    // Reverse physical stock increment if this was a standalone credit note
    if (
      owned.source_type !== "SALES_RETURN" &&
      oldLedger &&
      oldLedger.length > 0
    ) {
      for (const tx of oldLedger) {
        if (!tx.layer_id) continue;
        const { data: currentLayer } = await supabase
          .from("batch_stock_layers")
          .select("qty")
          .eq("id", tx.layer_id)
          .single();
        if (currentLayer) {
          const newQty = Math.max(
            0,
            (Number(currentLayer.qty) || 0) - Number(tx.qty_in),
          );
          await supabase
            .from("batch_stock_layers")
            .update({ qty: newQty, updated_at: new Date().toISOString() })
            .eq("id", tx.layer_id);
        }
      }
    }

    const { error: ledgerError } = await supabase
      .from("batch_transactions")
      .delete()
      .eq("ref_id", id)
      .eq("trans_type", "CREDIT_NOTE")
      .eq("entity_id", tenant.entityId);

    if (ledgerError) {
      throw new InternalServerErrorException(
        `Failed to delete credit note ledger entries: ${ledgerError.message}`,
      );
    }

    const { error: itemsError } = await supabase
      .from("credit_note_items")
      .delete()
      .eq("credit_note_id", id);

    if (itemsError) {
      throw new InternalServerErrorException(
        `Failed to delete credit note items: ${itemsError.message}`,
      );
    }

    const { error: cnError } = await supabase
      .from("credit_notes")
      .update({ is_delete: true })
      .eq("id", id);

    if (cnError) {
      throw new InternalServerErrorException(
        `Failed to soft-delete credit note: ${cnError.message}`,
      );
    }

    return { message: "Credit note deleted successfully" };
  }

  private toJournalAmount(value: unknown): number {
    const amount = Number(value ?? 0);
    return Number.isFinite(amount) ? Math.round(amount * 100) / 100 : 0;
  }

  private async resolveCreditNoteJournalAccounts(
    tx: any,
    entityId: string,
  ): Promise<Record<string, CreditNoteJournalAccount>> {
    const rows = this.rows<{
      id: string;
      name: string | null;
      systemAccountName: string | null;
      accountType: string | null;
    }>(
      await tx.execute(sql`
        SELECT
          id::text AS "id",
          COALESCE(NULLIF(user_account_name, ''), NULLIF(system_account_name, ''), account_code, id::text) AS "name",
          system_account_name AS "systemAccountName",
          account_type::text AS "accountType"
        FROM accounts
        WHERE entity_id = ${entityId}::uuid
          AND is_active = true
          AND COALESCE(is_deleted, false) = false
        FOR UPDATE
      `),
    );

    const normalized = (value: string | null | undefined) =>
      (value ?? "").trim().toLowerCase();
    const byExactName = (name: string) =>
      rows.find(
        (row) =>
          normalized(row.name) === normalized(name) ||
          normalized(row.systemAccountName) === normalized(name),
      );
    const bySystemAccountName = (name: string) =>
      rows.find(
        (row) => normalized(row.systemAccountName) === normalized(name),
      );
    const byType = (accountType: string) =>
      rows.find(
        (row) => normalized(row.accountType) === normalized(accountType),
      );

    const selected = {
      // Accounts Receivable must use the entity's designated system account,
      // not an arbitrary account that only shares the same account type.
      accountsReceivable: bySystemAccountName("Accounts Receivable"),
      outputCgst: byExactName("Output CGST"),
      outputSgst: byExactName("Output SGST"),
      sales: byExactName("Sales") ?? byType("Income"),
      inventoryAsset: byExactName("Inventory Asset") ?? byType("Stock"),
      costOfGoodsSold:
        byExactName("Cost Of Goods Sold") ?? byType("Cost Of Goods Sold"),
    };
    const missing = Object.entries(selected)
      .filter(([, account]) => !account)
      .map(([key]) => key);
    if (missing.length > 0) {
      throw new BadRequestException(
        `Missing active credit note journal accounts: ${missing.join(", ")}`,
      );
    }
    return selected as Record<string, CreditNoteJournalAccount>;
  }

  private async syncCreditNoteJournal(id: string, tenant: TenantContext) {
    if (!tenant.entityId) {
      throw new BadRequestException("An active entity is required");
    }

    const entityId = tenant.entityId;
    return db.transaction(async (tx) => {
      // Lock the document before locating its journal so concurrent requests
      // cannot create duplicate headers for one credit note.
      const notes = this.rows<{
        id: string;
        customerId: string;
        creditNoteNumber: string;
        creditNoteDate: string;
        status: string;
        taxTotal: number;
        grandTotal: number;
        warehouseName: string | null;
      }>(
        await tx.execute(sql`
          SELECT
            cn.id::text AS "id",
            cn.customer_id::text AS "customerId",
            cn.credit_note_number AS "creditNoteNumber",
            cn.credit_note_date::text AS "creditNoteDate",
            COALESCE(cn.status, 'DRAFT') AS "status",
            COALESCE(cn.tax_total, 0)::numeric AS "taxTotal",
            COALESCE(cn.grand_total, 0)::numeric AS "grandTotal",
            COALESCE(
              NULLIF(w.name, ''),
              (
                SELECT fallback.name
                FROM batch_transactions bt
                INNER JOIN warehouses fallback ON fallback.id = bt.warehouse_id
                WHERE bt.ref_id = cn.id
                  AND bt.trans_type = 'CREDIT_NOTE'
                  AND bt.entity_id = ${entityId}::uuid
                ORDER BY bt.created_at ASC
                LIMIT 1
              ),
              '-'
            ) AS "warehouseName"
          FROM credit_notes cn
          LEFT JOIN warehouses w ON w.id = cn.warehouse_id
          WHERE cn.id = ${id}::uuid
            AND cn.entity_id = ${entityId}::uuid
            AND COALESCE(cn.is_delete, false) = false
          FOR UPDATE OF cn
        `),
      );
      const creditNote = notes[0];
      if (!creditNote)
        throw new NotFoundException(`Credit Note ${id} not found`);

      const taxTotal = this.toJournalAmount(creditNote.taxTotal);
      // Credit notes persist one GST total, so the requested 50/50 CGST/SGST
      // split is the authoritative rule until component values are stored.
      const cgst = this.toJournalAmount(taxTotal / 2);
      const sgst = this.toJournalAmount(taxTotal - cgst);
      const grandTotal = this.toJournalAmount(creditNote.grandTotal);
      // Header adjustments are included in the persisted total; the Sales line
      // carries the non-tax residual to keep the required six-line entry balanced.
      const salesAmount = this.toJournalAmount(grandTotal - cgst - sgst);

      const inventoryFromLedger = this.rows<{ inventoryCost: number }>(
        await tx.execute(sql`
          SELECT COALESCE(SUM(COALESCE(qty_in, 0) * COALESCE(rate, 0)), 0)::numeric AS "inventoryCost"
          FROM batch_transactions
          WHERE ref_id = ${id}::uuid
            AND trans_type = 'CREDIT_NOTE'
            AND entity_id = ${entityId}::uuid
        `),
      );
      let inventoryCost = this.toJournalAmount(
        inventoryFromLedger[0]?.inventoryCost,
      );
      if (inventoryCost === 0) {
        const inventoryFromProducts = this.rows<{ inventoryCost: number }>(
          await tx.execute(sql`
            SELECT COALESCE(SUM(
              COALESCE(cni.quantity, 0) * COALESCE(p.cost_price, 0)
            ), 0)::numeric AS "inventoryCost"
            FROM credit_note_items cni
            INNER JOIN products p ON p.id = cni.product_id
            WHERE cni.credit_note_id = ${id}::uuid
          `),
        );
        inventoryCost = this.toJournalAmount(
          inventoryFromProducts[0]?.inventoryCost,
        );
      }

      const accounts = await this.resolveCreditNoteJournalAccounts(
        tx,
        entityId,
      );
      const lines: CreditNoteJournalLine[] = [
        {
          accountId: accounts.accountsReceivable.id,
          account: accounts.accountsReceivable.name,
          debit: 0,
          credit: grandTotal,
        },
        {
          accountId: accounts.outputCgst.id,
          account: accounts.outputCgst.name,
          debit: cgst,
          credit: 0,
        },
        {
          accountId: accounts.outputSgst.id,
          account: accounts.outputSgst.name,
          debit: sgst,
          credit: 0,
        },
        {
          accountId: accounts.sales.id,
          account: accounts.sales.name,
          debit: salesAmount,
          credit: 0,
        },
        {
          accountId: accounts.inventoryAsset.id,
          account: accounts.inventoryAsset.name,
          debit: inventoryCost,
          credit: 0,
        },
        {
          accountId: accounts.costOfGoodsSold.id,
          account: accounts.costOfGoodsSold.name,
          debit: 0,
          credit: inventoryCost,
        },
      ];
      // The database requires every persisted line to carry one positive side.
      // A zero-value Credit Note remains valid, but has no accounting lines to post.
      const persistedLines = lines.filter(
        (line) => line.debit > 0 || line.credit > 0,
      );
      const totalDebit = this.toJournalAmount(
        lines.reduce((sum, line) => sum + line.debit, 0),
      );
      const totalCredit = this.toJournalAmount(
        lines.reduce((sum, line) => sum + line.credit, 0),
      );
      if (Math.abs(totalDebit - totalCredit) > 0.005) {
        throw new BadRequestException(
          `Credit Note journal is unbalanced: debit ${totalDebit.toFixed(2)} does not equal credit ${totalCredit.toFixed(2)}`,
        );
      }

      const existing = this.rows<{ id: string }>(
        await tx.execute(sql`
          SELECT id::text AS "id"
          FROM journal_entries
          WHERE entity_id = ${entityId}::uuid
            AND source_document_type = 'CREDIT_NOTE'
            AND source_document_id = ${id}::uuid
          LIMIT 1
          FOR UPDATE
        `),
      );
      const journalNumber = `JE-${creditNote.creditNoteNumber}`;
      const journalStatus =
        creditNote.status.toUpperCase() === "DRAFT" ? "DRAFT" : "POSTED";
      let journalEntryId = existing[0]?.id;

      if (journalEntryId) {
        await tx.execute(
          sql`DELETE FROM journal_entry_lines WHERE journal_entry_id = ${journalEntryId}::uuid`,
        );
        await tx.execute(sql`
          UPDATE journal_entries
          SET journal_number = ${journalNumber}, journal_type = 'CREDIT NOTE',
              journal_date = ${creditNote.creditNoteDate}::date,
              posting_date = ${creditNote.creditNoteDate}::date,
              reference_number = ${creditNote.creditNoteNumber},
              narration = ${`Credit note ${creditNote.creditNoteNumber}`},
              status = ${journalStatus}, created_by = ${tenant.userId}::uuid
          WHERE id = ${journalEntryId}::uuid
        `);
      } else {
        const inserted = this.rows<{ id: string }>(
          await tx.execute(sql`
            INSERT INTO journal_entries (
              org_id, entity_id, journal_number, journal_type, journal_date,
              posting_date, reference_number, narration, source_module,
              source_document_type, source_document_id, status, created_by
            ) VALUES (
              ${tenant.orgId}::uuid, ${entityId}::uuid, ${journalNumber},
              'CREDIT NOTE', ${creditNote.creditNoteDate}::date,
              ${creditNote.creditNoteDate}::date, ${creditNote.creditNoteNumber},
              ${`Credit note ${creditNote.creditNoteNumber}`}, 'SALES',
              'CREDIT_NOTE', ${id}::uuid, ${journalStatus}, ${tenant.userId}::uuid
            ) RETURNING id::text AS "id"
          `),
        );
        journalEntryId = inserted[0]?.id;
      }
      if (!journalEntryId) {
        throw new InternalServerErrorException(
          "Failed to create the credit note journal entry",
        );
      }

      for (const line of persistedLines) {
        await tx.execute(sql`
          INSERT INTO journal_entry_lines (
            account_id, transaction_date, reference_number, description,
            debit, credit, source_id, source_type, contact_id, contact_type,
            entity_id, org_id, journal_entry_id, line_number
          ) VALUES (
            ${line.accountId}::uuid, ${creditNote.creditNoteDate}::date,
            ${creditNote.creditNoteNumber}, ${`Credit note ${creditNote.creditNoteNumber}`},
            ${line.debit}, ${line.credit}, ${id}::uuid, 'CREDIT_NOTE',
            ${creditNote.customerId}::uuid, 'CUSTOMER', ${entityId}::uuid,
            ${tenant.orgId}::uuid, ${journalEntryId}::uuid, NULL
          )
        `);
      }

      return {
        id: journalEntryId,
        entries: persistedLines.map((line) => ({
          account: line.account,
          warehouse: creditNote.warehouseName ?? "-",
          debit: line.debit,
          credit: line.credit,
        })),
        totalDebit,
        totalCredit,
      };
    });
  }

  async getJournal(id: string, tenant: TenantContext) {
    // Existing notes are backfilled the first time their journal is requested.
    return this.syncCreditNoteJournal(id, tenant);
  }
}

