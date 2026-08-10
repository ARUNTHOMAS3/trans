import { Injectable } from "@nestjs/common";
import { sql } from "drizzle-orm";
import { db } from "../../../db/db";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SalesReportQueryDto } from "../dto/sales-report-query.dto";

export interface SalesReportPage<T extends Record<string, unknown>> {
  rows: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

interface PaginationOptions {
  page: number;
  limit: number;
  offset: number;
}

@Injectable()
export class SalesReportsRepository {
  private parseNumber(value: unknown, fallback = 0): number {
    if (value === null || value === undefined || value === "") return fallback;
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  private normalizePagination(query: SalesReportQueryDto): PaginationOptions {
    const page = Math.max(1, Number(query.page ?? 1));
    const requestedLimit = Number(query.pageSize ?? query.limit ?? 100);
    const limit = Math.min(500, Math.max(1, requestedLimit));
    return { page, limit, offset: (page - 1) * limit };
  }

  private getEntityId(tenant: TenantContext): string {
    return tenant.entityId?.toString().trim() || "";
  }

  private dateConditions(query: SalesReportQueryDto, entityId: string) {
    const conditions = [
      sql`s.entity_id = ${entityId}`,
      sql`s.is_delete = false`,
    ];
    if (query.startDate?.trim()) {
      conditions.push(sql`s.sale_date >= ${query.startDate.trim()}`);
    }
    if (query.endDate?.trim()) {
      const endDate = query.endDate.includes("T")
        ? query.endDate.trim()
        : `${query.endDate.trim()} 23:59:59`;
      conditions.push(sql`s.sale_date <= ${endDate}`);
    }
    return conditions;
  }

  private recurringInvoiceDateKey(query: SalesReportQueryDto): string {
    const reportBy = query.reportBy?.toLowerCase().trim() ?? "";
    if (reportBy.includes("last")) return "last_run_date";
    if (reportBy.includes("expiry") || reportBy.includes("end"))
      return "end_date";
    return "next_run_date";
  }

  private recurringInvoiceDateExpression(query: SalesReportQueryDto) {
    const dateKey = this.recurringInvoiceDateKey(query);
    return sql`NULLIF(to_jsonb(ri)->>${dateKey}, '')::date`;
  }

  private recurringInvoiceConditions(
    query: SalesReportQueryDto,
    entityId: string,
  ) {
    const dateExpression = this.recurringInvoiceDateExpression(query);
    const conditions = [
      sql`COALESCE(to_jsonb(ri)->>'entity_id', ${entityId}) = ${entityId}`,
      sql`COALESCE(NULLIF(to_jsonb(ri)->>'is_delete', '')::boolean, false) = false`,
    ];
    if (query.startDate?.trim()) {
      conditions.push(
        sql`COALESCE(${dateExpression}, NULLIF(to_jsonb(ri)->>'start_date', '')::date, NULLIF(to_jsonb(ri)->>'created_at', '')::timestamp::date) >= ${query.startDate.trim()}::date`,
      );
    }
    if (query.endDate?.trim()) {
      conditions.push(
        sql`COALESCE(${dateExpression}, NULLIF(to_jsonb(ri)->>'start_date', '')::date, NULLIF(to_jsonb(ri)->>'created_at', '')::timestamp::date) <= ${query.endDate.trim()}::date`,
      );
    }
    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        COALESCE(to_jsonb(ri)->>'profile_name', to_jsonb(ri)->>'sale_number', to_jsonb(ri)->>'invoice_number', '') ILIKE ${search}
        OR COALESCE(c.display_name, to_jsonb(ri)->>'customer_name', '') ILIKE ${search}
        OR COALESCE(to_jsonb(ri)->>'status', '') ILIKE ${search}
      )`);
    }
    return conditions;
  }

  private paymentsReceivedConditions(
    query: SalesReportQueryDto,
    entityId: string,
  ) {
    const conditions = [sql`pr.entity_id = ${entityId}`];

    if (query.startDate?.trim()) {
      conditions.push(sql`pr.payment_date >= ${query.startDate.trim()}::date`);
    }

    if (query.endDate?.trim()) {
      conditions.push(sql`pr.payment_date <= ${query.endDate.trim()}::date`);
    }

    const transactionType = query.transactionType?.trim();
    if (transactionType && transactionType.toLowerCase() !== "all") {
      conditions.push(
        sql`LOWER(REPLACE(pr.payment_type, '_', ' ')) = LOWER(REPLACE(${transactionType}, '_', ' '))`,
      );
    }

    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        pr.payment_number ILIKE ${search}
        OR pr.reference_number ILIKE ${search}
        OR pr.payment_mode ILIKE ${search}
        OR pr.status ILIKE ${search}
        OR pr.notes ILIKE ${search}
        OR c.display_name ILIKE ${search}
        OR c.company_name ILIKE ${search}
        OR deposit_account.user_account_name ILIKE ${search}
        OR deposit_account.system_account_name ILIKE ${search}
      )`);
    }

