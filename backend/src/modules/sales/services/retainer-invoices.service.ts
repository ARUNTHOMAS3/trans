import { Injectable, NotFoundException } from "@nestjs/common";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../supabase/supabase.service";

@Injectable()
export class RetainerInvoicesService {
  constructor(private readonly supabaseService: SupabaseService) { }

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
    const client = this.supabaseService.getClient();
    const entityId = this.ensureEntityId(tenant);

    const safePage = page < 1 ? 1 : page;
    const safeLimit = limit < 1 ? 100 : limit;
    const from = (safePage - 1) * safeLimit;
    const to = from + safeLimit - 1;

    let query = client
      .from("retainer_invoices")
      .select("*", { count: "exact" })
      .eq("entity_id", entityId)
      .eq("is_deleted", false)
      .order("created_at", { ascending: false })
      .range(from, to);

    if (status && status.trim()) {
      query = query.eq("status", status.trim().toLowerCase());
    }
    if (search && search.trim()) {
      const term = `%${search.trim()}%`;
      query = query.or(
        `retainer_invoice_number.ilike.${term},reference_number.ilike.${term}`,
      );
    }

    const { data, error, count } = await query;

    if (error) {
      throw new Error(
        `Failed to load retainer invoices: ${(error as any)?.message ?? "Unknown error"}`,
      );
    }

    const enrichedWithCustomers = await this.attachCustomers(client, data ?? []);

    return {
      data: enrichedWithCustomers,
      page: safePage,
      limit: safeLimit,
      total: count ?? 0,
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const entityId = this.ensureEntityId(tenant);

    const { data: invoice, error } = await client
      .from("retainer_invoices")
      .select("*")
      .eq("id", id)
      .eq("entity_id", entityId)
      .eq("is_deleted", false)
      .single();

    if (error || !invoice) {
      throw new NotFoundException(`Retainer invoice with ID ${id} not found`);
    }

    const { data: items } = await client
      .from("retainer_invoice_items")
      .select("*")
      .eq("retainer_invoice_id", id)
      .order("line_no", { ascending: true });

    const enriched = await this.attachCustomers(client, [invoice]);

    return {
      data: {
        ...enriched[0],
        items: items ?? [],
      },
    };
  }

  async create(tenant: TenantContext, body: any) {
    const client = this.supabaseService.getClient();
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

    const payload = {
      entity_id: entityId,
      customer_id: customerId,
      transaction_series_id: transactionSeriesId || null,
      retainer_invoice_number: retainerInvoiceNumber,
      reference_number: referenceNumber || null,
      retainer_invoice_date: retainerInvoiceDate,
      customer_notes: customerNotes || null,
      terms_conditions: termsConditions || null,
      subtotal,
      round_off: roundOff,
      total_amount: totalAmount,
      amount_received: amountReceived,
      amount_applied: amountApplied,
      balance_amount: balanceAmount,
      status,
      created_by: tenant.userId || null,
      created_at: nowIso,
      updated_at: nowIso,
      is_deleted: false,
    };

    const { data: created, error } = await client
      .from("retainer_invoices")
      .insert(payload)
      .select("*")
      .single();

    if (error || !created) {
      throw new Error(
        `Failed to create retainer invoice: ${(error as any)?.message ?? "Unknown error"}`,
      );
    }

    if (Array.isArray(body.items) && body.items.length > 0) {
      const itemRows = body.items.map((item: any, idx: number) => ({
        retainer_invoice_id: created.id,
        line_no: item.lineNo ?? item.line_no ?? idx + 1,
        description: item.description ?? "",
        amount: item.amount ?? 0,
      }));

      await client.from("retainer_invoice_items").insert(itemRows);
    }

    return { data: created };
  }

  async update(id: string, tenant: TenantContext, body: any) {
    const client = this.supabaseService.getClient();
    const entityId = this.ensureEntityId(tenant);
    const nowIso = new Date().toISOString();

    const updates: Record<string, unknown> = { updated_at: nowIso };
    const assign = (key: string, value: unknown) => {
      if (value !== undefined) updates[key] = value;
    };

    assign("customer_id", body.customerId ?? body.customer_id);
    assign(
      "transaction_series_id",
      body.transactionSeriesId ?? body.transaction_series_id,
    );
    assign(
      "retainer_invoice_number",
      body.retainerInvoiceNumber ?? body.retainer_invoice_number,
    );
    assign("reference_number", body.referenceNumber ?? body.reference_number);
    assign(
      "retainer_invoice_date",
      body.retainerInvoiceDate ?? body.retainer_invoice_date,
    );
    assign("customer_notes", body.customerNotes ?? body.customer_notes);
    assign("terms_conditions", body.termsConditions ?? body.terms_conditions);
    assign("subtotal", body.subtotal);
    assign("round_off", body.roundOff ?? body.round_off);
    assign("total_amount", body.totalAmount ?? body.total_amount);
    assign("amount_received", body.amountReceived ?? body.amount_received);
    assign("amount_applied", body.amountApplied ?? body.amount_applied);
    assign("balance_amount", body.balanceAmount ?? body.balance_amount);
    if (body.status) assign("status", body.status.toLowerCase());

    const { data: updated, error } = await client
      .from("retainer_invoices")
      .update(updates)
      .eq("id", id)
      .eq("entity_id", entityId)
      .eq("is_deleted", false)
      .select("*")
      .single();

    if (error || !updated) {
      throw new Error(
        `Failed to update retainer invoice: ${(error as any)?.message ?? "Unknown error"}`,
      );
    }

    if (Array.isArray(body.items)) {
      await client
        .from("retainer_invoice_items")
        .delete()
        .eq("retainer_invoice_id", id);

      if (body.items.length > 0) {
        const itemRows = body.items.map((item: any, idx: number) => ({
          retainer_invoice_id: id,
          line_no: item.lineNo ?? item.line_no ?? idx + 1,
          description: item.description ?? "",
          amount: item.amount ?? 0,
        }));
        await client.from("retainer_invoice_items").insert(itemRows);
      }
    }

    return { data: updated };
  }

  async delete(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const entityId = this.ensureEntityId(tenant);

    const { error } = await client
      .from("retainer_invoices")
      .update({ is_deleted: true, updated_at: new Date().toISOString() })
      .eq("id", id)
      .eq("entity_id", entityId);

    if (error) {
      throw new Error(
        `Failed to delete retainer invoice: ${(error as any)?.message ?? "Unknown error"}`,
      );
    }

    return { success: true };
  }

  private async attachCustomers(
    client: ReturnType<SupabaseService["getClient"]>,
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

    const { data: customers } = await client
      .from("customers")
      .select("id, display_name, first_name, last_name, company_name")
      .in("id", customerIds);

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
