import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { db } from "../../db/db";
import { sql } from "drizzle-orm";

type AuditLogsParams = {
  page?: number;
  pageSize?: number;
  search?: string;
  tables?: string[];
  actions?: string[];
  requestId?: string;
  source?: string;
  orgId?: string;
  outletId?: string;
  fromDate?: string;
  toDate?: string;
  scope?: string;
};

@Injectable()
export class ReportsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getDashboardSummary(orgId: string, outletId?: string) {
    const supabase = this.supabaseService.getClient();

    // 1. Get Accounts Summary (Receivables/Payables)
    const { data: accounts, error: accError } = await supabase
      .from("accounts")
      .select("id, account_type, user_account_name");

    if (accError) throw accError;

    // 2. Get Transaction Balances
    let txQuery = supabase.from("account_transactions").select("account_id, debit, credit");
    if (orgId) txQuery = txQuery.eq("org_id", orgId);
    if (outletId) txQuery = txQuery.eq("outlet_id", outletId);

    const { data: txs, error: txError } = await txQuery;
    if (txError) throw txError;

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

    const { data: salesTrend, error: salesError } = await supabase
      .from("account_transactions")
      .select("transaction_date, credit")
      .eq("org_id", orgId)
      .gte("transaction_date", thirtyDaysAgo.toISOString())
      .filter("transaction_type", "in", '("invoice", "sales_receipt")');

    if (salesError) console.warn("Error fetching sales trend:", salesError);

    // Group by day
    const trendMap = new Map<string, number>();
    salesTrend?.forEach((s) => {
      const date = s.transaction_date.split("T")[0];
      trendMap.set(date, (trendMap.get(date) || 0) + Number(s.credit || 0));
    });

    const trendData = Array.from(trendMap.entries())
      .map(([date, amount]) => ({ date, amount }))
      .sort((a, b) => a.date.localeCompare(b.date));

    // 4. Top Customers
    const { data: topCustomersData, error: customerError } = await supabase
      .from("account_transactions")
      .select("contact_id, contact_type, credit")
      .eq("org_id", orgId)
      .eq("contact_type", "customer")
      .filter("transaction_type", "in", '("invoice", "sales_receipt")');

    if (customerError) console.warn("Error fetching top customers:", customerError);

    const customerMap = new Map<string, number>();
    topCustomersData?.forEach((c) => {
      if (c.contact_id) {
        customerMap.set(c.contact_id, (customerMap.get(c.contact_id) || 0) + Number(c.credit || 0));
      }
    });

    const topCustomerIds = Array.from(customerMap.keys())
      .sort((a, b) => customerMap.get(b)! - customerMap.get(a)!)
      .slice(0, 5);

    const topCustomers = await Promise.all(
      topCustomerIds.map(async (id) => {
        const { data } = await supabase.from("customers").select("display_name").eq("id", id).single();
        return {
          name: data?.display_name || "Unknown Customer",
          amount: customerMap.get(id) || 0,
        };
      })
    );

