import { Injectable } from "@nestjs/common";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { PurchasesExpensesReportQueryDto } from "../dto/purchases-expenses-report-query.dto";
import {
  PurchasesExpensesReportPage,
  PurchasesExpensesReportsRepository,
} from "../repositories/purchases-expenses-reports.repository";

@Injectable()
export class PurchasesExpensesReportsService {
  constructor(
    private readonly purchasesExpensesReportsRepository: PurchasesExpensesReportsRepository,
  ) {}

  private toResponse(
    page: PurchasesExpensesReportPage<Record<string, unknown>>,
  ) {
    return {
      data: page.rows,
      meta: {
        page: page.page,
        limit: page.limit,
        total: page.total,
        totalPages: page.totalPages,
        ...(page.totals ? { totals: page.totals } : {}),
      },
    };
  }

  async getPurchasesByItem(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ) {
    const page = await this.purchasesExpensesReportsRepository.purchasesByItem(
      tenant,
      query,
    );

    return this.toResponse(page);
  }
  async getExpenseDetails(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ) {
    const page = await this.purchasesExpensesReportsRepository.expenseDetails(
      tenant,
      query,
    );
    return this.toResponse(page);
  }
  async getBillableExpenseDetails(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ) {
    const page =
      await this.purchasesExpensesReportsRepository.billableExpenseDetails(
        tenant,
        query,
      );
    return this.toResponse(page);
  }

  async getBillDetails(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ) {
    const page = await this.purchasesExpensesReportsRepository.billDetails(
      tenant,
      query,
    );
    return this.toResponse(page);
  }
  async getVendorCreditsDetails(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ) {
    const page =
      await this.purchasesExpensesReportsRepository.vendorCreditsDetails(
        tenant,
        query,
      );
    return this.toResponse(page);
  }
  async getExpensesByCategory(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ) {
    const page =
      await this.purchasesExpensesReportsRepository.expensesByCategory(
        tenant,
        query,
      );
    return this.toResponse(page);
  }

  async getExpensesByCustomer(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ) {
    const page =
      await this.purchasesExpensesReportsRepository.expensesByCustomer(
        tenant,
        query,
      );
    return this.toResponse(page);
  }
  async getExpensesByEmployee(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ) {
    const page =
      await this.purchasesExpensesReportsRepository.expensesByEmployee(
        tenant,
        query,
      );
    return this.toResponse(page);
  }
  async getPurchasesByVendor(
    tenant: TenantContext,
    query: PurchasesExpensesReportQueryDto,
  ) {
    const page =
      await this.purchasesExpensesReportsRepository.purchasesByVendor(
        tenant,
        query,
      );
    return this.toResponse(page);
  }
}
