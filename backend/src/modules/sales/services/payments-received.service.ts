import { Injectable, NotFoundException } from "@nestjs/common";
import { v4 as uuidv4 } from "uuid";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../supabase/supabase.service";
import { R2StorageService } from "../../accountant/r2-storage.service";
import {
  CreatePaymentAllocationDto,
  CreatePaymentReceivedDto,
  PaymentAttachmentDto,
} from "../dto/create-payment-received.dto";
import { UpdatePaymentReceivedDto } from "../dto/update-payment-received.dto";
import { client } from "../../../db/db";

@Injectable()
export class PaymentsReceivedService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly r2StorageService: R2StorageService,
  ) {}

  private ensureEntityId(tenant: TenantContext): string {
    if (!tenant?.entityId) {
      throw new Error("Tenant entity context is required");
    }
    return tenant.entityId;
  }

  async create(tenant: TenantContext, dto: CreatePaymentReceivedDto) {
    const entityId = this.ensureEntityId(tenant);
    const nowIso = new Date().toISOString();
    const status = (dto.status ?? "draft").trim().toLowerCase();

    const createdRows = await client.unsafe(
      `INSERT INTO payments_received (
        entity_id, customer_id, payment_number, payment_type, payment_date,
        location_id, place_of_supply, description_of_supply, payment_mode,
        deposit_account_id, reference_number, amount_received, bank_charges,
        is_tds_deducted, tds_tax_id, tds_amount, tax_id, tax_amount,
        excess_amount, status, is_delete, notes, created_by, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, false, $21, $22, $23, $24)
      RETURNING *`,
      [
        entityId,
        dto.customer_id,
        dto.payment_number,
        dto.payment_type ?? "INVOICE_PAYMENT",
        dto.payment_date,
        dto.location_id ?? null,
        dto.place_of_supply ?? null,
        dto.description_of_supply ?? null,
        dto.payment_mode ?? null,
        dto.deposit_account_id,
        dto.reference_number ?? null,
        dto.amount_received ?? 0,
        dto.bank_charges ?? 0,
        dto.is_tds_deducted ?? false,
        dto.tds_tax_id ?? null,
        dto.tds_amount ?? 0,
        dto.tax_id ?? null,
        dto.tax_amount ?? 0,
        dto.excess_amount ?? 0,
        status,
        dto.notes ?? null,
        tenant.userId || null,
        nowIso,
        nowIso,
      ],
    );

    const data = createdRows[0];
    if (!data) throw new Error("Failed to create payment received");

    const attachments = dto.attachments ?? [];
    if (attachments.length > 0) {
      try {
        await this.insertAttachments(data.id, attachments, tenant.userId);
      } catch (attachErr) {
        await client.unsafe(`DELETE FROM payments_received WHERE id = $1`, [data.id]);
        throw attachErr;
      }
    }

    const allocations = (dto.allocations ?? []).filter(
      (a) => (a.allocated_amount ?? 0) > 0,
    );
    if (allocations.length > 0) {
      try {
        await this.insertAllocations(
          entityId,
          data.id,
          dto.payment_date,
          allocations,
        );
      } catch (allocErr) {
        await client.unsafe(
          `DELETE FROM payment_received_attachments WHERE payment_received_id = $1`,
          [data.id],
        );
        await client.unsafe(`DELETE FROM payments_received WHERE id = $1`, [data.id]);
        throw allocErr;
      }
      const used = allocations.reduce(
        (sum, a) => sum + (a.allocated_amount ?? 0),
        0,
      );

      const updatedRows = await client.unsafe(
        `UPDATE payments_received SET amount_used_for_payments = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
        [used, data.id],
      );
      const updated = updatedRows[0];
      if (updated) {
        await this.syncJournalEntries(tenant, updated);
        return updated;
      }
    }

    await this.syncJournalEntries(tenant, data);
    return data;
  }

  private async insertAllocations(
    entityId: string,
    paymentReceivedId: string,
    defaultDate: string,
    allocations: CreatePaymentAllocationDto[],
  ) {
    for (const a of allocations) {
      await client.unsafe(
        `INSERT INTO payment_received_allocations (entity_id, payment_received_id, invoice_id, invoice_amount, amount_due, allocated_amount, payment_received_on, remarks)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
          entityId,
          paymentReceivedId,
          a.invoice_id,
          a.invoice_amount ?? 0,
          a.amount_due ?? 0,
          a.allocated_amount ?? 0,
          a.payment_received_on || defaultDate,
          a.remarks ?? null,
        ],
      );
    }
  }

  private async insertAttachments(
    paymentReceivedId: string,
    attachments: PaymentAttachmentDto[],
    userId?: string | null,
  ) {
    for (const att of attachments) {
      const base64 = (att.data_base64 ?? "").replace(/^data:[^;]+;base64,/, "");
      if (!base64) continue;
      const buffer = Buffer.from(base64, "base64");
      const mimeType = this.guessMimeType(att.file_name, att.file_type);
      const key = await this.r2StorageService.uploadFile(
        att.file_name,
        buffer,
        mimeType,
        "payments-received",
      );

      await client.unsafe(
        `INSERT INTO payment_received_attachments (payment_received_id, file_name, original_file_name, file_url, file_type, file_size, uploaded_by, remarks)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
          paymentReceivedId,
          att.file_name,
          att.file_name,
          key,
          att.file_type ?? mimeType,
          att.file_size ?? buffer.length,
          userId || null,
          att.remarks ?? null,
        ],
      );
    }
  }

  private guessMimeType(fileName: string, provided?: string): string {
    if (provided && provided.includes("/")) return provided;
    const ext = (fileName.split(".").pop() ?? "").toLowerCase();
    switch (ext) {
      case "pdf":
        return "application/pdf";
      case "png":
        return "image/png";
      case "jpg":
      case "jpeg":
        return "image/jpeg";
      case "gif":
        return "image/gif";
      case "webp":
        return "image/webp";
      case "doc":
        return "application/msword";
      case "docx":
        return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
      case "xls":
        return "application/vnd.ms-excel";
      case "xlsx":
        return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      case "csv":
        return "text/csv";
      default:
        return "application/octet-stream";
    }
  }

  async update(
    id: string,
    tenant: TenantContext,
    dto: UpdatePaymentReceivedDto,
  ) {
    const entityId = this.ensureEntityId(tenant);
    const existing = await this.findOne(id, tenant);

    const isDeleteVal = dto.is_delete;
    let paymentNumberVal = dto.payment_number;
    if (isDeleteVal === true) {
      const currentNum = (existing as any).payment_number || "";
      if (currentNum && !currentNum.startsWith("SD-")) {
        paymentNumberVal = `SD-${currentNum}`;
      }
    }

    const updatedRows = await client.unsafe(
      `UPDATE payments_received SET
         customer_id = COALESCE($1, customer_id),
         payment_number = COALESCE($2, payment_number),
         payment_type = COALESCE($3, payment_type),
         payment_date = COALESCE($4, payment_date),
         location_id = COALESCE($5, location_id),
         place_of_supply = COALESCE($6, place_of_supply),
         description_of_supply = COALESCE($7, description_of_supply),
         payment_mode = COALESCE($8, payment_mode),
         deposit_account_id = COALESCE($9, deposit_account_id),
         reference_number = COALESCE($10, reference_number),
         amount_received = COALESCE($11, amount_received),
         bank_charges = COALESCE($12, bank_charges),
         is_tds_deducted = COALESCE($13, is_tds_deducted),
         tds_tax_id = COALESCE($14, tds_tax_id),
         tds_amount = COALESCE($15, tds_amount),
         tax_id = COALESCE($16, tax_id),
         tax_amount = COALESCE($17, tax_amount),
         excess_amount = COALESCE($18, excess_amount),
         status = COALESCE($19, status),
         notes = COALESCE($20, notes),
         is_delete = COALESCE($21, is_delete),
         updated_at = NOW()
       WHERE id = $22 AND entity_id = $23
       RETURNING *`,
      [
        dto.customer_id ?? null,
        paymentNumberVal ?? null,
        dto.payment_type ?? null,
        dto.payment_date ?? null,
        dto.location_id ?? null,
        dto.place_of_supply ?? null,
        dto.description_of_supply ?? null,
        dto.payment_mode ?? null,
        dto.deposit_account_id ?? null,
        dto.reference_number ?? null,
        dto.amount_received ?? null,
        dto.bank_charges ?? null,
        dto.is_tds_deducted ?? null,
        dto.tds_tax_id ?? null,
        dto.tds_amount ?? null,
        dto.tax_id ?? null,
        dto.tax_amount ?? null,
        dto.excess_amount ?? null,
        dto.status ? dto.status.trim().toLowerCase() : null,
        dto.notes ?? null,
        isDeleteVal ?? null,
        id,
        entityId,
      ],
    );

    const data = updatedRows[0];
    if (!data) throw new Error("Failed to update payment received");

    if (dto.attachments && dto.attachments.length > 0) {
      await this.insertAttachments(id, dto.attachments, tenant.userId);
    }

    if (dto.allocations !== undefined) {
      await client.unsafe(
        `DELETE FROM payment_received_allocations WHERE payment_received_id = $1 AND entity_id = $2`,
        [id, entityId],
      );

      const allocations = (dto.allocations ?? []).filter(
        (a) => (a.allocated_amount ?? 0) > 0,
      );
      if (allocations.length > 0) {
        await this.insertAllocations(
          entityId,
          id,
          dto.payment_date ?? (data.payment_date as string),
          allocations,
        );
      }
      const used = allocations.reduce(
        (sum, a) => sum + (a.allocated_amount ?? 0),
        0,
      );

      const refreshRows = await client.unsafe(
        `UPDATE payments_received SET amount_used_for_payments = $1, updated_at = NOW() WHERE id = $2 AND entity_id = $3 RETURNING *`,
        [used, id, entityId],
      );
      const updated = refreshRows[0];
      if (updated) {
        await this.syncJournalEntries(tenant, updated);
        return updated;
      }
    }

    await this.syncJournalEntries(tenant, data);
    return data;
  }

  async findAll(
    tenant: TenantContext,
    page = 1,
    limit = 100,
    search?: string,
    status?: string,
  ) {
    const entityId = this.ensureEntityId(tenant);

    const safePage = page < 1 ? 1 : page;
    const safeLimit = limit < 1 ? 100 : limit;
    const offset = (safePage - 1) * safeLimit;

    let sqlQuery = `SELECT * FROM payments_received WHERE entity_id = $1 AND is_delete = false`;
    let countQuery = `SELECT COUNT(*)::int as count FROM payments_received WHERE entity_id = $1 AND is_delete = false`;
    const params: any[] = [entityId];

    if (status && status.trim()) {
      params.push(status.trim().toLowerCase());
      const stIdx = params.length;
      sqlQuery += ` AND status = $${stIdx}`;
      countQuery += ` AND status = $${stIdx}`;
    }
    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      const sIdx = params.length;
      sqlQuery += ` AND (payment_number ILIKE $${sIdx} OR reference_number ILIKE $${sIdx})`;
      countQuery += ` AND (payment_number ILIKE $${sIdx} OR reference_number ILIKE $${sIdx})`;
    }

    sqlQuery += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    const [data, countRes] = await Promise.all([
      client.unsafe(sqlQuery, [...params, safeLimit, offset]),
      client.unsafe(countQuery, params),
    ]);

    const totalCount = countRes[0]?.count ?? 0;

    const enrichedWithCustomers = await this.attachCustomers((data as any[]) ?? []);
    const enriched = await this.attachLocations(enrichedWithCustomers as any);

    return {
      data: enriched,
      page: safePage,
      limit: safeLimit,
      total: totalCount,
    };
  }

  private async attachCustomers(
    rows: Array<{ customer_id?: string | null }>,
  ): Promise<Array<Record<string, unknown>>> {
    if (!rows.length) return rows as Array<Record<string, unknown>>;

    const customerIds = Array.from(
      new Set(
        rows
          .map((row) => row.customer_id)
          .filter((id): id is string => typeof id === "string" && id.length > 0),
      ),
    );

    if (!customerIds.length) {
      return rows.map((row) => ({ ...row, customer_name: null }));
    }

    const customers = await client.unsafe(
      `SELECT id, display_name, first_name, last_name, company_name FROM customers WHERE id = ANY($1)`,
      [customerIds],
    );

    const nameById = new Map<string, string>();
    for (const c of customers ?? []) {
      const name =
        c.display_name ||
        c.company_name ||
        [c.first_name, c.last_name].filter(Boolean).join(" ").trim();
      if (c.id) nameById.set(c.id, name || "");
    }

    return rows.map((row) => ({
      ...row,
      customer_name: row.customer_id
        ? nameById.get(row.customer_id) ?? null
        : null,
    }));
  }

  private async attachLocations(
    rows: Array<{ location_id?: string | null; entity_id?: string | null }>,
  ): Promise<Array<Record<string, unknown>>> {
    if (!rows.length) return rows as Array<Record<string, unknown>>;

    const entityId = rows[0].entity_id;
    let defaultWarehouseName: string | null = null;
    if (entityId) {
      const wh = await client.unsafe(
        `SELECT name FROM warehouses WHERE entity_id = $1 LIMIT 1`,
        [entityId],
      );
      if (wh && wh.length > 0) {
        defaultWarehouseName = wh[0].name;
      }
    }

    const locationIds = Array.from(
      new Set(
        rows
          .map((row) => row.location_id)
          .filter((id): id is string => typeof id === "string" && id.length > 0),
      ),
    );

    const nameById = new Map<string, string>();
    if (locationIds.length > 0) {
      const warehouses = await client.unsafe(
        `SELECT id, name FROM warehouses WHERE id = ANY($1)`,
        [locationIds],
      );

      for (const w of warehouses ?? []) {
        if (w.id) nameById.set(w.id, w.name || "");
      }
    }

    return rows.map((row) => ({
      ...row,
      location_name: row.location_id
        ? nameById.get(row.location_id) ?? defaultWarehouseName
        : defaultWarehouseName,
    }));
  }

  async findOne(id: string, tenant: TenantContext) {
    const entityId = this.ensureEntityId(tenant);

    const rows = await client.unsafe(
      `SELECT * FROM payments_received WHERE id = $1 AND entity_id = $2 LIMIT 1`,
      [id, entityId],
    );

    const data = rows[0];
    if (!data) {
      throw new NotFoundException("Payment received not found");
    }

    const allocations = await client.unsafe(
      `SELECT * FROM payment_received_allocations WHERE payment_received_id = $1 AND entity_id = $2`,
      [id, entityId],
    );

    const enriched = await this.attachLocations([data] as any);

    return { ...enriched[0], allocations: allocations ?? [] };
  }

  async getInvoiceCustomers(tenant: TenantContext) {
    const entityId = this.ensureEntityId(tenant);

    const invoices = await client.unsafe(
      `SELECT customer_id FROM invoice_master WHERE entity_id = $1 AND is_delete = false`,
      [entityId],
    );

    const customerIds = Array.from(
      new Set(
        (invoices ?? [])
          .map((row: any) => row.customer_id)
          .filter((id: unknown): id is string => typeof id === "string" && id.length > 0),
      ),
    );
    if (!customerIds.length) return [];

    const customers = await client.unsafe(
      `SELECT id, display_name, first_name, last_name, company_name, customer_number, email FROM customers WHERE id = ANY($1)`,
      [customerIds],
    );

    return (customers ?? [])
      .map((c: any) => ({
        id: c.id,
        name:
          c.display_name ||
          c.company_name ||
          [c.first_name, c.last_name].filter(Boolean).join(" ").trim() ||
          "",
        customer_number: c.customer_number ?? null,
        email: c.email ?? null,
      }))
      .filter((c: any) => c.name)
      .sort((a: any, b: any) => a.name.localeCompare(b.name));
  }

  async getUnpaidInvoices(tenant: TenantContext, customerId: string) {
    const entityId = this.ensureEntityId(tenant);

    const invoices = await client.unsafe(
      `SELECT id, invoice_number, invoice_date, due_date, grand_total, status, place_of_supply
       FROM invoice_master
       WHERE entity_id = $1 AND customer_id = $2 AND is_delete = false
       ORDER BY invoice_date ASC`,
      [entityId, customerId],
    );

    const list = invoices ?? [];
    if (!list.length) return [];

    const invoiceIds = list.map((i: any) => i.id);
    const allocations = await client.unsafe(
      `SELECT invoice_id, allocated_amount FROM payment_received_allocations WHERE invoice_id = ANY($1)`,
      [invoiceIds],
    );

    const allocatedByInvoice = new Map<string, number>();
    for (const a of allocations ?? []) {
      if (!a.invoice_id) continue;
      allocatedByInvoice.set(
        a.invoice_id,
        (allocatedByInvoice.get(a.invoice_id) ?? 0) +
          Number(a.allocated_amount ?? 0),
      );
    }

    return list
      .filter((inv: any) => {
        const status = (inv.status ?? "").toString().toLowerCase();
        return status !== "draft" && status !== "void" && status !== "cancelled";
      })
      .map((inv: any) => {
        const total = Number(inv.grand_total ?? 0);
        const due = total - (allocatedByInvoice.get(inv.id) ?? 0);
        return {
          id: inv.id,
          invoice_number: inv.invoice_number,
          invoice_date: inv.invoice_date,
          due_date: inv.due_date,
          place_of_supply: inv.place_of_supply,
          invoice_amount: total,
          amount_due: due,
        };
      })
      .filter((inv: any) => inv.amount_due > 0);
  }

  async syncJournalEntries(tenant: TenantContext, paymentData: any) {
    try {
      const entityId = this.ensureEntityId(tenant);
      const paymentId = paymentData.id;
      const paymentNumber = String(paymentData.payment_number || "");
      const customerId = paymentData.customer_id || null;
      const amountReceived = Number(paymentData.amount_received || 0);
      const paymentDate = paymentData.payment_date || new Date().toISOString().split("T")[0];
      const depositAccountIdRef = paymentData.deposit_account_id || null;

      if (!paymentId) return;

      const allAccs = await client.unsafe(
        `SELECT id, user_account_name, system_account_name, account_type FROM accounts`,
      );

      let depositToId: string | null = null;
      let unearnedRevId: string | null = null;
      let accountsReceivableId: string | null = null;

      const targetDeposit = depositAccountIdRef ? String(depositAccountIdRef).trim().toLowerCase() : "";

      for (const row of (allAccs || [])) {
        const accId = String(row.id || "");
        const userAcc = String(row.user_account_name || "").trim().toLowerCase();
        const sysAcc = String(row.system_account_name || "").trim().toLowerCase();

        if (!depositToId && targetDeposit) {
          if (accId === depositAccountIdRef || userAcc === targetDeposit || sysAcc === targetDeposit) {
            depositToId = accId;
          }
        }

        if (!unearnedRevId) {
          if (sysAcc === "unearned revenue" || userAcc === "unearned revenue" || sysAcc.includes("unearned") || userAcc.includes("unearned") || sysAcc.includes("advance") || userAcc.includes("advance") || sysAcc.includes("deferred") || userAcc.includes("deferred")) {
            unearnedRevId = accId;
          }
        }

        if (!accountsReceivableId) {
          if (
            sysAcc === "accounts receivable" ||
            userAcc === "accounts receivable" ||
            sysAcc === "accounts_receivable" ||
            userAcc === "accounts_receivable"
          ) {
            accountsReceivableId = accId;
          }
        }
      }

      if (!depositToId) {
        depositToId = depositAccountIdRef ? String(depositAccountIdRef) : (allAccs?.[0]?.id || null);
      }
      if (!unearnedRevId) {
        unearnedRevId = depositToId;
      }
      if (!accountsReceivableId) {
        for (const row of (allAccs || [])) {
          const accId = String(row.id || "");
          const userAcc = String(row.user_account_name || "").trim().toLowerCase();
          const sysAcc = String(row.system_account_name || "").trim().toLowerCase();
          const isTdsOrTcs = userAcc.includes("tds") || sysAcc.includes("tds") || userAcc.includes("tcs") || sysAcc.includes("tcs");
          if (!isTdsOrTcs && (sysAcc.includes("accounts") && sysAcc.includes("receivable"))) {
            accountsReceivableId = accId;
            break;
          }
        }
        accountsReceivableId ??= depositToId;
      }

      const existingJE = await client.unsafe(
        `SELECT id FROM journal_entries
         WHERE (source_document_type = 'payments_received' OR source_document_type = 'PAYMENT_RECEIVED')
         AND (source_document_id = $1 OR journal_number = $2) LIMIT 1`,
        [paymentId, paymentNumber],
      );

      const journalEntryId = existingJE[0]?.id || uuidv4();
      const defaultOrgId = tenant.orgId || "00000000-0000-0000-0000-000000000000";

      if (existingJE[0]?.id) {
        await client.unsafe(
          `UPDATE journal_entries SET
             org_id = $1, entity_id = $2, journal_number = $3, journal_type = 'payments received',
             journal_date = $4, posting_date = $4, reference_number = $5, narration = $6,
             source_module = 'sales', source_document_type = 'payments_received', source_document_id = $7,
             status = 'POSTED', updated_by = $8
           WHERE id = $9`,
          [
            defaultOrgId,
            entityId,
            paymentNumber,
            paymentDate,
            paymentData.reference_number || paymentNumber,
            paymentData.notes || `Payment Received ${paymentNumber}`,
            paymentId,
            tenant.userId || null,
            journalEntryId,
          ],
        );
        await client.unsafe(
          `DELETE FROM journal_entry_lines WHERE journal_entry_id = $1`,
          [journalEntryId],
        );
      } else {
        await client.unsafe(
          `INSERT INTO journal_entries (id, org_id, entity_id, journal_number, journal_type, journal_date, posting_date, reference_number, narration, source_module, source_document_type, source_document_id, status, created_by, updated_by)
           VALUES ($1, $2, $3, $4, 'payments received', $5, $5, $6, $7, 'sales', 'payments_received', $8, 'POSTED', $9, $9)`,
          [
            journalEntryId,
            defaultOrgId,
            entityId,
            paymentNumber,
            paymentDate,
            paymentData.reference_number || paymentNumber,
            paymentData.notes || `Payment Received ${paymentNumber}`,
            paymentId,
            tenant.userId || null,
          ],
        );
      }

      const lines: Array<Record<string, any>> = [];
      const mainDesc = `Customer Payment - ${paymentNumber}`;

      if (amountReceived > 0) {
        lines.push({
          id: uuidv4(),
          journal_entry_id: journalEntryId,
          account_id: depositToId,
          transaction_date: paymentDate,
          reference_number: paymentNumber,
          description: mainDesc,
          debit: amountReceived,
          credit: 0,
          source_id: paymentId,
          source_type: "payments_received",
          contact_id: customerId,
          contact_type: "customer",
          entity_id: entityId,
          org_id: defaultOrgId,
        });

        lines.push({
          id: uuidv4(),
          journal_entry_id: journalEntryId,
          account_id: unearnedRevId,
          transaction_date: paymentDate,
          reference_number: paymentNumber,
          description: mainDesc,
          debit: 0,
          credit: amountReceived,
          source_id: paymentId,
          source_type: "payments_received",
          contact_id: customerId,
          contact_type: "customer",
          entity_id: entityId,
          org_id: defaultOrgId,
        });
      }

      const allocRes = await client.unsafe(
        `SELECT pra.*, im.invoice_number FROM payment_received_allocations pra
         LEFT JOIN invoice_master im ON im.id = pra.invoice_id
         WHERE pra.payment_received_id = $1`,
        [paymentId],
      );

      for (const row of (allocRes || [])) {
        let invNo = String(row.invoice_number || "");
        if (!invNo) invNo = paymentNumber;

        const invAmt = Number(row.allocated_amount || 0);
        if (invAmt > 0) {
          const invDesc = `Invoice Payment - ${invNo}`;
          lines.push({
            id: uuidv4(),
            journal_entry_id: journalEntryId,
            account_id: accountsReceivableId,
            transaction_date: paymentDate,
            reference_number: invNo,
            description: invDesc,
            debit: 0,
            credit: invAmt,
            source_id: paymentId,
            source_type: "payments_received",
            contact_id: customerId,
            contact_type: "customer",
            entity_id: entityId,
            org_id: defaultOrgId,
          });
          lines.push({
            id: uuidv4(),
            journal_entry_id: journalEntryId,
            account_id: unearnedRevId,
            transaction_date: paymentDate,
            reference_number: invNo,
            description: invDesc,
            debit: invAmt,
            credit: 0,
            source_id: paymentId,
            source_type: "payments_received",
            contact_id: customerId,
            contact_type: "customer",
            entity_id: entityId,
            org_id: defaultOrgId,
          });
        }
      }

      const refundRes = await client.unsafe(
        `SELECT * FROM payment_received_refunds WHERE payment_received_id = $1`,
        [paymentId],
      );

      for (const refRow of (refundRes || [])) {
        const rNo = String(refRow.refund_number || refRow.reference_number || "1");
        const rAmt = Number(refRow.amount_refunded || refRow.amount || 0);
        const rDesc = `Payment Refund - ${rNo}`;
        const fromAccId = refRow.from_account_id || depositToId;
        if (rAmt > 0) {
          lines.push({
            id: uuidv4(),
            journal_entry_id: journalEntryId,
            account_id: fromAccId,
            transaction_date: paymentDate,
            reference_number: rNo,
            description: rDesc,
            debit: 0,
            credit: rAmt,
            source_id: paymentId,
            source_type: "payments_received",
            contact_id: customerId,
            contact_type: "customer",
            entity_id: entityId,
            org_id: defaultOrgId,
          });
          lines.push({
            id: uuidv4(),
            journal_entry_id: journalEntryId,
            account_id: unearnedRevId,
            transaction_date: paymentDate,
            reference_number: rNo,
            description: rDesc,
            debit: rAmt,
            credit: 0,
            source_id: paymentId,
            source_type: "payments_received",
            contact_id: customerId,
            contact_type: "customer",
            entity_id: entityId,
            org_id: defaultOrgId,
          });
        }
      }

      for (const line of lines) {
        await client.unsafe(
          `INSERT INTO journal_entry_lines (id, journal_entry_id, account_id, transaction_date, reference_number, description, debit, credit, source_id, source_type, contact_id, contact_type, entity_id, org_id)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`,
          [
            line.id,
            line.journal_entry_id,
            line.account_id,
            line.transaction_date,
            line.reference_number,
            line.description,
            line.debit,
            line.credit,
            line.source_id,
            line.source_type,
            line.contact_id,
            line.contact_type,
            line.entity_id,
            line.org_id,
          ],
        );
      }
    } catch (err: any) {
      console.error("Failed to sync journal entries for payment received:", err?.message || err);
    }
  }
}
