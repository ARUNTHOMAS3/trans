import { Injectable, NotFoundException } from "@nestjs/common";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../supabase/supabase.service";
import { client } from "../../../db/db";

@Injectable()
export class RetainerInvoicesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private ensureEntityId(tenant: TenantContext): string {
    if (!tenant?.entityId) {
      throw new Error("Tenant entity context is required");
    }
    return tenant.entityId;
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

    let sqlQuery = `SELECT * FROM retainer_invoices WHERE entity_id = $1 AND is_deleted = false`;
    let countQuery = `SELECT COUNT(*)::int as count FROM retainer_invoices WHERE entity_id = $1 AND is_deleted = false`;
    const params: any[] = [entityId];

    if (status && status.trim()) {
      params.push(status.trim().toLowerCase());
      sqlQuery += ` AND status = $${params.length}`;
      countQuery += ` AND status = $${params.length}`;
    }

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      const searchIdx = params.length;
      sqlQuery += ` AND (retainer_invoice_number ILIKE $${searchIdx} OR reference_number ILIKE $${searchIdx})`;
      countQuery += ` AND (retainer_invoice_number ILIKE $${searchIdx} OR reference_number ILIKE $${searchIdx})`;
    }

    sqlQuery += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    const [data, countRes] = await Promise.all([
      client.unsafe(sqlQuery, [...params, safeLimit, offset]),
      client.unsafe(countQuery, params),
    ]);

    const totalCount = countRes[0]?.count ?? 0;
    const enrichedWithCustomers = await this.attachCustomers((data as any[]) ?? []);

    return {
      data: enrichedWithCustomers,
      page: safePage,
      limit: safeLimit,
      total: totalCount,
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const entityId = this.ensureEntityId(tenant);

    const rows = await client.unsafe(
      `SELECT * FROM retainer_invoices WHERE id = $1 AND entity_id = $2 AND is_deleted = false LIMIT 1`,
      [id, entityId],
    );

    const invoice = rows[0];
    if (!invoice) {
      throw new NotFoundException(`Retainer invoice with ID ${id} not found`);
    }

    const items = await client.unsafe(
      `SELECT * FROM retainer_invoice_items WHERE retainer_invoice_id = $1 ORDER BY line_no ASC`,
      [id],
    );

    const enriched = await this.attachCustomers([invoice as any]);

    return {
      data: {
        ...enriched[0],
        items: items ?? [],
      },
    };
  }

  async create(tenant: TenantContext, body: any) {
    const entityId = this.ensureEntityId(tenant);
    const nowIso = new Date().toISOString();

    const customerId = body.customerId ?? body.customer_id;
    const transactionSeriesId =
      body.transactionSeriesId ?? body.transaction_series_id;
    const retainerInvoiceNumber =
      body.retainerInvoiceNumber ?? body.retainer_invoice_number;
    const referenceNumber = body.referenceNumber ?? body.reference_number;
    const retainerInvoiceDate =
      body.retainerInvoiceDate ?? body.retainer_invoice_date;
    const customerNotes = body.customerNotes ?? body.customer_notes;
    const termsConditions = body.termsConditions ?? body.terms_conditions;
    const subtotal = body.subtotal ?? 0;
    const roundOff = body.roundOff ?? body.round_off ?? 0;
    const totalAmount = body.totalAmount ?? body.total_amount ?? 0;
    const amountReceived = body.amountReceived ?? body.amount_received ?? 0;
    const amountApplied = body.amountApplied ?? body.amount_applied ?? 0;
    const balanceAmount = body.balanceAmount ?? body.balance_amount ?? 0;
    const status = (body.status ?? "draft").toLowerCase();

    const createdRows = await client.unsafe(
      `INSERT INTO retainer_invoices (entity_id, customer_id, transaction_series_id, retainer_invoice_number, reference_number, retainer_invoice_date, customer_notes, terms_conditions, subtotal, round_off, total_amount, amount_received, amount_applied, balance_amount, status, created_by, created_at, updated_at, is_deleted)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, false)
       RETURNING *`,
      [
        entityId,
        customerId,
        transactionSeriesId || null,
        retainerInvoiceNumber,
        referenceNumber || null,
        retainerInvoiceDate,
        customerNotes || null,
        termsConditions || null,
        subtotal,
        roundOff,
        totalAmount,
        amountReceived,
        amountApplied,
        balanceAmount,
        status,
        tenant.userId || null,
        nowIso,
        nowIso,
      ],
    );

    const created = createdRows[0];
    if (!created) {
      throw new Error("Failed to create retainer invoice");
    }

    if (Array.isArray(body.items) && body.items.length > 0) {
      for (let idx = 0; idx < body.items.length; idx++) {
        const item = body.items[idx];
        await client.unsafe(
          `INSERT INTO retainer_invoice_items (retainer_invoice_id, line_no, description, amount)
           VALUES ($1, $2, $3, $4)`,
          [
            created.id,
            item.lineNo ?? item.line_no ?? idx + 1,
            item.description ?? "",
            item.amount ?? 0,
          ],
        );
      }
    }

    return { data: created };
  }

  async update(id: string, tenant: TenantContext, body: any) {
    const entityId = this.ensureEntityId(tenant);
    const nowIso = new Date().toISOString();

    const customerId = body.customerId ?? body.customer_id;
    const transactionSeriesId =
      body.transactionSeriesId ?? body.transaction_series_id;
    const retainerInvoiceNumber =
      body.retainerInvoiceNumber ?? body.retainer_invoice_number;
    const referenceNumber = body.referenceNumber ?? body.reference_number;
    const retainerInvoiceDate =
      body.retainerInvoiceDate ?? body.retainer_invoice_date;
    const customerNotes = body.customerNotes ?? body.customer_notes;
    const termsConditions = body.termsConditions ?? body.terms_conditions;
    const subtotal = body.subtotal;
    const roundOff = body.roundOff ?? body.round_off;
    const totalAmount = body.totalAmount ?? body.total_amount;
    const amountReceived = body.amountReceived ?? body.amount_received;
    const amountApplied = body.amountApplied ?? body.amount_applied;
    const balanceAmount = body.balanceAmount ?? body.balance_amount;
    const status = body.status ? body.status.toLowerCase() : null;

    const updatedRows = await client.unsafe(
      `UPDATE retainer_invoices SET
         customer_id = COALESCE($1, customer_id),
         transaction_series_id = COALESCE($2, transaction_series_id),
         retainer_invoice_number = COALESCE($3, retainer_invoice_number),
         reference_number = COALESCE($4, reference_number),
         retainer_invoice_date = COALESCE($5, retainer_invoice_date),
         customer_notes = COALESCE($6, customer_notes),
         terms_conditions = COALESCE($7, terms_conditions),
         subtotal = COALESCE($8, subtotal),
         round_off = COALESCE($9, round_off),
         total_amount = COALESCE($10, total_amount),
         amount_received = COALESCE($11, amount_received),
         amount_applied = COALESCE($12, amount_applied),
         balance_amount = COALESCE($13, balance_amount),
         status = COALESCE($14, status),
         updated_at = $15
       WHERE id = $16 AND entity_id = $17 AND is_deleted = false
       RETURNING *`,
      [
        customerId ?? null,
        transactionSeriesId ?? null,
        retainerInvoiceNumber ?? null,
        referenceNumber ?? null,
        retainerInvoiceDate ?? null,
        customerNotes ?? null,
        termsConditions ?? null,
        subtotal ?? null,
        roundOff ?? null,
        totalAmount ?? null,
        amountReceived ?? null,
        amountApplied ?? null,
        balanceAmount ?? null,
        status,
        nowIso,
        id,
        entityId,
      ],
    );

    const updated = updatedRows[0];
    if (!updated) {
      throw new Error("Failed to update retainer invoice");
    }

    if (Array.isArray(body.items)) {
      await client.unsafe(
        `DELETE FROM retainer_invoice_items WHERE retainer_invoice_id = $1`,
        [id],
      );

      if (body.items.length > 0) {
        for (let idx = 0; idx < body.items.length; idx++) {
          const item = body.items[idx];
          await client.unsafe(
            `INSERT INTO retainer_invoice_items (retainer_invoice_id, line_no, description, amount)
             VALUES ($1, $2, $3, $4)`,
            [
              id,
              item.lineNo ?? item.line_no ?? idx + 1,
              item.description ?? "",
              item.amount ?? 0,
            ],
          );
        }
      }
    }

    return { data: updated };
  }

  async delete(id: string, tenant: TenantContext) {
    const entityId = this.ensureEntityId(tenant);

    await client.unsafe(
      `UPDATE retainer_invoices SET is_deleted = true, updated_at = NOW() WHERE id = $1 AND entity_id = $2`,
      [id, entityId],
    );

    return { success: true };
  }

  private async attachCustomers(
    rows: Array<{ customer_id?: string | null }>,
  ): Promise<Array<Record<string, unknown>>> {
    if (!rows.length) return rows as Array<Record<string, unknown>>;

    const customerIds = Array.from(
      new Set(
        rows
          .map((row) => row.customer_id)
          .filter(
            (id): id is string => typeof id === "string" && id.length > 0,
          ),
      ),
    );

    if (!customerIds.length) {
      return rows.map((row) => ({
        ...row,
        customer: null,
        customer_name: null,
      }));
    }

    const customers = await client.unsafe(
      `SELECT id, display_name, first_name, last_name, company_name FROM customers WHERE id = ANY($1)`,
      [customerIds],
    );

    const customerMap = new Map<string, any>();
    if (customers) {
      for (const c of customers) {
        customerMap.set(c.id, c);
      }
    }

    return rows.map((row) => {
      const c = row.customer_id ? customerMap.get(row.customer_id) : null;
      const displayName =
        c?.display_name ||
        [c?.first_name, c?.last_name].filter(Boolean).join(" ") ||
        c?.company_name ||
        null;

      return {
        ...row,
        customer: c ?? null,
        customer_name: displayName,
      };
    });
  }
}
