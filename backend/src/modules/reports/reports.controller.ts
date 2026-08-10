import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
} from "@nestjs/common";
import { ReportsService } from "./reports.service";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { SalesReportQueryDto } from "./dto/sales-report-query.dto";
import { InventoryReportQueryDto } from "./dto/inventory-report-query.dto";
import { PurchasesExpensesReportQueryDto } from "./dto/purchases-expenses-report-query.dto";
import { ReportFavoriteDto } from "./dto/report-favorite.dto";
import { SalesReportsService } from "./services/sales-reports.service";
import { InventoryReportsService } from "./services/inventory-reports.service";
import { PurchasesExpensesReportsService } from "./services/purchases-expenses-reports.service";
import { ReportsFavoritesService } from "./services/reports-favorites.service";

@Controller("reports")
export class ReportsController {
  constructor(
    private readonly reportsService: ReportsService,
    private readonly salesReportsService: SalesReportsService,
    private readonly reportsFavoritesService: ReportsFavoritesService,
    private readonly inventoryReportsService: InventoryReportsService,
    private readonly purchasesExpensesReportsService: PurchasesExpensesReportsService,
  ) {}

  @Get("dashboard-summary")
  getDashboardSummary(@Tenant() tenant: TenantContext) {
    return this.reportsService.getDashboardSummary(tenant);
  }

  @Get("current-branch")
  getCurrentBranchHeader(@Tenant() tenant: TenantContext) {
    return this.reportsService.getCurrentBranchHeader(tenant);
  }

  @Get("favorites")
  getReportFavorites(@Tenant() tenant: TenantContext) {
    return this.reportsFavoritesService.getFavorites(tenant);
  }

  @Post("favorites")
  saveReportFavorite(
    @Tenant() tenant: TenantContext,
    @Body() body: ReportFavoriteDto,
  ) {
    return this.reportsFavoritesService.saveFavorite(tenant, body);
  }

  @Delete("favorites")
  removeReportFavorite(
    @Tenant() tenant: TenantContext,
    @Query("report") report: string,
  ) {
    return this.reportsFavoritesService.removeFavorite(tenant, report);
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
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getGeneralLedgerReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }

  @Get("detailed-general-ledger")
  getDetailedGeneralLedger(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getDetailedGeneralLedgerReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }

  @Get("account-type-summary")
  getAccountTypeSummary(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
  ) {
    return this.reportsService.getAccountTypeSummaryReport(
      startDate,
      endDate,
      tenant,
      basis,
    );
  }
  @Get("account-type-transactions")
  getAccountTypeTransactions(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getAccountTypeTransactionsReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
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
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
    @Query("accountType") accountType?: string,
  ) {
    return this.reportsService.getAccountTransactionsReport(
      accountId,
      startDate,
      endDate,
      tenant,
      contactId,
      contactType,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
      accountType,
    );
  }


