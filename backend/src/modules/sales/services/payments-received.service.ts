import { Injectable, NotFoundException } from "@nestjs/common";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../supabase/supabase.service";
import { R2StorageService } from "../../accountant/r2-storage.service";
import {
  CreatePaymentAllocationDto,
  CreatePaymentReceivedDto,
  PaymentAttachmentDto,
} from "../dto/create-payment-received.dto";
import { UpdatePaymentReceivedDto } from "../dto/update-payment-received.dto";

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
    const client = this.supabaseService.getClient();
    const entityId = this.ensureEntityId(tenant);
    const nowIso = new Date().toISOString();

    const status = (dto.status ?? "draft").trim().toLowerCase();

    const payload = {
      entity_id: entityId,
      customer_id: dto.customer_id,
      payment_number: dto.payment_number,
      payment_type: dto.payment_type ?? "INVOICE_PAYMENT",
      payment_date: dto.payment_date,
      location_id: dto.location_id ?? null,
      place_of_supply: dto.place_of_supply ?? null,
      description_of_supply: dto.description_of_supply ?? null,
      payment_mode: dto.payment_mode ?? null,
      deposit_account_id: dto.deposit_account_id,
      reference_number: dto.reference_number ?? null,
      amount_received: dto.amount_received ?? 0,
      bank_charges: dto.bank_charges ?? 0,
      is_tds_deducted: dto.is_tds_deducted ?? false,
      tds_tax_id: dto.tds_tax_id ?? null,
      tds_amount: dto.tds_amount ?? 0,
      tax_id: dto.tax_id ?? null,
      tax_amount: dto.tax_amount ?? 0,
      excess_amount: dto.excess_amount ?? 0,
      status,
      is_delete: false,
      notes: dto.notes ?? null,
      created_by: tenant.userId || null,
      created_at: nowIso,
      updated_at: nowIso,
    };

    const { data, error } = await client
      .from("payments_received")
      .insert([payload])
      .select("*")
      .single();

    if (error || !data) {
      throw new Error(
        `Failed to create payment received: ${
          (error as any)?.message ?? "Unknown error"
        }`,
      );
    }

    // Upload + link attachments first so a storage failure rolls back cleanly
    // (before any allocations exist).
    const attachments = dto.attachments ?? [];
    if (attachments.length > 0) {
      try {
        await this.insertAttachments(data.id, attachments, tenant.userId);
      } catch (attachErr) {
        await client.from("payments_received").delete().eq("id", data.id);
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
        // Roll back the header (and any attachments) so we never leave an
        // orphaned payment.
        await client
          .from("payment_received_attachments")
          .delete()
          .eq("payment_received_id", data.id);
        await client.from("payments_received").delete().eq("id", data.id);
        throw allocErr;
      }
      const used = allocations.reduce(
        (sum, a) => sum + (a.allocated_amount ?? 0),
        0,
      );
      const { data: updated } = await client
        .from("payments_received")
        .update({ amount_used_for_payments: used, updated_at: nowIso })
        .eq("id", data.id)
        .select("*")
        .single();
      if (updated) return updated;
    }

    return data;
  }

  /// Inserts allocation rows for a payment. `defaultDate` is used when an entry
  /// omits its own payment_received_on.
  private async insertAllocations(
    entityId: string,
    paymentReceivedId: string,
    defaultDate: string,
    allocations: CreatePaymentAllocationDto[],
  ) {
    const client = this.supabaseService.getClient();
    const rows = allocations.map((a) => ({
      entity_id: entityId,
      payment_received_id: paymentReceivedId,
      invoice_id: a.invoice_id,
      invoice_amount: a.invoice_amount ?? 0,
      amount_due: a.amount_due ?? 0,
      allocated_amount: a.allocated_amount ?? 0,
      payment_received_on: a.payment_received_on || defaultDate,
      remarks: a.remarks ?? null,
    }));

    const { error } = await client
      .from("payment_received_allocations")
      .insert(rows);

    if (error) {
      throw new Error(
        `Failed to save payment allocations: ${
          (error as any)?.message ?? "Unknown error"
        }`,
      );
    }
  }

  /// Uploads each attachment's bytes to Cloudflare R2 and inserts a linking row
  /// into `payment_received_attachments`. `file_url` stores the R2 key; a
  /// presigned URL is generated on read. This table has no `entity_id` — tenant
  /// scoping is inherited through the parent payment.
  private async insertAttachments(
    paymentReceivedId: string,
    attachments: PaymentAttachmentDto[],
    userId?: string | null,
  ) {
    const client = this.supabaseService.getClient();
    const rows: Array<Record<string, unknown>> = [];

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
      rows.push({
        payment_received_id: paymentReceivedId,
        file_name: att.file_name,
        original_file_name: att.file_name,
        file_url: key,
        file_type: att.file_type ?? mimeType,
        file_size: att.file_size ?? buffer.length,
        uploaded_by: userId || null,
        remarks: att.remarks ?? null,
      });
    }

    if (!rows.length) return;

    const { error } = await client
      .from("payment_received_attachments")
      .insert(rows);

    if (error) {
      throw new Error(
        `Failed to save payment attachments: ${
          (error as any)?.message ?? "Unknown error"
        }`,
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
    const client = this.supabaseService.getClient();
    const entityId = this.ensureEntityId(tenant);

    // Ensure the row exists and belongs to this tenant before updating.
    const existing = await this.findOne(id, tenant);

    const updates: Record<string, unknown> = { updated_at: new Date().toISOString() };
    const assign = (key: string, value: unknown) => {
      if (value !== undefined) updates[key] = value;
    };

    if (dto.is_delete === true) {
      updates.is_delete = true;
      const currentNum = (existing as any).payment_number || "";
      if (currentNum && !currentNum.startsWith("SD-")) {
        updates.payment_number = `SD-${currentNum}`;
      }
    } else {
      assign("is_delete", dto.is_delete);
    }

    assign("customer_id", dto.customer_id);
    assign("payment_number", dto.payment_number);
    assign("payment_type", dto.payment_type);
    assign("payment_date", dto.payment_date);
    assign("location_id", dto.location_id);
    assign("place_of_supply", dto.place_of_supply);
    assign("description_of_supply", dto.description_of_supply);
    assign("payment_mode", dto.payment_mode);
    assign("deposit_account_id", dto.deposit_account_id);
    assign("reference_number", dto.reference_number);
    assign("amount_received", dto.amount_received);
    assign("bank_charges", dto.bank_charges);
    assign("is_tds_deducted", dto.is_tds_deducted);
    assign("tds_tax_id", dto.tds_tax_id);
    assign("tds_amount", dto.tds_amount);
    assign("tax_id", dto.tax_id);
    assign("tax_amount", dto.tax_amount);
    assign("excess_amount", dto.excess_amount);
    if (dto.status !== undefined) {
      updates.status = dto.status.trim().toLowerCase();
    }
    assign("notes", dto.notes);

    const { data, error } = await client
      .from("payments_received")
      .update(updates)
      .eq("id", id)
      .eq("entity_id", entityId)
      .select("*")
      .single();

    if (error || !data) {
      throw new Error(
        `Failed to update payment received: ${
          (error as any)?.message ?? "Unknown error"
        }`,
      );
    }

    // Append any newly attached files (existing ones are not resent).
    if (dto.attachments && dto.attachments.length > 0) {
      await this.insertAttachments(id, dto.attachments, tenant.userId);
    }

    // Replace allocations when the caller supplies them (omit to leave as-is).
    if (dto.allocations !== undefined) {
      await client
        .from("payment_received_allocations")
        .delete()
        .eq("payment_received_id", id)
        .eq("entity_id", entityId);

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
      const { data: updated } = await client
        .from("payments_received")
        .update({
          amount_used_for_payments: used,
          updated_at: new Date().toISOString(),
        })
        .eq("id", id)
        .eq("entity_id", entityId)
        .select("*")
        .single();
      if (updated) return updated;
    }

    return data;
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
      .from("payments_received")
      .select("*", { count: "exact" })
      .eq("entity_id", entityId)
      .eq("is_delete", false)
      .order("created_at", { ascending: false })
      .range(from, to);

    if (status && status.trim()) {
      query = query.eq("status", status.trim().toLowerCase());
    }
    if (search && search.trim()) {
      const term = `%${search.trim()}%`;
      query = query.or(
        `payment_number.ilike.${term},reference_number.ilike.${term}`,
      );
    }

    const { data, error, count } = await query;

    if (error) {
      throw new Error(
        `Failed to load payments received: ${(error as any)?.message ?? "Unknown error"}`,
      );
    }

    const enrichedWithCustomers = await this.attachCustomers(client, data ?? []);
    const enriched = await this.attachLocations(client, enrichedWithCustomers);

    return {
      data: enriched,
      page: safePage,
      limit: safeLimit,
      total: count ?? 0,
    };
  }

  /// Attaches a resolved customer display name to each row as `customer_name`.
  private async attachCustomers(
    client: ReturnType<SupabaseService["getClient"]>,
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

    const { data: customers } = await client
      .from("customers")
      .select("id, display_name, first_name, last_name, company_name")
      .in("id", customerIds);

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

  /// Attaches a resolved warehouse/location display name to each row as `location_name`.
  private async attachLocations(
    client: ReturnType<SupabaseService["getClient"]>,
    rows: Array<{ location_id?: string | null; entity_id?: string | null }>,
  ): Promise<Array<Record<string, unknown>>> {
    if (!rows.length) return rows as Array<Record<string, unknown>>;

    const entityId = rows[0].entity_id;
    let defaultWarehouseName: string | null = null;
    if (entityId) {
      const { data: wh } = await client
        .from("warehouses")
        .select("name")
        .eq("entity_id", entityId)
        .limit(1);
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
      const { data: warehouses } = await client
        .from("warehouses")
        .select("id, name")
        .in("id", locationIds);

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
    const client = this.supabaseService.getClient();
    const entityId = this.ensureEntityId(tenant);

    const { data, error } = await client
      .from("payments_received")
      .select("*")
      .eq("id", id)
      .eq("entity_id", entityId)
      .maybeSingle();

    if (error) {
      throw new Error(
        `Failed to load payment received: ${(error as any)?.message ?? "Unknown error"}`,
      );
    }
    if (!data) {
      throw new NotFoundException("Payment received not found");
    }

    const { data: allocations } = await client
      .from("payment_received_allocations")
      .select("*")
      .eq("payment_received_id", id)
      .eq("entity_id", entityId);

    const enriched = await this.attachLocations(client, [data]);

    return { ...enriched[0], allocations: allocations ?? [] };
  }

  /// Returns the distinct customers that appear in `invoice_master` for the
  /// active tenant, with their display name / number / email resolved from the
  /// `customers` table. Used to populate the "Customer Name" dropdown on the
  /// payment-create page so only customers who actually have invoices are shown.
  async getInvoiceCustomers(tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const entityId = this.ensureEntityId(tenant);

    const { data: invoices, error } = await client
      .from("invoice_master")
      .select("customer_id")
      .eq("entity_id", entityId)
      .eq("is_delete", false);

    if (error) {
      throw new Error(
        `Failed to load invoice customers: ${(error as any)?.message ?? "Unknown error"}`,
      );
    }

    const customerIds = Array.from(
      new Set(
        (invoices ?? [])
          .map((row) => row.customer_id)
          .filter((id): id is string => typeof id === "string" && id.length > 0),
      ),
    );
    if (!customerIds.length) return [];

    const { data: customers } = await client
      .from("customers")
      .select("id, display_name, first_name, last_name, company_name, customer_number, email")
      .in("id", customerIds);

    return (customers ?? [])
      .map((c) => ({
        id: c.id,
        name:
          c.display_name ||
          c.company_name ||
          [c.first_name, c.last_name].filter(Boolean).join(" ").trim() ||
          "",
        customer_number: c.customer_number ?? null,
        email: c.email ?? null,
      }))
      .filter((c) => c.name)
      .sort((a, b) => a.name.localeCompare(b.name));
  }

  /// Returns the customer's invoices that still have a balance due, computed as
  /// grand_total minus everything already allocated to each invoice. Used to
  /// populate the "Unpaid Invoices" table on the payment-create page.
  async getUnpaidInvoices(tenant: TenantContext, customerId: string) {
    const client = this.supabaseService.getClient();
    const entityId = this.ensureEntityId(tenant);

    const { data: invoices, error } = await client
      .from("invoice_master")
      .select(
        "id, invoice_number, invoice_date, due_date, grand_total, status, place_of_supply",
      )
      .eq("entity_id", entityId)
      .eq("customer_id", customerId)
      .eq("is_delete", false)
      .order("invoice_date", { ascending: true });

    if (error) {
      throw new Error(
        `Failed to load unpaid invoices: ${(error as any)?.message ?? "Unknown error"}`,
      );
    }

    const list = invoices ?? [];
    if (!list.length) return [];

    // Sum existing allocations per invoice to derive the remaining balance.
    const invoiceIds = list.map((i) => i.id);
    const { data: allocations } = await client
      .from("payment_received_allocations")
      .select("invoice_id, allocated_amount")
      .in("invoice_id", invoiceIds);

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
      .filter((inv) => {
        const status = (inv.status ?? "").toString().toLowerCase();
        return status !== "draft" && status !== "void" && status !== "cancelled";
      })
      .map((inv) => {
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
      .filter((inv) => inv.amount_due > 0);
  }
}
