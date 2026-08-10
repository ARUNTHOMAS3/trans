import { Injectable } from "@nestjs/common";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { InventoryReportQueryDto } from "../dto/inventory-report-query.dto";
import {
  InventoryReportPage,
  InventoryReportsRepository,
} from "../repositories/inventory-reports.repository";

@Injectable()
export class InventoryReportsService {
  constructor(
    private readonly inventoryReportsRepository: InventoryReportsRepository,
  ) {}

  private toResponse(page: InventoryReportPage<Record<string, unknown>>) {
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

  async getInventorySummary(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ) {
    const page = await this.inventoryReportsRepository.inventorySummary(
      tenant,
      query,
    );
    const response = this.toResponse(page);
    console.log("[REPORTS BACKEND] Inventory Summary service response", {
      runtimeType: Array.isArray(response) ? "array" : typeof response,
      json: response,
    });
    return response;
  }

  async getBatchDetails(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ) {
    const page = await this.inventoryReportsRepository.batchDetails(
      tenant,
      query,
    );
    return this.toResponse(page);
  }
  async getInventoryValuationSummary(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ) {
    const page = await this.inventoryReportsRepository.inventoryValuationSummary(
      tenant,
      query,
    );
    return this.toResponse(page);
  }
  async getLandedCostSummary(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ) {
    const page = await this.inventoryReportsRepository.landedCostSummary(
      tenant,
      query,
    );
    return this.toResponse(page);
  }
  async getStockSummary(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ) {
    const page = await this.inventoryReportsRepository.stockSummary(
      tenant,
      query,
    );
    return this.toResponse(page);
  }
  async getStockMovement(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ) {
    const page = await this.inventoryReportsRepository.stockMovement(
      tenant,
      query,
    );
    return this.toResponse(page);
  }
  async getInventoryTurnoverByQuantity(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ) {
    const page = await this.inventoryReportsRepository.inventoryTurnoverByQuantity(
      tenant,
      query,
    );
    return this.toResponse(page);
  }
  async getInventoryAdjustmentSummary(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ) {
    const page = await this.inventoryReportsRepository.inventoryAdjustmentSummary(
      tenant,
      query,
    );
    return this.toResponse(page);
  }
  async getInventoryAdjustmentDetails(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ) {
    const page = await this.inventoryReportsRepository.inventoryAdjustmentDetails(
      tenant,
      query,
    );
    return this.toResponse(page);
  }

  async getCommittedStockDetails(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ) {
    const page = await this.inventoryReportsRepository.committedStockDetails(
      tenant,
      query,
    );
    return this.toResponse(page);
  }

  async getAssemblyDetails(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ) {
    const page = await this.inventoryReportsRepository.assemblyDetails(
      tenant,
      query,
    );
    return this.toResponse(page);
  }

  async getInventoryAgingSummary(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ) {
    const page = await this.inventoryReportsRepository.inventoryAgingSummary(
      tenant,
      query,
    );
    return this.toResponse(page);
  }

  async getFifoCostLotTracking(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ) {
    const page = await this.inventoryReportsRepository.fifoCostLotTracking(
      tenant,
      query,
    );
    return this.toResponse(page);
  }
}