  @Get("journal-report")
  getJournalReport(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getJournalReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }
  @Get("day-book")
  getDayBook(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getDayBookReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }
  @Get("sales-order-details")
  getSalesOrderDetails(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("status") status?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getSalesOrderDetailsReport(
      startDate,
      endDate,
      tenant,
      basis,
      status,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }
  @Get("invoice-details")
  getInvoiceDetails(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("reportBy") reportBy?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getInvoiceDetailsReport(
      startDate,
      endDate,
      tenant,
      basis,
      reportBy,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }
  @Get("credit-note-details")
  getCreditNoteDetails(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getCreditNoteDetailsReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }
  @Get("retainer-invoice-details")
  getRetainerInvoiceDetails(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getRetainerInvoiceDetailsReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }
  @Get("quote-details")
  getQuoteDetails(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("reportBy") reportBy?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getQuoteDetailsReport(
      startDate,
      endDate,
      tenant,
      basis,
      reportBy,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }
  @Get("delivery-challan-details")
  getDeliveryChallanDetails(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getDeliveryChallanDetailsReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }
  @Get("tax-summary")
  getTaxSummary(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getTaxSummaryReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }

  @Get("tds-summary")
  getTdsSummary(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getTdsSummaryReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }

  @Get("purchase-orders-by-vendor")
  getPurchaseOrdersByVendor(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getPurchaseOrdersByVendorReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }
  @Get("purchase-orders-by-item")
  getPurchaseOrdersByItem(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getPurchaseOrdersByItemReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }
  @Get("purchase-order-details")
  getPurchaseOrderDetails(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getPurchaseOrderDetailsReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }
  @Get("payments-made")
  getPaymentsMade(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getPaymentsMadeReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }
  @Get("trial-balance")
  getTrialBalance(
    @Query("startDate") startDate: string,
    @Query("endDate") endDate: string,
    @Tenant() tenant: TenantContext,
    @Query("basis") basis?: string,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
  ) {
    return this.reportsService.getTrialBalanceReport(
      startDate,
      endDate,
      tenant,
      basis,
      page ? Number.parseInt(page, 10) : undefined,
      pageSize ? Number.parseInt(pageSize, 10) : undefined,
    );
  }

  @Get("sales-by-customer")
  getSalesByCustomer(
    @Tenant() tenant: TenantContext,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.salesReportsService.getSalesByCustomer(tenant, query);
  }

  @Get("sales-by-customer/:customerId/transactions")
  getSalesByCustomerTransactions(
    @Tenant() tenant: TenantContext,
    @Param("customerId") customerId: string,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.salesReportsService.getCustomerTransactions(
      tenant,
      customerId,
      query,
    );
  }

  @Get("sales-by-item")
  getSalesByItem(
    @Tenant() tenant: TenantContext,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.salesReportsService.getSalesByItem(tenant, query);
  }

  @Get("sales-by-item/:itemId/transactions")
  getSalesByItemTransactions(
    @Tenant() tenant: TenantContext,
    @Param("itemId") itemId: string,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.salesReportsService.getItemTransactions(tenant, itemId, query);
  }

  @Get("sales-by-salesperson")
  getSalesBySalesperson(
    @Tenant() tenant: TenantContext,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.salesReportsService.getSalesBySalesperson(tenant, query);
  }

  @Get("sales-by-salesperson/:salespersonName/transactions")
  getSalesBySalespersonTransactions(
    @Tenant() tenant: TenantContext,
    @Param("salespersonName") salespersonName: string,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.salesReportsService.getSalespersonTransactions(
      tenant,
      salespersonName,
      query,
    );
  }

  @Get("sales-summary")
  getSalesSummary(
    @Tenant() tenant: TenantContext,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.salesReportsService.getSalesSummary(tenant, query);
  }

  @Get("profit-by-item")
  getProfitByItem(
    @Tenant() tenant: TenantContext,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.salesReportsService.getProfitByItem(tenant, query);
  }

  @Get("payments-received")
  getPaymentsReceived(
    @Tenant() tenant: TenantContext,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.salesReportsService.getPaymentsReceived(tenant, query);
  }

  @Get("recurring-invoices")
  getRecurringInvoices(
    @Tenant() tenant: TenantContext,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.salesReportsService.getRecurringInvoices(tenant, query);
  }

  @Get("recurring-invoices/:recurringInvoiceId/details")
  getRecurringInvoiceDetails(
    @Tenant() tenant: TenantContext,
    @Param("recurringInvoiceId") recurringInvoiceId: string,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.salesReportsService.getRecurringInvoiceDetails(
      tenant,
      recurringInvoiceId,
      query,
    );
  }

  @Get("sales-channel-integrations-sync-summary")
  getSalesChannelIntegrationsSyncSummary(@Query() query: SalesReportQueryDto) {
    return this.salesReportsService.getSalesChannelIntegrationsSyncSummary(
      query,
    );
  }

  @Get("batch-details")
  getBatchDetails(
    @Tenant() tenant: TenantContext,
    @Query() query: InventoryReportQueryDto,
  ) {
    return this.inventoryReportsService.getBatchDetails(tenant, query);
  }
  @Get("inventory-summary")
  async getInventorySummary(
    @Tenant() tenant: TenantContext,
    @Query() query: InventoryReportQueryDto,
  ) {
    console.log("[REPORTS BACKEND] Inventory Summary endpoint called", {
      query,
      entityId: tenant.entityId,
    });
    const response = await this.inventoryReportsService.getInventorySummary(
      tenant,
      query,
    );
    console.log("[REPORTS BACKEND] Inventory Summary controller return", {
      runtimeType: Array.isArray(response) ? "array" : typeof response,
      json: response,
    });
    return response;
  }

  @Get("stock-summary")
  getStockSummary(
    @Tenant() tenant: TenantContext,
    @Query() query: InventoryReportQueryDto,
  ) {
    return this.inventoryReportsService.getStockSummary(tenant, query);
  }
  @Get("stock-movement")
  getStockMovement(
    @Tenant() tenant: TenantContext,
    @Query() query: InventoryReportQueryDto,
  ) {
    return this.inventoryReportsService.getStockMovement(tenant, query);
  }
  @Get("inventory-turnover-by-quantity")
  getInventoryTurnoverByQuantity(
    @Tenant() tenant: TenantContext,
    @Query() query: InventoryReportQueryDto,
  ) {
    return this.inventoryReportsService.getInventoryTurnoverByQuantity(
      tenant,
      query,
    );
  }
  @Get("inventory-adjustment-summary")
  getInventoryAdjustmentSummary(
    @Tenant() tenant: TenantContext,
    @Query() query: InventoryReportQueryDto,
  ) {
    return this.inventoryReportsService.getInventoryAdjustmentSummary(
      tenant,
      query,
    );
  }
  @Get("inventory-adjustment-details")
  getInventoryAdjustmentDetails(
    @Tenant() tenant: TenantContext,
    @Query() query: InventoryReportQueryDto,
  ) {
    return this.inventoryReportsService.getInventoryAdjustmentDetails(
      tenant,
      query,
    );
  }
  @Get("committed-stock-details")
  getCommittedStockDetails(
    @Tenant() tenant: TenantContext,
    @Query() query: InventoryReportQueryDto,
  ) {
    return this.inventoryReportsService.getCommittedStockDetails(tenant, query);
  }

  @Get("assembly-details")
  getAssemblyDetails(
    @Tenant() tenant: TenantContext,
    @Query() query: InventoryReportQueryDto,
  ) {
    return this.inventoryReportsService.getAssemblyDetails(tenant, query);
  }

  @Get("inventory-aging-summary")
  getInventoryAgingSummary(
    @Tenant() tenant: TenantContext,
    @Query() query: InventoryReportQueryDto,
  ) {
    return this.inventoryReportsService.getInventoryAgingSummary(tenant, query);
  }
  @Get("fifo-cost-lot-tracking")
  getFifoCostLotTracking(
    @Tenant() tenant: TenantContext,
    @Query() query: InventoryReportQueryDto,
  ) {
    return this.inventoryReportsService.getFifoCostLotTracking(tenant, query);
  }
  @Get("inventory-valuation")
  getInventoryValuation(
    @Tenant() tenant: TenantContext,
    @Query() query: InventoryReportQueryDto,
  ) {
    return this.inventoryReportsService.getInventoryValuationSummary(
      tenant,
      query,
    );
  }

  @Get("landed-cost-summary")
  getLandedCostSummary(
    @Tenant() tenant: TenantContext,
    @Query() query: InventoryReportQueryDto,
  ) {
    return this.inventoryReportsService.getLandedCostSummary(tenant, query);
  }
  @Get("expense-details")
  getExpenseDetails(
    @Tenant() tenant: TenantContext,
    @Query() query: PurchasesExpensesReportQueryDto,
  ) {
    return this.purchasesExpensesReportsService.getExpenseDetails(
      tenant,
      query,
    );
  }
  @Get("bill-details")
  getBillDetails(
    @Tenant() tenant: TenantContext,
    @Query() query: PurchasesExpensesReportQueryDto,
  ) {
    return this.purchasesExpensesReportsService.getBillDetails(tenant, query);
  }

  @Get("vendor-credits-details")
  getVendorCreditsDetails(
    @Tenant() tenant: TenantContext,
    @Query() query: PurchasesExpensesReportQueryDto,
  ) {
    return this.purchasesExpensesReportsService.getVendorCreditsDetails(
      tenant,
      query,
    );
  }
  @Get("billable-expense-details")
  getBillableExpenseDetails(
    @Tenant() tenant: TenantContext,
    @Query() query: PurchasesExpensesReportQueryDto,
  ) {
    return this.purchasesExpensesReportsService.getBillableExpenseDetails(
      tenant,
      query,
    );
  }

  @Get("expenses-by-category")
  getExpensesByCategory(
    @Tenant() tenant: TenantContext,
    @Query() query: PurchasesExpensesReportQueryDto,
  ) {
    return this.purchasesExpensesReportsService.getExpensesByCategory(
      tenant,
      query,
    );
  }

  @Get("expenses-by-customer")
  getExpensesByCustomer(
    @Tenant() tenant: TenantContext,
    @Query() query: PurchasesExpensesReportQueryDto,
  ) {
    return this.purchasesExpensesReportsService.getExpensesByCustomer(
      tenant,
      query,
    );
  }
  @Get("expenses-by-employee")
  getExpensesByEmployee(
    @Tenant() tenant: TenantContext,
    @Query() query: PurchasesExpensesReportQueryDto,
  ) {
    return this.purchasesExpensesReportsService.getExpensesByEmployee(
      tenant,
      query,
    );
  }
  @Get("purchases-by-item")
  getPurchasesByItem(
    @Tenant() tenant: TenantContext,
    @Query() query: PurchasesExpensesReportQueryDto,
  ) {
    return this.purchasesExpensesReportsService.getPurchasesByItem(
      tenant,
      query,
    );
  }
  @Get("purchases-by-vendor")
  getPurchasesByVendor(
    @Tenant() tenant: TenantContext,
    @Query() query: PurchasesExpensesReportQueryDto,
  ) {
    return this.purchasesExpensesReportsService.getPurchasesByVendor(
      tenant,
      query,
    );
  }
  @Get("audit-logs")
  getAuditLogs(
    @Tenant() tenant: TenantContext,
    @Query("page") page?: string,
    @Query("pageSize") pageSize?: string,
    @Query("accountType") accountType?: string,
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
