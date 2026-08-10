import { Injectable } from "@nestjs/common";
import { sql } from "drizzle-orm";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { db } from "../../../db/db";
import { PurchasesExpensesReportQueryDto } from "../dto/purchases-expenses-report-query.dto";

export interface PurchasesExpensesReportPage<
  T extends Record<string, unknown>,
> {
  rows: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
  totals?: Record<string, unknown>;
}

interface PaginationOptions {
  page: number;
  limit: number;
  offset: number;
}

@Injectable()
export class PurchasesExpensesReportsRepository {
  private parseNumber(value: unknown, fallback = 0): number {
    if (value === null || value === undefined || value === "") return fallback;
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  private normalizePagination(
    query: PurchasesExpensesReportQueryDto,
  ): PaginationOptions {
    const page = Math.max(1, Number(query.page ?? 1));
    const requestedLimit = Number(query.pageSize ?? query.limit ?? 100);
    const limit = Math.min(500, Math.max(1, requestedLimit));
    return { page, limit, offset: (page - 1) * limit };
  }

  private getEntityId(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ): string {
    return query.entityId?.trim() || tenant.entityId?.toString().trim() || "";
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
  ): PurchasesExpensesReportPage<T> {
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

  private emptyPage<T extends Record<string, unknown>>(
    pagination: PaginationOptions,
  ): PurchasesExpensesReportPage<T> {
    return {
      rows: [],
      total: 0,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: 1,
    };
  }

  private purchasesByVendorSort(query: PurchasesExpensesReportQueryDto) {
    const direction =
      query.sortDirection?.toLowerCase() === "desc" ? sql`DESC` : sql`ASC`;

    let expression = sql`"vendorName"`;
    switch (query.sortBy?.trim()) {
      case "expenseCount":
        expression = sql`"expenseCount"`;
        break;
      case "billCount":
        expression = sql`"billCount"`;
        break;
      case "vendorCreditCount":
        expression = sql`"vendorCreditCount"`;
        break;
      case "journalCount":
        expression = sql`"journalCount"`;
        break;
      case "amount":
        expression = sql`"amount"`;
        break;
      case "amountWithTax":
        expression = sql`"amountWithTax"`;
        break;
      default:
        expression = sql`"vendorName"`;
        break;
    }

    return sql`${expression} ${direction}`;
  }

  private purchasesByItemSort(query: PurchasesExpensesReportQueryDto) {
    const direction =
      query.sortDirection?.toLowerCase() === "desc" ? sql`DESC` : sql`ASC`;

    let expression = sql`"itemName"`;
    switch (query.sortBy?.trim()) {
      case "quantityPurchased":
        expression = sql`"quantityPurchased"`;
        break;
      case "amount":
        expression = sql`"amount"`;
        break;
      case "averagePrice":
        expression = sql`"averagePrice"`;
        break;
      default:
        expression = sql`"itemName"`;
        break;
    }

    return sql`${expression} ${direction}`;
  }

  private expenseDetailsSort(query: PurchasesExpensesReportQueryDto) {
    const direction =
      query.sortDirection?.toLowerCase() === "desc" ? sql`DESC` : sql`ASC`;

    let expression = sql`"date"`;
    switch (query.sortBy?.trim()) {
      case "status":
        expression = sql`"status"`;
        break;
      case "transactionType":
        expression = sql`"transactionType"`;
        break;
      case "transactionNumber":
        expression = sql`"transactionNumber"`;
        break;
      case "vendorName":
        expression = sql`"vendorName"`;
        break;
      case "category":
        expression = sql`"category"`;
        break;
      case "customerName":
        expression = sql`"customerName"`;
        break;
      case "amount":
        expression = sql`"amountValue"`;
        break;
      case "amountWithTax":
        expression = sql`"amountWithTaxValue"`;
        break;
      case "date":
      default:
        expression = sql`"date"`;
        break;
    }

    return sql`${expression} ${direction}`;
  }

  private expensesByCategorySort(query: PurchasesExpensesReportQueryDto) {
    const direction =
      query.sortDirection?.toLowerCase() === "desc" ? sql`DESC` : sql`ASC`;

    let expression = sql`"categoryName"`;
    switch (query.sortBy?.trim()) {
      case "amount":
        expression = sql`"amount"`;
        break;
      case "amountWithTax":
        expression = sql`"amountWithTax"`;
        break;
      case "categoryName":
      case "category":
      default:
        expression = sql`"categoryName"`;
        break;
    }

    return sql`${expression} ${direction}`;
  }

  private expensesByCustomerSort(query: PurchasesExpensesReportQueryDto) {
    const direction =
      query.sortDirection?.toLowerCase() === "desc" ? sql`DESC` : sql`ASC`;

    let expression = sql`"customerName"`;
    switch (query.sortBy?.trim()) {
      case "expenseCount":
        expression = sql`"expenseCount"`;
        break;
      case "expenseAmount":
        expression = sql`"expenseAmount"`;
        break;
      case "expenseAmountWithTax":
        expression = sql`"expenseAmountWithTax"`;
        break;
      case "customerName":
      default:
        expression = sql`"customerName"`;
        break;
    }

    return sql`${expression} ${direction}`;
  }
  private expensesByEmployeeSort(query: PurchasesExpensesReportQueryDto) {
    const direction =
      query.sortDirection?.toLowerCase() === "desc" ? sql`DESC` : sql`ASC`;

    let expression = sql`"employeeName"`;
    switch (query.sortBy?.trim()) {
      case "distance":
        expression = sql`"distance"`;
        break;
      case "expenseCount":
        expression = sql`"expenseCount"`;
        break;
      case "amount":
        expression = sql`"amount"`;
        break;
      case "amountWithTax":
        expression = sql`"amountWithTax"`;
        break;
      case "employeeName":
      default:
        expression = sql`"employeeName"`;
        break;
    }

    return sql`${expression} ${direction}`;
  }
  private billDetailsSort(query: PurchasesExpensesReportQueryDto) {
    const direction =
      query.sortDirection?.toLowerCase() === "asc" ? sql`ASC` : sql`DESC`;

    let expression = sql`"billDateRaw"`;
    switch (query.sortBy?.trim()) {
      case "status":
        expression = sql`"status"`;
        break;
      case "dueDate":
        expression = sql`"dueDateRaw"`;
        break;
      case "billNumber":
        expression = sql`"billNumber"`;
        break;
      case "vendorName":
        expression = sql`"vendorName"`;
        break;
      case "billAmount":
        expression = sql`"billAmount"`;
        break;
      case "balanceAmount":
        expression = sql`"balanceAmount"`;
        break;
      case "billDate":
      default:
        expression = sql`"billDateRaw"`;
        break;
    }

    return sql`${expression} ${direction}`;
  }
  private vendorCreditsDetailsSort(query: PurchasesExpensesReportQueryDto) {
    const direction =
      query.sortDirection?.toLowerCase() === "asc" ? sql`ASC` : sql`DESC`;

    let expression = sql`"vendorCreditDateRaw"`;
    switch (query.sortBy?.trim()) {
      case "status":
        expression = sql`"status"`;
        break;
      case "vendorCreditNumber":
        expression = sql`"vendorCreditNumber"`;
        break;
      case "vendorName":
        expression = sql`"vendorName"`;
        break;
      case "amount":
        expression = sql`"amount"`;
        break;
      case "balanceAmount":
        expression = sql`"balanceAmount"`;
        break;
      case "vendorCreditDate":
      default:
        expression = sql`"vendorCreditDateRaw"`;
        break;
    }

    return sql`${expression} ${direction}`;
  }
  private billableExpenseDetailsSort(query: PurchasesExpensesReportQueryDto) {
    const direction =
      query.sortDirection?.toLowerCase() === "desc" ? sql`DESC` : sql`ASC`;

    let expression = sql`"date"`;
    switch (query.sortBy?.trim()) {
      case "transactionNumber":
        expression = sql`"transactionNumber"`;
        break;
      case "vendorName":
        expression = sql`"vendorName"`;
        break;
      case "itemName":
        expression = sql`"itemName"`;
        break;
      case "itemAmount":
        expression = sql`"itemAmount"`;
        break;
      case "invoiceItemAmount":
        expression = sql`"invoiceItemAmount"`;
        break;
      case "markedUpAmount":
        expression = sql`"markedUpAmount"`;
        break;
      case "grossProfit":
        expression = sql`"grossProfit"`;
        break;
      case "date":
      default:
        expression = sql`"date"`;
        break;
    }

    return sql`${expression} ${direction}`;
  }
  async purchasesByVendor(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ): Promise<PurchasesExpensesReportPage<Record<string, unknown>>> {
    const pagination = this.normalizePagination(query);
    const entityId = this.getEntityId(tenant, query);
    const filterBy = query.filterBy?.trim().toLowerCase() || "all";
    const includeBills = ["all", "bills", "bill"].includes(filterBy);
    const includeExpenses = ["all", "expenses", "expense"].includes(filterBy);

    if (!entityId || (!includeBills && !includeExpenses)) {
      return this.emptyPage(pagination);
    }

    const billConditions = [
      includeBills ? sql`b.entity_id = ${entityId}` : sql`false`,
      sql`COALESCE(b.is_delete, false) = false`,
    ];

    const expenseConditions = [
      includeExpenses ? sql`e.entity_id = ${entityId}` : sql`false`,
      sql`COALESCE(e.is_delete, false) = false`,
    ];

    if (query.startDate?.trim()) {
      billConditions.push(sql`b.bill_date >= ${query.startDate.trim()}`);
      expenseConditions.push(sql`e.expense_date >= ${query.startDate.trim()}`);
    }

    if (query.endDate?.trim()) {
      billConditions.push(sql`b.bill_date <= ${query.endDate.trim()}`);
      expenseConditions.push(sql`e.expense_date <= ${query.endDate.trim()}`);
    }

    if (query.vendorId?.trim()) {
      billConditions.push(sql`b.vendor_id = ${query.vendorId.trim()}`);
      expenseConditions.push(sql`e.vendor_id = ${query.vendorId.trim()}`);
    }

    if (query.warehouseId?.trim()) {
      billConditions.push(sql`b.warehouse_id = ${query.warehouseId.trim()}`);
    }

    if (query.status?.trim()) {
      const status = query.status.trim().toLowerCase();
      billConditions.push(sql`LOWER(COALESCE(b.status, '')) = ${status}`);
      expenseConditions.push(sql`LOWER(COALESCE(e.status, '')) = ${status}`);
    }

    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      billConditions.push(sql`(
        v.display_name ILIKE ${search}
        OR b.bill_number ILIKE ${search}
        OR b.order_number ILIKE ${search}
        OR p.product_name ILIKE ${search}
        OR bi.description ILIKE ${search}
      )`);
      expenseConditions.push(sql`(
        v_expense.display_name ILIKE ${search}
        OR e.expense_number ILIKE ${search}
        OR e.notes ILIKE ${search}
        OR expense_account.user_account_name ILIKE ${search}
        OR expense_account.system_account_name ILIKE ${search}
        OR expense_account.account_code ILIKE ${search}
      )`);
    }

    const billWhereClause = sql.join(billConditions, sql` AND `);
    const expenseWhereClause = sql.join(expenseConditions, sql` AND `);
    const orderBy = this.purchasesByVendorSort(query);

    const result = await db.execute(sql`
      WITH bill_rows AS (
        SELECT
          b.id AS "sourceId",
          b.vendor_id AS "vendorId",
          CASE
            WHEN b.vendor_id IS NULL THEN 'Others'
            ELSE COALESCE(NULLIF(v.display_name, ''), 'Others')
          END AS "vendorName",
          0::int AS "expenseCount",
          1::int AS "billCount",
          0::int AS "vendorCreditCount",
          0::int AS "journalCount",
          COALESCE(SUM(COALESCE(bi.line_total, 0)), 0)::numeric AS "amount",
          COALESCE(b.grand_total, 0)::numeric AS "amountWithTax",
          0::numeric AS "balanceAmount",
          b.bill_date AS "recordDate",
          jsonb_build_object(
            'sourceType', 'Bill',
            'sourceId', b.id,
            'status', COALESCE(NULLIF(b.status, ''), '-'),
            'date', b.bill_date,
            'accountName', 'Bills',
            'transactionNumber', COALESCE(NULLIF(b.bill_number, ''), b.id::text),
            'amount', COALESCE(SUM(COALESCE(bi.line_total, 0)), 0),
            'amountWithTax', COALESCE(b.grand_total, 0),
            'balanceAmount', 0
          ) AS "detailRecord"
        FROM bills b
        LEFT JOIN vendors v ON v.id = b.vendor_id
        LEFT JOIN warehouses w ON w.id = b.warehouse_id
        LEFT JOIN bill_items bi ON bi.bill_id = b.id
        LEFT JOIN products p ON p.id = bi.product_id
        WHERE ${billWhereClause}
        GROUP BY
          b.id,
          b.vendor_id,
          v.display_name,
          b.bill_number,
          b.bill_date,
          b.status,
          b.grand_total
      ),
      expense_rows AS (
        SELECT
          e.id AS "sourceId",
          e.vendor_id AS "vendorId",
          CASE
            WHEN e.vendor_id IS NULL THEN 'Others'
            ELSE COALESCE(NULLIF(v_expense.display_name, ''), 'Others')
          END AS "vendorName",
          1::int AS "expenseCount",
          0::int AS "billCount",
          0::int AS "vendorCreditCount",
          0::int AS "journalCount",
          COALESCE(e.amount, 0)::numeric AS "amount",
          COALESCE(e.total_amount, e.amount, 0)::numeric AS "amountWithTax",
          0::numeric AS "balanceAmount",
          e.expense_date AS "recordDate",
          jsonb_build_object(
            'sourceType', 'Expense',
            'sourceId', e.id,
            'status', CASE
              WHEN COALESCE(e.is_billable, false) THEN 'Billable'
              ELSE 'Non-Billable'
            END,
            'date', e.expense_date,
            'accountName', CASE
              WHEN e.expense_mode = 'RECORD_MILEAGE' THEN 'Fuel/Mileage Expenses'
              ELSE COALESCE(
                NULLIF(expense_account.user_account_name, ''),
                NULLIF(expense_account.system_account_name, ''),
                NULLIF(expense_account.account_code, ''),
                '-'
              )
            END,
            'transactionNumber', COALESCE(NULLIF(e.expense_number, ''), '--'),
            'amount', COALESCE(e.amount, 0),
            'amountWithTax', COALESCE(e.total_amount, e.amount, 0),
            'balanceAmount', 0
          ) AS "detailRecord"
        FROM expenses e
        LEFT JOIN vendors v_expense ON v_expense.id = e.vendor_id
        LEFT JOIN accounts expense_account ON expense_account.id = e.expense_account_id
        WHERE ${expenseWhereClause}
      ),
      purchase_rows AS (
        SELECT * FROM bill_rows
        UNION ALL
        SELECT * FROM expense_rows
      ),
      vendor_rows AS (
        SELECT
          "vendorId",
          "vendorName",
          COALESCE(SUM("expenseCount"), 0)::int AS "expenseCount",
          COALESCE(SUM("billCount"), 0)::int AS "billCount",
          COALESCE(SUM("vendorCreditCount"), 0)::int AS "vendorCreditCount",
          COALESCE(SUM("journalCount"), 0)::int AS "journalCount",
          COALESCE(SUM("amount"), 0)::numeric AS "amount",
          COALESCE(SUM("amountWithTax"), 0)::numeric AS "amountWithTax",
          COALESCE(SUM("balanceAmount"), 0)::numeric AS "balanceAmount",
          jsonb_agg("detailRecord" ORDER BY "recordDate" ASC NULLS LAST, "sourceId" ASC) AS "details"
        FROM purchase_rows
        GROUP BY "vendorId", "vendorName"
      )
      SELECT
        "vendorId",
        "vendorName",
        "expenseCount",
        "billCount",
        "vendorCreditCount",
        "journalCount",
        "amount",
        "amountWithTax",
        "balanceAmount",
        "details",
        COUNT(*) OVER()::int AS "__total"
      FROM vendor_rows
      ORDER BY ${orderBy}, "vendorName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      expenseCount: this.parseNumber(row.expenseCount),
      billCount: this.parseNumber(row.billCount),
      vendorCreditCount: this.parseNumber(row.vendorCreditCount),
      journalCount: this.parseNumber(row.journalCount),
      amount: this.parseNumber(row.amount),
      amountWithTax: this.parseNumber(row.amountWithTax),
      balanceAmount: this.parseNumber(row.balanceAmount),
    }));

    return this.pageFromRows(rows, pagination);
  }
  async purchasesByItem(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ): Promise<PurchasesExpensesReportPage<Record<string, unknown>>> {
    const pagination = this.normalizePagination(query);
    const entityId = this.getEntityId(tenant, query);

    if (!entityId) {
      return this.emptyPage(pagination);
    }

    const conditions = [
      sql`b.entity_id = ${entityId}`,
      sql`COALESCE(b.is_delete, false) = false`,
    ];

    if (query.startDate?.trim()) {
      conditions.push(sql`b.bill_date >= ${query.startDate.trim()}`);
    }

    if (query.endDate?.trim()) {
      conditions.push(sql`b.bill_date <= ${query.endDate.trim()}`);
    }

    if (query.vendorId?.trim()) {
      conditions.push(sql`b.vendor_id = ${query.vendorId.trim()}`);
    }

    if (query.warehouseId?.trim()) {
      conditions.push(sql`b.warehouse_id = ${query.warehouseId.trim()}`);
    }

    if (query.status?.trim()) {
      conditions.push(
        sql`LOWER(COALESCE(b.status, '')) = ${query.status.trim().toLowerCase()}`,
      );
    }

    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        p.product_name ILIKE ${search}
        OR bi.description ILIKE ${search}
        OR b.bill_number ILIKE ${search}
        OR b.order_number ILIKE ${search}
        OR v.display_name ILIKE ${search}
      )`);
    }

    const whereClause = sql.join(conditions, sql` AND `);
    const orderBy = this.purchasesByItemSort(query);

    const result = await db.execute(sql`
      WITH item_rows AS (
        SELECT
          bi.id AS "billItemId",
          bi.product_id AS "productId",
          COALESCE(NULLIF(p.product_name, ''), '-') AS "itemName",
          COALESCE(NULLIF(bi.description, ''), '-') AS "description",
          COALESCE(bi.quantity, 0)::numeric AS "quantity",
          COALESCE(bi.rate, 0)::numeric AS "rate",
          COALESCE(bi.discount_amount, 0)::numeric AS "discountAmount",
          COALESCE(bi.discount_value, 0)::numeric AS "discountValue",
          COALESCE(NULLIF(bi.discount_type, ''), '-') AS "discountType",
          COALESCE(bi.tax_percentage, 0)::numeric AS "taxPercentage",
          COALESCE(bi.tax_amount, 0)::numeric AS "taxAmount",
          COALESCE(bi.line_total, 0)::numeric AS "lineTotal",
          b.id AS "billId",
          COALESCE(NULLIF(b.bill_number, ''), b.id::text) AS "billNumber",
          b.bill_date AS "billDate",
          b.due_date AS "dueDate",
          COALESCE(NULLIF(b.status, ''), '-') AS "status",
          COALESCE(b.grand_total, 0)::numeric AS "grandTotal",
          b.entity_id AS "entityId",
          b.vendor_id AS "vendorId",
          COALESCE(NULLIF(v.display_name, ''), 'Others') AS "vendorName",
          b.warehouse_id AS "warehouseId",
          COALESCE(NULLIF(w.name, ''), '-') AS "warehouse",
          b.payment_term_id AS "paymentTermId",
          COALESCE(NULLIF(pt.term_name, ''), '-') AS "paymentTerm"
        FROM bills b
        JOIN bill_items bi ON bi.bill_id = b.id
        JOIN products p ON p.id = bi.product_id
        JOIN vendors v ON v.id = b.vendor_id
        LEFT JOIN warehouses w ON w.id = b.warehouse_id
        LEFT JOIN payment_terms pt ON pt.id = b.payment_term_id
        WHERE ${whereClause}
      ),
      product_rows AS (
        SELECT
          "productId",
          "itemName",
          COALESCE(SUM("quantity"), 0)::numeric AS "quantityPurchased",
          COALESCE(SUM("lineTotal"), 0)::numeric AS "amount",
          CASE
            WHEN COALESCE(SUM("quantity"), 0) = 0 THEN 0::numeric
            ELSE (COALESCE(SUM("lineTotal"), 0) / NULLIF(SUM("quantity"), 0))::numeric
          END AS "averagePrice",
          jsonb_agg(
            jsonb_build_object(
              'billItemId', "billItemId",
              'billId', "billId",
              'billNumber', "billNumber",
              'billDate', "billDate",
              'dueDate', "dueDate",
              'status', "status",
              'grandTotal', "grandTotal",
              'entityId', "entityId",
              'vendorId', "vendorId",
              'vendorName', "vendorName",
              'warehouseId', "warehouseId",
              'warehouse', "warehouse",
              'paymentTermId', "paymentTermId",
              'paymentTerm', "paymentTerm",
              'description', "description",
              'quantity', "quantity",
              'rate', "rate",
              'discountType', "discountType",
              'discountValue', "discountValue",
              'discountAmount', "discountAmount",
              'taxPercentage', "taxPercentage",
              'taxAmount', "taxAmount",
              'lineTotal', "lineTotal"
            )
            ORDER BY "billDate" ASC NULLS LAST, "billNumber" ASC
          ) AS "purchases"
        FROM item_rows
        GROUP BY "productId", "itemName"
      )
      SELECT
        "productId",
        "itemName",
        "quantityPurchased",
        "amount",
        "averagePrice",
        "purchases",
        COUNT(*) OVER()::int AS "__total"
      FROM product_rows
      ORDER BY ${orderBy}, "itemName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      quantityPurchased: this.parseNumber(row.quantityPurchased),
      amount: this.parseNumber(row.amount),
      averagePrice: this.parseNumber(row.averagePrice),
    }));

    return this.pageFromRows(rows, pagination);
  }
  async billDetails(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ): Promise<PurchasesExpensesReportPage<Record<string, unknown>>> {
    const pagination = this.normalizePagination(query);
    const entityId = this.getEntityId(tenant, query);

    if (!entityId) {
      return this.emptyPage(pagination);
    }

    const allocationBillIdExpression = sql`COALESCE(
      NULLIF(to_jsonb(alloc)->>'bill_id', ''),
      NULLIF(to_jsonb(alloc)->>'billId', '')
    )`;
    const allocationAmountTextExpression = sql`COALESCE(
      NULLIF(to_jsonb(alloc)->>'amount', ''),
      NULLIF(to_jsonb(alloc)->>'allocated_amount', ''),
      NULLIF(to_jsonb(alloc)->>'payment_amount', ''),
      NULLIF(to_jsonb(alloc)->>'amount_applied', ''),
      NULLIF(to_jsonb(alloc)->>'applied_amount', '')
    )`;
    const allocationAmountExpression = sql`CASE
      WHEN ${allocationAmountTextExpression} ~ '^-?[0-9]+([.][0-9]+)?$'
      THEN ${allocationAmountTextExpression}::numeric
      ELSE 0::numeric
    END`;
    const dateColumn = query.reportBy?.trim().toLowerCase().includes('due')
      ? sql`b.due_date`
      : sql`b.bill_date`;
    const conditions = [
      sql`b.entity_id = ${entityId}`,
      sql`COALESCE(b.is_delete, false) = false`,
    ];

    if (query.startDate?.trim()) {
      conditions.push(sql`${dateColumn} >= ${query.startDate.trim()}`);
    }

    if (query.endDate?.trim()) {
      conditions.push(sql`${dateColumn} <= ${query.endDate.trim()}`);
    }

    if (query.vendorId?.trim()) {
      conditions.push(sql`b.vendor_id = ${query.vendorId.trim()}`);
    }

    if (query.warehouseId?.trim()) {
      conditions.push(sql`b.warehouse_id = ${query.warehouseId.trim()}`);
    }

    if (query.status?.trim()) {
      conditions.push(
        sql`LOWER(COALESCE(b.status, '')) = ${query.status.trim().toLowerCase()}`,
      );
    }

    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        b.bill_number ILIKE ${search}
        OR b.order_number ILIKE ${search}
        OR v.display_name ILIKE ${search}
        OR v.company_name ILIKE ${search}
      )`);
    }

