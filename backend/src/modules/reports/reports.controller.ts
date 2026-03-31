import { Controller, Get, Query } from "@nestjs/common";
import { ReportsService } from "./reports.service";

@Controller("reports")
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get("dashboard-summary")
  getDashboardSummary(
    @Query("orgId") orgId: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.reportsService.getDashboardSummary(orgId, outletId);
  }

  @Get("profit-and-loss")
  getProfitAndLoss(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Query("orgId") orgId?: string,
  ) {
    return this.reportsService.getProfitAndLossReport(
      startDate,
      endDate,
      orgId,
    );
  }

  @Get("general-ledger")
  getGeneralLedger(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Query("orgId") orgId?: string,
  ) {
    return this.reportsService.getGeneralLedgerReport(
      startDate,
      endDate,
      orgId,
    );
  }

  @Get("account-transactions")
  getAccountTransactions(
    @Query("accountId") accountId: string,
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Query("orgId") orgId?: string,
    @Query("contactId") contactId?: string,
    @Query("contactType") contactType?: string,
  ) {
    return this.reportsService.getAccountTransactionsReport(
      accountId,
      startDate,
      endDate,
      orgId,
      contactId,
      contactType,
    );
  }

  @Get("trial-balance")
  getTrialBalance(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Query("orgId") orgId?: string,
  ) {
    return this.reportsService.getTrialBalanceReport(startDate, endDate, orgId);
  }

  @Get("sales-by-customer")
  getSalesByCustomer(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Query("orgId") orgId?: string,
  ) {
    return this.reportsService.getSalesByCustomerReport(
      startDate,
      endDate,
      orgId,
    );
  }

  @Get("inventory-valuation")
  getInventoryValuation(@Query("orgId") orgId?: string) {
    return this.reportsService.getInventoryValuationReport(orgId);
  }

  @Get("audit-logs")
  getAuditLogs(
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
    @Query("search") search?: string,
    @Query("tables") tables?: string,
    @Query("actions") actions?: string,
    @Query("requestId") requestId?: string,
    @Query("source") source?: string,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
    @Query("fromDate") fromDate?: string,
    @Query("toDate") toDate?: string,
    @Query("scope") scope?: string,
  ) {
    const parsedPage = page ? Number.parseInt(page, 10) : undefined;
    const parsedPageSize = pageSize ? Number.parseInt(pageSize, 10) : undefined;
    const parsedTables = tables
      ?.split(",")
      .map((value) => value.trim())
      .filter((value) => value.length > 0);
    const parsedActions = actions
      ?.split(",")
      .map((value) => value.trim().toUpperCase())
      .filter((value) => value.length > 0);

    return this.reportsService.getAuditLogs({
      page: Number.isNaN(parsedPage) ? undefined : parsedPage,
      pageSize: Number.isNaN(parsedPageSize) ? undefined : parsedPageSize,
      search,
      tables: parsedTables,
      actions: parsedActions,
      requestId,
      source,
      orgId,
      outletId,
      fromDate,
      toDate,
      scope,
    });
  }
}
