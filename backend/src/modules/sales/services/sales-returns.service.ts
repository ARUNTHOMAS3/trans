import { Injectable, NotFoundException } from "@nestjs/common";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../supabase/supabase.service";
import { CreateSalesReturnDto } from "../dto/create-sales-return.dto";
import { SequencesService } from "../../../sequences/sequences.service";

@Injectable()
export class SalesReturnsService {
  private static readonly RMA_SEQUENCE_MODULE = "rma";

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly sequencesService: SequencesService,
  ) {}

  private ensureEntityId(tenant: TenantContext): string {
    if (!tenant?.entityId) {
      throw new Error("Tenant entity context is required");
    }
    return tenant.entityId;
  }

  private isDuplicateRmaError(error: unknown): boolean {
    const anyErr = error as
      | { code?: string; message?: string; details?: string }
      | undefined;
    const code = anyErr?.code?.toString();
    const combined = `${anyErr?.message ?? ""} ${anyErr?.details ?? ""}`
      .toLowerCase()
      .trim();
    return (
      code === "23505" &&
      (combined.includes("rma_number") || combined.includes("sales_returns"))
    );
  }

  private async attachCustomers<T extends { customer_id?: string | null }>(
    rows: T[],
  ): Promise<Array<T & { customer: any | null }>> {
    if (!rows.length) return [];

    const client = this.supabaseService.getClient();
    const customerIds = Array.from(
      new Set(
        rows
          .map((row) => row.customer_id)
          .filter((id): id is string => typeof id === "string" && id.length > 0),
      ),
    );

    if (!customerIds.length) {
      return rows.map((row) => ({ ...row, customer: null }));
    }

    const { data: customers, error } = await client
      .from("customers")
      .select("id, display_name, first_name, last_name, company_name")
      .in("id", customerIds);

    if (error) {
      throw new Error(`Failed to fetch related customers: ${error.message}`);
    }

    const customerMap = new Map(
      (customers ?? []).map((customer: any) => [customer.id, customer]),
    );

    return rows.map((row) => ({
      ...row,
      customer: row.customer_id ? (customerMap.get(row.customer_id) ?? null) : null,
    }));
  }

  async create(tenant: TenantContext, dto: CreateSalesReturnDto) {
    const client = this.supabaseService.getClient();
    const entityId = this.ensureEntityId(tenant);

    const nowIso = new Date().toISOString();
    const status = (dto.status ?? "draft").trim().toLowerCase();
    let header: any = null;
    let resolvedRmaNumber = "";
    let lastCreateError: unknown = null;

    for (let attempt = 0; attempt < 5; attempt++) {
      resolvedRmaNumber = (
        await this.sequencesService.getNextNumberFormatted(
          SalesReturnsService.RMA_SEQUENCE_MODULE,
          tenant,
        )
      ).trim();

      const headerPayload = {
        entity_id: entityId,
        customer_id: dto.customer_id,
        rma_number: resolvedRmaNumber,
        return_date: dto.return_date,
        warehouse_id: dto.warehouse_id,
        reason: dto.reason ?? null,
        reference_number: dto.reference_number ?? null,
        contains_credit_only_goods: dto.contains_credit_only_goods ?? false,
        status,
        notes: dto.notes ?? null,
        created_by: tenant.userId || null,
        created_at: nowIso,
        updated_at: nowIso,
      };

      const { data: createdHeader, error: headerError } = await client
        .from("sales_returns")
        .insert([headerPayload])
        .select("*")
        .single();

      if (!headerError && createdHeader) {
        header = createdHeader;
        break;
      }

      lastCreateError = headerError;

      if (this.isDuplicateRmaError(headerError)) {
        await this.sequencesService.incrementSequence(
          SalesReturnsService.RMA_SEQUENCE_MODULE,
          tenant,
          resolvedRmaNumber,
        );
        continue;
      }

      throw new Error(
        `Failed to create sales return: ${(headerError as any)?.message ?? "Unknown error"}`,
      );
    }

    if (!header) {
      throw new Error(
        `Failed to create sales return: ${(
          lastCreateError as any
        )?.message ?? "Unable to allocate unique RMA number"}`,
      );
    }

    const rows = (dto.items ?? []).map((item) => ({
      sales_return_id: header.id,
      product_id: item.product_id,
      sales_invoice_item_id: item.sales_invoice_item_id ?? null,
      invoiced_qty: item.invoiced_qty ?? 0,
      already_returned_qty: item.already_returned_qty ?? 0,
      return_qty: item.return_qty ?? 0,
      receivable_qty: item.receivable_qty ?? 0,
      credit_only_qty: item.credit_only_qty ?? 0,
      remarks: item.remarks ?? null,
      created_at: nowIso,
      updated_at: nowIso,
    }));

    if (rows.length > 0) {
      const { error: itemsError } = await client
        .from("sales_return_items")
        .insert(rows);

      if (itemsError) {
        await client.from("sales_returns").delete().eq("id", header.id);
        throw new Error(
          `Failed to create sales return items: ${itemsError.message}`,
        );
      }
    }

    await this.sequencesService.incrementSequence(
      SalesReturnsService.RMA_SEQUENCE_MODULE,
      tenant,
      resolvedRmaNumber,
    );

    // Avoid a second strict-tenant read immediately after insert, which can
    // intermittently return not found in some environments and surface as 404
    // for otherwise successful create calls.
    return {
      ...header,
      items: rows,
    };
  }

  async findAll(
    tenant: TenantContext,
    page: number = 1,
    limit: number = 100,
    search?: string,
    status?: string,
  ) {
    const client = this.supabaseService.getClient();
    const entityId = this.ensureEntityId(tenant);
    const offset = (page - 1) * limit;

    let query = client
      .from("sales_returns")
      .select(
        "*, items:sales_return_items(return_qty, receivable_qty, credit_only_qty)",
        { count: "exact" },
      )
      .eq("entity_id", entityId)
      .range(offset, offset + limit - 1)
      .order("created_at", { ascending: false });

    if (search?.trim()) {
      const q = search.trim();
      query = query.or(
        `rma_number.ilike.%${q}%,reference_number.ilike.%${q}%,reason.ilike.%${q}%`,
      );
    }

    if (status?.trim()) {
      query = query.eq("status", status.trim().toLowerCase());
    }

    const { data, error, count } = await query;

    if (error) {
      throw new Error(`Failed to fetch sales returns: ${error.message}`);
    }

    const rowsWithCustomers = await this.attachCustomers(data ?? []);

    return {
      data: rowsWithCustomers,
      meta: {
        total: count ?? 0,
        page,
        limit,
        totalPages: Math.ceil((count ?? 0) / limit),
      },
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const entityId = this.ensureEntityId(tenant);

    const { data, error } = await client
      .from("sales_returns")
      .select(
        `
        *,
        items:sales_return_items(
          *,
          product:products(id, product_name, item_code)
        )
      `,
      )
      .eq("id", id)
      // Keep tenant scoping, but allow legacy rows where entity_id is null.
      .or(`entity_id.eq.${entityId},entity_id.is.null`)
      .single();

    if (error || !data) {
      throw new NotFoundException(`Sales return ${id} not found`);
    }

    const [rowWithCustomer] = await this.attachCustomers([data]);
    return rowWithCustomer ?? data;
  }

  async updateStatus(id: string, tenant: TenantContext, status: string) {
    const client = this.supabaseService.getClient();
    const entityId = this.ensureEntityId(tenant);
    const normalizedStatus = status.trim().toLowerCase();

    const updatePayload: Record<string, unknown> = {
      status: normalizedStatus,
      updated_at: new Date().toISOString(),
    };

    if (normalizedStatus === "approved") {
      updatePayload.approved_by = tenant.userId || null;
      updatePayload.approved_at = new Date().toISOString();
    }

    const { data, error } = await client
      .from("sales_returns")
      .update(updatePayload)
      .eq("id", id)
      .eq("entity_id", entityId)
      .select("*")
      .single();

    if (error || !data) {
      throw new NotFoundException(`Sales return ${id} not found`);
    }

    return data;
  }
}
