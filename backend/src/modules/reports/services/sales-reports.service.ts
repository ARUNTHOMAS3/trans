import { Injectable } from "@nestjs/common";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SalesReportQueryDto } from "../dto/sales-report-query.dto";
import {
  SalesReportPage,
  SalesReportsRepository,
} from "../repositories/sales-reports.repository";

@Injectable()
export class SalesReportsService {
  constructor(
    private readonly salesReportsRepository: SalesReportsRepository,
  ) {}

  private toResponse(page: SalesReportPage<Record<string, unknown>>) {
    return {
      data: page.rows,
      meta: {
        page: page.page,
        limit: page.limit,
        total: page.total,
        totalPages: page.totalPages,
      },
    };
  }

  getSalesByCustomer(tenant: TenantContext, query: SalesReportQueryDto) {
    return this.salesReportsRepository
      .salesByCustomer(tenant, query)
      .then((page) => this.toResponse(page));
  }

  getSalesByItem(tenant: TenantContext, query: SalesReportQueryDto) {
    return this.salesReportsRepository
      .salesByItem(tenant, query)
      .then((page) => this.toResponse(page));
  }

  getSalesBySalesperson(tenant: TenantContext, query: SalesReportQueryDto) {
    return this.salesReportsRepository
      .salesBySalesperson(tenant, query)
      .then((page) => this.toResponse(page));
  }

  getSalesSummary(tenant: TenantContext, query: SalesReportQueryDto) {
    return this.salesReportsRepository
      .salesSummary(tenant, query)
      .then((page) => this.toResponse(page));
  }

  getProfitByItem(tenant: TenantContext, query: SalesReportQueryDto) {
    return this.salesReportsRepository
      .profitByItem(tenant, query)
      .then((page) => this.toResponse(page));
  }

  getPaymentsReceived(tenant: TenantContext, query: SalesReportQueryDto) {
    return this.salesReportsRepository
      .paymentsReceived(tenant, query)
      .then((page) => this.toResponse(page));
  }

  getRecurringInvoices(tenant: TenantContext, query: SalesReportQueryDto) {
    return this.salesReportsRepository
      .recurringInvoices(tenant, query)
      .then((page) => this.toResponse(page));
  }

  getRecurringInvoiceDetails(
    tenant: TenantContext,
    recurringInvoiceId: string,
    query: SalesReportQueryDto,
  ) {
    return this.salesReportsRepository.recurringInvoiceDetails(
      tenant,
      recurringInvoiceId,
      query,
    );
  }

  getSalesChannelIntegrationsSyncSummary(query: SalesReportQueryDto) {
    return this.salesReportsRepository
      .salesChannelIntegrationsSyncSummary(query)
      .then((page) => this.toResponse(page));
  }

  getCustomerTransactions(
    tenant: TenantContext,
    customerId: string,
    query: SalesReportQueryDto,
  ) {
    return this.salesReportsRepository.customerTransactions(
      tenant,
      customerId,
      query,
    );
  }

  getItemTransactions(
    tenant: TenantContext,
    itemId: string,
    query: SalesReportQueryDto,
  ) {
    return this.salesReportsRepository.itemTransactions(tenant, itemId, query);
  }

  getSalespersonTransactions(
    tenant: TenantContext,
    salespersonName: string,
    query: SalesReportQueryDto,
  ) {
    return this.salesReportsRepository.salespersonTransactions(
      tenant,
      salespersonName,
      query,
    );
  }
}