    return {
      receivables: totalReceivables,
      payables: totalPayables,
      cashOnHand: cashOnHand,
      salesTrend: trendData,
      topCustomers,
      topItems: [],
    };
  }

  // --- Reports Methods (Relocated from Accountant) ---

  async getProfitAndLossReport(
    startDate: string,
    endDate: string,
    orgId?: string,
  ) {
    const conditions: any[] = [
      sql`t.transaction_date >= ${new Date(startDate).toISOString()}`,
      sql`t.transaction_date <= ${new Date(endDate).toISOString()}`,
      sql`COALESCE(a.user_account_name, a.system_account_name) != 'Opening Balance Offset'`,
    ];
    if (orgId) conditions.push(sql`t.org_id = ${orgId}`);

    const whereClause = sql.join(conditions, sql` AND `);

    const query = sql`
      SELECT 
        a.account_type as "accountType",
        COALESCE(a.user_account_name, a.system_account_name) as "accountName",
        a.id as "accountId",
        SUM(t.debit) as "totalDebit",
        SUM(t.credit) as "totalCredit"
      FROM account_transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
      GROUP BY a.account_type, COALESCE(a.user_account_name, a.system_account_name), a.id
    `;

    const result = await db.execute(query);
    const rows = result as any[];

    const report = { operatingIncome: [], costOfGoodsSold: [], operatingExpenses: [] };
    let totalIncome = 0, totalCogs = 0, totalExpenses = 0;

    for (const row of rows) {
      const type = row.accountType?.toLowerCase() || "";
      const isIncome = type.includes("income") || type.includes("sales");
      const isCogs = type.includes("cogs") || type.includes("cost");
      const isExpense = type.includes("expense");

      const totalDebit = Number(row.totalDebit);
      const totalCredit = Number(row.totalCredit);
      const netAmount = isIncome ? totalCredit - totalDebit : totalDebit - totalCredit;

      const item = { accountId: row.accountId, accountName: row.accountName, accountType: row.accountType, netAmount };

      if (isIncome) { report.operatingIncome.push(item); totalIncome += netAmount; }
      else if (isCogs) { report.costOfGoodsSold.push(item); totalCogs += netAmount; }
      else if (isExpense) { report.operatingExpenses.push(item); totalExpenses += netAmount; }
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

  async getGeneralLedgerReport(startDate: string, endDate: string, orgId?: string) {
    const conditions: any[] = [
      sql`t.transaction_date >= ${new Date(startDate).toISOString()}`,
      sql`t.transaction_date <= ${new Date(endDate).toISOString()}`,
    ];
    if (orgId) conditions.push(sql`t.org_id = ${orgId}`);

    const whereClause = sql.join(conditions, sql` AND `);

    const query = sql`
      SELECT 
        a.account_type as "accountType",
        COALESCE(a.user_account_name, a.system_account_name) as "accountName",
        a.account_code as "accountCode",
        a.id as "accountId",
        SUM(t.debit) as "totalDebit",
        SUM(t.credit) as "totalCredit"
      FROM account_transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
      GROUP BY a.account_type, COALESCE(a.user_account_name, a.system_account_name), a.account_code, a.id
    `;

    const result = await db.execute(query);
    const rows = result as any[];

    return {
      period: { startDate, endDate },
      accounts: rows.map((r: any) => ({
        accountId: r.accountId,
        accountName: r.accountName,
        accountCode: r.accountCode,
        accountType: r.accountType,
        debit: Number(r.totalDebit),
        credit: Number(r.totalCredit),
        netBalance: Number(r.totalDebit) - Number(r.totalCredit),
      })),
    };
  }

  async getAccountTransactionsReport(
    accountId: string,
    startDate: string,
    endDate: string,
    orgId?: string,
    contactId?: string,
    contactType?: string,
  ) {
    const conditions: any[] = [];
    if (accountId) conditions.push(sql`t.account_id = ${accountId}`);
    if (contactId) conditions.push(sql`t.contact_id = ${contactId}`);
    if (contactType) conditions.push(sql`t.contact_type = ${contactType}`);
    conditions.push(sql`t.transaction_date >= ${new Date(startDate).toISOString()}`);
    conditions.push(sql`t.transaction_date <= ${new Date(endDate).toISOString()}`);
    if (orgId) conditions.push(sql`t.org_id = ${orgId}`);

    const whereClause = sql.join(conditions, sql` AND `);

    const query = sql`
      SELECT 
        t.transaction_date as "date",
        t.description as "details",
        t.transaction_type as "type",
        t.reference_number as "reference",
        t.debit as "debit",
        t.credit as "credit",
        t.source_id as "sourceId",
        t.source_type as "sourceType"
      FROM account_transactions t
      WHERE ${whereClause}
      ORDER BY t.transaction_date ASC
    `;

    const result = await db.execute(query);
    const rows = result as any[];

    let runningBalance = 0;
    const transactions = rows.map((r: any) => {
      const debit = Number(r.debit || 0);
      const credit = Number(r.credit || 0);
      runningBalance += debit - credit;
      return { ...r, debit, credit, runningBalance };
    });

    return { accountId, period: { startDate, endDate }, transactions };
  }

  async getTrialBalanceReport(startDate: string, endDate: string, orgId?: string) {
    const conditions: any[] = [];
    if (endDate) conditions.push(sql`t.transaction_date <= ${new Date(endDate).toISOString()}`);
    if (orgId) conditions.push(sql`t.org_id = ${orgId}`);

    const whereClause = conditions.length > 0 ? sql.join(conditions, sql` AND `) : sql`1=1`;

    const query = sql`
      SELECT 
        COALESCE(a.user_account_name, a.system_account_name) as "accountName",
        a.id as "accountId",
        SUM(t.debit) as "totalDebit",
        SUM(t.credit) as "totalCredit"
      FROM account_transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
      GROUP BY COALESCE(a.user_account_name, a.system_account_name), a.id
      HAVING SUM(t.debit) != SUM(t.credit)
    `;

    const result = await db.execute(query);
    const rows = result as any[];

    let totalDebit = 0, totalCredit = 0;

    const accountsData = rows.map((r: any) => {
      const debit = Number(r.totalDebit || 0);
      const credit = Number(r.totalCredit || 0);
      const netDebit = debit > credit ? debit - credit : 0;
      const netCredit = credit > debit ? credit - debit : 0;
      totalDebit += netDebit; totalCredit += netCredit;
      return { accountId: r.accountId, accountName: r.accountName, debit: netDebit, credit: netCredit };
    }).filter((acc) => acc.debit > 0 || acc.credit > 0);

    return { period: { startDate, endDate }, accounts: accountsData, totalDebit, totalCredit };
  }

  async getSalesByCustomerReport(startDate: string, endDate: string, orgId?: string) {
    const conditions: any[] = [sql`s.document_type = 'invoice'`];
    if (startDate) conditions.push(sql`s.sale_date >= ${new Date(startDate).toISOString()}`);
    if (endDate) conditions.push(sql`s.sale_date <= ${new Date(endDate).toISOString()}`);
    if (orgId) conditions.push(sql`c.org_id = ${orgId}`);

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

  async getInventoryValuationReport(_orgId?: string) {
    const query = sql`
      SELECT 
        p.product_name as "itemName",
        p.sku as "sku",
        s.location_name as "warehouse",
        COALESCE(SUM(i.current_stock), 0) as "stockOnHand",
        (COALESCE(SUM(i.current_stock), 0) * COALESCE(p.cost_price, 0)) as "assetValue"
      FROM outlet_inventory i
      JOIN products p ON i.product_id = p.id
      LEFT JOIN storage_locations s ON p.storage_id = s.id
      GROUP BY p.id, p.product_name, p.sku, s.location_name, p.cost_price
      HAVING SUM(i.current_stock) > 0
      ORDER BY "assetValue" DESC
    `;

    const result = await db.execute(query);
    const rows = result as any[];

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

  async getAuditLogs(params: AuditLogsParams) {
    const supabase = this.supabaseService.getClient();
    const page = Math.max(1, params.page ?? 1);
    const pageSize = Math.min(100, Math.max(10, params.pageSize ?? 25));
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;

    let query = supabase
      .from("audit_logs_all")
      .select("*", { count: "exact" })
      .order("created_at", { ascending: false })
      .range(from, to);

    if (params.orgId) query = query.eq("org_id", params.orgId);
    if (params.outletId) query = query.eq("outlet_id", params.outletId);
    if (params.requestId) query = query.eq("request_id", params.requestId);
    if (params.source) query = query.eq("source", params.source);
    if (params.tables?.length) query = query.in("table_name", params.tables);
    if (params.actions?.length) query = query.in("action", params.actions);
    if (params.fromDate) {
      query = query.gte(
        "created_at",
        new Date(params.fromDate).toISOString(),
      );
    }
    if (params.toDate) {
      query = query.lte("created_at", new Date(params.toDate).toISOString());
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
          "table_name.ilike.%${term}%",
          "record_pk.ilike.%${term}%",
          "actor_name.ilike.%${term}%",
          "module_name.ilike.%${term}%",
          "request_id.ilike.%${term}%",
          "source.ilike.%${term}%",
          "action.ilike.%${term}%",
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
