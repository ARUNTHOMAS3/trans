import { Controller, Get, Query } from "@nestjs/common";
import { AccountantService } from "./accountant.service";

@Controller("reports")
export class ReportsController {
  constructor(private readonly accountantService: AccountantService) {}

  @Get("profit-and-loss")
  getProfitAndLoss(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Query("orgId") orgId: string,
  ) {
    return this.accountantService.getProfitAndLossReport(
      startDate,
      endDate,
      orgId,
    );
  }

  @Get("general-ledger")
  getGeneralLedger(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Query("orgId") orgId: string,
  ) {
    return this.accountantService.getGeneralLedgerReport(
      startDate,
      endDate,
      orgId,
    );
  }

  @Get("trial-balance")
  getTrialBalance(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Query("orgId") orgId: string,
  ) {
    // Add stub for now, or implement it if possible. The prompt only focuses strictly on P&L and GL instructions.
    // Wait, the user did list four endpoints in one place: P&L, GL, AT, TB.
    return this.accountantService.getTrialBalanceReport(
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
    @Query("orgId") orgId: string,
    @Query("contactId") contactId: string,
    @Query("contactType") contactType: string,
  ) {
    return this.accountantService.getAccountTransactionsReport(
      accountId,
      startDate,
      endDate,
      orgId,
      contactId,
      contactType,
    );
  }

  @Get("sales-by-customer")
  getSalesByCustomer(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Query("orgId") orgId: string,
  ) {
    return this.accountantService.getSalesByCustomerReport(
      startDate,
      endDate,
      orgId,
    );
  }

  @Get("inventory-valuation")
  getInventoryValuation(@Query("orgId") orgId: string) {
    return this.accountantService.getInventoryValuationReport(orgId);
  }
}
