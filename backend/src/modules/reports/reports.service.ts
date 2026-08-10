import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { db } from "../../db/db";
import { sql } from "drizzle-orm";
import { TenantContext } from "../../common/middleware/tenant.middleware";

type AuditLogsParams = {
  page?: number;
  pageSize?: number;
  search?: string;
  tables?: string[];
  actions?: string[];
  requestId?: string;
  source?: string;
  fromDate?: string;
  toDate?: string;
  scope?: string;
};

@Injectable()
export class ReportsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private async resolveDashboardEntityScope(tenant: TenantContext): Promise<{
    entityIds: string[];
    scopeLabel: string;
    entityBreakdown: Array<{
      entityId: string;
      entityName: string;
      entityType: "ORG" | "BRANCH";
      place: string;
    }>;
  }> {
    const supabase = this.supabaseService.getClient();
    const currentEntityId = tenant.entityId?.toString().trim() || "";

    if (!currentEntityId) {
      return {
        entityIds: [],
        scopeLabel: "No entity selected",
        entityBreakdown: [],
      };
    }

    const { data: selectedEntity } = await supabase
      .from("organisation_branch_master")
      .select("id, type, ref_id, parent_id")
      .eq("id", currentEntityId)
      .maybeSingle();
    const entityRows: Array<{
      id: string;
      type: "ORG" | "BRANCH";
      ref_id: string;
      parent_id: string | null;
    }> = selectedEntity ? [selectedEntity as any] : [];

    const orgRefIds = entityRows
      .filter((row) => row.type === "ORG")
      .map((row) => row.ref_id)
      .filter(Boolean);
    const branchRefIds = entityRows
      .filter((row) => row.type === "BRANCH")
      .map((row) => row.ref_id)
      .filter(Boolean);

    const orgMap = new Map<string, { name: string; place: string }>();
    const branchMap = new Map<string, { name: string; place: string }>();

    if (orgRefIds.length > 0) {
      const { data } = await supabase
        .from("organization")
        .select("id, name, place, city")
        .in("id", orgRefIds);
      for (const row of data ?? []) {
        orgMap.set(String((row as any).id), {
          name: String((row as any).name ?? "Organization"),
          place: String((row as any).place ?? (row as any).city ?? "").trim(),
        });
      }
    }

    if (branchRefIds.length > 0) {
      const { data } = await supabase
        .from("branches")
        .select("id, name, place, city")
        .in("id", branchRefIds);
      for (const row of data ?? []) {
        branchMap.set(String((row as any).id), {
          name: String((row as any).name ?? "Branch"),
          place: String((row as any).place ?? (row as any).city ?? "").trim(),
        });
      }
    }

    const entityBreakdown = entityRows.map((row) => {
      if (row.type === "ORG") {
        const meta = orgMap.get(row.ref_id) ?? {
          name: "Organization",
          place: "",
        };
        return {
          entityId: row.id,
          entityName: meta.name,
          entityType: "ORG" as const,
          place: meta.place,
        };
      }
      const meta = branchMap.get(row.ref_id) ?? { name: "Branch", place: "" };
      return {
        entityId: row.id,
        entityName: meta.name,
        entityType: "BRANCH" as const,
        place: meta.place,
      };
    });

    const scopeLabel =
      entityRows.length == 0
        ? "No scope"
        : entityRows[0].type === "BRANCH"
          ? "Branch Scope"
          : "Organization Scope";

    return {
      entityIds: entityRows.map((row) => row.id),
      scopeLabel,
      entityBreakdown,
    };
  }

  async getCurrentBranchHeader(tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();
    const userId = tenant.userId?.toString().trim() || "";
    const orgId = tenant.orgId?.toString().trim() || "";
    const activeEntityId = tenant.entityId?.toString().trim() || "";

    const accessRows: Array<Record<string, any>> = [];

    if (userId) {
      const { data } = await supabase
        .from("branch_user_access")
        .select("entity_id, is_default_branch")
        .eq("user_id", userId);
      if (Array.isArray(data)) {
        accessRows.push(
          ...data.map((row) => ({ ...row, source: "branch_user_access" })),
        );
      }

      if (accessRows.length === 0) {
        let fallbackQuery = supabase
          .from("user_branch_access")
          .select("entity_id, is_default_business, is_default_warehouse")
          .eq("user_id", userId);
        if (orgId) {
          fallbackQuery = fallbackQuery.eq("org_id", orgId);
        }
        const { data: fallbackData } = await fallbackQuery;
        if (Array.isArray(fallbackData)) {
          accessRows.push(
            ...fallbackData.map((row) => ({
              ...row,
              source: "user_branch_access",
            })),
          );
        }
      }
    }

    const selectedAccess =
      accessRows.find(
        (row) => row?.entity_id?.toString().trim() === activeEntityId,
      ) ??
      accessRows.find(
        (row) =>
          row?.is_default_branch === true ||
          row?.is_default_business === true ||
          row?.is_default_warehouse === true,
      ) ??
      accessRows[0];

    const entityId =
      selectedAccess?.entity_id?.toString().trim() || activeEntityId || "";

    if (!entityId) {
      return {
        branchName: "",
        entityId: null,
        branchId: tenant.branchId ?? null,
      };
    }

    const { data: entityRow } = await supabase
      .from("organisation_branch_master")
      .select("id, name, type, ref_id")
      .eq("id", entityId)
      .maybeSingle();

    const entity = (entityRow ?? {}) as Record<string, any>;
    const branchRefId =
      entity.ref_id?.toString().trim() || tenant.branchId || "";
    let branchName = "";

    if (entity.type === "BRANCH" && branchRefId) {
      const { data: branchRow } = await supabase
        .from("branches")
        .select("id, name")
        .eq("id", branchRefId)
        .maybeSingle();
      branchName = String((branchRow as any)?.name ?? "").trim();
    }

    if (!branchName) {
      branchName = String(entity.name ?? "").trim();
    }

    return {
      branchName,
      entityId,
      branchId: branchRefId || tenant.branchId || null,
    };
  }

  private getErrorMessage(error: unknown): string {
    if (!error || typeof error !== "object") {
      return String(error ?? "Unknown error");
    }
    const root = error as any;
    const cause =
      root.cause && typeof root.cause === "object" ? root.cause : null;
    return (
      String(cause?.message ?? "").trim() ||
      String(root.message ?? "").trim() ||
      "Unknown error"
    );
  }

  private isMissingRelationError(error: unknown, relationName: string) {
    if (!error || typeof error !== "object") {
      return false;
    }

    const root = error as any;
    const cause =
      root.cause && typeof root.cause === "object" ? root.cause : null;

    const codes = [
      "code" in root ? String(root.code ?? "") : "",
      cause && "code" in cause ? String(cause.code ?? "") : "",
    ].filter((value) => value.length > 0);

    const messages = [
      "message" in root ? String(root.message ?? "") : "",
      cause && "message" in cause ? String(cause.message ?? "") : "",
    ].filter((value) => value.length > 0);

    return (
      codes.includes("42P01") &&
      messages.some((message) => message.includes(relationName))
    );
  }

  private isSchemaShapeError(error: unknown) {
    if (!error || typeof error !== "object") return false;

    const root = error as any;
    const cause =
      root.cause && typeof root.cause === "object" ? root.cause : null;

    const codes = [
      "code" in root ? String(root.code ?? "") : "",
      cause && "code" in cause ? String(cause.code ?? "") : "",
    ].filter(Boolean);

    const messages = [
      "message" in root ? String(root.message ?? "") : "",
      cause && "message" in cause ? String(cause.message ?? "") : "",
    ].filter(Boolean);

    // 42P01: relation does not exist, 42703: column does not exist
    const missingShape = codes.includes("42P01") || codes.includes("42703");
    if (!missingShape) return false;

    return messages.some((m) =>
      ["branch_inventory", "entity_id", "storage_conditions"].some((token) =>
        m.includes(token),
      ),
    );
  }

  async getDashboardSummary(tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();
    const scope = await this.resolveDashboardEntityScope(tenant);
    if (scope.entityIds.length === 0) {
      return {
        receivables: 0,
        payables: 0,
        cashOnHand: 0,
        purchaseReceivablesAmount: 0,
        billsTotalAmount: 0,
        picklistsCount: 0,
        packagesCount: 0,
        salesInvoicesCount: 0,
        salesInvoicesAmount: 0,
        salesOrdersAmount: 0,
        purchaseOrdersAmount: 0,
        salesTrend: [],
        topCustomers: [],
        topItems: [],
        scopeLabel: "No scope",
        entityBreakdown: [],
      };
    }

    // 1. Get Accounts Summary (Receivables/Payables)
    const accountsQuery = supabase
      .from("accounts")
      .select("id, account_type, user_account_name")
      .in("entity_id", scope.entityIds);
    const { data: accounts, error: accError } = await accountsQuery;

    if (accError) throw accError;

    // 2. Get Transaction Balances
    // Query the accounting ledger through Drizzle/Postgres instead of PostgREST,
    // because some tenants can have a stale PostgREST schema cache for this table.
    const entityScopeSql = sql.join(scope.entityIds.map((id) => sql`${id}`), sql`, `);
    let txs: any[] = [];
    try {
      txs = (await db.execute(sql`
        SELECT account_id, debit, credit
        FROM ${this.accountTransactionsReportSourceSql()}
        WHERE entity_id IN (${entityScopeSql})
      `)) as any[];
    } catch (error) {
      console.warn("Error fetching transaction balances:", error);
    }

    const balances = new Map<string, number>();
    txs?.forEach((tx) => {
      const d = Number(tx.debit || 0);
      const c = Number(tx.credit || 0);
      balances.set(tx.account_id, (balances.get(tx.account_id) || 0) + (d - c));
    });

    let totalReceivables = 0;
    let totalPayables = 0;
    let cashOnHand = 0;

    accounts?.forEach((acc) => {
      const bal = balances.get(acc.id) || 0;
      const type = acc.account_type?.toLowerCase();

      if (type === "accounts receivable" || type === "accounts_receivable") {
        totalReceivables += bal;
      } else if (type === "accounts payable" || type === "accounts_payable") {
        totalPayables += Math.abs(bal);
      } else if (type === "bank" || type === "cash") {
        cashOnHand += bal;
      }
    });

    // 3. Sales Trend (Last 30 days)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    let salesTrend: any[] = [];
    try {
      salesTrend = (await db.execute(sql`
        SELECT transaction_date, credit
        FROM ${this.accountTransactionsReportSourceSql()}
        WHERE entity_id IN (${entityScopeSql})
          AND transaction_date >= ${thirtyDaysAgo.toISOString()}
          AND transaction_type IN ('invoice', 'sales_receipt')
      `)) as any[];
    } catch (error) {
      console.warn("Error fetching sales trend:", error);
    }

    // Group by day
    const trendMap = new Map<string, number>();
    salesTrend?.forEach((s) => {
      const rawDate = s.transaction_date instanceof Date
        ? s.transaction_date.toISOString()
        : String(s.transaction_date ?? "");
      const date = rawDate.split("T")[0];
      trendMap.set(date, (trendMap.get(date) || 0) + Number(s.credit || 0));
    });

    const trendData = Array.from(trendMap.entries())
      .map(([date, amount]) => ({ date, amount }))
      .sort((a, b) => a.date.localeCompare(b.date));

    // 4. Top Customers
    let topCustomersData: any[] = [];
    try {
      topCustomersData = (await db.execute(sql`
        SELECT contact_id, contact_type, credit
        FROM ${this.accountTransactionsReportSourceSql()}
        WHERE entity_id IN (${entityScopeSql})
          AND contact_type = 'customer'
          AND transaction_type IN ('invoice', 'sales_receipt')
      `)) as any[];
    } catch (error) {
      console.warn("Error fetching top customers:", error);
    }

    const customerMap = new Map<string, number>();
    topCustomersData?.forEach((c) => {
      if (c.contact_id) {
        customerMap.set(
          c.contact_id,
          (customerMap.get(c.contact_id) || 0) + Number(c.credit || 0),
        );
      }
    });

    const topCustomerIds = Array.from(customerMap.keys())
      .sort((a, b) => customerMap.get(b)! - customerMap.get(a)!)
      .slice(0, 5);

    const topCustomers = await Promise.all(
      topCustomerIds.map(async (id) => {
        const { data } = await supabase
          .from("customers")
          .select("display_name")
          .eq("id", id)
          .in("entity_id", scope.entityIds)
          .single();
        return {
          name: data?.display_name || "Unknown Customer",
          amount: customerMap.get(id) || 0,
        };
      }),
    );

    let topItems: Array<{
      id: string;
      name: string;
      stockOnHand: number;
    }> = [];
    try {
      const entityIdList = sql.join(
        scope.entityIds.map((entityId) => sql`${entityId}::uuid`),
        sql`, `,
      );
      const topItemsQuery = sql`
        SELECT
          p.id as "id",
          p.product_name as "name",
          COALESCE(SUM(oi.qty - COALESCE(oi.reserved_qty, 0)), 0) as "stockOnHand"
        FROM batch_stock_layers oi
        JOIN products p ON oi.product_id = p.id
        WHERE oi.entity_id IN (${entityIdList})
        GROUP BY p.id, p.product_name
        HAVING COALESCE(SUM(oi.qty - COALESCE(oi.reserved_qty, 0)), 0) > 0
        ORDER BY "stockOnHand" DESC, p.product_name ASC
        LIMIT 5
      `;
      const rows = (await db.execute(topItemsQuery)) as Array<
        Record<string, unknown>
      >;
      topItems = rows.map((row) => ({
        id: String(row.id ?? ""),
        name: String(row.name ?? "Unknown Item"),
        stockOnHand: Number(row.stockOnHand ?? 0),
      }));
    } catch (drizzleError) {
      // Dashboard must not fail hard if inventory aggregation query breaks.
      // Fall back to Supabase aggregation when direct Postgres connectivity
      // is unavailable (e.g., ETIMEDOUT on pooled DB connection).
      console.warn(
        "Dashboard topItems Drizzle query failed; using Supabase fallback:",
        this.getErrorMessage(drizzleError),
      );
      try {
        const { data: inventoryRows, error: inventoryError } = await supabase
          .from("batch_stock_layers")
          .select("product_id, qty, reserved_qty")
          .in("entity_id", scope.entityIds);

        if (inventoryError) {
          throw inventoryError;
        }

        const stockByProductId = new Map<string, number>();
        for (const row of inventoryRows ?? []) {
          const productId = String(row.product_id ?? "").trim();
          if (!productId) continue;
          const currentStock =
            Number(row.qty ?? 0) - Number(row.reserved_qty ?? 0);
          stockByProductId.set(
            productId,
            (stockByProductId.get(productId) ?? 0) + currentStock,
          );
        }

        const topProductIds = Array.from(stockByProductId.entries())
          .filter(([, stock]) => stock > 0)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 5)
          .map(([productId]) => productId);

        if (topProductIds.length === 0) {
          topItems = [];
        } else {
          const { data: products, error: productError } = await supabase
            .from("products")
            .select("id, product_name")
            .in("id", topProductIds);

          if (productError) {
            throw productError;
          }

          const productNameById = new Map<string, string>();
          for (const product of products ?? []) {
            productNameById.set(
              String(product.id),
              String(product.product_name ?? "Unknown Item"),
            );
          }

          topItems = topProductIds.map((productId) => ({
            id: productId,
            name: productNameById.get(productId) ?? "Unknown Item",
            stockOnHand: Number(stockByProductId.get(productId) ?? 0),
          }));
        }
      } catch (fallbackError) {
        console.warn(
          "Dashboard topItems Supabase fallback failed:",
          this.getErrorMessage(fallbackError),
        );
        topItems = [];
      }
    }

    const { data: purchaseReceiveBatchRows } = await supabase
      .from("purchase_receive_item_batches")
      .select("quantity, foc_qty, ptr, entity_id")
      .in("entity_id", scope.entityIds);

    const purchaseReceivablesAmount = (purchaseReceiveBatchRows ?? []).reduce(
      (sum, row) => {
        const qty = Number((row as any).quantity ?? 0);
        const foc = Number((row as any).foc_qty ?? 0);
        const rate = Number((row as any).ptr ?? 0);
        return sum + (qty + foc) * rate;
      },
      0,
    );

    const { data: billsRows } = await supabase
      .from("bills")
      .select("grand_total, is_delete, entity_id")
      .in("entity_id", scope.entityIds)
      .eq("is_delete", false);
    const billsTotalAmount = (billsRows ?? []).reduce(
      (sum, row) => sum + Number((row as any).grand_total ?? 0),
      0,
    );

    const { count: picklistsCount } = await supabase
      .from("picklist_master")
      .select("id", { count: "exact", head: true })
      .in("entity_id", scope.entityIds)
      .eq("is_delete", false);

    const { count: packagesCount } = await supabase
      .from("inventory_packages")
      .select("id", { count: "exact", head: true })
      .in("entity_id", scope.entityIds)
      .eq("is_delete", false);

    const { data: salesInvoiceRows } = await supabase
      .from("sales_orders")
      .select("total, document_type, is_delete, entity_id")
      .in("entity_id", scope.entityIds)
      .eq("is_delete", false)
      .in("document_type", ["invoice", "sales_invoice"]);
    const salesInvoicesCount = (salesInvoiceRows ?? []).length;
    const salesInvoicesAmount = (salesInvoiceRows ?? []).reduce(
      (sum, row) => sum + Number((row as any).total ?? 0),
      0,
    );

    const { data: salesOrderRows } = await supabase
      .from("sales_orders")
      .select("total, document_type, is_delete, entity_id")
      .in("entity_id", scope.entityIds)
      .eq("is_delete", false)
      .in("document_type", ["order", "sales_order"]);
    const salesOrdersAmount = (salesOrderRows ?? []).reduce(
      (sum, row) => sum + Number((row as any).total ?? 0),
      0,
    );

    const { data: purchaseOrderRows } = await supabase
      .from("purchase_orders")
      .select("total, is_delete, entity_id")
      .in("entity_id", scope.entityIds)
      .eq("is_delete", false);
    const purchaseOrdersAmount = (purchaseOrderRows ?? []).reduce(
      (sum, row) => sum + Number((row as any).total ?? 0),
      0,
    );

    return {
      receivables: totalReceivables,
      payables: totalPayables,
      cashOnHand: cashOnHand,
      purchaseReceivablesAmount,
      billsTotalAmount,
      picklistsCount: picklistsCount ?? 0,
      packagesCount: packagesCount ?? 0,
      salesInvoicesCount,
      salesInvoicesAmount,
      salesOrdersAmount,
      purchaseOrdersAmount,
      salesTrend: trendData,
      topCustomers,
      topItems,
      scopeLabel: scope.scopeLabel,
      entityBreakdown: scope.entityBreakdown,
    };
  }

  // --- Reports Methods (Relocated from Accountant) ---

  async getProfitAndLossReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
  ) {
    const conditions: any[] = [
      sql`t.transaction_date >= ${new Date(startDate).toISOString()}`,
      sql`t.transaction_date <= ${new Date(endDate).toISOString()}`,
      sql`COALESCE(a.user_account_name, a.system_account_name) != 'Opening Balance Offset'`,
    ];
    conditions.push(sql`t.entity_id = ${tenant.entityId}`);

    const whereClause = sql.join(conditions, sql` AND `);

    const query = sql`
      SELECT 
        a.account_type as "accountType",
        COALESCE(a.user_account_name, a.system_account_name) as "accountName",
        a.id as "accountId",
        SUM(t.debit) as "totalDebit",
        SUM(t.credit) as "totalCredit"
      FROM ${this.accountTransactionsReportSourceSql()} t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
      GROUP BY a.account_type, COALESCE(a.user_account_name, a.system_account_name), a.id
    `;

    let rows: any[] = [];
    try {
      const result = await db.execute(query);
      rows = result as any[];
    } catch (error) {
      // Report screens should degrade to empty content instead of hard 500s
      // when tenant data/schema drifts or aggregate queries fail.
      console.warn("Profit and loss query failed:", error);
      rows = [];
    }

    const report = {
      operatingIncome: [],
      costOfGoodsSold: [],
      operatingExpenses: [],
    };
    let totalIncome = 0,
      totalCogs = 0,
      totalExpenses = 0;

    for (const row of rows) {
      const type = row.accountType?.toLowerCase() || "";
      const isIncome = type.includes("income") || type.includes("sales");
      const isCogs = type.includes("cogs") || type.includes("cost");
      const isExpense = type.includes("expense");

      const totalDebit = Number(row.totalDebit);
      const totalCredit = Number(row.totalCredit);
      const netAmount = isIncome
        ? totalCredit - totalDebit
        : totalDebit - totalCredit;

      const item = {
        accountId: row.accountId,
        accountName: row.accountName,
        accountType: row.accountType,
        netAmount,
      };

      if (isIncome) {
        report.operatingIncome.push(item);
        totalIncome += netAmount;
      } else if (isCogs) {
        report.costOfGoodsSold.push(item);
        totalCogs += netAmount;
      } else if (isExpense) {
        report.operatingExpenses.push(item);
        totalExpenses += netAmount;
      }
    }

    return {
      period: { startDate, endDate },
      report,
      summary: {
        totalIncome,
        totalCogs,
        grossProfit: totalIncome - totalCogs,
        totalExpenses,
        netProfit: totalIncome - totalCogs - totalExpenses,
      },
    };
  }

  async getGeneralLedgerReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const allowedPageSizes = [10, 25, 50, 100, 200];
    const normalizedPageSize = allowedPageSizes.includes(Number(pageSize))
      ? Number(pageSize)
      : 25;
    const requestedPage = Number.isFinite(Number(page))
      ? Math.max(1, Number(page))
      : 1;
    const existingSourceTables = await this.getExistingPublicReportTables([
      "expenses",
      "bills",
      "purchase_orders",
      "purchase_receives",
      "invoices",
      "vendor_credits",
      "payments_received",
      "recurring_invoices",
      "journal_entries",
      "manual_journals",
      "inventory_adjustments",
    ]);

    const accountActiveCondition = sql`COALESCE(NULLIF(to_jsonb(a)->>'is_deleted', '')::boolean, false) = false`;
    const sourceValidationCondition =
      this.buildAccountTransactionSourceValidationCondition(
        existingSourceTables,
      );
    const transactionJoinConditions = [
      sql`t.account_id = a.id`,
      sql`t.transaction_date >= ${start.toISOString()}`,
      sql`t.transaction_date < ${endExclusive.toISOString()}`,
      sql`t.entity_id = ${tenant.entityId}`,
      sourceValidationCondition,
    ];
    const accountConditions = [
      accountActiveCondition,
      sql`a.entity_id = ${tenant.entityId}`,
    ];
    const accountWhereClause = sql.join(accountConditions, sql` AND `);

    const countResult = await db.execute(sql`
      SELECT COUNT(*)::int AS "total"
      FROM accounts a
      WHERE ${accountWhereClause}
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      SELECT
        SUM(COALESCE(t.debit, 0)) AS "totalDebit",
        SUM(COALESCE(t.credit, 0)) AS "totalCredit"
      FROM accounts a
      LEFT JOIN ${this.accountTransactionsReportSourceSql()} t
        ON ${sql.join(transactionJoinConditions, sql` AND `)}
      WHERE ${accountWhereClause}
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};
    const totalDebit = Number(totalsRow.totalDebit || 0);
    const totalCredit = Number(totalsRow.totalCredit || 0);

    const query = sql`
      SELECT
        a.id AS "accountId",
        COALESCE(
          NULLIF(a.user_account_name, ''),
          NULLIF(a.system_account_name, ''),
          NULLIF(a.account_code, ''),
          a.id::text
        ) AS "accountName",
        a.account_code AS "accountCode",
        COALESCE(NULLIF(a.account_group::text, ''), 'Uncategorized') AS "accountGroup",
        COALESCE(NULLIF(a.account_type::text, ''), 'Uncategorized') AS "accountType",
        a.parent_id AS "parentId",
        EXISTS (
          SELECT 1
          FROM accounts child
          WHERE child.parent_id = a.id
            AND child.entity_id = ${tenant.entityId}
            AND COALESCE(NULLIF(to_jsonb(child)->>'is_deleted', '')::boolean, false) = false
        ) AS "hasChildren",
        SUM(COALESCE(t.debit, 0)) AS "totalDebit",
        SUM(COALESCE(t.credit, 0)) AS "totalCredit"
      FROM accounts a
      LEFT JOIN ${this.accountTransactionsReportSourceSql()} t
        ON ${sql.join(transactionJoinConditions, sql` AND `)}
      WHERE ${accountWhereClause}
      GROUP BY
        a.id,
        COALESCE(NULLIF(a.user_account_name, ''), NULLIF(a.system_account_name, ''), NULLIF(a.account_code, ''), a.id::text),
        a.account_code,
        COALESCE(NULLIF(a.account_group::text, ''), 'Uncategorized'),
        COALESCE(NULLIF(a.account_type::text, ''), 'Uncategorized'),
        a.parent_id
      ORDER BY
        COALESCE(NULLIF(a.user_account_name, ''), NULLIF(a.system_account_name, ''), NULLIF(a.account_code, ''), a.id::text) ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `;

    const rows = this.rowsFromQueryResult(await db.execute(query));
    const accounts = rows.map((r: any) => {
      const debit = Number(r.totalDebit || 0);
      const credit = Number(r.totalCredit || 0);
      return {
        accountId: r.accountId,
        accountName: r.accountName,
        accountCode: r.accountCode,
        accountGroup: r.accountGroup,
        accountType: r.accountType,
        parentId: r.parentId,
        hasChildren: Boolean(r.hasChildren),
        debit,
        credit,
        balance: debit - credit,
        netBalance: debit - credit,
      };
    });

    return {
      period: { startDate, endDate },
      basis: basis || "Accrual",
      accounts,
      Accountant: accounts,
      totalDebit,
      totalCredit,
      totalBalance: totalDebit - totalCredit,
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }

  async getDetailedGeneralLedgerReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const allowedPageSizes = [10, 25, 50, 100, 200];
    const normalizedPageSize = allowedPageSizes.includes(Number(pageSize))
      ? Number(pageSize)
      : 25;
    const requestedPage = Number.isFinite(Number(page))
      ? Math.max(1, Number(page))
      : 1;
    const existingSourceTables = await this.getExistingPublicReportTables([
      "expenses",
      "bills",
      "purchase_orders",
      "purchase_receives",
      "invoices",
      "vendor_credits",
      "payments_received",
      "recurring_invoices",
      "journal_entries",
      "manual_journals",
      "inventory_adjustments",
    ]);

    const accountNameExpression = sql`COALESCE(
      NULLIF(a.user_account_name, ''),
      NULLIF(a.system_account_name, ''),
      NULLIF(a.account_code, ''),
      a.id::text
    )`;
    const accountActiveCondition = sql`COALESCE(NULLIF(to_jsonb(a)->>'is_deleted', '')::boolean, false) = false`;
    const accountWhereClause = sql.join(
      [accountActiveCondition, sql`a.entity_id = ${tenant.entityId}`],
      sql` AND `,
    );
    const sourceValidationCondition =
      this.buildAccountTransactionSourceValidationCondition(
        existingSourceTables,
      );

    const countResult = await db.execute(sql`
      SELECT COUNT(*)::int AS "total"
      FROM accounts a
      WHERE ${accountWhereClause}
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const accountResult = await db.execute(sql`
      SELECT
        a.id AS "accountId",
        ${accountNameExpression} AS "accountName",
        COALESCE(NULLIF(a.account_group::text, ''), 'Uncategorized') AS "accountGroup",
        COALESCE(NULLIF(a.account_type::text, ''), 'Uncategorized') AS "accountType"
      FROM accounts a
      WHERE ${accountWhereClause}
      ORDER BY ${accountNameExpression} ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);
    const accountRows = this.rowsFromQueryResult(accountResult);
    const accountIds = accountRows
      .map((row) => row.accountId?.toString())
      .filter(Boolean);

    if (accountIds.length === 0) {
      return {
        basis: basis || "Accrual",
        period: { startDate, endDate },
        sections: [],
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
        pagination: {
          totalRecords: total,
          total,
          page: currentPage,
          pageSize: normalizedPageSize,
          totalPages,
        },
      };
    }

    const accountIdList = sql.join(
      accountIds.map((accountId) => sql`${accountId}`),
      sql`, `,
    );
    const validTransactionConditions = [
      sql`t.entity_id = ${tenant.entityId}`,
      sql`t.account_id IN (${accountIdList})`,
      sourceValidationCondition,
    ];
    const validTransactionWhereClause = sql.join(
      validTransactionConditions,
      sql` AND `,
    );

    const openingResult = await db.execute(sql`
      SELECT
        t.account_id AS "accountId",
        SUM(COALESCE(t.debit, 0) - COALESCE(t.credit, 0)) AS "openingBalance"
      FROM ${this.accountTransactionsReportSourceSql()} t
      WHERE ${validTransactionWhereClause}
        AND t.transaction_date < ${start.toISOString()}
      GROUP BY t.account_id
    `);

    const periodBalanceResult = await db.execute(sql`
      SELECT
        t.account_id AS "accountId",
        SUM(COALESCE(t.debit, 0) - COALESCE(t.credit, 0)) AS "periodBalance"
      FROM ${this.accountTransactionsReportSourceSql()} t
      WHERE ${validTransactionWhereClause}
        AND t.transaction_date >= ${start.toISOString()}
        AND t.transaction_date < ${endExclusive.toISOString()}
      GROUP BY t.account_id
    `);

    const transactionResult = await db.execute(sql`
      SELECT
        t.account_id AS "accountId",
        t.transaction_date AS "date",
        ${accountNameExpression} AS "accountName",
        COALESCE(NULLIF(t.description, ''), '--') AS "details",
        COALESCE(NULLIF(t.source_type, ''), '--') AS "type",
        COALESCE(NULLIF(t.reference_number, ''), t.source_id::text, '') AS "transactionNumber",
        COALESCE(NULLIF(t.reference_number, ''), '') AS "reference",
        t.debit AS "debit",
        t.credit AS "credit"
      FROM ${this.accountTransactionsReportSourceSql()} t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${validTransactionWhereClause}
        AND ${accountActiveCondition}
        AND t.transaction_date >= ${start.toISOString()}
        AND t.transaction_date < ${endExclusive.toISOString()}
      ORDER BY ${accountNameExpression} ASC, t.transaction_date ASC, t.created_at ASC, t.id ASC
    `);

    const openingBalances = new Map<string, number>();
    for (const row of this.rowsFromQueryResult(openingResult)) {
      openingBalances.set(
        String(row.accountId),
        Number(row.openingBalance || 0),
      );
    }

    const periodBalances = new Map<string, number>();
    for (const row of this.rowsFromQueryResult(periodBalanceResult)) {
      periodBalances.set(String(row.accountId), Number(row.periodBalance || 0));
    }

    const transactionsByAccount = new Map<string, Array<Record<string, any>>>();
    for (const row of this.rowsFromQueryResult(transactionResult)) {
      const accountId = String(row.accountId);
      const debit = Number(row.debit || 0);
      const credit = Number(row.credit || 0);
      const transactions = transactionsByAccount.get(accountId) ?? [];
      transactions.push({
        ...row,
        debit,
        credit,
        amount: debit > 0 ? debit : credit,
        amountType: debit > 0 ? "Dr" : credit > 0 ? "Cr" : "",
      });
      transactionsByAccount.set(accountId, transactions);
    }

    const sections = accountRows.map((row) => {
      const accountId = String(row.accountId);
      const openingBalance = openingBalances.get(accountId) ?? 0;
      return {
        accountId,
        accountName: String(row.accountName ?? "Unknown"),
        accountGroup: String(row.accountGroup ?? "Uncategorized"),
        accountType: String(row.accountType ?? "Uncategorized"),
        openingBalance,
        closingBalance: openingBalance + (periodBalances.get(accountId) ?? 0),
        transactions: transactionsByAccount.get(accountId) ?? [],
      };
    });

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      sections,
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }

  private rowsFromQueryResult(result: unknown): Record<string, any>[] {
    if (Array.isArray(result)) return result as Record<string, any>[];
    const rows = (result as { rows?: Record<string, any>[] } | undefined)?.rows;
    return Array.isArray(rows) ? rows : [];
  }

  private accountTransactionsReportSourceSql() {
    return sql`(
      SELECT
        bt.id AS id,
        NULL::uuid AS account_id,
        bt.entity_id AS entity_id,
        bt.trans_date AS transaction_date,
        LOWER(REPLACE(COALESCE(bt.trans_type, ''), ' ', '_')) AS transaction_type,
        COALESCE(NULLIF(bt.ref_no, ''), '') AS reference_number,
        COALESCE(NULLIF(bt.ref_no, ''), '') AS description,
        (COALESCE(bt.qty_in, 0) * COALESCE(bt.rate, 0))::numeric AS debit,
        (COALESCE(bt.qty_out, 0) * COALESCE(bt.rate, 0))::numeric AS credit,
        bt.ref_id AS source_id,
        LOWER(REPLACE(COALESCE(bt.trans_type, ''), ' ', '_')) AS source_type,
        NULL::uuid AS contact_id,
        NULL::text AS contact_type,
        bt.created_at AS created_at,
        NULL::uuid AS journal_entry_id,
        NULL::integer AS line_number
      FROM batch_transactions bt
    )`;
  }

  private async getExistingPublicReportTables(
    tableNames: string[],
  ): Promise<Set<string>> {
    const uniqueTableNames = Array.from(new Set(tableNames));
    if (uniqueTableNames.length === 0) return new Set<string>();

    const result = await db.execute(sql`
      SELECT table_name AS "tableName"
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name IN (${sql.join(
          uniqueTableNames.map((tableName) => sql`${tableName}`),
          sql`, `,
        )})
    `);

    return new Set(
      this.rowsFromQueryResult(result)
        .map((row) => row.tableName?.toString())
        .filter(Boolean),
    );
  }

  private buildAccountTransactionSourceValidationCondition(
    existingTables: Set<string>,
  ) {
    const sourceMappings = [
      { tableName: "expenses", types: ["expense", "expenses"] },
      { tableName: "bills", types: ["bill", "bills"] },
      {
        tableName: "purchase_orders",
        types: ["purchase_order", "purchase_orders"],
      },
      {
        tableName: "purchase_receives",
        types: ["purchase_receive", "purchase_receives"],
      },
      { tableName: "invoices", types: ["invoice", "invoices"] },
      {
        tableName: "vendor_credits",
        types: ["vendor_credit", "vendor_credits"],
      },
      {
        tableName: "payments_received",
        types: [
          "customer_payment",
          "payment_received",
          "payments_received",
          "payment",
        ],
      },
      {
        tableName: "recurring_invoices",
        types: ["recurring_invoice", "recurring_invoices"],
      },
      {
        tableName: "journal_entries",
        types: ["journal_entry", "journal_entries"],
        idExpression: sql`COALESCE(t.journal_entry_id, t.source_id)`,
      },
      {
        tableName: "manual_journals",
        types: ["journal", "manual_journal", "manual_journals"],
      },
      {
        tableName: "inventory_adjustments",
        types: ["inventory_adjustment", "inventory_adjustments"],
      },
    ];
    const normalizedSourceType = sql`LOWER(REPLACE(COALESCE(t.source_type, ''), ' ', '_'))`;
    const branches = sourceMappings.map((mapping) => {
      const typeList = sql.join(
        mapping.types.map((type) => sql`${type}`),
        sql`, `,
      );
      const sourceId = mapping.idExpression ?? sql`t.source_id`;

      if (!existingTables.has(mapping.tableName)) {
        return sql`WHEN ${normalizedSourceType} IN (${typeList}) THEN false`;
      }

      return sql`WHEN ${normalizedSourceType} IN (${typeList}) THEN EXISTS (
        SELECT 1
        FROM ${sql.raw(mapping.tableName)} source_record
        WHERE source_record.id = ${sourceId}
          AND COALESCE(
            NULLIF(to_jsonb(source_record)->>'is_delete', '')::boolean,
            NULLIF(to_jsonb(source_record)->>'is_deleted', '')::boolean,
            false
          ) = false
      )`;
    });

    return sql`(
      CASE
        WHEN t.source_type IS NULL OR t.source_id IS NULL THEN false
        ${sql.join(branches, sql` `)}
        ELSE true
      END
    )`;
  }

  private formatAccountTypeReportLabel(value: string | null | undefined) {
    const rawValue = String(value ?? "").trim();
    if (!rawValue) return "Uncategorized";

    const normalizedGroupLabel = rawValue.replace(/[_-]+/g, " ").trim();
    const groupLabelOverrides: Record<string, string> = {
      assets: "Asset",
      liabilities: "Liability",
      expenses: "Expense",
    };
    const override = groupLabelOverrides[normalizedGroupLabel.toLowerCase()];
    if (override) return override;

    return rawValue
      .replace(/[_-]+/g, " ")
      .replace(/\s+/g, " ")
      .trim()
      .split(" ")
      .map((part) =>
        part.length === 0
          ? part
          : `${part[0].toUpperCase()}${part.slice(1).toLowerCase()}`,
      )
      .join(" ");
  }

  private normalizeAccountTypeFilter(value: string | null | undefined) {
    return String(value ?? "")
      .trim()
      .replace(/[_-]+/g, " ")
      .replace(/\s+/g, " ")
      .toLowerCase();
  }

  private formatTrialBalanceGroupLabel(value: string | null | undefined) {
    const rawValue = String(value ?? "").trim();
    const normalized = rawValue.toLowerCase();
    const labels: Record<string, string> = {
      assets: "Assets",
      liabilities: "Liabilities",
      equity: "Equities",
      income: "Income",
      expenses: "Expense",
    };
    if (labels[normalized]) return labels[normalized];
    return this.formatAccountTypeReportLabel(rawValue);
  }
  private buildAccountTypeFilterCondition(accountType?: string) {
    const normalizedAccountType = this.normalizeAccountTypeFilter(accountType);
    if (!normalizedAccountType || normalizedAccountType === "all") return null;

    return sql`(
      LOWER(REPLACE(COALESCE(a.account_type::text, ''), '_', ' ')) = ${normalizedAccountType}
      OR LOWER(REPLACE(COALESCE(a.account_group::text, ''), '_', ' ')) = ${normalizedAccountType}
      OR LOWER(REPLACE(COALESCE(a.user_account_name, ''), '_', ' ')) = ${normalizedAccountType}
      OR LOWER(REPLACE(COALESCE(a.system_account_name, ''), '_', ' ')) = ${normalizedAccountType}
    )`;
  }

  async getAccountTypeSummaryReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const existingSourceTables = await this.getExistingPublicReportTables([
      "expenses",
      "bills",
      "purchase_orders",
      "purchase_receives",
      "invoices",
      "vendor_credits",
      "payments_received",
      "recurring_invoices",
      "journal_entries",
      "manual_journals",
      "inventory_adjustments",
    ]);

    const transactionJoinConditions = [
      sql`t.account_id = a.id`,
      sql`t.transaction_date >= ${start.toISOString()}`,
      sql`t.transaction_date < ${endExclusive.toISOString()}`,
      sql`t.entity_id = ${tenant.entityId}`,
      this.buildAccountTransactionSourceValidationCondition(
        existingSourceTables,
      ),
    ];

    const query = sql`
      SELECT
        COALESCE(
          NULLIF(a.account_group::text, ''),
          'Uncategorized'
        ) AS "accountGroup",
        COALESCE(NULLIF(a.account_type::text, ''), 'Uncategorized') AS "accountType",
        SUM(COALESCE(t.debit, 0)) AS "totalDebit",
        SUM(COALESCE(t.credit, 0)) AS "totalCredit"
      FROM accounts a
      LEFT JOIN ${this.accountTransactionsReportSourceSql()} t
        ON ${sql.join(transactionJoinConditions, sql` AND `)}
      WHERE COALESCE(NULLIF(to_jsonb(a)->>'is_deleted', '')::boolean, false) = false
        AND (a.entity_id = ${tenant.entityId} OR a.entity_id IS NULL)
      GROUP BY
        COALESCE(NULLIF(a.account_group::text, ''), 'Uncategorized'),
        COALESCE(NULLIF(a.account_type::text, ''), 'Uncategorized')
      ORDER BY
        CASE LOWER(COALESCE(NULLIF(a.account_group::text, ''), 'Uncategorized'))
          WHEN 'assets' THEN 1
          WHEN 'equity' THEN 2
          WHEN 'expenses' THEN 3
          WHEN 'income' THEN 4
          WHEN 'liabilities' THEN 5
          ELSE 6
        END,
        COALESCE(NULLIF(a.account_type::text, ''), 'Uncategorized') ASC
    `;

    const result = await db.execute(query);
    const rows = this.rowsFromQueryResult(result);
    const sections = new Map<
      string,
      {
        accountType: string;
        accountTypeLabel: string;
        debit: number;
        credit: number;
        rows: Array<{
          accountType: string;
          accountTypeLabel: string;
          parentAccountType: string;
          debit: number;
          credit: number;
        }>;
      }
    >();
    let totalDebit = 0;
    let totalCredit = 0;

    for (const row of rows) {
      const accountGroup = String(row.accountGroup ?? "Uncategorized");
      const accountType = String(row.accountType ?? accountGroup);
      const debit = Number(row.totalDebit || 0);
      const credit = Number(row.totalCredit || 0);
      const accountGroupLabel = this.formatAccountTypeReportLabel(accountGroup);
      const accountTypeLabel = this.formatAccountTypeReportLabel(accountType);

      if (!sections.has(accountGroup)) {
        sections.set(accountGroup, {
          accountType: accountGroup,
          accountTypeLabel: accountGroupLabel,
          debit: 0,
          credit: 0,
          rows: [],
        });
      }

      const section = sections.get(accountGroup)!;
      section.debit += debit;
      section.credit += credit;
      section.rows.push({
        accountType,
        accountTypeLabel,
        parentAccountType: accountGroup,
        debit,
        credit,
      });
      totalDebit += debit;
      totalCredit += credit;
    }

    return {
      period: { startDate, endDate },
      basis: basis || "Accrual",
      sections: Array.from(sections.values()),
      totalDebit,
      totalCredit,
    };
  }
  async getAccountTypeTransactionsReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const allowedPageSizes = [10, 25, 50, 100, 200];
    const normalizedPageSize = allowedPageSizes.includes(Number(pageSize))
      ? Number(pageSize)
      : 25;
    const requestedPage = Number.isFinite(Number(page))
      ? Math.max(1, Number(page))
      : 1;
    const existingSourceTables = await this.getExistingPublicReportTables([
      "expenses",
      "bills",
      "purchase_orders",
      "purchase_receives",
      "invoices",
      "vendor_credits",
      "payments_received",
      "recurring_invoices",
      "journal_entries",
      "manual_journals",
      "inventory_adjustments",
    ]);

    const accountActiveCondition = sql`COALESCE(NULLIF(to_jsonb(a)->>'is_deleted', '')::boolean, false) = false`;
    const sourceValidationCondition =
      this.buildAccountTransactionSourceValidationCondition(
        existingSourceTables,
      );
    const periodConditions = [
      sql`t.transaction_date >= ${start.toISOString()}`,
      sql`t.transaction_date < ${endExclusive.toISOString()}`,
      sql`t.entity_id = ${tenant.entityId}`,
      accountActiveCondition,
      sourceValidationCondition,
    ];
    const periodWhereClause = sql.join(periodConditions, sql` AND `);

    const countResult = await db.execute(sql`
      SELECT COUNT(*)::int AS "total"
      FROM ${this.accountTransactionsReportSourceSql()} t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${periodWhereClause}
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const openingResult = await db.execute(sql`
      SELECT
        COALESCE(NULLIF(a.account_type::text, ''), 'Uncategorized') AS "accountType",
        SUM(COALESCE(t.debit, 0) - COALESCE(t.credit, 0)) AS "openingBalance"
      FROM ${this.accountTransactionsReportSourceSql()} t
      JOIN accounts a ON t.account_id = a.id
      WHERE t.transaction_date < ${start.toISOString()}
        AND t.entity_id = ${tenant.entityId}
        AND ${accountActiveCondition}
        AND ${sourceValidationCondition}
      GROUP BY COALESCE(NULLIF(a.account_type::text, ''), 'Uncategorized')
    `);

    const periodBalanceResult = await db.execute(sql`
      SELECT
        COALESCE(NULLIF(a.account_type::text, ''), 'Uncategorized') AS "accountType",
        SUM(COALESCE(t.debit, 0) - COALESCE(t.credit, 0)) AS "periodBalance"
      FROM ${this.accountTransactionsReportSourceSql()} t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${periodWhereClause}
      GROUP BY COALESCE(NULLIF(a.account_type::text, ''), 'Uncategorized')
    `);

    const query = sql`
      SELECT
        COALESCE(NULLIF(a.account_type::text, ''), 'Uncategorized') AS "accountType",
        t.transaction_date AS "date",
        COALESCE(
          NULLIF(a.user_account_name, ''),
          NULLIF(a.system_account_name, ''),
          NULLIF(a.account_code, ''),
          a.id::text
        ) AS "accountName",
        COALESCE(NULLIF(t.description, ''), '--') AS "details",
        COALESCE(NULLIF(t.source_type, ''), '--') AS "type",
        COALESCE(NULLIF(t.reference_number, ''), t.source_id::text, '') AS "transactionNumber",
        COALESCE(NULLIF(t.reference_number, ''), '') AS "reference",
        t.debit AS "debit",
        t.credit AS "credit"
      FROM ${this.accountTransactionsReportSourceSql()} t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${periodWhereClause}
      ORDER BY
        COALESCE(NULLIF(a.account_type::text, ''), 'Uncategorized') ASC,
        t.transaction_date ASC,
        t.created_at ASC,
        t.id ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `;

    const rows = this.rowsFromQueryResult(await db.execute(query));
    const openingBalances = new Map<string, number>();
    for (const row of this.rowsFromQueryResult(openingResult)) {
      openingBalances.set(
        String(row.accountType ?? "Uncategorized"),
        Number(row.openingBalance || 0),
      );
    }
    const periodBalances = new Map<string, number>();
    for (const row of this.rowsFromQueryResult(periodBalanceResult)) {
      periodBalances.set(
        String(row.accountType ?? "Uncategorized"),
        Number(row.periodBalance || 0),
      );
    }

    const sections = new Map<
      string,
      {
        accountType: string;
        accountTypeLabel: string;
        openingBalance: number;
        closingBalance: number;
        transactions: Array<Record<string, unknown>>;
      }
    >();

    for (const row of rows) {
      const accountType = String(row.accountType ?? "Uncategorized");
      if (!sections.has(accountType)) {
        const openingBalance = openingBalances.get(accountType) ?? 0;
        sections.set(accountType, {
          accountType,
          accountTypeLabel: this.formatAccountTypeReportLabel(accountType),
          openingBalance,
          closingBalance: openingBalance + (periodBalances.get(accountType) ?? 0),
          transactions: [],
        });
      }

      const section = sections.get(accountType)!;
      const debit = Number(row.debit || 0);
      const credit = Number(row.credit || 0);
      section.transactions.push({
        ...row,
        debit,
        credit,
        amount: debit > 0 ? debit : credit,
        amountType: debit > 0 ? "Dr" : credit > 0 ? "Cr" : "",
      });
    }

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      sections: Array.from(sections.values()),
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getAccountTransactionsReport(
    accountId: string | undefined,
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    contactId?: string,
    contactType?: string,
    basis?: string,
    page = 1,
    pageSize = 25,
    accountType?: string,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const allowedPageSizes = [10, 25, 50, 100, 200];
    const normalizedPageSize = allowedPageSizes.includes(Number(pageSize))
      ? Number(pageSize)
      : 25;
    const requestedPage = Number.isFinite(Number(page))
      ? Math.max(1, Number(page))
      : 1;

    const conditions: any[] = [];
    if (accountId) conditions.push(sql`t.account_id = ${accountId}`);
    const accountTypeCondition =
      this.buildAccountTypeFilterCondition(accountType);
    if (accountTypeCondition) conditions.push(accountTypeCondition);
    if (contactId) conditions.push(sql`t.contact_id = ${contactId}`);
    if (contactType) conditions.push(sql`t.contact_type = ${contactType}`);
    conditions.push(sql`t.transaction_date >= ${start.toISOString()}`);
    conditions.push(sql`t.transaction_date < ${endExclusive.toISOString()}`);
    conditions.push(sql`t.entity_id = ${tenant.entityId}`);

    const whereClause = sql.join(conditions, sql` AND `);

    const countResult = await db.execute(sql`
      SELECT COUNT(*)::int AS "total"
      FROM ${this.accountTransactionsReportSourceSql()} t
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const query = sql`
      SELECT
        t.transaction_date AS "date",
        COALESCE(
          NULLIF(a.user_account_name, ''),
          NULLIF(a.system_account_name, ''),
          NULLIF(a.account_code, ''),
          a.id::text,
          NULLIF(t.source_type, ''),
          'Batch Transaction'
        ) AS "accountName",
        COALESCE(NULLIF(t.description, ''), '--') AS "details",
        COALESCE(NULLIF(t.source_type, ''), '--') AS "type",
        COALESCE(NULLIF(t.reference_number, ''), t.source_id::text, '') AS "transactionNumber",
        COALESCE(NULLIF(t.reference_number, ''), '') AS "reference",
        t.debit AS "debit",
        t.credit AS "credit",
        t.source_id AS "sourceId",
        t.source_type AS "sourceType"
      FROM ${this.accountTransactionsReportSourceSql()} t
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
      ORDER BY t.transaction_date ASC, t.created_at ASC, t.id ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `;
    const result = await db.execute(query);
    const rows = this.rowsFromQueryResult(result);

    let runningBalance = 0;
    const transactions = rows.map((r: any) => {
      const debit = Number(r.debit || 0);
      const credit = Number(r.credit || 0);
      runningBalance += debit - credit;
      return { ...r, debit, credit, runningBalance };
    });

    return {
      accountId: accountId || null,
      accountType: accountType || null,
      basis: basis || "Accrual",
      period: { startDate, endDate },
      transactions,
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getJournalReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const existingSourceTables = await this.getExistingPublicReportTables([
      "expenses",
      "bills",
      "purchase_orders",
      "purchase_receives",
      "invoices",
      "vendor_credits",
      "payments_received",
      "recurring_invoices",
      "journal_entries",
      "manual_journals",
      "inventory_adjustments",
    ]);
    const sourceValidationCondition =
      this.buildAccountTransactionSourceValidationCondition(
        existingSourceTables,
      );
    const sourceTypeExpression = sql`COALESCE(NULLIF(t.source_type, ''), 'Journal')`;
    const journalKeyExpression = sql`COALESCE(t.source_id::text, t.journal_entry_id::text, t.id::text)`;
    const conditions = [
      sql`t.transaction_date >= ${start.toISOString()}`,
      sql`t.transaction_date < ${endExclusive.toISOString()}`,
      sql`t.entity_id = ${tenant.entityId}`,
      sql`COALESCE(to_jsonb(a)->>'is_deleted', 'false')::boolean = false`,
      sourceValidationCondition,
    ];
    const whereClause = sql.join(conditions, sql` AND `);

    const countResult = await db.execute(sql`
      SELECT COUNT(*)::int AS "total"
      FROM (
        SELECT ${sourceTypeExpression} AS "sourceType", ${journalKeyExpression} AS "journalKey"
        FROM ${this.accountTransactionsReportSourceSql()} t
        JOIN accounts a ON t.account_id = a.id
        WHERE ${whereClause}
        GROUP BY ${sourceTypeExpression}, ${journalKeyExpression}
      ) grouped_journals
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const groupsResult = await db.execute(sql`
      SELECT
        ${sourceTypeExpression} AS "sourceType",
        ${journalKeyExpression} AS "journalKey",
        MIN(t.transaction_date) AS "date",
        COALESCE(NULLIF(MIN(t.reference_number), ''), MIN(t.source_id::text), '') AS "transactionNumber",
        COALESCE(NULLIF(MIN(t.reference_number), ''), '') AS "reference",
        COALESCE(NULLIF(MIN(t.description), ''), '') AS "description",
        SUM(COALESCE(t.debit, 0)) AS "totalDebit",
        SUM(COALESCE(t.credit, 0)) AS "totalCredit"
      FROM ${this.accountTransactionsReportSourceSql()} t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
      GROUP BY ${sourceTypeExpression}, ${journalKeyExpression}
      ORDER BY MIN(t.transaction_date) ASC, ${sourceTypeExpression} ASC, ${journalKeyExpression} ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);
    const groupRows = this.rowsFromQueryResult(groupsResult);

    if (groupRows.length === 0) {
      return {
        basis: basis || "Accrual",
        period: { startDate, endDate },
        sections: [],
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
        pagination: {
          totalRecords: total,
          total,
          page: currentPage,
          pageSize: normalizedPageSize,
          totalPages,
        },
      };
    }

    const groupConditions = groupRows.map(
      (row: any) => sql`(${sourceTypeExpression} = ${String(row.sourceType ?? "Journal")} AND ${journalKeyExpression} = ${String(row.journalKey ?? "")})`,
    );
    const groupWhereClause = sql.join(groupConditions, sql` OR `);
    const linesResult = await db.execute(sql`
      SELECT
        ${sourceTypeExpression} AS "sourceType",
        ${journalKeyExpression} AS "journalKey",
        t.transaction_date AS "date",
        COALESCE(
          NULLIF(a.user_account_name, ''),
          NULLIF(a.system_account_name, ''),
          NULLIF(a.account_code, ''),
          a.id::text
        ) AS "accountName",
        COALESCE(NULLIF(t.description, ''), '') AS "description",
        COALESCE(NULLIF(t.reference_number, ''), '') AS "reference",
        COALESCE(t.debit, 0) AS "debit",
        COALESCE(t.credit, 0) AS "credit"
      FROM ${this.accountTransactionsReportSourceSql()} t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
        AND (${groupWhereClause})
      ORDER BY t.transaction_date ASC, ${sourceTypeExpression} ASC, ${journalKeyExpression} ASC, t.line_number ASC NULLS LAST, t.created_at ASC, t.id ASC
    `);

    const linesByGroup = new Map<string, Array<Record<string, any>>>();
    for (const row of this.rowsFromQueryResult(linesResult)) {
      const key = `${row.sourceType}::${row.journalKey}`;
      const debit = Number(row.debit || 0);
      const credit = Number(row.credit || 0);
      const lines = linesByGroup.get(key) ?? [];
      lines.push({
        accountName: row.accountName,
        description: row.description,
        reference: row.reference,
        debit,
        credit,
      });
      linesByGroup.set(key, lines);
    }

    const sections = groupRows.map((row: any) => {
      const sourceType = String(row.sourceType ?? "Journal");
      const journalKey = String(row.journalKey ?? "");
      return {
        sourceType,
        journalKey,
        date: row.date,
        transactionNumber: row.transactionNumber,
        reference: row.reference,
        description: row.description,
        totalDebit: Number(row.totalDebit || 0),
        totalCredit: Number(row.totalCredit || 0),
        lines: linesByGroup.get(`${sourceType}::${journalKey}`) ?? [],
      };
    });

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      sections,
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getDayBookReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const existingSourceTables = await this.getExistingPublicReportTables([
      "expenses",
      "bills",
      "purchase_orders",
      "purchase_receives",
      "invoices",
      "vendor_credits",
      "payments_received",
      "recurring_invoices",
      "journal_entries",
      "manual_journals",
      "inventory_adjustments",
    ]);
    const sourceValidationCondition =
      this.buildAccountTransactionSourceValidationCondition(
        existingSourceTables,
      );
    const conditions = [
      sql`t.transaction_date >= ${start.toISOString()}`,
      sql`t.transaction_date < ${endExclusive.toISOString()}`,
      sql`t.entity_id = ${tenant.entityId}`,
      sql`COALESCE(to_jsonb(a)->>'is_deleted', 'false')::boolean = false`,
      sourceValidationCondition,
    ];
    const whereClause = sql.join(conditions, sql` AND `);

    const countResult = await db.execute(sql`
      SELECT COUNT(*)::int AS "total"
      FROM ${this.accountTransactionsReportSourceSql()} t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      SELECT
        SUM(COALESCE(t.debit, 0)) AS "totalDebit",
        SUM(COALESCE(t.credit, 0)) AS "totalCredit"
      FROM ${this.accountTransactionsReportSourceSql()} t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const query = sql`
      SELECT
        t.transaction_date AS "date",
        COALESCE(
          NULLIF(a.user_account_name, ''),
          NULLIF(a.system_account_name, ''),
          NULLIF(a.account_code, ''),
          a.id::text
        ) AS "accountName",
        COALESCE(NULLIF(t.description, ''), '--') AS "details",
        COALESCE(NULLIF(t.source_type, ''), '--') AS "transactionType",
        COALESCE(NULLIF(t.reference_number, ''), t.source_id::text, '') AS "transactionNumber",
        COALESCE(NULLIF(t.reference_number, ''), '') AS "reference",
        COALESCE(t.debit, 0) AS "debit",
        COALESCE(t.credit, 0) AS "credit"
      FROM ${this.accountTransactionsReportSourceSql()} t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
      ORDER BY t.transaction_date ASC, t.created_at ASC, t.line_number ASC NULLS LAST, t.id ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `;
    const rows = this.rowsFromQueryResult(await db.execute(query)).map(
      (row: any) => {
        const debit = Number(row.debit || 0);
        const credit = Number(row.credit || 0);
        return {
          ...row,
          debit,
          credit,
          amount: Math.abs(debit - credit),
          amountType: debit >= credit ? "Dr" : "Cr",
        };
      },
    );

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      transactions: rows,
      totals: {
        debit: Number(totalsRow.totalDebit || 0),
        credit: Number(totalsRow.totalCredit || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getInvoiceDetailsReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    reportBy = "Invoice Date",
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const startDay = start.toISOString().substring(0, 10);
    const endDay = endExclusive.toISOString().substring(0, 10);
    const entityId = tenant.entityId;
    const normalizedReportBy = (reportBy || "Invoice Date").toLowerCase();
    const reportDateExpression = normalizedReportBy.includes("due")
      ? sql`im.due_date`
      : sql`im.invoice_date`;

    const invoiceBaseRows = sql`
      WITH order_numbers AS (
        SELECT
          iso.invoice_id AS "invoiceId",
          string_agg(
            DISTINCT COALESCE(NULLIF(so.sale_number, ''), iso.sales_order_id::text),
            ', '
          ) AS "orderNumber"
        FROM invoice_sales_orders iso
        LEFT JOIN sales_orders so ON so.id = iso.sales_order_id
        GROUP BY iso.invoice_id
      ),
      base_invoices AS (
        SELECT
          im.id AS "invoiceId",
          COALESCE(NULLIF(im.status, ''), 'draft') AS "status",
          im.invoice_date AS "invoiceDate",
          im.due_date AS "dueDate",
          COALESCE(NULLIF(im.invoice_number, ''), im.id::text) AS "invoiceNumber",
          COALESCE(NULLIF(onn."orderNumber", ''), '') AS "orderNumber",
          COALESCE(
            NULLIF(c.display_name, ''),
            NULLIF(c.company_name, ''),
            im.customer_id::text,
            '-'
          ) AS "customerName",
          COALESCE(NULLIF(u.full_name, ''), NULLIF(u.email, ''), '') AS "salespersonName",
          COALESCE(NULLIF(w.name, ''), '') AS "warehouseName",
          COALESCE(NULLIF(im.payment_terms, ''), '') AS "paymentTerms",
          COALESCE(NULLIF(pl.name, ''), '') AS "priceListName",
          COALESCE(NULLIF(im.place_of_supply, ''), '') AS "placeOfSupply",
          COALESCE(NULLIF(to_jsonb(im)->>'currency', ''), 'INR') AS "currency",
          COALESCE(im.subtotal, 0)::numeric AS "subtotal",
          COALESCE(im.tax_total, 0)::numeric AS "taxTotal",
          COALESCE(im.shipping_charges, 0)::numeric AS "shippingCharges",
          COALESCE(im.adjustment_amount, 0)::numeric AS "adjustment",
          COALESCE(im.round_off, 0)::numeric AS "roundOff",
          COALESCE(im.grand_total, 0)::numeric AS "grandTotal",
          CASE
            WHEN LOWER(COALESCE(im.status, '')) = 'paid' THEN 0::numeric
            ELSE COALESCE(im.grand_total, 0)::numeric
          END AS "balance"
        FROM invoice_master im
        LEFT JOIN customers c ON c.id = im.customer_id
        LEFT JOIN users u ON u.id = im.salesperson_id
        LEFT JOIN warehouses w ON w.id = im.warehouse_id
        LEFT JOIN price_lists pl ON pl.id = im.price_list_id
        LEFT JOIN order_numbers onn ON onn."invoiceId" = im.id
        WHERE ${reportDateExpression} >= ${startDay}
          AND ${reportDateExpression} < ${endDay}
          AND im.entity_id = ${entityId}
          AND COALESCE(im.is_delete, false) = false
      )
    `;

    const countResult = await db.execute(sql`
      ${invoiceBaseRows}
      SELECT COUNT(*)::int AS "total" FROM base_invoices
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      ${invoiceBaseRows}
      SELECT
        COALESCE(SUM("subtotal"), 0)::numeric AS "subtotal",
        COALESCE(SUM("taxTotal"), 0)::numeric AS "taxTotal",
        COALESCE(SUM("shippingCharges"), 0)::numeric AS "shippingCharges",
        COALESCE(SUM("adjustment"), 0)::numeric AS "adjustment",
        COALESCE(SUM("roundOff"), 0)::numeric AS "roundOff",
        COALESCE(SUM("grandTotal"), 0)::numeric AS "grandTotal",
        COALESCE(SUM("balance"), 0)::numeric AS "balance"
      FROM base_invoices
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const rowsResult = await db.execute(sql`
      ${invoiceBaseRows}
      SELECT *
      FROM base_invoices
      ORDER BY "invoiceDate" ASC, "invoiceNumber" ASC, "invoiceId" ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);
    const rows = this.rowsFromQueryResult(rowsResult).map((row: any) => ({
      invoiceId: row.invoiceId?.toString() || '',
      status: row.status?.toString() || 'draft',
      invoiceDate: row.invoiceDate,
      dueDate: row.dueDate,
      invoiceNumber: row.invoiceNumber?.toString() || '',
      orderNumber: row.orderNumber?.toString() || '',
      customerName: row.customerName?.toString() || '-',
      salespersonName: row.salespersonName?.toString() || '',
      warehouseName: row.warehouseName?.toString() || '',
      paymentTerms: row.paymentTerms?.toString() || '',
      priceListName: row.priceListName?.toString() || '',
      placeOfSupply: row.placeOfSupply?.toString() || '',
      currency: row.currency?.toString() || 'INR',
      subtotal: Number(row.subtotal || 0),
      taxTotal: Number(row.taxTotal || 0),
      shippingCharges: Number(row.shippingCharges || 0),
      adjustment: Number(row.adjustment || 0),
      roundOff: Number(row.roundOff || 0),
      grandTotal: Number(row.grandTotal || 0),
      balance: Number(row.balance || 0),
    }));

    return {
      basis: basis || "Accrual",
      reportBy: reportBy || "Invoice Date",
      period: { startDate, endDate },
      rows,
      totals: {
        subtotal: Number(totalsRow.subtotal || 0),
        taxTotal: Number(totalsRow.taxTotal || 0),
        shippingCharges: Number(totalsRow.shippingCharges || 0),
        adjustment: Number(totalsRow.adjustment || 0),
        roundOff: Number(totalsRow.roundOff || 0),
        grandTotal: Number(totalsRow.grandTotal || 0),
        balance: Number(totalsRow.balance || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getCreditNoteDetailsReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const startDay = start.toISOString().substring(0, 10);
    const endDay = endExclusive.toISOString().substring(0, 10);
    const entityId = tenant.entityId;

    const creditNoteBaseRows = sql`
      WITH base_credit_notes AS (
        SELECT
          cn.id AS "creditNoteId",
          COALESCE(NULLIF(cn.status, ''), 'draft') AS "status",
          cn.credit_note_date AS "creditDate",
          COALESCE(NULLIF(cn.credit_note_number, ''), cn.id::text) AS "creditNoteNumber",
          cn.id::text AS "creditNoteRecordId",
          COALESCE(NULLIF(cn.reference_number, ''), '') AS "referenceNumber",
          COALESCE(NULLIF(cn.reason, ''), '') AS "reason",
          COALESCE(NULLIF(to_jsonb(u)->>'full_name', ''), NULLIF(to_jsonb(u)->>'email', ''), '') AS "salespersonName",
          COALESCE(NULLIF(w.name, ''), '') AS "warehouseName",
          COALESCE(NULLIF(pl.name, ''), '') AS "priceListName",
          COALESCE(NULLIF(cn.source_type, ''), '') AS "sourceType",
          COALESCE(
            NULLIF(c.display_name, ''),
            NULLIF(c.company_name, ''),
            cn.customer_id::text,
            '-'
          ) AS "customerName",
          COALESCE(cn.subtotal, 0)::numeric AS "subtotal",
          COALESCE(cn.discount_total, 0)::numeric AS "discountTotal",
          COALESCE(cn.tax_total, 0)::numeric AS "taxTotal",
          COALESCE(cn.shipping_charges, 0)::numeric AS "shippingCharges",
          COALESCE(cn.tds_total, 0)::numeric AS "tdsTotal",
          COALESCE(cn.tcs_total, 0)::numeric AS "tcsTotal",
          COALESCE(cn.adjustment_amount, 0)::numeric AS "adjustmentAmount",
          COALESCE(cn.round_off, 0)::numeric AS "roundOff",
          COALESCE(cn.grand_total, 0)::numeric AS "grandTotal",
          CASE
            WHEN LOWER(COALESCE(cn.status, '')) IN ('closed', 'applied') THEN 0::numeric
            ELSE COALESCE(cn.grand_total, 0)::numeric
          END AS "balanceAmount"
        FROM credit_notes cn
        LEFT JOIN customers c ON c.id = cn.customer_id
        LEFT JOIN users u ON u.id = cn.salesperson_id
        LEFT JOIN warehouses w ON w.id = cn.warehouse_id
        LEFT JOIN price_lists pl ON pl.id = cn.price_list_id
        WHERE cn.credit_note_date >= ${startDay}
          AND cn.credit_note_date < ${endDay}
          AND cn.entity_id = ${entityId}
      )
    `;

    const countResult = await db.execute(sql`
      ${creditNoteBaseRows}
      SELECT COUNT(*)::int AS "total" FROM base_credit_notes
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      ${creditNoteBaseRows}
      SELECT
        COALESCE(SUM("subtotal"), 0)::numeric AS "subtotal",
        COALESCE(SUM("discountTotal"), 0)::numeric AS "discountTotal",
        COALESCE(SUM("taxTotal"), 0)::numeric AS "taxTotal",
        COALESCE(SUM("shippingCharges"), 0)::numeric AS "shippingCharges",
        COALESCE(SUM("grandTotal"), 0)::numeric AS "grandTotal",
        COALESCE(SUM("balanceAmount"), 0)::numeric AS "balanceAmount"
      FROM base_credit_notes
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const rowsResult = await db.execute(sql`
      ${creditNoteBaseRows}
      SELECT *
      FROM base_credit_notes
      ORDER BY "creditDate" ASC, "creditNoteNumber" ASC, "creditNoteId" ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);
    const rows = this.rowsFromQueryResult(rowsResult).map((row: any) => ({
      creditNoteId: row.creditNoteId?.toString() || '',
      status: row.status?.toString() || 'draft',
      creditDate: row.creditDate,
      creditNoteNumber: row.creditNoteNumber?.toString() || '',
      creditNoteRecordId: row.creditNoteRecordId?.toString() || '',
      referenceNumber: row.referenceNumber?.toString() || '',
      reason: row.reason?.toString() || '',
      salespersonName: row.salespersonName?.toString() || '',
      warehouseName: row.warehouseName?.toString() || '',
      priceListName: row.priceListName?.toString() || '',
      sourceType: row.sourceType?.toString() || '',
      customerName: row.customerName?.toString() || '-',
      subtotal: Number(row.subtotal || 0),
      discountTotal: Number(row.discountTotal || 0),
      taxTotal: Number(row.taxTotal || 0),
      shippingCharges: Number(row.shippingCharges || 0),
      tdsTotal: Number(row.tdsTotal || 0),
      tcsTotal: Number(row.tcsTotal || 0),
      adjustmentAmount: Number(row.adjustmentAmount || 0),
      roundOff: Number(row.roundOff || 0),
      grandTotal: Number(row.grandTotal || 0),
      balanceAmount: Number(row.balanceAmount || 0),
    }));

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      rows,
      totals: {
        subtotal: Number(totalsRow.subtotal || 0),
        discountTotal: Number(totalsRow.discountTotal || 0),
        taxTotal: Number(totalsRow.taxTotal || 0),
        shippingCharges: Number(totalsRow.shippingCharges || 0),
        grandTotal: Number(totalsRow.grandTotal || 0),
        balanceAmount: Number(totalsRow.balanceAmount || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getRetainerInvoiceDetailsReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const startDay = start.toISOString().substring(0, 10);
    const endDay = endExclusive.toISOString().substring(0, 10);
    const entityId = tenant.entityId;
    const invoiceDateExpression = sql`COALESCE(
      NULLIF(to_jsonb(ri)->>'retainer_invoice_date', '')::date,
      NULLIF(to_jsonb(ri)->>'invoice_date', '')::date,
      NULLIF(to_jsonb(ri)->>'date', '')::date,
      NULLIF(to_jsonb(ri)->>'created_at', '')::timestamp::date
    )`;

    const numericValue = (keys: string[]) => sql`CASE
      WHEN COALESCE(${sql.join(
        keys.map((key) => sql`NULLIF(to_jsonb(ri)->>${key}, '')`),
        sql`, `,
      )}) ~ '^-?[0-9]+([.][0-9]+)?$'
      THEN COALESCE(${sql.join(
        keys.map((key) => sql`NULLIF(to_jsonb(ri)->>${key}, '')`),
        sql`, `,
      )})::numeric
      ELSE 0::numeric
    END`;

    const totalAmountExpression = numericValue([
      'total_amount',
      'grand_total',
      'total',
      'amount',
    ]);
    const amountReceivedExpression = numericValue([
      'amount_received',
      'received_amount',
      'paid_amount',
    ]);
    const amountAppliedExpression = numericValue([
      'amount_applied',
      'applied_amount',
      'used_amount',
    ]);
    const balanceAmountExpression = numericValue([
      'balance_amount',
      'unused_retainer',
      'unused_retainers',
      'unused_amount',
      'balance',
    ]);

    const retainerBaseRows = sql`
      WITH base_retainers AS (
        SELECT
          ri.id AS "retainerInvoiceId",
          COALESCE(NULLIF(to_jsonb(ri)->>'status', ''), 'draft') AS "status",
          ${invoiceDateExpression} AS "retainerInvoiceDate",
          COALESCE(
            NULLIF(to_jsonb(ri)->>'retainer_invoice_number', ''),
            NULLIF(to_jsonb(ri)->>'retainer_invoice_no', ''),
            NULLIF(to_jsonb(ri)->>'invoice_number', ''),
            NULLIF(to_jsonb(ri)->>'number', ''),
            ri.id::text
          ) AS "retainerInvoiceNumber",
          COALESCE(
            NULLIF(c.display_name, ''),
            NULLIF(c.company_name, ''),
            NULLIF(to_jsonb(ri)->>'customer_name', ''),
            NULLIF(to_jsonb(ri)->>'customerName', ''),
            NULLIF(to_jsonb(ri)->>'customer_id', ''),
            '-'
          ) AS "customerName",
          COALESCE(
            NULLIF(to_jsonb(ri)->>'project_estimate', ''),
            NULLIF(to_jsonb(ri)->>'project_name', ''),
            NULLIF(to_jsonb(ri)->>'estimate_number', ''),
            NULLIF(to_jsonb(ri)->>'estimate_id', ''),
            ''
          ) AS "projectEstimate",
          COALESCE(
            NULLIF(to_jsonb(ri)->>'reference_number', ''),
            NULLIF(to_jsonb(ri)->>'reference', ''),
            ''
          ) AS "referenceNumber",
          COALESCE(NULLIF(to_jsonb(ri)->>'customer_notes', ''), NULLIF(to_jsonb(ri)->>'notes', ''), '') AS "customerNotes",
          COALESCE(NULLIF(to_jsonb(ri)->>'terms_conditions', ''), NULLIF(to_jsonb(ri)->>'terms_and_conditions', ''), '') AS "termsConditions",
          ${totalAmountExpression} AS "totalAmount",
          ${amountReceivedExpression} AS "amountReceived",
          ${amountAppliedExpression} AS "amountApplied",
          CASE
            WHEN ${balanceAmountExpression} <> 0 THEN ${balanceAmountExpression}
            ELSE ${totalAmountExpression} - ${amountReceivedExpression} - ${amountAppliedExpression}
          END AS "balanceAmount"
        FROM retainer_invoices ri
        LEFT JOIN customers c ON c.id::text = NULLIF(to_jsonb(ri)->>'customer_id', '')
        WHERE ${invoiceDateExpression} >= ${startDay}
          AND ${invoiceDateExpression} < ${endDay}
          AND ri.entity_id = ${entityId}
          AND COALESCE(NULLIF(to_jsonb(ri)->>'is_deleted', '')::boolean, false) = false
      )
    `;

    const countResult = await db.execute(sql`
      ${retainerBaseRows}
      SELECT COUNT(*)::int AS "total" FROM base_retainers
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      ${retainerBaseRows}
      SELECT
        COALESCE(SUM("totalAmount"), 0)::numeric AS "totalAmount",
        COALESCE(SUM("amountReceived"), 0)::numeric AS "amountReceived",
        COALESCE(SUM("amountApplied"), 0)::numeric AS "amountApplied",
        COALESCE(SUM("balanceAmount"), 0)::numeric AS "balanceAmount"
      FROM base_retainers
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const rowsResult = await db.execute(sql`
      ${retainerBaseRows}
      SELECT *
      FROM base_retainers
      ORDER BY "retainerInvoiceDate" ASC, "retainerInvoiceNumber" ASC, "retainerInvoiceId" ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);
    const rows = this.rowsFromQueryResult(rowsResult).map((row: any) => ({
      retainerInvoiceId: row.retainerInvoiceId?.toString() || '',
      status: row.status?.toString() || 'draft',
      retainerInvoiceDate: row.retainerInvoiceDate,
      retainerInvoiceNumber: row.retainerInvoiceNumber?.toString() || '',
      customerName: row.customerName?.toString() || '-',
      projectEstimate: row.projectEstimate?.toString() || '',
      referenceNumber: row.referenceNumber?.toString() || '',
      customerNotes: row.customerNotes?.toString() || '',
      termsConditions: row.termsConditions?.toString() || '',
      totalAmount: Number(row.totalAmount || 0),
      amountReceived: Number(row.amountReceived || 0),
      amountApplied: Number(row.amountApplied || 0),
      balanceAmount: Number(row.balanceAmount || 0),
    }));

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      rows,
      totals: {
        totalAmount: Number(totalsRow.totalAmount || 0),
        amountReceived: Number(totalsRow.amountReceived || 0),
        amountApplied: Number(totalsRow.amountApplied || 0),
        balanceAmount: Number(totalsRow.balanceAmount || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getQuoteDetailsReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    reportBy = "Quote Date",
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const startDay = start.toISOString().substring(0, 10);
    const endDay = endExclusive.toISOString().substring(0, 10);
    const entityId = tenant.entityId;
    const normalizedReportBy = (reportBy || "Quote Date").toLowerCase();
    const reportDateExpression = normalizedReportBy.includes("expiry")
      ? sql`COALESCE(
          NULLIF(to_jsonb(sq)->>'expiry_date', '')::date,
          NULLIF(to_jsonb(sq)->>'valid_until', '')::date,
          NULLIF(to_jsonb(sq)->>'valid_till', '')::date,
          NULLIF(to_jsonb(sq)->>'created_at', '')::timestamp::date
        )`
      : sql`COALESCE(
          NULLIF(to_jsonb(sq)->>'quote_date', '')::date,
          NULLIF(to_jsonb(sq)->>'quotation_date', '')::date,
          NULLIF(to_jsonb(sq)->>'date', '')::date,
          NULLIF(to_jsonb(sq)->>'created_at', '')::timestamp::date
        )`;

    const quoteAmountExpression = sql`CASE
      WHEN COALESCE(
        NULLIF(to_jsonb(sq)->>'grand_total', ''),
        NULLIF(to_jsonb(sq)->>'total', ''),
        NULLIF(to_jsonb(sq)->>'quote_amount', ''),
        NULLIF(to_jsonb(sq)->>'quotation_amount', '')
      ) ~ '^-?[0-9]+([.][0-9]+)?$'
      THEN COALESCE(
        NULLIF(to_jsonb(sq)->>'grand_total', ''),
        NULLIF(to_jsonb(sq)->>'total', ''),
        NULLIF(to_jsonb(sq)->>'quote_amount', ''),
        NULLIF(to_jsonb(sq)->>'quotation_amount', '')
      )::numeric
      ELSE 0::numeric
    END`;

    const quoteBaseRows = sql`
      WITH base_quotes AS (
        SELECT
          sq.id AS "quoteId",
          COALESCE(NULLIF(to_jsonb(sq)->>'status', ''), 'draft') AS "status",
          COALESCE(
            NULLIF(to_jsonb(sq)->>'quote_date', '')::date,
            NULLIF(to_jsonb(sq)->>'quotation_date', '')::date,
            NULLIF(to_jsonb(sq)->>'date', '')::date,
            NULLIF(to_jsonb(sq)->>'created_at', '')::timestamp::date
          ) AS "quoteDate",
          COALESCE(
            NULLIF(to_jsonb(sq)->>'expiry_date', '')::date,
            NULLIF(to_jsonb(sq)->>'valid_until', '')::date,
            NULLIF(to_jsonb(sq)->>'valid_till', '')::date
          ) AS "expiryDate",
          COALESCE(
            NULLIF(to_jsonb(sq)->>'quote_number', ''),
            NULLIF(to_jsonb(sq)->>'quotation_number', ''),
            NULLIF(to_jsonb(sq)->>'quote_no', ''),
            NULLIF(to_jsonb(sq)->>'number', ''),
            sq.id::text
          ) AS "quoteNumber",
          COALESCE(
            NULLIF(to_jsonb(sq)->>'reference_number', ''),
            NULLIF(to_jsonb(sq)->>'reference', ''),
            ''
          ) AS "referenceNumber",
          COALESCE(
            NULLIF(c.display_name, ''),
            NULLIF(c.company_name, ''),
            NULLIF(to_jsonb(sq)->>'customer_name', ''),
            NULLIF(to_jsonb(sq)->>'customerName', ''),
            NULLIF(to_jsonb(sq)->>'customer_id', ''),
            '-'
          ) AS "customerName",
          COALESCE(NULLIF(u.full_name, ''), NULLIF(u.email, ''), '') AS "salespersonName",
          COALESCE(
            NULLIF(to_jsonb(cur)->>'currency_code', ''),
            NULLIF(to_jsonb(cur)->>'code', ''),
            NULLIF(to_jsonb(cur)->>'symbol', ''),
            NULLIF(to_jsonb(sq)->>'currency', ''),
            'INR'
          ) AS "currency",
          COALESCE(NULLIF(pl.name, ''), NULLIF(to_jsonb(sq)->>'price_list_name', ''), '') AS "priceListName",
          COALESCE(NULLIF(to_jsonb(sq)->>'invoice_number', ''), NULLIF(im.invoice_number, ''), '') AS "invoiceNumber",
          COALESCE(NULLIF(to_jsonb(sq)->>'project_name', ''), NULLIF(to_jsonb(sq)->>'project', ''), '') AS "projectName",
          COALESCE(NULLIF(to_jsonb(sq)->>'subject', ''), '') AS "subject",
          ${quoteAmountExpression} AS "quoteAmount"
        FROM sales_quotations sq
        LEFT JOIN customers c ON c.id::text = NULLIF(to_jsonb(sq)->>'customer_id', '')
        LEFT JOIN users u ON u.id::text = COALESCE(
          NULLIF(to_jsonb(sq)->>'salesperson_id', ''),
          NULLIF(to_jsonb(sq)->>'sales_person_id', ''),
          NULLIF(to_jsonb(sq)->>'created_by', '')
        )
        LEFT JOIN currencies cur ON cur.id::text = NULLIF(to_jsonb(sq)->>'currency_id', '')
        LEFT JOIN price_lists pl ON pl.id::text = NULLIF(to_jsonb(sq)->>'price_list_id', '')
        LEFT JOIN invoice_master im ON im.id::text = NULLIF(to_jsonb(sq)->>'invoice_id', '')
        WHERE ${reportDateExpression} >= ${startDay}
          AND ${reportDateExpression} < ${endDay}
          AND sq.entity_id = ${entityId}
          AND sq.deleted_at IS NULL
      )
    `;

    const countResult = await db.execute(sql`
      ${quoteBaseRows}
      SELECT COUNT(*)::int AS "total" FROM base_quotes
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      ${quoteBaseRows}
      SELECT COALESCE(SUM("quoteAmount"), 0)::numeric AS "quoteAmount"
      FROM base_quotes
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const rowsResult = await db.execute(sql`
      ${quoteBaseRows}
      SELECT *
      FROM base_quotes
      ORDER BY "quoteDate" ASC, "quoteNumber" ASC, "quoteId" ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);
    const rows = this.rowsFromQueryResult(rowsResult).map((row: any) => ({
      quoteId: row.quoteId?.toString() || '',
      status: row.status?.toString() || 'draft',
      quoteDate: row.quoteDate,
      expiryDate: row.expiryDate,
      quoteNumber: row.quoteNumber?.toString() || '',
      referenceNumber: row.referenceNumber?.toString() || '',
      customerName: row.customerName?.toString() || '-',
      salespersonName: row.salespersonName?.toString() || '',
      currency: row.currency?.toString() || 'INR',
      priceListName: row.priceListName?.toString() || '',
      invoiceNumber: row.invoiceNumber?.toString() || '',
      projectName: row.projectName?.toString() || '',
      subject: row.subject?.toString() || '',
      quoteAmount: Number(row.quoteAmount || 0),
    }));

    return {
      basis: basis || "Accrual",
      reportBy: reportBy || "Quote Date",
      period: { startDate, endDate },
      rows,
      totals: {
        quoteAmount: Number(totalsRow.quoteAmount || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getTaxSummaryReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const entityId = tenant.entityId;
    const startIso = start.toISOString();
    const endIso = endExclusive.toISOString();
    const startDay = startIso.substring(0, 10);
    const endDay = endIso.substring(0, 10);

    const taxableRows = sql`
      WITH taxable_rows AS (
        SELECT
          COALESCE(NULLIF(tr.tax_name, ''), CONCAT('Tax ', COALESCE(soi.tax_rate, 0)::text)) AS "taxName",
          COALESCE(soi.tax_rate, tr.tax_rate, 0)::numeric AS "taxPercentage",
          CASE
            WHEN LOWER(COALESCE(so.document_type, '')) LIKE '%credit%' THEN -ABS(COALESCE(soi.amount, 0))
            ELSE COALESCE(soi.amount, 0)
          END::numeric AS "taxableAmount",
          CASE
            WHEN LOWER(COALESCE(so.document_type, '')) LIKE '%credit%' THEN -ABS(COALESCE(soi.tax_amount, 0))
            ELSE COALESCE(soi.tax_amount, 0)
          END::numeric AS "taxAmount"
        FROM sales_order_items soi
        JOIN sales_orders so ON so.id = soi.sales_order_id
        LEFT JOIN tax_rates tr ON tr.id = soi.tax_id
        WHERE so.sale_date >= ${startIso}
          AND so.sale_date < ${endIso}
          AND so.entity_id = ${entityId}
          AND COALESCE(so.is_delete, false) = false
          AND COALESCE(soi.tax_amount, 0) <> 0

        UNION ALL

        SELECT
          COALESCE(NULLIF(tr.tax_name, ''), CONCAT('Tax ', COALESCE(bi.tax_percentage, 0)::text)) AS "taxName",
          COALESCE(bi.tax_percentage, tr.tax_rate, 0)::numeric AS "taxPercentage",
          COALESCE(bi.line_total, 0)::numeric AS "taxableAmount",
          COALESCE(bi.tax_amount, 0)::numeric AS "taxAmount"
        FROM bill_items bi
        JOIN bills b ON b.id = bi.bill_id
        LEFT JOIN tax_rates tr ON tr.id = bi.tax_id
        WHERE b.bill_date >= ${startDay}
          AND b.bill_date < ${endDay}
          AND b.entity_id = ${entityId}
          AND COALESCE(b.is_delete, false) = false
          AND COALESCE(bi.tax_amount, 0) <> 0

        UNION ALL

        SELECT
          COALESCE(NULLIF(tr.tax_name, ''), CONCAT('Tax ', COALESCE(tr.tax_rate, 0)::text)) AS "taxName",
          COALESCE(tr.tax_rate, 0)::numeric AS "taxPercentage",
          COALESCE(e.amount, 0)::numeric AS "taxableAmount",
          COALESCE(e.tax_amount, 0)::numeric AS "taxAmount"
        FROM expenses e
        LEFT JOIN tax_rates tr ON tr.id = e.tax_id
        WHERE e.expense_date >= ${startDay}
          AND e.expense_date < ${endDay}
          AND e.entity_id = ${entityId}
          AND COALESCE(e.is_delete, false) = false
          AND COALESCE(e.tax_amount, 0) <> 0
      ),
      grouped_rows AS (
        SELECT
          "taxName",
          "taxPercentage",
          SUM("taxableAmount")::numeric AS "taxableAmount",
          SUM("taxAmount")::numeric AS "taxAmount"
        FROM taxable_rows
        GROUP BY "taxName", "taxPercentage"
      )
    `;

    const countResult = await db.execute(sql`
      ${taxableRows}
      SELECT COUNT(*)::int AS "total" FROM grouped_rows
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      ${taxableRows}
      SELECT
        COALESCE(SUM("taxableAmount"), 0)::numeric AS "taxableAmount",
        COALESCE(SUM("taxAmount"), 0)::numeric AS "taxAmount"
      FROM grouped_rows
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const rowsResult = await db.execute(sql`
      ${taxableRows}
      SELECT
        "taxName",
        "taxPercentage",
        "taxableAmount",
        "taxAmount"
      FROM grouped_rows
      ORDER BY "taxName" ASC, "taxPercentage" ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);

    const rows = this.rowsFromQueryResult(rowsResult).map((row: any) => ({
      taxName: row.taxName?.toString() || '-',
      taxPercentage: Number(row.taxPercentage || 0),
      taxableAmount: Number(row.taxableAmount || 0),
      taxAmount: Number(row.taxAmount || 0),
    }));

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      rows,
      totals: {
        taxableAmount: Number(totalsRow.taxableAmount || 0),
        taxAmount: Number(totalsRow.taxAmount || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getPurchaseOrdersByVendorReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const startIso = start.toISOString();
    const endIso = endExclusive.toISOString();
    const startDay = startIso.substring(0, 10);
    const endDay = endIso.substring(0, 10);
    const entityId = tenant.entityId;

    const purchaseOrderBaseRows = sql`
      WITH base_orders AS (
        SELECT
          po.id AS "purchaseOrderId",
          po.vendor_id::text AS "vendorId",
          COALESCE(
            NULLIF(v.display_name, ''),
            NULLIF(v.company_name, ''),
            po.vendor_id::text,
            'Others'
          ) AS "vendorName",
          COALESCE(NULLIF(po.status, ''), 'Draft') AS "status",
          po.order_date AS "orderDate",
          po.expected_delivery_date AS "expectedDeliveryDate",
          COALESCE(NULLIF(po.order_number, ''), po.id::text) AS "purchaseOrderNumber",
          COALESCE(NULLIF(po.reference_number, ''), '') AS "referenceNumber",
          COALESCE(NULLIF(w.name, ''), '') AS "warehouseName",
          COALESCE(NULLIF(pt.term_name, ''), '') AS "paymentTerms",
          COALESCE(NULLIF(to_jsonb(po)->>'shipment_preference', ''), NULLIF(to_jsonb(po)->>'shipment_preference_id', ''), '') AS "shipmentPreference",
          COALESCE(NULLIF(po.currency, ''), 'INR') AS "currency",
          COALESCE(po.subtotal, 0)::numeric AS "subtotal",
          COALESCE(po.tax_amount, 0)::numeric AS "taxAmount",
          COALESCE(po.tds_tcs_amount, 0)::numeric AS "tdsTcsAmount",
          COALESCE(po.adjustment, 0)::numeric AS "adjustment",
          COALESCE(po.total, 0)::numeric AS "grandTotal"
        FROM purchase_orders po
        LEFT JOIN vendors v ON v.id = po.vendor_id
        LEFT JOIN warehouses w ON w.id = po.warehouse_id
        LEFT JOIN payment_terms pt ON pt.id::text = COALESCE(to_jsonb(po)->>'payment_terms_id', to_jsonb(po)->>'payment_term_id')
        WHERE po.order_date >= ${startDay}
          AND po.order_date < ${endDay}
          AND po.entity_id = ${entityId}
          AND COALESCE(po.is_delete, false) = false
      ),
      vendor_groups AS (
        SELECT
          "vendorId",
          MIN("vendorName") AS "vendorName",
          COUNT(*)::int AS "purchaseOrderCount",
          COALESCE(SUM("subtotal"), 0)::numeric AS "subtotal",
          COALESCE(SUM("taxAmount"), 0)::numeric AS "taxAmount",
          COALESCE(SUM("tdsTcsAmount"), 0)::numeric AS "tdsTcsAmount",
          COALESCE(SUM("adjustment"), 0)::numeric AS "adjustment",
          COALESCE(SUM("grandTotal"), 0)::numeric AS "grandTotal"
        FROM base_orders
        GROUP BY "vendorId"
      )
    `;

    const countResult = await db.execute(sql`
      ${purchaseOrderBaseRows}
      SELECT COUNT(*)::int AS "total" FROM vendor_groups
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      ${purchaseOrderBaseRows}
      SELECT
        COALESCE(SUM("purchaseOrderCount"), 0)::int AS "purchaseOrderCount",
        COALESCE(SUM("subtotal"), 0)::numeric AS "subtotal",
        COALESCE(SUM("taxAmount"), 0)::numeric AS "taxAmount",
        COALESCE(SUM("tdsTcsAmount"), 0)::numeric AS "tdsTcsAmount",
        COALESCE(SUM("adjustment"), 0)::numeric AS "adjustment",
        COALESCE(SUM("grandTotal"), 0)::numeric AS "grandTotal"
      FROM vendor_groups
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const groupsResult = await db.execute(sql`
      ${purchaseOrderBaseRows}
      SELECT *
      FROM vendor_groups
      ORDER BY "vendorName" ASC, "vendorId" ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);
    const vendorGroups = this.rowsFromQueryResult(groupsResult);
    const vendorIds = vendorGroups
      .map((row: any) => row.vendorId?.toString())
      .filter(Boolean);

    let orderRows: Record<string, any>[] = [];
    if (vendorIds.length > 0) {
      const ordersResult = await db.execute(sql`
        ${purchaseOrderBaseRows}
        SELECT base_orders.*
        FROM base_orders
        WHERE "vendorId" IN (${sql.join(vendorIds.map((id) => sql`${id}`), sql`, `)})
        ORDER BY "vendorName" ASC, "orderDate" ASC, "purchaseOrderNumber" ASC, "purchaseOrderId" ASC
      `);
      orderRows = this.rowsFromQueryResult(ordersResult);
    }

    const ordersByVendor = new Map<string, any[]>();
    for (const row of orderRows) {
      const vendorId = row.vendorId?.toString() || '';
      if (!ordersByVendor.has(vendorId)) ordersByVendor.set(vendorId, []);
      ordersByVendor.get(vendorId)!.push({
        purchaseOrderId: row.purchaseOrderId?.toString() || '',
        status: row.status?.toString() || 'Draft',
        orderDate: row.orderDate,
        expectedDeliveryDate: row.expectedDeliveryDate,
        purchaseOrderNumber: row.purchaseOrderNumber?.toString() || '',
        referenceNumber: row.referenceNumber?.toString() || '',
        warehouseName: row.warehouseName?.toString() || '',
        paymentTerms: row.paymentTerms?.toString() || '',
        shipmentPreference: row.shipmentPreference?.toString() || '',
        currency: row.currency?.toString() || 'INR',
        subtotal: Number(row.subtotal || 0),
        taxAmount: Number(row.taxAmount || 0),
        tdsTcsAmount: Number(row.tdsTcsAmount || 0),
        adjustment: Number(row.adjustment || 0),
        grandTotal: Number(row.grandTotal || 0),
      });
    }

    const groups = vendorGroups.map((row: any) => {
      const vendorId = row.vendorId?.toString() || '';
      return {
        vendorId,
        vendorName: row.vendorName?.toString() || 'Others',
        purchaseOrderCount: Number(row.purchaseOrderCount || 0),
        totals: {
          subtotal: Number(row.subtotal || 0),
          taxAmount: Number(row.taxAmount || 0),
          tdsTcsAmount: Number(row.tdsTcsAmount || 0),
          adjustment: Number(row.adjustment || 0),
          grandTotal: Number(row.grandTotal || 0),
        },
        purchaseOrders: ordersByVendor.get(vendorId) ?? [],
      };
    });

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      groups,
      rows: groups,
      totals: {
        purchaseOrderCount: Number(totalsRow.purchaseOrderCount || 0),
        subtotal: Number(totalsRow.subtotal || 0),
        taxAmount: Number(totalsRow.taxAmount || 0),
        tdsTcsAmount: Number(totalsRow.tdsTcsAmount || 0),
        adjustment: Number(totalsRow.adjustment || 0),
        grandTotal: Number(totalsRow.grandTotal || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getPurchaseOrdersByItemReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 200,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 200);
    const requestedPage = Math.max(1, Number(page) || 1);
    const startIso = start.toISOString();
    const endIso = endExclusive.toISOString();
    const startDay = startIso.substring(0, 10);
    const endDay = endIso.substring(0, 10);
    const entityId = tenant.entityId;

    const purchaseOrderItemRows = sql`
      WITH base_items AS (
        SELECT
          poi.id AS "purchaseOrderItemId",
          po.id AS "purchaseOrderId",
          COALESCE(NULLIF(po.order_number, ''), po.id::text) AS "purchaseOrderNumber",
          po.order_date AS "orderDate",
          COALESCE(NULLIF(po.status, ''), 'Draft') AS "status",
          COALESCE(
            NULLIF(v.display_name, ''),
            NULLIF(v.company_name, ''),
            po.vendor_id::text,
            '-'
          ) AS "vendorName",
          COALESCE(
            NULLIF(p.product_name, ''),
            NULLIF(p.billing_name, ''),
            NULLIF(poi.description, ''),
            poi.product_id::text,
            '-'
          ) AS "itemName",
          COALESCE(poi.quantity, 0)::numeric AS "quantityOrdered",
          COALESCE(poi.cancelled_quantity, 0)::numeric AS "quantityCancelled",
          COALESCE(
            NULLIF(to_jsonb(poi)->>'quantity_billed', '')::numeric,
            NULLIF(to_jsonb(poi)->>'billed_quantity', '')::numeric,
            NULLIF(to_jsonb(poi)->>'received_quantity', '')::numeric,
            0
          )::numeric AS "quantityBilled",
          COALESCE(poi.rate, 0)::numeric AS "rate",
          COALESCE(poi.tax_amount, 0)::numeric AS "taxAmount",
          COALESCE(poi.discount, 0)::numeric AS "discount",
          COALESCE(poi.amount, 0)::numeric AS "amount",
          COALESCE(NULLIF(w.name, ''), '') AS "warehouseLocationName",
          COALESCE(NULLIF(obm.name, ''), '') AS "location"
        FROM purchase_order_items poi
        JOIN purchase_orders po ON po.id = poi.purchase_order_id
        LEFT JOIN products p ON p.id = poi.product_id
        LEFT JOIN vendors v ON v.id = po.vendor_id
        LEFT JOIN warehouses w ON w.id = po.warehouse_id
        LEFT JOIN organisation_branch_master obm ON obm.id = po.entity_id
        WHERE po.order_date >= ${startDay}
          AND po.order_date < ${endDay}
          AND po.entity_id = ${entityId}
          AND poi.entity_id = ${entityId}
          AND COALESCE(po.is_delete, false) = false
          AND COALESCE(poi.is_header, false) = false
      )
    `;

    const countResult = await db.execute(sql`
      ${purchaseOrderItemRows}
      SELECT COUNT(*)::int AS "total" FROM base_items
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      ${purchaseOrderItemRows}
      SELECT
        COALESCE(SUM("quantityOrdered"), 0)::numeric AS "quantityOrdered",
        COALESCE(SUM("quantityCancelled"), 0)::numeric AS "quantityCancelled",
        COALESCE(SUM("quantityBilled"), 0)::numeric AS "quantityBilled",
        COALESCE(SUM("amount"), 0)::numeric AS "amount"
      FROM base_items
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const rowsResult = await db.execute(sql`
      ${purchaseOrderItemRows}
      SELECT *
      FROM base_items
      ORDER BY "orderDate" ASC, "purchaseOrderNumber" ASC, "itemName" ASC, "purchaseOrderItemId" ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);

    const rows = this.rowsFromQueryResult(rowsResult).map((row: any) => ({
      purchaseOrderItemId: row.purchaseOrderItemId?.toString() || '',
      purchaseOrderId: row.purchaseOrderId?.toString() || '',
      purchaseOrderNumber: row.purchaseOrderNumber?.toString() || '',
      orderDate: row.orderDate,
      status: row.status?.toString() || 'Draft',
      vendorName: row.vendorName?.toString() || '-',
      itemName: row.itemName?.toString() || '-',
      quantityOrdered: Number(row.quantityOrdered || 0),
      quantityCancelled: Number(row.quantityCancelled || 0),
      quantityBilled: Number(row.quantityBilled || 0),
      rate: Number(row.rate || 0),
      taxAmount: Number(row.taxAmount || 0),
      discount: Number(row.discount || 0),
      amount: Number(row.amount || 0),
      warehouseLocationName: row.warehouseLocationName?.toString() || '',
      location: row.location?.toString() || '',
    }));

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      rows,
      totals: {
        quantityOrdered: Number(totalsRow.quantityOrdered || 0),
        quantityCancelled: Number(totalsRow.quantityCancelled || 0),
        quantityBilled: Number(totalsRow.quantityBilled || 0),
        amount: Number(totalsRow.amount || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getPaymentsMadeReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const startDay = start.toISOString().substring(0, 10);
    const endDay = endExclusive.toISOString().substring(0, 10);
    const entityId = tenant.entityId?.toString() || "";

    const masterTextValue = (alias: string, keys: string[]) => sql`COALESCE(${sql.join(
      keys.map((key) => sql`NULLIF(to_jsonb(${sql.raw(alias)})->>${key}, '')`),
      sql`, `,
    )})`;
    const masterNumericValue = (alias: string, keys: string[]) => sql`CASE
      WHEN COALESCE(${sql.join(
        keys.map((key) => sql`NULLIF(to_jsonb(${sql.raw(alias)})->>${key}, '')`),
        sql`, `,
      )}) ~ '^-?[0-9]+([.][0-9]+)?$'
      THEN COALESCE(${sql.join(
        keys.map((key) => sql`NULLIF(to_jsonb(${sql.raw(alias)})->>${key}, '')`),
        sql`, `,
      )})::numeric
      ELSE 0::numeric
    END`;

    const paymentDateExpression = sql`COALESCE(
      NULLIF(to_jsonb(pm)->>'payment_date', '')::date,
      NULLIF(to_jsonb(pm)->>'date', '')::date,
      NULLIF(to_jsonb(pm)->>'created_at', '')::timestamp::date
    )`;
    const paymentAmountExpression = masterNumericValue('pm', [
      'payment_amount',
      'amount',
      'total_amount',
      'paid_amount',
    ]);
    const amountFcyExpression = masterNumericValue('pm', [
      'amount_fcy',
      'payment_amount_fcy',
      'foreign_currency_amount',
      'payment_amount',
      'amount',
      'total_amount',
    ]);
    const totalRefundedExpression = masterNumericValue('pm', [
      'total_refunded',
      'amount_refunded',
      'refunded_amount',
    ]);
    const excessAmountExpression = masterNumericValue('pm', [
      'excess_amount',
      'unused_amount_bcy',
      'unused_amount',
      'balance_amount',
    ]);
    const excessAmountFcyExpression = masterNumericValue('pm', [
      'excess_amount_fcy',
      'unused_amount_fcy',
      'foreign_currency_unused_amount',
      'excess_amount',
      'unused_amount_bcy',
      'unused_amount',
      'balance_amount',
    ]);
    const allocationPaymentIdExpression = masterTextValue('alloc', [
      'payment_made_id',
      'payment_id',
      'payment_made_master_id',
      'payment_made_master',
    ]);
    const allocationBillIdExpression = masterTextValue('alloc', ['bill_id']);
    const allocationAmountExpression = masterNumericValue('alloc', [
      'amount',
      'allocated_amount',
      'payment_amount',
      'amount_applied',
      'applied_amount',
    ]);

    const paymentsMadeBaseRows = sql`
      WITH allocation_rows AS (
        SELECT
          ${allocationPaymentIdExpression} AS "paymentId",
          ${allocationBillIdExpression} AS "billId",
          ${allocationAmountExpression} AS "allocatedAmount"
        FROM payment_made_bill_allocations alloc
      ),
      allocation_summary AS (
        SELECT
          ar."paymentId",
          string_agg(
            DISTINCT COALESCE(NULLIF(b.bill_number, ''), ar."billId", ''),
            ','
          ) AS "billNumbers",
          COALESCE(SUM(ar."allocatedAmount"), 0)::numeric AS "totalAllocated"
        FROM allocation_rows ar
        LEFT JOIN bills b ON b.id::text = ar."billId"
        WHERE ar."paymentId" IS NOT NULL
        GROUP BY ar."paymentId"
      ),
      base_payments AS (
        SELECT
          pm.id AS "paymentMadeId",
          ${paymentDateExpression} AS "paymentDate",
          COALESCE(
            ${masterTextValue('pm', ['payment_number', 'payment_made_number', 'number'])},
            pm.id::text
          ) AS "paymentNumber",
          COALESCE(${masterTextValue('pm', ['reference_number', 'reference'])}, '') AS "referenceNumber",
          COALESCE(NULLIF(alloc."billNumbers", ''), '') AS "billNumber",
          COALESCE(
            NULLIF(v.display_name, ''),
            NULLIF(v.company_name, ''),
            ${masterTextValue('pm', ['vendor_name'])},
            ${masterTextValue('pm', ['vendor_id'])},
            '-'
          ) AS "vendorName",
          COALESCE(${masterTextValue('pm', ['payment_type', 'type'])}, 'Vendor Payment') AS "paymentType",
          COALESCE(
            NULLIF(to_jsonb(mode)->>'name', ''),
            NULLIF(to_jsonb(mode)->>'payment_mode', ''),
            NULLIF(to_jsonb(mode)->>'mode_name', ''),
            ${masterTextValue('pm', ['payment_mode'])},
            '-'
          ) AS "paymentMode",
          COALESCE(${masterTextValue('pm', ['notes', 'note', 'description'])}, '') AS "notes",
          COALESCE(
            NULLIF(paid_account.user_account_name, ''),
            NULLIF(paid_account.system_account_name, ''),
            NULLIF(paid_account.account_code, ''),
            ${masterTextValue('pm', ['paid_through', 'paid_through_account', 'deposit_to'])},
            '-'
          ) AS "paidThrough",
          COALESCE(
            NULLIF(deposit_account.user_account_name, ''),
            NULLIF(deposit_account.system_account_name, ''),
            NULLIF(deposit_account.account_code, ''),
            ${masterTextValue('pm', ['deposit_to', 'deposit_to_account'])},
            ''
          ) AS "depositTo",
          COALESCE(${masterTextValue('pm', ['status'])}, 'Paid') AS "status",
          COALESCE(${paymentAmountExpression}, 0)::numeric AS "paymentAmount",
          COALESCE(${amountFcyExpression}, ${paymentAmountExpression}, 0)::numeric AS "amountFcy",
          COALESCE(alloc."totalAllocated", 0)::numeric AS "totalAllocated",
          COALESCE(${totalRefundedExpression}, 0)::numeric AS "totalRefunded",
          COALESCE(${excessAmountExpression}, 0)::numeric AS "excessAmount",
          COALESCE(${excessAmountFcyExpression}, ${excessAmountExpression}, 0)::numeric AS "excessAmountFcy"
        FROM payment_made_master pm
        LEFT JOIN allocation_summary alloc ON alloc."paymentId" = pm.id::text
        LEFT JOIN vendors v ON v.id::text = ${masterTextValue('pm', ['vendor_id'])}
        LEFT JOIN accounts paid_account ON paid_account.id::text = COALESCE(
          ${masterTextValue('pm', ['paid_through_account_id', 'paid_through_id', 'paid_through'])},
          ${masterTextValue('pm', ['deposit_account_id'])}
        )
        LEFT JOIN accounts deposit_account ON deposit_account.id::text = ${masterTextValue('pm', ['deposit_to_account_id', 'deposit_account_id'])}
        LEFT JOIN payment_made_payment_mode mode ON mode.id::text = ${masterTextValue('pm', ['payment_mode_id'])}
        WHERE ${paymentDateExpression} >= ${startDay}
          AND ${paymentDateExpression} < ${endDay}
          AND COALESCE(to_jsonb(pm)->>'entity_id', '') = ${entityId}
          AND COALESCE(NULLIF(to_jsonb(pm)->>'is_deleted', '')::boolean, false) = false
      )
    `;

    const countResult = await db.execute(sql`
      ${paymentsMadeBaseRows}
      SELECT COUNT(*)::int AS "total" FROM base_payments
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      ${paymentsMadeBaseRows}
      SELECT
        COALESCE(SUM("paymentAmount"), 0)::numeric AS "paymentAmount",
        COALESCE(SUM("amountFcy"), 0)::numeric AS "amountFcy",
        COALESCE(SUM("totalAllocated"), 0)::numeric AS "totalAllocated",
        COALESCE(SUM("totalRefunded"), 0)::numeric AS "totalRefunded",
        COALESCE(SUM("excessAmount"), 0)::numeric AS "excessAmount",
        COALESCE(SUM("excessAmountFcy"), 0)::numeric AS "excessAmountFcy"
      FROM base_payments
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const rowsResult = await db.execute(sql`
      ${paymentsMadeBaseRows}
      SELECT *
      FROM base_payments
      ORDER BY "paymentDate" ASC, "paymentNumber" ASC, "paymentMadeId" ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);
    const rows = this.rowsFromQueryResult(rowsResult).map((row: any) => ({
      paymentMadeId: row.paymentMadeId?.toString() || '',
      paymentDate: row.paymentDate,
      paymentNumber: row.paymentNumber?.toString() || '',
      referenceNumber: row.referenceNumber?.toString() || '',
      billNumber: row.billNumber?.toString() || '',
      vendorName: row.vendorName?.toString() || '-',
      paymentType: row.paymentType?.toString() || 'Vendor Payment',
      paymentMode: row.paymentMode?.toString() || '-',
      notes: row.notes?.toString() || '',
      paidThrough: row.paidThrough?.toString() || '-',
      depositTo: row.depositTo?.toString() || '',
      status: row.status?.toString() || 'Paid',
      paymentAmount: Number(row.paymentAmount || 0),
      amountFcy: Number(row.amountFcy || 0),
      totalAllocated: Number(row.totalAllocated || 0),
      totalRefunded: Number(row.totalRefunded || 0),
      excessAmount: Number(row.excessAmount || 0),
      excessAmountFcy: Number(row.excessAmountFcy || 0),
    }));

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      rows,
      totals: {
        paymentAmount: Number(totalsRow.paymentAmount || 0),
        amountFcy: Number(totalsRow.amountFcy || 0),
        totalAllocated: Number(totalsRow.totalAllocated || 0),
        totalRefunded: Number(totalsRow.totalRefunded || 0),
        excessAmount: Number(totalsRow.excessAmount || 0),
        excessAmountFcy: Number(totalsRow.excessAmountFcy || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getPurchaseOrderDetailsReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const startIso = start.toISOString();
    const endIso = endExclusive.toISOString();
    const startDay = startIso.substring(0, 10);
    const endDay = endIso.substring(0, 10);
    const entityId = tenant.entityId;

    const purchaseOrderRows = sql`
      WITH base_orders AS (
        SELECT
          po.id AS "purchaseOrderId",
          COALESCE(NULLIF(po.status, ''), 'Draft') AS "status",
          po.order_date AS "orderDate",
          po.expected_delivery_date AS "expectedDeliveryDate",
          COALESCE(NULLIF(po.order_number, ''), po.id::text) AS "purchaseOrderNumber",
          COALESCE(NULLIF(po.reference_number, ''), '') AS "referenceNumber",
          COALESCE(
            NULLIF(v.display_name, ''),
            NULLIF(v.company_name, ''),
            po.vendor_id::text,
            '-'
          ) AS "vendorName",
          COALESCE(NULLIF(w.name, ''), '') AS "warehouseName",
          COALESCE(NULLIF(pt.term_name, ''), '') AS "paymentTerms",
          COALESCE(NULLIF(to_jsonb(po)->>'shipment_preference', ''), NULLIF(to_jsonb(po)->>'shipment_preference_id', ''), '') AS "shipmentPreference",
          COALESCE(NULLIF(po.currency, ''), 'INR') AS "currency",
          COALESCE(po.subtotal, 0)::numeric AS "subtotal",
          COALESCE(po.tax_amount, 0)::numeric AS "taxAmount",
          COALESCE(po.tds_tcs_amount, 0)::numeric AS "tdsTcsAmount",
          COALESCE(po.adjustment, 0)::numeric AS "adjustment",
          COALESCE(po.total, 0)::numeric AS "grandTotal"
        FROM purchase_orders po
        LEFT JOIN vendors v ON v.id = po.vendor_id
        LEFT JOIN warehouses w ON w.id = po.warehouse_id
        LEFT JOIN payment_terms pt ON pt.id::text = COALESCE(to_jsonb(po)->>'payment_terms_id', to_jsonb(po)->>'payment_term_id')
        WHERE po.order_date >= ${startDay}
          AND po.order_date < ${endDay}
          AND po.entity_id = ${entityId}
          AND COALESCE(po.is_delete, false) = false
      )
    `;

    const countResult = await db.execute(sql`
      ${purchaseOrderRows}
      SELECT COUNT(*)::int AS "total" FROM base_orders
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      ${purchaseOrderRows}
      SELECT
        COALESCE(SUM("subtotal"), 0)::numeric AS "subtotal",
        COALESCE(SUM("taxAmount"), 0)::numeric AS "taxAmount",
        COALESCE(SUM("tdsTcsAmount"), 0)::numeric AS "tdsTcsAmount",
        COALESCE(SUM("adjustment"), 0)::numeric AS "adjustment",
        COALESCE(SUM("grandTotal"), 0)::numeric AS "grandTotal"
      FROM base_orders
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const rowsResult = await db.execute(sql`
      ${purchaseOrderRows}
      SELECT *
      FROM base_orders
      ORDER BY "orderDate" ASC, "purchaseOrderNumber" ASC, "purchaseOrderId" ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);

    const rows = this.rowsFromQueryResult(rowsResult).map((row: any) => ({
      purchaseOrderId: row.purchaseOrderId?.toString() || '',
      status: row.status?.toString() || 'Draft',
      orderDate: row.orderDate,
      expectedDeliveryDate: row.expectedDeliveryDate,
      purchaseOrderNumber: row.purchaseOrderNumber?.toString() || '',
      referenceNumber: row.referenceNumber?.toString() || '',
      vendorName: row.vendorName?.toString() || '-',
      warehouseName: row.warehouseName?.toString() || '',
      paymentTerms: row.paymentTerms?.toString() || '',
      shipmentPreference: row.shipmentPreference?.toString() || '',
      currency: row.currency?.toString() || 'INR',
      subtotal: Number(row.subtotal || 0),
      taxAmount: Number(row.taxAmount || 0),
      tdsTcsAmount: Number(row.tdsTcsAmount || 0),
      adjustment: Number(row.adjustment || 0),
      grandTotal: Number(row.grandTotal || 0),
    }));

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      rows,
      totals: {
        subtotal: Number(totalsRow.subtotal || 0),
        taxAmount: Number(totalsRow.taxAmount || 0),
        tdsTcsAmount: Number(totalsRow.tdsTcsAmount || 0),
        adjustment: Number(totalsRow.adjustment || 0),
        grandTotal: Number(totalsRow.grandTotal || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getSalesOrderDetailsReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    status?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const startIso = start.toISOString();
    const endIso = endExclusive.toISOString();
    const entityId = tenant.entityId;
    const statusValues = (status || '')
      .split(',')
      .map((value) => value.trim().toLowerCase())
      .filter(Boolean);
    const statusFilter = statusValues.length > 0
      ? sql`AND LOWER(COALESCE(so.status, '')) IN (${sql.join(statusValues.map((value) => sql`${value}`), sql`, `)})`
      : sql``;

    const salesOrderRows = sql`
      WITH base_orders AS (
        SELECT
          so.id AS "salesOrderId",
          COALESCE(NULLIF(so.status, ''), 'Draft') AS "status",
          so.sale_date AS "date",
          so.expected_shipment_date AS "expectedShipmentDate",
          COALESCE(NULLIF(so.sale_number, ''), so.id::text) AS "salesOrderNumber",
          COALESCE(NULLIF(so.reference, ''), '') AS "reference",
          COALESCE(
            NULLIF(c.display_name, ''),
            NULLIF(c.company_name, ''),
            so.customer_id::text,
            '-'
          ) AS "customerName",
          COALESCE(NULLIF(w.name, ''), NULLIF(so.warehouse_name, ''), '') AS "warehouseName",
          COALESCE(NULLIF(pt.term_name, ''), NULLIF(so.payment_terms, ''), '') AS "paymentTerms",
          COALESCE(NULLIF(pl.name, ''), '') AS "priceListName",
          COALESCE(NULLIF(so.salesperson_name, ''), '') AS "salespersonName",
          COALESCE(NULLIF(obm.name, ''), '') AS "location",
          COALESCE(NULLIF(so.currency, ''), 'INR') AS "currency",
          COALESCE(so.sub_total, 0)::numeric AS "subTotal",
          COALESCE(so.tax_total, 0)::numeric AS "taxTotal",
          COALESCE(so.discount_total, 0)::numeric AS "discount",
          COALESCE(so.shipping_charges, 0)::numeric AS "shippingCharges",
          COALESCE(so.adjustment, 0)::numeric AS "adjustment",
          COALESCE(so.total, 0)::numeric AS "grandTotal"
        FROM sales_orders so
        LEFT JOIN customers c ON c.id = so.customer_id
        LEFT JOIN warehouses w ON w.id = so.warehouse_id
        LEFT JOIN payment_terms pt ON pt.id = so.payment_term_id
        LEFT JOIN price_lists pl ON pl.id = so.price_list_id
        LEFT JOIN organisation_branch_master obm ON obm.id = so.entity_id
        WHERE so.sale_date >= ${startIso}
          AND so.sale_date < ${endIso}
          AND so.entity_id = ${entityId}
          AND COALESCE(so.is_delete, false) = false
          ${statusFilter}
      )
    `;

    const countResult = await db.execute(sql`
      ${salesOrderRows}
      SELECT COUNT(*)::int AS "total" FROM base_orders
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      ${salesOrderRows}
      SELECT
        COALESCE(SUM("subTotal"), 0)::numeric AS "subTotal",
        COALESCE(SUM("taxTotal"), 0)::numeric AS "taxTotal",
        COALESCE(SUM("discount"), 0)::numeric AS "discount",
        COALESCE(SUM("shippingCharges"), 0)::numeric AS "shippingCharges",
        COALESCE(SUM("adjustment"), 0)::numeric AS "adjustment",
        COALESCE(SUM("grandTotal"), 0)::numeric AS "grandTotal"
      FROM base_orders
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const rowsResult = await db.execute(sql`
      ${salesOrderRows}
      SELECT *
      FROM base_orders
      ORDER BY "date" ASC, "salesOrderNumber" ASC, "salesOrderId" ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);

    const rows = this.rowsFromQueryResult(rowsResult).map((row: any) => ({
      salesOrderId: row.salesOrderId?.toString() || '',
      status: row.status?.toString() || 'Draft',
      date: row.date,
      expectedShipmentDate: row.expectedShipmentDate,
      salesOrderNumber: row.salesOrderNumber?.toString() || '',
      reference: row.reference?.toString() || '',
      customerName: row.customerName?.toString() || '-',
      warehouseName: row.warehouseName?.toString() || '',
      paymentTerms: row.paymentTerms?.toString() || '',
      priceListName: row.priceListName?.toString() || '',
      salespersonName: row.salespersonName?.toString() || '',
      location: row.location?.toString() || '',
      currency: row.currency?.toString() || 'INR',
      subTotal: Number(row.subTotal || 0),
      taxTotal: Number(row.taxTotal || 0),
      discount: Number(row.discount || 0),
      shippingCharges: Number(row.shippingCharges || 0),
      adjustment: Number(row.adjustment || 0),
      grandTotal: Number(row.grandTotal || 0),
    }));

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      rows,
      totals: {
        subTotal: Number(totalsRow.subTotal || 0),
        taxTotal: Number(totalsRow.taxTotal || 0),
        discount: Number(totalsRow.discount || 0),
        shippingCharges: Number(totalsRow.shippingCharges || 0),
        adjustment: Number(totalsRow.adjustment || 0),
        grandTotal: Number(totalsRow.grandTotal || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getDeliveryChallanDetailsReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const startIso = start.toISOString();
    const endIso = endExclusive.toISOString();
    const entityId = tenant.entityId;
    const challanDate = sql`COALESCE(
      NULLIF(to_jsonb(dc)->>'challan_date', '')::timestamp,
      NULLIF(to_jsonb(dc)->>'delivery_challan_date', '')::timestamp,
      NULLIF(to_jsonb(dc)->>'delivery_date', '')::timestamp,
      NULLIF(to_jsonb(dc)->>'date', '')::timestamp,
      NULLIF(to_jsonb(dc)->>'created_at', '')::timestamp
    )`;
    const grandTotal = sql`COALESCE(
      NULLIF(to_jsonb(dc)->>'grand_total', '')::numeric,
      NULLIF(to_jsonb(dc)->>'total', '')::numeric,
      0
    )`;

    const deliveryChallanRows = sql`
      WITH base_challans AS (
        SELECT
          dc.id AS "deliveryChallanId",
          COALESCE(
            NULLIF(to_jsonb(dc)->>'challan_number', ''),
            NULLIF(to_jsonb(dc)->>'delivery_challan_number', ''),
            NULLIF(to_jsonb(dc)->>'dc_number', ''),
            NULLIF(to_jsonb(dc)->>'reference_number', ''),
            dc.id::text
          ) AS "deliveryChallanNumber",
          ${challanDate} AS "date",
          COALESCE(NULLIF(to_jsonb(dc)->>'reference_number', ''), NULLIF(to_jsonb(dc)->>'reference', ''), '') AS "referenceNumber",
          COALESCE(NULLIF(to_jsonb(dc)->>'status', ''), 'Draft') AS "status",
          COALESCE(
            NULLIF(to_jsonb(dc)->>'invoice_status', ''),
            NULLIF(to_jsonb(dc)->>'invoicing_status', ''),
            'Not Invoiced'
          ) AS "invoiceStatus",
          COALESCE(
            NULLIF(c.display_name, ''),
            NULLIF(c.company_name, ''),
            NULLIF(to_jsonb(dc)->>'customer_name', ''),
            NULLIF(to_jsonb(dc)->>'customer_id', ''),
            '-'
          ) AS "customerName",
          COALESCE(NULLIF(w.name, ''), NULLIF(to_jsonb(dc)->>'warehouse_name', ''), '') AS "warehouseName",
          COALESCE(NULLIF(pl.name, ''), '') AS "priceListName",
          COALESCE(NULLIF(to_jsonb(dc)->>'challan_type', ''), NULLIF(to_jsonb(dc)->>'delivery_challan_type', ''), '') AS "challanType",
          COALESCE(NULLIF(to_jsonb(dc)->>'place_of_supply', ''), '') AS "placeOfSupply",
          COALESCE(NULLIF(to_jsonb(dc)->>'inventory_flow_type', ''), '') AS "inventoryFlowType",
          COALESCE(NULLIF(obm.name, ''), '') AS "location",
          COALESCE(NULLIF(to_jsonb(dc)->>'currency', ''), 'INR') AS "currency",
          COALESCE(NULLIF(to_jsonb(dc)->>'subtotal', '')::numeric, NULLIF(to_jsonb(dc)->>'sub_total', '')::numeric, 0) AS "subtotal",
          COALESCE(NULLIF(to_jsonb(dc)->>'tax_total', '')::numeric, NULLIF(to_jsonb(dc)->>'tax_amount', '')::numeric, 0) AS "taxTotal",
          COALESCE(NULLIF(to_jsonb(dc)->>'adjustment', '')::numeric, NULLIF(to_jsonb(dc)->>'adjustment_amount', '')::numeric, 0) AS "adjustment",
          COALESCE(NULLIF(to_jsonb(dc)->>'round_off', '')::numeric, 0) AS "roundOff",
          ${grandTotal} AS "grandTotal"
        FROM delivery_challans dc
        LEFT JOIN customers c ON c.id::text = NULLIF(to_jsonb(dc)->>'customer_id', '')
        LEFT JOIN warehouses w ON w.id::text = COALESCE(NULLIF(to_jsonb(dc)->>'warehouse_id', ''), NULLIF(to_jsonb(dc)->>'delivery_warehouse_id', ''))
        LEFT JOIN price_lists pl ON pl.id::text = NULLIF(to_jsonb(dc)->>'price_list_id', '')
        LEFT JOIN organisation_branch_master obm ON obm.id::text = NULLIF(to_jsonb(dc)->>'entity_id', '')
        WHERE ${challanDate} >= ${startIso}
          AND ${challanDate} < ${endIso}
          AND NULLIF(to_jsonb(dc)->>'entity_id', '') = ${entityId}
          AND COALESCE(
            NULLIF(to_jsonb(dc)->>'is_deleted', '')::boolean,
            NULLIF(to_jsonb(dc)->>'is_delete', '')::boolean,
            false
          ) = false
      )
    `;

    const countResult = await db.execute(sql`
      ${deliveryChallanRows}
      SELECT COUNT(*)::int AS "total" FROM base_challans
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      ${deliveryChallanRows}
      SELECT
        COALESCE(SUM("subtotal"), 0)::numeric AS "subtotal",
        COALESCE(SUM("taxTotal"), 0)::numeric AS "taxTotal",
        COALESCE(SUM("adjustment"), 0)::numeric AS "adjustment",
        COALESCE(SUM("roundOff"), 0)::numeric AS "roundOff",
        COALESCE(SUM("grandTotal"), 0)::numeric AS "grandTotal"
      FROM base_challans
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const rowsResult = await db.execute(sql`
      ${deliveryChallanRows}
      SELECT *
      FROM base_challans
      ORDER BY "date" ASC, "deliveryChallanNumber" ASC, "deliveryChallanId" ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);

    const rows = this.rowsFromQueryResult(rowsResult).map((row: any) => ({
      deliveryChallanId: row.deliveryChallanId?.toString() || '',
      deliveryChallanNumber: row.deliveryChallanNumber?.toString() || '',
      date: row.date,
      referenceNumber: row.referenceNumber?.toString() || '',
      status: row.status?.toString() || 'Draft',
      invoiceStatus: row.invoiceStatus?.toString() || 'Not Invoiced',
      customerName: row.customerName?.toString() || '-',
      warehouseName: row.warehouseName?.toString() || '',
      priceListName: row.priceListName?.toString() || '',
      challanType: row.challanType?.toString() || '',
      placeOfSupply: row.placeOfSupply?.toString() || '',
      inventoryFlowType: row.inventoryFlowType?.toString() || '',
      location: row.location?.toString() || '',
      currency: row.currency?.toString() || 'INR',
      subtotal: Number(row.subtotal || 0),
      taxTotal: Number(row.taxTotal || 0),
      adjustment: Number(row.adjustment || 0),
      roundOff: Number(row.roundOff || 0),
      grandTotal: Number(row.grandTotal || 0),
    }));

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      rows,
      totals: {
        subtotal: Number(totalsRow.subtotal || 0),
        taxTotal: Number(totalsRow.taxTotal || 0),
        adjustment: Number(totalsRow.adjustment || 0),
        roundOff: Number(totalsRow.roundOff || 0),
        grandTotal: Number(totalsRow.grandTotal || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getTdsSummaryReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const entityId = tenant.entityId;
    const startIso = start.toISOString();
    const endIso = endExclusive.toISOString();
    const startDay = startIso.substring(0, 10);
    const endDay = endIso.substring(0, 10);

    const tdsRows = sql`
      WITH tds_rows AS (
        SELECT
          COALESCE(NULLIF(tr.tax_name, ''), 'Uncategorized') AS "tdsSection",
          COALESCE(so.total, so.sub_total, 0)::numeric AS "total",
          (COALESCE(so.total, so.sub_total, 0) - COALESCE(so.tds_tcs_amount, 0))::numeric AS "totalAfterDeduction",
          COALESCE(so.tds_tcs_amount, 0)::numeric AS "tdsAmount"
        FROM sales_orders so
        LEFT JOIN tds_rates tr ON tr.id = so.tds_tcs_tax_id
        WHERE so.sale_date >= ${startIso}
          AND so.sale_date < ${endIso}
          AND so.entity_id = ${entityId}
          AND COALESCE(so.is_delete, false) = false
          AND LOWER(COALESCE(so.tds_tcs_type, 'TDS')) = 'tds'
          AND COALESCE(so.tds_tcs_amount, 0) <> 0

        UNION ALL

        SELECT
          COALESCE(NULLIF(tr.tax_name, ''), 'Uncategorized') AS "tdsSection",
          COALESCE(po.total, po.sub_total, 0)::numeric AS "total",
          (COALESCE(po.total, po.sub_total, 0) - COALESCE(po.tds_tcs_amount, 0))::numeric AS "totalAfterDeduction",
          COALESCE(po.tds_tcs_amount, 0)::numeric AS "tdsAmount"
        FROM purchase_orders po
        LEFT JOIN tds_rates tr ON tr.id = po.tds_tcs_tax_id
        WHERE po.purchase_date >= ${startIso}
          AND po.purchase_date < ${endIso}
          AND po.entity_id = ${entityId}
          AND COALESCE(po.is_delete, false) = false
          AND LOWER(COALESCE(po.tds_tcs_type, 'TDS')) = 'tds'
          AND COALESCE(po.tds_tcs_amount, 0) <> 0

        UNION ALL

        SELECT
          'Uncategorized' AS "tdsSection",
          COALESCE(b.grand_total, b.subtotal, 0)::numeric AS "total",
          (COALESCE(b.grand_total, b.subtotal, 0) - COALESCE(b.tds_total, 0))::numeric AS "totalAfterDeduction",
          COALESCE(b.tds_total, 0)::numeric AS "tdsAmount"
        FROM bills b
        WHERE b.bill_date >= ${startDay}
          AND b.bill_date < ${endDay}
          AND b.entity_id = ${entityId}
          AND COALESCE(b.is_delete, false) = false
          AND COALESCE(b.tds_total, 0) <> 0
      ),
      grouped_rows AS (
        SELECT
          "tdsSection",
          SUM("total")::numeric AS "total",
          SUM("totalAfterDeduction")::numeric AS "totalAfterDeduction",
          SUM("tdsAmount")::numeric AS "tdsAmount"
        FROM tds_rows
        GROUP BY "tdsSection"
      )
    `;

    const countResult = await db.execute(sql`
      ${tdsRows}
      SELECT COUNT(*)::int AS "total" FROM grouped_rows
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      ${tdsRows}
      SELECT
        COALESCE(SUM("total"), 0)::numeric AS "total",
        COALESCE(SUM("totalAfterDeduction"), 0)::numeric AS "totalAfterDeduction",
        COALESCE(SUM("tdsAmount"), 0)::numeric AS "tdsAmount"
      FROM grouped_rows
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const rowsResult = await db.execute(sql`
      ${tdsRows}
      SELECT
        "tdsSection",
        "total",
        "totalAfterDeduction",
        "tdsAmount"
      FROM grouped_rows
      ORDER BY "tdsSection" ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);

    const rows = this.rowsFromQueryResult(rowsResult).map((row: any) => ({
      tdsSection: row.tdsSection?.toString() || 'Uncategorized',
      total: Number(row.total || 0),
      totalAfterDeduction: Number(row.totalAfterDeduction || 0),
      tdsAmount: Number(row.tdsAmount || 0),
    }));

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      rows,
      totals: {
        total: Number(totalsRow.total || 0),
        totalAfterDeduction: Number(totalsRow.totalAfterDeduction || 0),
        tdsAmount: Number(totalsRow.tdsAmount || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getTrialBalanceReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
    basis?: string,
    page = 1,
    pageSize = 25,
  ) {
    const start = new Date(startDate);
    const endExclusive = new Date(endDate);
    endExclusive.setDate(endExclusive.getDate() + 1);
    const normalizedPageSize = Math.max(1, Number(pageSize) || 25);
    const requestedPage = Math.max(1, Number(page) || 1);
    const existingSourceTables = await this.getExistingPublicReportTables([
      "expenses",
      "bills",
      "purchase_orders",
      "purchase_receives",
      "invoices",
      "vendor_credits",
      "payments_received",
      "recurring_invoices",
      "journal_entries",
      "manual_journals",
      "inventory_adjustments",
    ]);
    const sourceValidationCondition =
      this.buildAccountTransactionSourceValidationCondition(
        existingSourceTables,
      );
    const accountNameExpression = sql`COALESCE(
      NULLIF(a.user_account_name, ''),
      NULLIF(a.system_account_name, ''),
      NULLIF(a.account_code, ''),
      a.id::text
    )`;
    const groupExpression = sql`COALESCE(NULLIF(a.account_group::text, ''), 'Uncategorized')`;
    const accountWhereClause = sql`COALESCE(to_jsonb(a)->>'is_deleted', 'false')::boolean = false
      AND (a.entity_id = ${tenant.entityId} OR a.entity_id IS NULL)`;
    const transactionJoinClause = sql`t.account_id = a.id
      AND t.transaction_date < ${endExclusive.toISOString()}
      AND t.entity_id = ${tenant.entityId}
      AND ${sourceValidationCondition}`;
    const balanceSelect = sql`
      a.id AS "accountId",
      ${accountNameExpression} AS "accountName",
      COALESCE(NULLIF(a.account_code, ''), '') AS "accountCode",
      ${groupExpression} AS "accountGroup",
      SUM(CASE WHEN t.transaction_date < ${start.toISOString()} THEN COALESCE(t.debit, 0) ELSE 0 END) AS "openingDebitRaw",
      SUM(CASE WHEN t.transaction_date < ${start.toISOString()} THEN COALESCE(t.credit, 0) ELSE 0 END) AS "openingCreditRaw",
      SUM(CASE WHEN t.transaction_date >= ${start.toISOString()} THEN COALESCE(t.debit, 0) ELSE 0 END) AS "periodDebit",
      SUM(CASE WHEN t.transaction_date >= ${start.toISOString()} THEN COALESCE(t.credit, 0) ELSE 0 END) AS "periodCredit",
      SUM(COALESCE(t.debit, 0)) AS "closingDebitRaw",
      SUM(COALESCE(t.credit, 0)) AS "closingCreditRaw"
    `;
    const groupedAccountQuery = sql`
      SELECT ${balanceSelect}
      FROM accounts a
      LEFT JOIN ${this.accountTransactionsReportSourceSql()} t ON ${transactionJoinClause}
      WHERE ${accountWhereClause}
      GROUP BY a.id, ${accountNameExpression}, a.account_code, ${groupExpression}
      HAVING
        SUM(COALESCE(t.debit, 0)) <> 0
        OR SUM(COALESCE(t.credit, 0)) <> 0
    `;

    const countResult = await db.execute(sql`
      SELECT COUNT(*)::int AS "total"
      FROM (${groupedAccountQuery}) trial_accounts
    `);
    const total = Number(this.rowsFromQueryResult(countResult)[0]?.total || 0);
    const totalPages = total === 0 ? 1 : Math.ceil(total / normalizedPageSize);
    const currentPage = Math.min(requestedPage, totalPages);
    const offset = (currentPage - 1) * normalizedPageSize;

    const totalsResult = await db.execute(sql`
      SELECT
        SUM(GREATEST("openingDebitRaw" - "openingCreditRaw", 0)) AS "totalOpeningDebit",
        SUM(GREATEST("openingCreditRaw" - "openingDebitRaw", 0)) AS "totalOpeningCredit",
        SUM("periodDebit") AS "totalPeriodDebit",
        SUM("periodCredit") AS "totalPeriodCredit",
        SUM(GREATEST("closingDebitRaw" - "closingCreditRaw", 0)) AS "totalClosingDebit",
        SUM(GREATEST("closingCreditRaw" - "closingDebitRaw", 0)) AS "totalClosingCredit"
      FROM (${groupedAccountQuery}) trial_accounts
    `);
    const totalsRow = this.rowsFromQueryResult(totalsResult)[0] ?? {};

    const rowsResult = await db.execute(sql`
      SELECT *
      FROM (${groupedAccountQuery}) trial_accounts
      ORDER BY
        CASE LOWER("accountGroup")
          WHEN 'assets' THEN 1
          WHEN 'liabilities' THEN 2
          WHEN 'equity' THEN 3
          WHEN 'income' THEN 4
          WHEN 'expenses' THEN 5
          ELSE 6
        END,
        "accountName" ASC
      LIMIT ${normalizedPageSize}
      OFFSET ${offset}
    `);

    const sections = new Map<
      string,
      {
        accountGroup: string;
        accountGroupLabel: string;
        rows: Array<Record<string, any>>;
      }
    >();
    for (const row of this.rowsFromQueryResult(rowsResult)) {
      const accountGroup = String(row.accountGroup ?? "Uncategorized");
      if (!sections.has(accountGroup)) {
        sections.set(accountGroup, {
          accountGroup,
          accountGroupLabel: this.formatTrialBalanceGroupLabel(accountGroup),
          rows: [],
        });
      }
      const openingDebitRaw = Number(row.openingDebitRaw || 0);
      const openingCreditRaw = Number(row.openingCreditRaw || 0);
      const closingDebitRaw = Number(row.closingDebitRaw || 0);
      const closingCreditRaw = Number(row.closingCreditRaw || 0);
      sections.get(accountGroup)!.rows.push({
        accountId: row.accountId,
        accountName: row.accountName,
        accountCode: row.accountCode,
        openingDebit: Math.max(openingDebitRaw - openingCreditRaw, 0),
        openingCredit: Math.max(openingCreditRaw - openingDebitRaw, 0),
        periodDebit: Number(row.periodDebit || 0),
        periodCredit: Number(row.periodCredit || 0),
        closingDebit: Math.max(closingDebitRaw - closingCreditRaw, 0),
        closingCredit: Math.max(closingCreditRaw - closingDebitRaw, 0),
      });
    }

    return {
      basis: basis || "Accrual",
      period: { startDate, endDate },
      sections: Array.from(sections.values()),
      totals: {
        openingDebit: Number(totalsRow.totalOpeningDebit || 0),
        openingCredit: Number(totalsRow.totalOpeningCredit || 0),
        periodDebit: Number(totalsRow.totalPeriodDebit || 0),
        periodCredit: Number(totalsRow.totalPeriodCredit || 0),
        closingDebit: Number(totalsRow.totalClosingDebit || 0),
        closingCredit: Number(totalsRow.totalClosingCredit || 0),
      },
      total,
      page: currentPage,
      pageSize: normalizedPageSize,
      totalPages,
      pagination: {
        totalRecords: total,
        total,
        page: currentPage,
        pageSize: normalizedPageSize,
        totalPages,
      },
    };
  }
  async getSalesByCustomerReport(
    startDate: string,
    endDate: string,
    tenant: TenantContext,
  ) {
    const conditions: any[] = [sql`s.document_type = 'invoice'`];
    if (startDate)
      conditions.push(sql`s.sale_date >= ${new Date(startDate).toISOString()}`);
    if (endDate)
      conditions.push(sql`s.sale_date <= ${new Date(endDate).toISOString()}`);
    conditions.push(sql`s.entity_id = ${tenant.entityId}`);

    const whereClause = sql.join(conditions, sql` AND `);

    const query = sql`
      SELECT 
        c.id as "customerId",
        c.display_name as "customerName",
        COUNT(s.id) as "invoiceCount",
        SUM(s.total) as "totalSales"
      FROM sales_orders s
      JOIN customers c ON s.customer_id = c.id
      WHERE ${whereClause}
      GROUP BY c.id, c.display_name
      ORDER BY "totalSales" DESC
    `;

    const result = await db.execute(query);
    const rows = result as any[];

    return {
      period: { startDate, endDate },
      data: rows.map((r: any) => ({
        customerId: r.customerId,
        customerName: r.customerName,
        invoiceCount: Number(r.invoiceCount || 0),
        totalSales: Number(r.totalSales || 0),
      })),
    };
  }

  async getInventoryValuationReport(tenant: TenantContext) {
    let rows: any[] = [];
    try {
      const query = sql`
        SELECT 
          p.product_name as "itemName",
          p.sku as "sku",
          s.location_name as "warehouse",
          COALESCE(SUM(i.qty - COALESCE(i.reserved_qty, 0)), 0) as "stockOnHand",
          (COALESCE(SUM(i.qty - COALESCE(i.reserved_qty, 0)), 0) * COALESCE(p.cost_price, 0)) as "assetValue"
        FROM batch_stock_layers i
        JOIN products p ON i.product_id = p.id
        LEFT JOIN storage_conditions s ON p.storage_id = s.id
        WHERE i.entity_id = ${tenant.entityId}
        GROUP BY p.id, p.product_name, p.sku, s.location_name, p.cost_price
        HAVING SUM(i.qty - COALESCE(i.reserved_qty, 0)) > 0
        ORDER BY "assetValue" DESC
      `;
      const result = await db.execute(query);
      rows = result as any[];
    } catch (error) {
      // Report endpoint should degrade gracefully instead of 500.
      console.warn("Inventory valuation query failed:", error);
      rows = [];
    }

    return {
      data: rows.map((r: any) => ({
        itemName: r.itemName,
        sku: r.sku || "--",
        warehouse: r.warehouse || "Default",
        stockOnHand: Number(r.stockOnHand || 0),
        assetValue: Number(r.assetValue || 0),
      })),
    };
  }

  async getAuditLogs(tenant: TenantContext, params: AuditLogsParams) {
    const supabase = this.supabaseService.getClient();
    const page = Math.max(1, params.page ?? 1);
    const pageSize = Math.min(100, Math.max(10, params.pageSize ?? 25));
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;

    let query = supabase
      .from("audit_logs_all")
      .select("*", { count: "exact" })
      .eq("org_id", tenant.orgId)
      .order("created_at", { ascending: false })
      .range(from, to);

    if (params.requestId) query = query.eq("request_id", params.requestId);
    if (params.source) query = query.eq("source", params.source);
    if (params.tables?.length) query = query.in("table_name", params.tables);
    if (params.actions?.length) query = query.in("action", params.actions);
    if (params.fromDate) {
      const fromDate = params.fromDate.includes("T")
        ? new Date(params.fromDate)
        : new Date(`${params.fromDate}T00:00:00.000Z`);
      query = query.gte("created_at", fromDate.toISOString());
    }
    if (params.toDate) {
      const toDate = params.toDate.includes("T")
        ? new Date(params.toDate)
        : new Date(`${params.toDate}T23:59:59.999Z`);
      query = query.lte("created_at", toDate.toISOString());
    }

    if (params.scope == "archived") {
      query = query.not("archived_at", "is", null);
    } else if (params.scope == "recent") {
      query = query.is("archived_at", null);
    }

    if (params.search?.trim().length) {
      const term = params.search.trim().replaceAll(",", " ");
      query = query.or(
        [
          `table_name.ilike.%${term}%`,
          `record_pk.ilike.%${term}%`,
          `actor_name.ilike.%${term}%`,
          `module_name.ilike.%${term}%`,
          `request_id.ilike.%${term}%`,
          `source.ilike.%${term}%`,
          `action.ilike.%${term}%`,
        ].join(","),
      );
    }

    const { data, count, error } = await query;
    if (error) throw error;

    const logs = Array.isArray(data)
      ? (data as Array<Record<string, unknown>>)
      : [];
    const visibleItems = logs.length;
    const summary = {
      insertCount: logs.filter((log) => log["action"] === "INSERT").length,
      updateCount: logs.filter((log) => log["action"] === "UPDATE").length,
      deleteCount: logs.filter((log) => log["action"] === "DELETE").length,
      truncateCount: logs.filter((log) => log["action"] === "TRUNCATE").length,
      archivedCount: logs.filter((log) => log["archived_at"] != null).length,
      visibleItems,
    };

    return {
      items: logs,
      total: count ?? visibleItems,
      page,
      pageSize,
      summary,
    };
  }
}
