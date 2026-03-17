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
    return this.reportsService.getProfitAndLossReport(startDate, endDate, orgId);
  }

  @Get("general-ledger")
  getGeneralLedger(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Query("orgId") orgId?: string,
  ) {
    return this.reportsService.getGeneralLedgerReport(startDate, endDate, orgId);
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
}
