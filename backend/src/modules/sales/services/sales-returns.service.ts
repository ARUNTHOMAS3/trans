import { Injectable, NotFoundException } from "@nestjs/common";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../supabase/supabase.service";
import { CreateSalesReturnDto } from "../dto/create-sales-return.dto";
import { SequencesService } from "../../../sequences/sequences.service";
import { client } from "../../../db/db";

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

    const customers = await client.unsafe(
      `SELECT id, display_name, first_name, last_name, company_name FROM customers WHERE id = ANY($1)`,
      [customerIds],
    );

    const customerMap = new Map<string, any>(
      (customers ?? []).map((customer: any) => [customer.id, customer] as [string, any]),
    );

    return rows.map((row) => ({
      ...row,
      customer: row.customer_id ? (customerMap.get(row.customer_id) ?? null) : null,
    }));
  }

  async create(tenant: TenantContext, dto: CreateSalesReturnDto) {
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

      try {
        const rows = await client.unsafe(
          `INSERT INTO sales_returns (entity_id, customer_id, rma_number, return_date, warehouse_id, reason, reference_number, contains_credit_only_goods, status, notes, created_by, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
           RETURNING *`,
          [
            entityId,
            dto.customer_id,
            resolvedRmaNumber,
            dto.return_date,
            dto.warehouse_id,
            dto.reason ?? null,
            dto.reference_number ?? null,
            dto.contains_credit_only_goods ?? false,
            status,
            dto.notes ?? null,
            tenant.userId || null,
            nowIso,
            nowIso,
          ],
        );

        if (rows[0]) {
          header = rows[0];
          break;
        }
      } catch (err) {
        lastCreateError = err;

        if (this.isDuplicateRmaError(err)) {
          await this.sequencesService.incrementSequence(
            SalesReturnsService.RMA_SEQUENCE_MODULE,
            tenant,
            resolvedRmaNumber,
          );
          continue;
        }

        throw new Error(
          `Failed to create sales return: ${(err as any)?.message ?? "Unknown error"}`,
        );
      }
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
      try {
        for (const item of rows) {
          await client.unsafe(
            `INSERT INTO sales_return_items (sales_return_id, product_id, sales_invoice_item_id, invoiced_qty, already_returned_qty, return_qty, receivable_qty, credit_only_qty, remarks, created_at, updated_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
            [
              item.sales_return_id,
              item.product_id,
              item.sales_invoice_item_id,
              item.invoiced_qty,
              item.already_returned_qty,
              item.return_qty,
              item.receivable_qty,
              item.credit_only_qty,
              item.remarks,
              item.created_at,
              item.updated_at,
            ],
          );
        }
      } catch (itemsError) {
        await client.unsafe(`DELETE FROM sales_returns WHERE id = $1`, [header.id]);
        throw new Error(
          `Failed to create sales return items: ${(itemsError as any).message}`,
        );
      }
    }

    await this.sequencesService.incrementSequence(
      SalesReturnsService.RMA_SEQUENCE_MODULE,
      tenant,
      resolvedRmaNumber,
    );

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
    const entityId = this.ensureEntityId(tenant);
    const offset = (page - 1) * limit;

    let sqlQuery = `SELECT * FROM sales_returns WHERE entity_id = $1`;
    let countQuery = `SELECT COUNT(*)::int as count FROM sales_returns WHERE entity_id = $1`;
    const params: any[] = [entityId];

    if (search?.trim()) {
      params.push(`%${search.trim()}%`);
      const searchIdx = params.length;
      sqlQuery += ` AND (rma_number ILIKE $${searchIdx} OR reference_number ILIKE $${searchIdx} OR reason ILIKE $${searchIdx})`;
      countQuery += ` AND (rma_number ILIKE $${searchIdx} OR reference_number ILIKE $${searchIdx} OR reason ILIKE $${searchIdx})`;
    }

    if (status?.trim()) {
      params.push(status.trim().toLowerCase());
      const statusIdx = params.length;
      sqlQuery += ` AND status = $${statusIdx}`;
      countQuery += ` AND status = $${statusIdx}`;
    }

    sqlQuery += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    const [data, countRes] = await Promise.all([
      client.unsafe(sqlQuery, [...params, limit, offset]),
      client.unsafe(countQuery, params),
    ]);

    const totalCount = countRes[0]?.count ?? 0;
    const rowsWithCustomers = await this.attachCustomers((data as any[]) ?? []);

    return {
      data: rowsWithCustomers,
      meta: {
        total: totalCount,
        page,
        limit,
        totalPages: Math.ceil(totalCount / limit),
      },
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const entityId = this.ensureEntityId(tenant);

    const rows = await client.unsafe(
      `SELECT * FROM sales_returns WHERE id = $1 AND (entity_id = $2 OR entity_id IS NULL) LIMIT 1`,
      [id, entityId],
    );

    const data = rows[0];
    if (!data) {
      throw new NotFoundException(`Sales return ${id} not found`);
    }

    const items = await client.unsafe(
      `SELECT sri.*, p.product_name, p.item_code
       FROM sales_return_items sri
       LEFT JOIN products p ON p.id = sri.product_id
       WHERE sri.sales_return_id = $1`,
      [id],
    );

    data.items = (items ?? []).map((item: any) => ({
      ...item,
      product: item.product_id
        ? {
            id: item.product_id,
            product_name: item.product_name,
            item_code: item.item_code,
          }
        : null,
    }));

    const [rowWithCustomer] = await this.attachCustomers([data as any]);
    return rowWithCustomer ?? data;
  }

  async updateStatus(id: string, tenant: TenantContext, status: string) {
    const entityId = this.ensureEntityId(tenant);
    const normalizedStatus = status.trim().toLowerCase();

    let sqlQuery = `UPDATE sales_returns SET status = $1, updated_at = NOW()`;
    const params: any[] = [normalizedStatus];

    if (normalizedStatus === "approved") {
      params.push(tenant.userId || null);
      sqlQuery += `, approved_by = $2, approved_at = NOW()`;
    }

    params.push(id, entityId);
    sqlQuery += ` WHERE id = $${params.length - 1} AND entity_id = $${params.length} RETURNING *`;

    const rows = await client.unsafe(sqlQuery, params);
    const data = rows[0];

    if (!data) {
      throw new NotFoundException(`Sales return ${id} not found`);
    }

    return data;
  }
}