    return conditions;
  }
  private rowsFrom(result: unknown): Record<string, unknown>[] {
    if (Array.isArray(result)) return result as Record<string, unknown>[];
    const maybeRows = (result as { rows?: unknown })?.rows;
    return Array.isArray(maybeRows)
      ? (maybeRows as Record<string, unknown>[])
      : [];
  }

  private pageFromRows<T extends Record<string, unknown>>(
    rows: T[],
    pagination: PaginationOptions,
  ): SalesReportPage<T> {
    const total = rows.length > 0 ? this.parseNumber(rows[0]["__total"]) : 0;
    const cleaned = rows.map((row) => {
      const { __total, ...rest } = row;
      return rest as T;
    });
    return {
      rows: cleaned,
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: total === 0 ? 1 : Math.ceil(total / pagination.limit),
    };
  }

  async salesByCustomer(
    tenant: TenantContext,
    query: SalesReportQueryDto,
  ): Promise<SalesReportPage<Record<string, unknown>>> {
    const scopedQuery = query;
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(scopedQuery);
    const conditions = this.dateConditions(scopedQuery, entityId);
    conditions.push(
      sql`LOWER(s.document_type) IN ('invoice', 'sales_invoice', 'order', 'sales_order', 'bill_of_supply', 'bill of supply', 'retainer_invoice', 'recurring_invoice')`,
    );
    if (scopedQuery.search?.trim()) {
      conditions.push(
        sql`c.display_name ILIKE ${`%${scopedQuery.search.trim()}%`}`,
      );
    }
    const whereClause = sql.join(conditions, sql` AND `);

    const result = await db.execute(sql`
      WITH grouped AS (
        SELECT
          c.id::text AS "customerId",
          c.display_name AS "customerName",
          COALESCE(c.customer_type, 'Business') AS "customerType",
          COUNT(s.id)::int AS "invoiceCount",
          COALESCE(SUM(s.sub_total), 0)::numeric AS "totalSales",
          COALESCE(SUM(s.total), 0)::numeric AS "salesWithTax"
        FROM sales_orders s
        JOIN customers c ON c.id = s.customer_id
        WHERE ${whereClause}
        GROUP BY c.id, c.display_name, c.customer_type
      )
      SELECT *, COUNT(*) OVER()::int AS "__total"
      FROM grouped
      ORDER BY "totalSales" DESC, "customerName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);
    const groupedRows = this.rowsFrom(result);
    const rows = groupedRows.map((row) => ({
      ...row,
      invoiceCount: this.parseNumber(row.invoiceCount),
      totalSales: this.parseNumber(row.totalSales),
      salesWithTax: this.parseNumber(row.salesWithTax),
    }));
    return this.pageFromRows(rows, pagination);
  }

  async salesByItem(
    tenant: TenantContext,
    query: SalesReportQueryDto,
  ): Promise<SalesReportPage<Record<string, unknown>>> {
    const scopedQuery = query;
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(scopedQuery);
    const conditions = this.dateConditions(scopedQuery, entityId);
    if (scopedQuery.search?.trim()) {
      conditions.push(
        sql`p.product_name ILIKE ${`%${scopedQuery.search.trim()}%`}`,
      );
    }
    const whereClause = sql.join(conditions, sql` AND `);
    let result;
    if (scopedQuery.groupBy === 'Customer Name') {
      result = await db.execute(sql`
        WITH grouped AS (
          SELECT
            c.id::text AS "customerId",
            c.display_name AS "customerName",
            p.id::text AS "itemId",
            p.product_name AS "itemName",
            COALESCE(SUM(soi.quantity), 0)::numeric AS "quantitySold",
            COALESCE(SUM(soi.amount), 0)::numeric AS "amount",
            CASE
              WHEN COALESCE(SUM(soi.quantity), 0) = 0 THEN 0
              ELSE COALESCE(SUM(soi.amount), 0) / NULLIF(SUM(soi.quantity), 0)
            END::numeric AS "averagePrice"
          FROM sales_orders s
          JOIN sales_order_items soi ON soi.sales_order_id = s.id AND soi.entity_id = s.entity_id
          JOIN products p ON p.id = soi.product_id
          LEFT JOIN customers c ON c.id = s.customer_id
          WHERE ${whereClause}
          GROUP BY c.id, c.display_name, p.id, p.product_name
        )
        SELECT *, COUNT(*) OVER()::int AS "__total"
        FROM grouped
        ORDER BY "customerName" ASC, "amount" DESC, "itemName" ASC
        LIMIT ${pagination.limit} OFFSET ${pagination.offset}
      `);
    } else {
      result = await db.execute(sql`
        WITH grouped AS (
          SELECT
            p.id::text AS "itemId",
            p.product_name AS "itemName",
            COALESCE(SUM(soi.quantity), 0)::numeric AS "quantitySold",
            COALESCE(SUM(soi.amount), 0)::numeric AS "amount",
            CASE
              WHEN COALESCE(SUM(soi.quantity), 0) = 0 THEN 0
              ELSE COALESCE(SUM(soi.amount), 0) / NULLIF(SUM(soi.quantity), 0)
            END::numeric AS "averagePrice"
          FROM sales_orders s
          JOIN sales_order_items soi ON soi.sales_order_id = s.id AND soi.entity_id = s.entity_id
          JOIN products p ON p.id = soi.product_id
          WHERE ${whereClause}
          GROUP BY p.id, p.product_name
        )
        SELECT *, COUNT(*) OVER()::int AS "__total"
        FROM grouped
        ORDER BY "amount" DESC, "itemName" ASC
        LIMIT ${pagination.limit} OFFSET ${pagination.offset}
      `);
    }
    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      quantitySold: this.parseNumber(row.quantitySold),
      amount: this.parseNumber(row.amount),
      averagePrice: this.parseNumber(row.averagePrice),
    }));
    return this.pageFromRows(rows, pagination);
  }

  async salesBySalesperson(
    tenant: TenantContext,
    query: SalesReportQueryDto,
  ): Promise<SalesReportPage<Record<string, unknown>>> {
    const scopedQuery = query;
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(scopedQuery);
    const conditions = this.dateConditions(scopedQuery, entityId);
    if (scopedQuery.search?.trim()) {
      conditions.push(
        sql`u.full_name ILIKE ${`%${scopedQuery.search.trim()}%`}`,
      );
    }
    const whereClause = sql.join(conditions, sql` AND `);
    const result = await db.execute(sql`
      WITH grouped AS (
        SELECT
          COALESCE(NULLIF(u.full_name, ''), 'Unassigned') AS "salespersonName",
          COUNT(*) FILTER (WHERE LOWER(s.document_type) NOT LIKE '%credit%')::int AS "invoiceCount",
          COALESCE(SUM(s.sub_total) FILTER (WHERE LOWER(s.document_type) NOT LIKE '%credit%'), 0)::numeric AS "invoiceSales",
          COALESCE(SUM(s.total) FILTER (WHERE LOWER(s.document_type) NOT LIKE '%credit%'), 0)::numeric AS "invoiceSalesWithTax",
          COUNT(*) FILTER (WHERE LOWER(s.document_type) LIKE '%credit%')::int AS "creditNoteCount",
          ABS(COALESCE(SUM(s.sub_total) FILTER (WHERE LOWER(s.document_type) LIKE '%credit%'), 0))::numeric AS "creditNoteSales",
          ABS(COALESCE(SUM(s.total) FILTER (WHERE LOWER(s.document_type) LIKE '%credit%'), 0))::numeric AS "creditNoteSalesWithTax",
          COALESCE(SUM(CASE WHEN LOWER(s.document_type) LIKE '%credit%' THEN -ABS(s.sub_total) ELSE s.sub_total END), 0)::numeric AS "totalSales",
          COALESCE(SUM(CASE WHEN LOWER(s.document_type) LIKE '%credit%' THEN -ABS(s.total) ELSE s.total END), 0)::numeric AS "totalSalesWithTax"
        FROM sales_orders s
        LEFT JOIN users u ON u.id = NULLIF(s.salesperson_id, '')::uuid
        WHERE ${whereClause}
        GROUP BY COALESCE(NULLIF(u.full_name, ''), 'Unassigned')
      )
      SELECT *, COUNT(*) OVER()::int AS "__total"
      FROM grouped
      ORDER BY "totalSales" DESC, "salespersonName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);
    const numericFields = [
      "invoiceCount",
      "invoiceSales",
      "invoiceSalesWithTax",
      "creditNoteCount",
      "creditNoteSales",
      "creditNoteSalesWithTax",
      "totalSales",
      "totalSalesWithTax",
    ];
    const rows = this.rowsFrom(result).map((row) => {
      const mapped = { ...row };
      for (const field of numericFields)
        mapped[field] = this.parseNumber(row[field]);
      return mapped;
    });
    return this.pageFromRows(rows, pagination);
  }

  async salesSummary(
    tenant: TenantContext,
    query: SalesReportQueryDto,
  ): Promise<SalesReportPage<Record<string, unknown>>> {
    const scopedQuery = query;
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(scopedQuery);
    const whereClause = sql.join(
      this.dateConditions(scopedQuery, entityId),
      sql` AND `,
    );
    let result;
    if (scopedQuery.groupBy === 'Location') {
      result = await db.execute(sql`
        WITH grouped AS (
          SELECT
            obm.name AS "locationName",
            to_char(s.sale_date::date, 'DD-MM-YYYY') AS "date",
            s.sale_date::date AS "sortDate",
            COUNT(*) FILTER (WHERE LOWER(s.document_type) NOT LIKE '%credit%')::int AS "invoiceCount",
            COALESCE(SUM(s.sub_total), 0)::numeric AS "totalSales",
            COALESCE(SUM(s.total), 0)::numeric AS "totalSalesWithTax",
            COALESCE(SUM(s.tax_total), 0)::numeric AS "totalTaxAmount"
          FROM sales_orders s
          JOIN organisation_branch_master obm ON obm.id = s.entity_id
          WHERE ${whereClause}
          GROUP BY obm.id, obm.name, s.sale_date::date
        )
        SELECT "locationName", "date", "invoiceCount", "totalSales", "totalSalesWithTax", "totalTaxAmount", COUNT(*) OVER()::int AS "__total"
        FROM grouped
        ORDER BY "locationName" ASC, "sortDate" ASC
        LIMIT ${pagination.limit} OFFSET ${pagination.offset}
      `);
    } else {
      result = await db.execute(sql`
        WITH grouped AS (
          SELECT
            to_char(s.sale_date::date, 'DD-MM-YYYY') AS "date",
            s.sale_date::date AS "sortDate",
            COUNT(*) FILTER (WHERE LOWER(s.document_type) NOT LIKE '%credit%')::int AS "invoiceCount",
            COALESCE(SUM(s.sub_total), 0)::numeric AS "totalSales",
            COALESCE(SUM(s.total), 0)::numeric AS "totalSalesWithTax",
            COALESCE(SUM(s.tax_total), 0)::numeric AS "totalTaxAmount"
          FROM sales_orders s
          WHERE ${whereClause}
          GROUP BY s.sale_date::date
        )
        SELECT "date", "invoiceCount", "totalSales", "totalSalesWithTax", "totalTaxAmount", COUNT(*) OVER()::int AS "__total"
        FROM grouped
        ORDER BY "sortDate" ASC
        LIMIT ${pagination.limit} OFFSET ${pagination.offset}
      `);
    }
    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      invoiceCount: this.parseNumber(row.invoiceCount),
      totalSales: this.parseNumber(row.totalSales),
      totalSalesWithTax: this.parseNumber(row.totalSalesWithTax),
      totalTaxAmount: this.parseNumber(row.totalTaxAmount),
    }));
    return this.pageFromRows(rows, pagination);
  }

  async profitByItem(
    tenant: TenantContext,
    query: SalesReportQueryDto,
  ): Promise<SalesReportPage<Record<string, unknown>>> {
    const scopedQuery = query;
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(scopedQuery);
    const conditions = this.dateConditions(scopedQuery, entityId);
    if (scopedQuery.search?.trim()) {
      conditions.push(
        sql`p.product_name ILIKE ${`%${scopedQuery.search.trim()}%`}`,
      );
    }
    const whereClause = sql.join(conditions, sql` AND `);
    const result = await db.execute(sql`
      WITH grouped AS (
        SELECT
          p.id::text AS "itemId",
          p.product_name AS "itemName",
          COALESCE(SUM(soi.quantity), 0)::numeric AS "quantitySold",
          COALESCE(SUM(soi.amount), 0)::numeric AS "totalSales",
          COALESCE(SUM(soi.amount + soi.tax_amount), 0)::numeric AS "totalSalesWithTax",
          COALESCE(SUM(soi.quantity * COALESCE(p.cost_price, 0)), 0)::numeric AS "totalCost"
        FROM sales_orders s
        JOIN sales_order_items soi ON soi.sales_order_id = s.id AND soi.entity_id = s.entity_id
        JOIN products p ON p.id = soi.product_id
        WHERE ${whereClause}
        GROUP BY p.id, p.product_name
      )
      SELECT
        *,
        ("totalSales" - "totalCost")::numeric AS "profit",
        COUNT(*) OVER()::int AS "__total"
      FROM grouped
      ORDER BY "profit" DESC, "itemName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);
    const rows = this.rowsFrom(result).map((row) => {
      const totalSales = this.parseNumber(row.totalSales);
      const totalCost = this.parseNumber(row.totalCost);
      const profit = this.parseNumber(row.profit);
      const margin =
        totalSales === 0 ? 0 : (profit / Math.abs(totalSales)) * 100;
      return {
        ...row,
        margin: `${margin.toFixed(2)}%`,
        quantitySold: this.parseNumber(row.quantitySold),
        totalSales,
        totalSalesWithTax: this.parseNumber(row.totalSalesWithTax),
        totalCost,
        profit,
      };
    });
    return this.pageFromRows(rows, pagination);
  }

  async paymentsReceived(
    tenant: TenantContext,
    query: SalesReportQueryDto,
  ): Promise<SalesReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);

    if (!entityId) {
      return {
        rows: [],
        total: 0,
        page: pagination.page,
        limit: pagination.limit,
        totalPages: 1,
      };
    }

    const whereClause = sql.join(
      this.paymentsReceivedConditions(query, entityId),
      sql` AND `,
    );

    const result = await db.execute(sql`
      WITH rows AS (
        SELECT
          pr.id::text AS "paymentReceivedId",
          COALESCE(NULLIF(pr.payment_number, ''), pr.id::text) AS "paymentNumber",
          to_char(pr.payment_date::date, 'DD-MM-YYYY') AS "date",
          COALESCE(NULLIF(pr.status, ''), '-') AS "status",
          COALESCE(NULLIF(pr.reference_number, ''), '-') AS "referenceNumber",
          COALESCE(NULLIF(c.display_name, ''), NULLIF(c.company_name, ''), '-') AS "customerName",
          COALESCE(NULLIF(pr.payment_type, ''), '-') AS "paymentType",
          COALESCE(NULLIF(pr.payment_mode, ''), '-') AS "paymentMode",
          COALESCE(NULLIF(pr.notes, ''), '') AS "notes",
          '-' AS "invoiceNumber",
          COALESCE(
            NULLIF(deposit_account.user_account_name, ''),
            NULLIF(deposit_account.system_account_name, ''),
            NULLIF(deposit_account.account_code, ''),
            '-'
          ) AS "depositTo",
          COALESCE(pr.amount_received, 0)::numeric AS "amountReceived",
          COALESCE(pr.bank_charges, 0)::numeric AS "bankCharges",
          COALESCE(pr.tds_amount, 0)::numeric AS "tdsAmount",
          COALESCE(pr.tax_amount, 0)::numeric AS "taxAmount",
          COALESCE(pr.amount_used_for_payments, 0)::numeric AS "amountUsedForPayments",
          COALESCE(pr.amount_refunded, 0)::numeric AS "amountRefunded",
          COALESCE(pr.excess_amount, 0)::numeric AS "excessAmount",
          COALESCE(NULLIF(pr.place_of_supply, ''), '') AS "placeOfSupply",
          COALESCE(SUM(COALESCE(pr.amount_received, 0)) OVER(), 0)::numeric AS "amountReceivedTotal",
          COALESCE(SUM(COALESCE(pr.excess_amount, 0)) OVER(), 0)::numeric AS "excessAmountTotal",
          pr.payment_date::date AS "__sortDate",
          COUNT(*) OVER()::int AS "__total"
        FROM payments_received pr
        LEFT JOIN customers c ON c.id = pr.customer_id
        LEFT JOIN accounts deposit_account ON deposit_account.id = pr.deposit_account_id
        WHERE ${whereClause}
      )
      SELECT *
      FROM rows
      ORDER BY "__sortDate" ASC, "paymentNumber" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      amountReceived: this.parseNumber(row.amountReceived),
      bankCharges: this.parseNumber(row.bankCharges),
      tdsAmount: this.parseNumber(row.tdsAmount),
      taxAmount: this.parseNumber(row.taxAmount),
      amountUsedForPayments: this.parseNumber(row.amountUsedForPayments),
      amountRefunded: this.parseNumber(row.amountRefunded),
      excessAmount: this.parseNumber(row.excessAmount),
      amountReceivedTotal: this.parseNumber(row.amountReceivedTotal),
      excessAmountTotal: this.parseNumber(row.excessAmountTotal),
    }));

    return this.pageFromRows(rows, pagination);
  }
  async recurringInvoices(
    tenant: TenantContext,
    query: SalesReportQueryDto,
  ): Promise<SalesReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);
    const dateExpression = this.recurringInvoiceDateExpression(query);
    const whereClause = sql.join(
      this.recurringInvoiceConditions(query, entityId),
      sql` AND `,
    );
    const result = await db.execute(sql`
      WITH rows AS (
        SELECT
          ri.id::text AS "recurringInvoiceId",
          COALESCE(NULLIF(to_jsonb(ri)->>'profile_name', ''), NULLIF(to_jsonb(ri)->>'sale_number', ''), NULLIF(to_jsonb(ri)->>'invoice_number', ''), '-') AS "profileName",
          COALESCE(NULLIF(c.display_name, ''), NULLIF(to_jsonb(ri)->>'customer_name', ''), '-') AS "customerName",
          CASE
            WHEN NULLIF(to_jsonb(ri)->>'start_date', '') IS NULL THEN '-'
            ELSE to_char((to_jsonb(ri)->>'start_date')::date, 'DD-MM-YYYY')
          END AS "startDate",
          CASE
            WHEN NULLIF(to_jsonb(ri)->>'end_date', '') IS NULL THEN '-'
            ELSE to_char((to_jsonb(ri)->>'end_date')::date, 'DD-MM-YYYY')
          END AS "endDate",
          COALESCE(NULLIF(to_jsonb(ri)->>'repeat_every', ''), '-') AS "repeatEvery",
          COALESCE(NULLIF(to_jsonb(ri)->>'repeat_type', ''), '-') AS "repeatType",
          COALESCE(
            NULLIF(trim(CONCAT_WS(' ', NULLIF(to_jsonb(ri)->>'repeat_every', ''), NULLIF(to_jsonb(ri)->>'repeat_type', ''))), ''),
            NULLIF(to_jsonb(ri)->>'frequency', ''),
            '-'
          ) AS "frequency",
          CASE
            WHEN NULLIF(to_jsonb(ri)->>'next_run_date', '') IS NULL THEN '-'
            ELSE to_char((to_jsonb(ri)->>'next_run_date')::date, 'DD-MM-YYYY')
          END AS "nextInvoiceDate",
          CASE
            WHEN COALESCE(NULLIF(to_jsonb(ri)->>'last_run_date', ''), NULLIF(to_jsonb(ri)->>'last_generated_date', '')) IS NULL THEN '-'
            ELSE to_char(COALESCE(NULLIF(to_jsonb(ri)->>'last_run_date', ''), NULLIF(to_jsonb(ri)->>'last_generated_date', ''))::date, 'DD-MM-YYYY')
          END AS "lastInvoiceDate",
          CASE
            WHEN NULLIF(to_jsonb(ri)->>'end_date', '') IS NULL THEN '-'
            ELSE to_char((to_jsonb(ri)->>'end_date')::date, 'DD-MM-YYYY')
          END AS "expiryDate",
          COALESCE(NULLIF(to_jsonb(ri)->>'status', ''), '-') AS "status",
          COALESCE(NULLIF(to_jsonb(ri)->>'grand_total', '')::numeric, NULLIF(to_jsonb(ri)->>'total', '')::numeric, 0)::numeric AS "grandTotal",
          COALESCE(NULLIF(to_jsonb(ri)->>'grand_total', '')::numeric, NULLIF(to_jsonb(ri)->>'total', '')::numeric, 0)::numeric AS "amount",
          COALESCE(${dateExpression}, NULLIF(to_jsonb(ri)->>'start_date', '')::date, NULLIF(to_jsonb(ri)->>'created_at', '')::timestamp::date, CURRENT_DATE) AS "__sortDate",
          COUNT(*) OVER()::int AS "__total"
        FROM recurring_invoices ri
        LEFT JOIN customers c ON c.id = NULLIF(to_jsonb(ri)->>'customer_id', '')::uuid
        WHERE ${whereClause}
      )
      SELECT *
      FROM rows
      ORDER BY "__sortDate" ASC, "profileName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);
    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      grandTotal: this.parseNumber(row.grandTotal),
      amount: this.parseNumber(row.amount),
    }));
    return this.pageFromRows(rows, pagination);
  }

  async recurringInvoiceDetails(
    tenant: TenantContext,
    recurringInvoiceId: string,
    query: SalesReportQueryDto,
  ): Promise<Record<string, unknown>[]> {
    const entityId = this.getEntityId(tenant);
    const conditions = this.recurringInvoiceConditions(query, entityId);
    conditions.push(sql`ri.id = ${recurringInvoiceId}::uuid`);
    const whereClause = sql.join(conditions, sql` AND `);
    const result = await db.execute(sql`
      SELECT
        ri.id::text AS "recurringInvoiceId",
        COALESCE(NULLIF(to_jsonb(ri)->>'profile_name', ''), NULLIF(to_jsonb(ri)->>'sale_number', ''), NULLIF(to_jsonb(ri)->>'invoice_number', ''), '-') AS "profileName",
        COALESCE(NULLIF(c.display_name, ''), NULLIF(to_jsonb(ri)->>'customer_name', ''), '-') AS "customerName",
        CASE
          WHEN NULLIF(to_jsonb(ri)->>'start_date', '') IS NULL THEN '-'
          ELSE to_char((to_jsonb(ri)->>'start_date')::date, 'DD-MM-YYYY')
        END AS "startDate",
        CASE
          WHEN NULLIF(to_jsonb(ri)->>'end_date', '') IS NULL THEN '-'
          ELSE to_char((to_jsonb(ri)->>'end_date')::date, 'DD-MM-YYYY')
        END AS "endDate",
        COALESCE(NULLIF(to_jsonb(ri)->>'repeat_every', ''), '-') AS "repeatEvery",
        COALESCE(NULLIF(to_jsonb(ri)->>'repeat_type', ''), '-') AS "repeatType",
        COALESCE(
          NULLIF(trim(CONCAT_WS(' ', NULLIF(to_jsonb(ri)->>'repeat_every', ''), NULLIF(to_jsonb(ri)->>'repeat_type', ''))), ''),
          NULLIF(to_jsonb(ri)->>'frequency', ''),
          '-'
        ) AS "frequency",
        CASE
          WHEN NULLIF(to_jsonb(ri)->>'next_run_date', '') IS NULL THEN '-'
          ELSE to_char((to_jsonb(ri)->>'next_run_date')::date, 'DD-MM-YYYY')
        END AS "nextInvoiceDate",
        CASE
          WHEN COALESCE(NULLIF(to_jsonb(ri)->>'last_run_date', ''), NULLIF(to_jsonb(ri)->>'last_generated_date', '')) IS NULL THEN '-'
          ELSE to_char(COALESCE(NULLIF(to_jsonb(ri)->>'last_run_date', ''), NULLIF(to_jsonb(ri)->>'last_generated_date', ''))::date, 'DD-MM-YYYY')
        END AS "lastInvoiceDate",
        CASE
          WHEN NULLIF(to_jsonb(ri)->>'end_date', '') IS NULL THEN '-'
          ELSE to_char((to_jsonb(ri)->>'end_date')::date, 'DD-MM-YYYY')
        END AS "expiryDate",
        COALESCE(NULLIF(to_jsonb(ri)->>'status', ''), '-') AS "status",
        COALESCE(NULLIF(to_jsonb(ri)->>'grand_total', '')::numeric, NULLIF(to_jsonb(ri)->>'total', '')::numeric, 0)::numeric AS "grandTotal",
        COALESCE(NULLIF(to_jsonb(ri)->>'grand_total', '')::numeric, NULLIF(to_jsonb(ri)->>'total', '')::numeric, 0)::numeric AS "amount"
      FROM recurring_invoices ri
      LEFT JOIN customers c ON c.id = NULLIF(to_jsonb(ri)->>'customer_id', '')::uuid
      WHERE ${whereClause}
      ORDER BY COALESCE(NULLIF(to_jsonb(ri)->>'next_run_date', '')::date, NULLIF(to_jsonb(ri)->>'start_date', '')::date, NULLIF(to_jsonb(ri)->>'created_at', '')::timestamp::date, CURRENT_DATE) ASC, "profileName" ASC
    `);
    return this.rowsFrom(result).map((row) => ({
      ...row,
      grandTotal: this.parseNumber(row.grandTotal),
      amount: this.parseNumber(row.amount),
    }));
  }
  async salesChannelIntegrationsSyncSummary(
    query: SalesReportQueryDto,
  ): Promise<SalesReportPage<Record<string, unknown>>> {
    const pagination = this.normalizePagination(query);
    return {
      rows: [],
      total: 0,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: 1,
    };
  }

  async customerTransactions(
    tenant: TenantContext,
    customerId: string,
    query: SalesReportQueryDto,
  ): Promise<Record<string, unknown>[]> {
    const scopedQuery = query;
    const entityId = this.getEntityId(tenant);
    const conditions = this.dateConditions(scopedQuery, entityId);
    conditions.push(sql`s.customer_id = ${customerId}`);
    const whereClause = sql.join(conditions, sql` AND `);
    const result = await db.execute(sql`
      SELECT
        to_char(s.sale_date::date, 'DD-MM-YYYY') AS "date",
        COALESCE(NULLIF(s.document_type, ''), 'Invoice') AS "type",
        COALESCE(NULLIF(s.status, ''), 'Sent') AS "status",
        COALESCE(NULLIF(s.sale_number, ''), '-') AS "number",
        COALESCE(s.sub_total, 0)::numeric AS "sales",
        COALESCE(s.total, 0)::numeric AS "salesWithTax",
        COALESCE(s.total, 0)::numeric AS "balanceDue"
      FROM sales_orders s
      WHERE ${whereClause}
      ORDER BY s.sale_date ASC, s.sale_number ASC
    `);
    return this.rowsFrom(result).map((row) => ({
      ...row,
      sales: this.parseNumber(row.sales),
      salesWithTax: this.parseNumber(row.salesWithTax),
      balanceDue: this.parseNumber(row.balanceDue),
    }));
  }

  async itemTransactions(
    tenant: TenantContext,
    itemId: string,
    query: SalesReportQueryDto,
  ): Promise<Record<string, unknown>[]> {
    const scopedQuery = query;
    const entityId = this.getEntityId(tenant);
    const conditions = this.dateConditions(scopedQuery, entityId);
    conditions.push(sql`soi.product_id = ${itemId}`);
    const whereClause = sql.join(conditions, sql` AND `);
    const result = await db.execute(sql`
      SELECT
        COALESCE(c.display_name, '-') AS "customerName",
        COALESCE(SUM(soi.quantity), 0)::numeric AS "quantity",
        COALESCE(SUM(soi.amount), 0)::numeric AS "amount",
        CASE
          WHEN COALESCE(SUM(soi.quantity), 0) = 0 THEN 0
          ELSE COALESCE(SUM(soi.amount), 0) / NULLIF(SUM(soi.quantity), 0)
        END::numeric AS "averagePrice"
      FROM sales_orders s
      JOIN sales_order_items soi ON soi.sales_order_id = s.id AND soi.entity_id = s.entity_id
      LEFT JOIN customers c ON c.id = s.customer_id
      WHERE ${whereClause}
      GROUP BY c.id, c.display_name
      ORDER BY "amount" DESC
    `);
    return this.rowsFrom(result).map((row) => ({
      ...row,
      quantity: this.parseNumber(row.quantity),
      amount: this.parseNumber(row.amount),
      averagePrice: this.parseNumber(row.averagePrice),
    }));
  }

  async salespersonTransactions(
    tenant: TenantContext,
    salespersonName: string,
    query: SalesReportQueryDto,
  ): Promise<Record<string, unknown>[]> {
    const scopedQuery = query;
    const entityId = this.getEntityId(tenant);
    const conditions = this.dateConditions(scopedQuery, entityId);
    conditions.push(
      sql`COALESCE(NULLIF(u.full_name, ''), 'Unassigned') = ${salespersonName}`,
    );
    const whereClause = sql.join(conditions, sql` AND `);
    const result = await db.execute(sql`
      SELECT
        to_char(s.sale_date::date, 'DD-MM-YYYY') AS "date",
        COALESCE(NULLIF(s.document_type, ''), 'Invoice') AS "type",
        COALESCE(NULLIF(s.status, ''), 'Sent') AS "status",
        CASE
          WHEN s.expected_shipment_date IS NULL THEN '-'
          ELSE to_char(s.expected_shipment_date::date, 'DD-MM-YYYY')
        END AS "dueDate",
        COALESCE(NULLIF(s.sale_number, ''), '-') AS "number",
        COALESCE(c.display_name, '-') AS "customerName",
        COALESCE(s.sub_total, 0)::numeric AS "sales",
        COALESCE(s.total, 0)::numeric AS "salesWithTax",
        COALESCE(s.total, 0)::numeric AS "balanceDue"
      FROM sales_orders s
      LEFT JOIN users u ON u.id = NULLIF(s.salesperson_id, '')::uuid
      LEFT JOIN customers c ON c.id = s.customer_id
      WHERE ${whereClause}
      ORDER BY s.sale_date ASC, s.sale_number ASC
    `);
    return this.rowsFrom(result).map((row) => ({
      ...row,
      sales: this.parseNumber(row.sales),
      salesWithTax: this.parseNumber(row.salesWithTax),
      balanceDue: this.parseNumber(row.balanceDue),
    }));
  }
}
