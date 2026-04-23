import { Controller, Get, Query } from "@nestjs/common";
import { ReportsService } from "./reports.service";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Controller("reports")
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get("dashboard-summary")
  getDashboardSummary(@Tenant() tenant: TenantContext) {
    return this.reportsService.getDashboardSummary(tenant);
  }

  @Get("profit-and-loss")
  getProfitAndLoss(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.reportsService.getProfitAndLossReport(
      startDate,
      endDate,
      tenant,
    );
  }

  @Get("general-ledger")
  getGeneralLedger(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.reportsService.getGeneralLedgerReport(
      startDate,
      endDate,
      tenant,
    );
  }

  @Get("account-transactions")
  getAccountTransactions(
    @Query("accountId") accountId: string,
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("contactId") contactId?: string,
    @Query("contactType") contactType?: string,
  ) {
    return this.reportsService.getAccountTransactionsReport(
      accountId,
      startDate,
      endDate,
      tenant,
      contactId,
      contactType,
    );
  }

  @Get("trial-balance")
  getTrialBalance(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.reportsService.getTrialBalanceReport(
      startDate,
      endDate,
      tenant,
    );
  }

  @Get("sales-by-customer")
  getSalesByCustomer(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.reportsService.getSalesByCustomerReport(
      startDate,
      endDate,
      tenant,
    );
  }

  @Get("inventory-valuation")
  getInventoryValuation(@Tenant() tenant: TenantContext) {
    return this.reportsService.getInventoryValuationReport(tenant);
  }

  @Get("audit-logs")
  getAuditLogs(
    @Tenant() tenant: TenantContext,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
    @Query("search") search?: string,
    @Query("tables") tables?: string,
    @Query("actions") actions?: string,
    @Query("requestId") requestId?: string,
    @Query("source") source?: string,
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

    return this.reportsService.getAuditLogs(tenant, {
      page: Number.isNaN(parsedPage) ? undefined : parsedPage,
      pageSize: Number.isNaN(parsedPageSize) ? undefined : parsedPageSize,
      search,
      tables: parsedTables,
      actions: parsedActions,
      requestId,
      source,
      fromDate,
      toDate,
      scope,
    });
  }
}