    const whereClause = sql.join(conditions, sql` AND `);
    const orderBy = this.billDetailsSort(query);

    const result = await db.execute(sql`
      WITH allocation_rows AS (
        SELECT
          ${allocationBillIdExpression} AS "billId",
          ${allocationAmountExpression} AS "allocatedAmount"
        FROM payment_made_bill_allocations alloc
      ),
      allocation_summary AS (
        SELECT
          ar."billId",
          COALESCE(SUM(ar."allocatedAmount"), 0)::numeric AS "amountPaid"
        FROM allocation_rows ar
        WHERE ar."billId" IS NOT NULL
        GROUP BY ar."billId"
      ),
      bill_rows AS (
        SELECT
          b.id::text AS "billId",
          COALESCE(NULLIF(b.status, ''), 'Draft') AS "status",
          b.bill_date AS "billDateRaw",
          b.due_date AS "dueDateRaw",
          COALESCE(NULLIF(b.bill_number, ''), b.id::text) AS "billNumber",
          COALESCE(NULLIF(b.order_number, ''), '') AS "orderNumber",
          COALESCE(
            NULLIF(v.display_name, ''),
            NULLIF(v.company_name, ''),
            b.vendor_id::text,
            '-'
          ) AS "vendorName",
          b.vendor_id::text AS "vendorId",
          COALESCE(NULLIF(w.name, ''), '') AS "warehouseName",
          b.warehouse_id::text AS "warehouseId",
          COALESCE(NULLIF(pt.term_name, ''), '') AS "paymentTerms",
          b.payment_term_id::text AS "paymentTermId",
          COALESCE(
            b.grand_total,
            NULLIF(to_jsonb(b)->>'invoice_total', '')::numeric,
            0
          )::numeric AS "billAmount",
          COALESCE(alloc."amountPaid", 0)::numeric AS "amountPaid",
          (
            COALESCE(
              b.grand_total,
              NULLIF(to_jsonb(b)->>'invoice_total', '')::numeric,
              0
            ) - COALESCE(alloc."amountPaid", 0)
          )::numeric AS "balanceAmount"
        FROM bills b
        LEFT JOIN allocation_summary alloc ON alloc."billId" = b.id::text
        LEFT JOIN vendors v ON v.id = b.vendor_id
        LEFT JOIN warehouses w ON w.id = b.warehouse_id
        LEFT JOIN payment_terms pt ON pt.id = b.payment_term_id
        WHERE ${whereClause}
      )
      SELECT
        *,
        COUNT(*) OVER()::int AS "__total",
        COALESCE(SUM("billAmount") OVER(), 0)::numeric AS "__totalBillAmount",
        COALESCE(SUM("balanceAmount") OVER(), 0)::numeric AS "__totalBalanceAmount"
      FROM bill_rows
      ORDER BY ${orderBy} NULLS LAST, "billNumber" ASC, "billId" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rawRows = this.rowsFrom(result);
    const firstRow = rawRows[0] ?? {};
    const total = rawRows.length > 0 ? this.parseNumber(firstRow.__total) : 0;
    const rows = rawRows.map((row) => {
      const {
        __total,
        __totalBillAmount,
        __totalBalanceAmount,
        ...rest
      } = row;
      return {
        ...rest,
        billAmount: this.parseNumber(rest.billAmount),
        amountPaid: this.parseNumber(rest.amountPaid),
        balanceAmount: this.parseNumber(rest.balanceAmount),
      };
    });

    return {
      rows,
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: total === 0 ? 1 : Math.ceil(total / pagination.limit),
      totals: {
        billAmount: this.parseNumber(firstRow.__totalBillAmount),
        balanceAmount: this.parseNumber(firstRow.__totalBalanceAmount),
      },
    };
  }

  async vendorCreditsDetails(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ): Promise<PurchasesExpensesReportPage<Record<string, unknown>>> {
    const pagination = this.normalizePagination(query);
    const entityId = this.getEntityId(tenant, query);

    if (!entityId) {
      return this.emptyPage(pagination);
    }

    const balanceTextExpression = sql`COALESCE(
      NULLIF(to_jsonb(vc)->>'balance_amount', ''),
      NULLIF(to_jsonb(vc)->>'unapplied_amount', ''),
      NULLIF(to_jsonb(vc)->>'available_credit', ''),
      NULLIF(to_jsonb(vc)->>'unused_amount', ''),
      NULLIF(to_jsonb(vc)->>'balance', '')
    )`;
    const balanceValueExpression = sql`CASE
      WHEN ${balanceTextExpression} ~ '^-?[0-9]+([.][0-9]+)?$'
      THEN ${balanceTextExpression}::numeric
      ELSE NULL::numeric
    END`;
    const totalAmountExpression = sql`COALESCE(
      vc.total_amount,
      COALESCE(vc.subtotal, 0)
        - COALESCE(vc.discount_amount, 0)
        + COALESCE(vc.tax_amount, 0)
        + COALESCE(vc.adjustment_amount, 0),
      0
    )::numeric`;
    const conditions = [
      sql`vc.entity_id = ${entityId}`,
      sql`COALESCE(NULLIF(to_jsonb(vc)->>'is_deleted', '')::boolean, false) = false`,
    ];

    if (query.startDate?.trim()) {
      conditions.push(sql`vc.vendor_credit_date >= ${query.startDate.trim()}`);
    }

    if (query.endDate?.trim()) {
      conditions.push(sql`vc.vendor_credit_date <= ${query.endDate.trim()}`);
    }

    if (query.vendorId?.trim()) {
      conditions.push(sql`vc.vendor_id = ${query.vendorId.trim()}`);
    }

    if (query.warehouseId?.trim()) {
      conditions.push(sql`vc.warehouse_id = ${query.warehouseId.trim()}`);
    }

    if (query.status?.trim()) {
      conditions.push(
        sql`LOWER(COALESCE(vc.status, '')) = ${query.status.trim().toLowerCase()}`,
      );
    }

    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        vc.vendor_credit_number ILIKE ${search}
        OR vc.reference_number ILIKE ${search}
        OR vendor.display_name ILIKE ${search}
        OR vendor.company_name ILIKE ${search}
      )`);
    }

    const whereClause = sql.join(conditions, sql` AND `);
    const orderBy = this.vendorCreditsDetailsSort(query);

    const result = await db.execute(sql`
      WITH vendor_credit_rows AS (
        SELECT
          vc.id::text AS "vendorCreditId",
          COALESCE(NULLIF(vc.status, ''), 'Open') AS "status",
          vc.vendor_credit_date AS "vendorCreditDateRaw",
          COALESCE(NULLIF(vc.vendor_credit_number, ''), vc.id::text) AS "vendorCreditNumber",
          COALESCE(NULLIF(vc.reference_number, ''), '') AS "referenceNumber",
          COALESCE(
            NULLIF(vendor.display_name, ''),
            NULLIF(vendor.company_name, ''),
            vc.vendor_id::text,
            '-'
          ) AS "vendorName",
          vc.vendor_id::text AS "vendorId",
          COALESCE(NULLIF(warehouse.name, ''), '') AS "warehouseName",
          vc.warehouse_id::text AS "warehouseId",
          COALESCE(NULLIF(vc.source_type, ''), '') AS "sourceType",
          vc.purchase_return_id::text AS "purchaseReturnId",
          vc.bill_id::text AS "billId",
          ${totalAmountExpression} AS "amount",
          COALESCE(
            ${balanceValueExpression},
            CASE
              WHEN LOWER(COALESCE(vc.status, '')) IN ('closed', 'applied', 'used') THEN 0::numeric
              ELSE ${totalAmountExpression}
            END
          )::numeric AS "balanceAmount"
        FROM vendor_credits vc
        LEFT JOIN vendors vendor ON vendor.id = vc.vendor_id
        LEFT JOIN warehouses warehouse ON warehouse.id = vc.warehouse_id
        WHERE ${whereClause}
      )
      SELECT
        *,
        COUNT(*) OVER()::int AS "__total",
        COALESCE(SUM("amount") OVER(), 0)::numeric AS "__totalAmount",
        COALESCE(SUM("balanceAmount") OVER(), 0)::numeric AS "__totalBalanceAmount"
      FROM vendor_credit_rows
      ORDER BY ${orderBy} NULLS LAST, "vendorCreditNumber" ASC, "vendorCreditId" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rawRows = this.rowsFrom(result);
    const firstRow = rawRows[0] ?? {};
    const total = rawRows.length > 0 ? this.parseNumber(firstRow.__total) : 0;
    const rows = rawRows.map((row) => {
      const { __total, __totalAmount, __totalBalanceAmount, ...rest } = row;
      return {
        ...rest,
        amount: this.parseNumber(rest.amount),
        balanceAmount: this.parseNumber(rest.balanceAmount),
      };
    });

    return {
      rows,
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: total === 0 ? 1 : Math.ceil(total / pagination.limit),
      totals: {
        amount: this.parseNumber(firstRow.__totalAmount),
        balanceAmount: this.parseNumber(firstRow.__totalBalanceAmount),
      },
    };
  }
  async expensesByCategory(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ): Promise<PurchasesExpensesReportPage<Record<string, unknown>>> {
    const pagination = this.normalizePagination(query);
    const entityId = this.getEntityId(tenant, query);

    if (!entityId) {
      return this.emptyPage(pagination);
    }

    const conditions = [
      sql`e.entity_id = ${entityId}`,
      sql`e.is_delete = false`,
    ];

    if (query.startDate?.trim()) {
      conditions.push(sql`e.expense_date >= ${query.startDate.trim()}`);
    }

    if (query.endDate?.trim()) {
      conditions.push(sql`e.expense_date <= ${query.endDate.trim()}`);
    }

    if (query.vendorId?.trim()) {
      conditions.push(sql`e.vendor_id = ${query.vendorId.trim()}`);
    }

    const filterBy = query.filterBy?.trim().toLowerCase();
    if (filterBy && filterBy !== "all") {
      if (filterBy === "mileage") {
        conditions.push(sql`e.expense_mode = 'RECORD_MILEAGE'`);
      } else if (filterBy === "expense" || filterBy === "expenses") {
        conditions.push(
          sql`COALESCE(e.expense_mode, 'RECORD_EXPENSE') <> 'RECORD_MILEAGE'`,
        );
      }
    }

    const accountType = query.accountType?.trim().toLowerCase();
    if (accountType && accountType !== "all") {
      if (accountType === "expenses" || accountType === "expense") {
        conditions.push(sql`(
          e.expense_mode = 'RECORD_MILEAGE'
          OR LOWER(COALESCE(expense_account.account_group::text, '')) = 'expenses'
          OR LOWER(COALESCE(expense_account.account_type::text, '')) IN (
            'expense',
            'other expense',
            'cost of goods sold'
          )
        )`);
      } else {
        conditions.push(
          sql`LOWER(COALESCE(expense_account.account_type::text, '')) = ${accountType}`,
        );
      }
    }

    if (query.status?.trim()) {
      const status = query.status.trim().toLowerCase();
      if (["billable", "billed"].includes(status)) {
        conditions.push(sql`COALESCE(e.is_billable, false) = true`);
      } else if (
        ["non-billable", "non_billable", "non billable"].includes(status)
      ) {
        conditions.push(sql`COALESCE(e.is_billable, false) = false`);
      } else {
        conditions.push(sql`LOWER(COALESCE(e.status, '')) = ${status}`);
      }
    }

    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        e.expense_number ILIKE ${search}
        OR e.invoice_number ILIKE ${search}
        OR e.notes ILIKE ${search}
        OR expense_account.user_account_name ILIKE ${search}
        OR expense_account.system_account_name ILIKE ${search}
        OR expense_account.account_code ILIKE ${search}
      )`);
    }

    const whereClause = sql.join(conditions, sql` AND `);
    const orderBy = this.expensesByCategorySort(query);

    const result = await db.execute(sql`
      WITH category_rows AS (
        SELECT
          CASE
            WHEN e.expense_mode = 'RECORD_MILEAGE' THEN 'Fuel/Mileage Expenses'
            ELSE COALESCE(
              NULLIF(expense_account.user_account_name, ''),
              NULLIF(expense_account.system_account_name, ''),
              NULLIF(expense_account.account_code, ''),
              'Uncategorized'
            )
          END AS "categoryName",
          COUNT(e.id)::int AS "expenseCount",
          COALESCE(SUM(COALESCE(e.amount, 0)), 0)::numeric AS "amount",
          COALESCE(SUM(COALESCE(e.total_amount, e.amount, 0)), 0)::numeric AS "amountWithTax"
        FROM expenses e
        LEFT JOIN accounts expense_account ON expense_account.id = e.expense_account_id
        WHERE ${whereClause}
        GROUP BY
          CASE
            WHEN e.expense_mode = 'RECORD_MILEAGE' THEN 'Fuel/Mileage Expenses'
            ELSE COALESCE(
              NULLIF(expense_account.user_account_name, ''),
              NULLIF(expense_account.system_account_name, ''),
              NULLIF(expense_account.account_code, ''),
              'Uncategorized'
            )
          END
      )
      SELECT
        "categoryName",
        "expenseCount",
        "amount",
        "amountWithTax",
        COUNT(*) OVER()::int AS "__total"
      FROM category_rows
      ORDER BY ${orderBy}, "categoryName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      expenseCount: this.parseNumber(row.expenseCount),
      amount: this.parseNumber(row.amount),
      amountWithTax: this.parseNumber(row.amountWithTax),
    }));

    return this.pageFromRows(rows, pagination);
  }
  async expensesByCustomer(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ): Promise<PurchasesExpensesReportPage<Record<string, unknown>>> {
    const pagination = this.normalizePagination(query);
    const entityId = this.getEntityId(tenant, query);

    if (!entityId) {
      return this.emptyPage(pagination);
    }

    const conditions = [
      sql`e.entity_id = ${entityId}`,
      sql`e.is_delete = false`,
    ];

    if (query.startDate?.trim()) {
      conditions.push(sql`e.expense_date >= ${query.startDate.trim()}`);
    }

    if (query.endDate?.trim()) {
      conditions.push(sql`e.expense_date <= ${query.endDate.trim()}`);
    }

    if (query.vendorId?.trim()) {
      conditions.push(sql`e.vendor_id = ${query.vendorId.trim()}`);
    }

    if (query.status?.trim()) {
      const status = query.status.trim().toLowerCase();
      if (["billable", "billed"].includes(status)) {
        conditions.push(sql`COALESCE(e.is_billable, false) = true`);
      } else if (
        ["non-billable", "non_billable", "non billable"].includes(status)
      ) {
        conditions.push(sql`COALESCE(e.is_billable, false) = false`);
      } else {
        conditions.push(sql`LOWER(COALESCE(e.status, '')) = ${status}`);
      }
    }

    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        e.expense_number ILIKE ${search}
        OR e.invoice_number ILIKE ${search}
        OR e.notes ILIKE ${search}
        OR c.display_name ILIKE ${search}
        OR c.company_name ILIKE ${search}
      )`);
    }

    const whereClause = sql.join(conditions, sql` AND `);
    const orderBy = this.expensesByCustomerSort(query);

    const result = await db.execute(sql`
      WITH customer_rows AS (
        SELECT
          COALESCE(e.customer_id::text, '__others__') AS "customerGroupId",
          CASE
            WHEN e.customer_id IS NULL THEN 'Others'
            ELSE COALESCE(NULLIF(c.display_name, ''), NULLIF(c.company_name, ''), 'Others')
          END AS "customerName",
          COUNT(e.id)::int AS "expenseCount",
          COALESCE(SUM(COALESCE(e.amount, 0)), 0)::numeric AS "expenseAmount",
          COALESCE(SUM(COALESCE(e.total_amount, e.amount, 0)), 0)::numeric AS "expenseAmountWithTax"
        FROM expenses e
        LEFT JOIN customers c ON c.id = e.customer_id
        WHERE ${whereClause}
        GROUP BY
          COALESCE(e.customer_id::text, '__others__'),
          CASE
            WHEN e.customer_id IS NULL THEN 'Others'
            ELSE COALESCE(NULLIF(c.display_name, ''), NULLIF(c.company_name, ''), 'Others')
          END
      )
      SELECT
        "customerGroupId",
        "customerName",
        "expenseCount",
        "expenseAmount",
        "expenseAmountWithTax",
        COUNT(*) OVER()::int AS "__total"
      FROM customer_rows
      ORDER BY ${orderBy}, "customerName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      expenseCount: this.parseNumber(row.expenseCount),
      expenseAmount: this.parseNumber(row.expenseAmount),
      expenseAmountWithTax: this.parseNumber(row.expenseAmountWithTax),
    }));

    return this.pageFromRows(rows, pagination);
  }
  async expensesByEmployee(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ): Promise<PurchasesExpensesReportPage<Record<string, unknown>>> {
    const pagination = this.normalizePagination(query);
    const entityId = this.getEntityId(tenant, query);

    if (!entityId) {
      return this.emptyPage(pagination);
    }

    const conditions = [
      sql`e.entity_id = ${entityId}`,
      sql`e.is_delete = false`,
    ];

    if (query.startDate?.trim()) {
      conditions.push(sql`e.expense_date >= ${query.startDate.trim()}`);
    }

    if (query.endDate?.trim()) {
      conditions.push(sql`e.expense_date <= ${query.endDate.trim()}`);
    }

    if (query.vendorId?.trim()) {
      conditions.push(sql`e.vendor_id = ${query.vendorId.trim()}`);
    }

    if (query.status?.trim()) {
      const status = query.status.trim().toLowerCase();
      if (["billable", "billed"].includes(status)) {
        conditions.push(sql`COALESCE(e.is_billable, false) = true`);
      } else if (
        ["non-billable", "non_billable", "non billable"].includes(status)
      ) {
        conditions.push(sql`COALESCE(e.is_billable, false) = false`);
      } else {
        conditions.push(sql`LOWER(COALESCE(e.status, '')) = ${status}`);
      }
    }

    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        e.expense_number ILIKE ${search}
        OR e.invoice_number ILIKE ${search}
        OR e.notes ILIKE ${search}
        OR employee_user.full_name ILIKE ${search}
        OR (mileage.employee_id IS NULL AND 'Others' ILIKE ${search})
      )`);
    }

    const whereClause = sql.join(conditions, sql` AND `);
    const orderBy = this.expensesByEmployeeSort(query);

    const result = await db.execute(sql`
      WITH employee_rows AS (
        SELECT
          COALESCE(mileage.employee_id::text, '__others__') AS "employeeGroupId",
          CASE
            WHEN mileage.employee_id IS NULL THEN 'Others'
            ELSE COALESCE(NULLIF(employee_user.full_name, ''), 'Others')
          END AS "employeeName",
          COALESCE(SUM(COALESCE(mileage.distance, 0)), 0)::numeric AS "distance",
          COUNT(e.id)::int AS "expenseCount",
          COALESCE(SUM(COALESCE(e.amount, 0)), 0)::numeric AS "amount",
          COALESCE(SUM(COALESCE(e.total_amount, e.amount, 0)), 0)::numeric AS "amountWithTax"
        FROM expenses e
        LEFT JOIN LATERAL (
          SELECT em.id, em.employee_id, em.distance
          FROM expense_mileage em
          WHERE em.expense_id = e.id
          ORDER BY em.created_at DESC NULLS LAST
          LIMIT 1
        ) mileage ON true
        LEFT JOIN users employee_user ON employee_user.id = mileage.employee_id
        WHERE ${whereClause}
        GROUP BY
          COALESCE(mileage.employee_id::text, '__others__'),
          CASE
            WHEN mileage.employee_id IS NULL THEN 'Others'
            ELSE COALESCE(NULLIF(employee_user.full_name, ''), 'Others')
          END
      )
      SELECT
        "employeeGroupId",
        "employeeName",
        "distance",
        "expenseCount",
        "amount",
        "amountWithTax",
        COUNT(*) OVER()::int AS "__total"
      FROM employee_rows
      ORDER BY ${orderBy}, "employeeName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      distance: this.parseNumber(row.distance),
      expenseCount: this.parseNumber(row.expenseCount),
      amount: this.parseNumber(row.amount),
      amountWithTax: this.parseNumber(row.amountWithTax),
    }));

    return this.pageFromRows(rows, pagination);
  }
  async billableExpenseDetails(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ): Promise<PurchasesExpensesReportPage<Record<string, unknown>>> {
    const pagination = this.normalizePagination(query);
    const entityId = this.getEntityId(tenant, query);

    if (!entityId) {
      return this.emptyPage(pagination);
    }

    const conditions = [
      sql`e.entity_id = ${entityId}`,
      sql`COALESCE(e.is_delete, false) = false`,
      sql`COALESCE(e.is_billable, false) = true`,
    ];

    if (query.startDate?.trim()) {
      conditions.push(sql`e.expense_date >= ${query.startDate.trim()}`);
    }

    if (query.endDate?.trim()) {
      conditions.push(sql`e.expense_date <= ${query.endDate.trim()}`);
    }

    if (query.vendorId?.trim()) {
      conditions.push(sql`e.vendor_id = ${query.vendorId.trim()}`);
    }

    if (query.status?.trim()) {
      const status = query.status.trim().toLowerCase();
      if (!["billable", "billed"].includes(status)) {
        conditions.push(sql`LOWER(COALESCE(e.status, '')) = ${status}`);
      }
    }

    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        e.expense_number ILIKE ${search}
        OR e.invoice_number ILIKE ${search}
        OR e.notes ILIKE ${search}
        OR v.display_name ILIKE ${search}
        OR v.company_name ILIKE ${search}
        OR c.display_name ILIKE ${search}
        OR c.company_name ILIKE ${search}
        OR expense_account.user_account_name ILIKE ${search}
        OR expense_account.system_account_name ILIKE ${search}
      )`);
    }

    const whereClause = sql.join(conditions, sql` AND `);
    const orderBy = this.billableExpenseDetailsSort(query);

    const result = await db.execute(sql`
      SELECT
        e.id AS "expenseId",
        e.expense_date AS "date",
        COALESCE(NULLIF(e.expense_number, ''), NULLIF(e.invoice_number, ''), e.id::text) AS "transactionNumber",
        COALESCE(NULLIF(v.display_name, ''), NULLIF(v.company_name, ''), '-') AS "vendorName",
        COALESCE(
          NULLIF(expense_account.user_account_name, ''),
          NULLIF(expense_account.system_account_name, ''),
          NULLIF(expense_account.account_code, ''),
          '-'
        ) AS "itemName",
        COALESCE(e.amount, e.subtotal, 0)::numeric AS "itemAmount",
        0::numeric AS "markup",
        COALESCE(e.total_amount, e.amount, e.subtotal, 0)::numeric AS "invoiceItemAmount",
        COALESCE(e.total_amount, e.amount, e.subtotal, 0)::numeric AS "markedUpAmount",
        (COALESCE(e.total_amount, e.amount, e.subtotal, 0) - COALESCE(e.amount, e.subtotal, 0))::numeric AS "grossProfit",
        CASE
          WHEN COALESCE(e.is_billable, false) THEN 'Billable'
          ELSE 'Non-Billable'
        END AS "billableStatus",
        COALESCE(NULLIF(e.status, ''), 'Billable') AS "status",
        COALESCE(NULLIF(c.display_name, ''), NULLIF(c.company_name, ''), '-') AS "customerName",
        e.customer_id AS "customerId",
        e.vendor_id AS "vendorId",
        e.expense_account_id AS "expenseAccountId",
        COUNT(*) OVER()::int AS "__total"
      FROM expenses e
      LEFT JOIN vendors v ON v.id = e.vendor_id
      LEFT JOIN customers c ON c.id = e.customer_id
      LEFT JOIN accounts expense_account ON expense_account.id = e.expense_account_id
      WHERE ${whereClause}
      ORDER BY ${orderBy}, "transactionNumber" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      itemAmount: this.parseNumber(row.itemAmount),
      markup: this.parseNumber(row.markup),
      invoiceItemAmount: this.parseNumber(row.invoiceItemAmount),
      markedUpAmount: this.parseNumber(row.markedUpAmount),
      grossProfit: this.parseNumber(row.grossProfit),
    }));

    return this.pageFromRows(rows, pagination);
  }
  async expenseDetails(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ): Promise<PurchasesExpensesReportPage<Record<string, unknown>>> {
    const pagination = this.normalizePagination(query);
    const entityId = this.getEntityId(tenant, query);

    if (!entityId) {
      return this.emptyPage(pagination);
    }

    const conditions = [
      sql`e.entity_id = ${entityId}`,
      sql`COALESCE(e.is_delete, false) = false`,
    ];

    if (query.startDate?.trim()) {
      conditions.push(sql`e.expense_date >= ${query.startDate.trim()}`);
    }

    if (query.endDate?.trim()) {
      conditions.push(sql`e.expense_date <= ${query.endDate.trim()}`);
    }

    if (query.vendorId?.trim()) {
      conditions.push(sql`e.vendor_id = ${query.vendorId.trim()}`);
    }

    if (query.status?.trim()) {
      const status = query.status.trim().toLowerCase();
      if (["billable", "billed"].includes(status)) {
        conditions.push(sql`COALESCE(e.is_billable, false) = true`);
      } else if (
        ["non-billable", "non_billable", "non billable"].includes(status)
      ) {
        conditions.push(sql`COALESCE(e.is_billable, false) = false`);
      } else {
        conditions.push(sql`LOWER(COALESCE(e.status, '')) = ${status}`);
      }
    }

    const filterBy = query.filterBy?.trim().toLowerCase();
    if (filterBy && filterBy !== "all") {
      if (filterBy === "mileage") {
        conditions.push(sql`e.expense_mode = 'RECORD_MILEAGE'`);
      } else if (filterBy === "expense" || filterBy === "expenses") {
        conditions.push(
          sql`COALESCE(e.expense_mode, 'RECORD_EXPENSE') <> 'RECORD_MILEAGE'`,
        );
      }
    }

    const accountType = query.accountType?.trim().toLowerCase();
    if (accountType && accountType !== "all") {
      if (accountType === "expenses" || accountType === "expense") {
        conditions.push(sql`(
          e.expense_mode = 'RECORD_MILEAGE'
          OR LOWER(COALESCE(expense_account.account_group::text, '')) = 'expenses'
          OR LOWER(COALESCE(expense_account.account_type::text, '')) IN (
            'expense',
            'other expense',
            'cost of goods sold'
          )
        )`);
      } else {
        conditions.push(
          sql`LOWER(COALESCE(expense_account.account_type::text, '')) = ${accountType}`,
        );
      }
    }

    if (query.categoryName?.trim()) {
      const categoryName = query.categoryName.trim();
      if (categoryName === "Fuel/Mileage Expenses") {
        conditions.push(sql`e.expense_mode = 'RECORD_MILEAGE'`);
      } else {
        conditions.push(sql`COALESCE(
          NULLIF(expense_account.user_account_name, ''),
          NULLIF(expense_account.system_account_name, ''),
          NULLIF(expense_account.account_code, ''),
          'Uncategorized'
        ) = ${categoryName}`);
      }
    }

    if (query.customerName?.trim()) {
      const customerName = query.customerName.trim();
      if (customerName === "Others") {
        conditions.push(sql`e.customer_id IS NULL`);
      } else {
        conditions.push(sql`COALESCE(
          NULLIF(c.display_name, ''),
          NULLIF(c.company_name, ''),
          'Others'
        ) = ${customerName}`);
      }
    }

    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        e.expense_number ILIKE ${search}
        OR e.invoice_number ILIKE ${search}
        OR e.notes ILIKE ${search}
        OR v.display_name ILIKE ${search}
        OR v.company_name ILIKE ${search}
        OR c.display_name ILIKE ${search}
        OR c.company_name ILIKE ${search}
        OR expense_account.user_account_name ILIKE ${search}
        OR expense_account.system_account_name ILIKE ${search}
        OR paid_account.user_account_name ILIKE ${search}
        OR paid_account.system_account_name ILIKE ${search}
      )`);
    }

    const whereClause = sql.join(conditions, sql` AND `);
    const orderBy = this.expenseDetailsSort(query);

    const result = await db.execute(sql`
      SELECT
        e.id AS "expenseId",
        CASE
          WHEN COALESCE(e.is_billable, false) THEN 'Billable'
          ELSE 'Non-Billable'
        END AS "status",
        COALESCE(NULLIF(e.status, ''), '-') AS "expenseStatus",
        e.expense_date AS "date",
        'Expense' AS "transactionType",
        COALESCE(NULLIF(e.expense_number, ''), NULLIF(e.invoice_number, ''), e.id::text) AS "transactionNumber",
        CASE
          WHEN mileage.id IS NULL THEN '0 Kilometer(s)'
          ELSE CONCAT(
            TRIM(TRAILING '.' FROM TRIM(TRAILING '0' FROM COALESCE(mileage.distance, 0)::text)),
            ' ',
            CASE
              WHEN UPPER(COALESCE(mileage.distance_unit, 'KM')) = 'KM' THEN 'Kilometer(s)'
              ELSE COALESCE(mileage.distance_unit, 'Kilometer(s)')
            END
          )
        END AS "distance",
        COALESCE(NULLIF(v.display_name, ''), NULLIF(v.company_name, ''), '-') AS "vendorName",
        CASE
          WHEN e.expense_mode = 'RECORD_MILEAGE' THEN 'Fuel/Mileage Expenses'
          ELSE COALESCE(
            NULLIF(expense_account.user_account_name, ''),
            NULLIF(expense_account.system_account_name, ''),
            NULLIF(expense_account.account_code, ''),
            '-'
          )
        END AS "category",
        COALESCE(NULLIF(c.display_name, ''), NULLIF(c.company_name, ''), '-') AS "customerName",
        COALESCE(e.amount, 0)::numeric AS "amountValue",
        COALESCE(e.total_amount, e.amount, 0)::numeric AS "amountWithTaxValue",
        COALESCE(e.tax_amount, 0)::numeric AS "taxAmount",
        COALESCE(NULLIF(e.currency_code, ''), 'INR') AS "currencyCode",
        COALESCE(NULLIF(e.expense_type, ''), '-') AS "expenseType",
        COALESCE(e.is_billable, false) AS "isBillable",
        COALESCE(NULLIF(e.notes, ''), '') AS "notes",
        e.vendor_id AS "vendorId",
        e.customer_id AS "customerId",
        e.expense_account_id AS "expenseAccountId",
        COALESCE(
          NULLIF(paid_account.user_account_name, ''),
          NULLIF(paid_account.system_account_name, ''),
          NULLIF(paid_account.account_code, ''),
          '-'
        ) AS "paidThrough",
        e.paid_through_account_id AS "paidThroughAccountId",
        e.tax_id AS "taxId",
        COALESCE(NULLIF(t.tax_name, ''), '-') AS "taxName",
        e.created_by AS "createdById",
        COALESCE(NULLIF(created_user.full_name, ''), '-') AS "createdByName",
        COUNT(*) OVER()::int AS "__total"
      FROM expenses e
      LEFT JOIN vendors v ON v.id = e.vendor_id
      LEFT JOIN customers c ON c.id = e.customer_id
      LEFT JOIN accounts expense_account ON expense_account.id = e.expense_account_id
      LEFT JOIN accounts paid_account ON paid_account.id = e.paid_through_account_id
      LEFT JOIN tax_rates t ON t.id = e.tax_id
      LEFT JOIN users created_user ON created_user.id = e.created_by
      LEFT JOIN LATERAL (
        SELECT em.id, em.distance, em.distance_unit
        FROM expense_mileage em
        WHERE em.expense_id = e.id
        ORDER BY em.created_at DESC NULLS LAST
        LIMIT 1
      ) mileage ON true
      WHERE ${whereClause}
      ORDER BY ${orderBy}, "transactionNumber" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      amountValue: this.parseNumber(row.amountValue),
      amountWithTaxValue: this.parseNumber(row.amountWithTaxValue),
      taxAmount: this.parseNumber(row.taxAmount),
    }));

    return this.pageFromRows(rows, pagination);
  }
}
