import {
  Body,
  Controller,
  Delete,
  Get,
  Patch,
  Param,
  Post,
  Put,
  Query,
} from "@nestjs/common";
import { Tenant } from "../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import {
  CreateInventoryAdjustmentDto,
  InventoryAdjustmentsService,
  ListInventoryAdjustmentsQuery,
  UpdateInventoryAdjustmentDto,
} from "../services/inventory-adjustments.service";

@Controller("inventory-adjustments")
export class InventoryAdjustmentsController {
  constructor(
    private readonly inventoryAdjustmentsService: InventoryAdjustmentsService,
  ) {}

  @Get()
  findAll(
    @Tenant() tenant: TenantContext,
    @Query() query: ListInventoryAdjustmentsQuery,
  ) {
    return this.inventoryAdjustmentsService.findAll(tenant, query);
  }

  @Get("batch-suggestions")
  getBatchSuggestions(
    @Query("product_id") productId: string,
    @Query("q") query: string,
    @Tenant("entityId") entityId: string,
  ) {
    return this.inventoryAdjustmentsService.getBatchSuggestions(
      productId,
      query ?? "",
      entityId,
    );
  }

  @Get("bin-master")
  getBinMaster(@Query("warehouse_id") warehouseId: string) {
    return this.inventoryAdjustmentsService.getBinMaster(warehouseId);
  }

  @Get("reasons")
  getReasons(@Tenant() tenant: TenantContext) {
    return this.inventoryAdjustmentsService.getReasons(tenant);
  }

  @Post("reasons")
  createReason(
    @Tenant() tenant: TenantContext,
    @Body()
    body: {
      name: string;
      code?: string | null;
      is_active?: boolean;
      sort_order?: number;
    },
  ) {
    return this.inventoryAdjustmentsService.createReason(tenant, body);
  }

  @Patch("reasons/:id")
  updateReason(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body()
    body: {
      name?: string;
      code?: string | null;
      is_active?: boolean;
      sort_order?: number;
    },
  ) {
    return this.inventoryAdjustmentsService.updateReason(id, tenant, body);
  }

  @Delete("reasons/:id")
  deleteReason(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.inventoryAdjustmentsService.deleteReason(id, tenant);
  }

  @Get(":id")
  findOne(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.inventoryAdjustmentsService.findOne(id, tenant);
  }

  @Post()
  create(
    @Tenant() tenant: TenantContext,
    @Body() createDto: CreateInventoryAdjustmentDto,
  ) {
    return this.inventoryAdjustmentsService.create(createDto, tenant);
  }

  @Put(":id")
  update(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() updateDto: UpdateInventoryAdjustmentDto,
  ) {
    return this.inventoryAdjustmentsService.update(id, updateDto, tenant);
  }

  @Delete(":id")
  remove(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.inventoryAdjustmentsService.remove(id, tenant);
  }

  @Post(":id/approve")
  approve(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.inventoryAdjustmentsService.approve(id, tenant);
  }

  @Post(":id/reject")
  reject(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() body: { reason?: string },
  ) {
    return this.inventoryAdjustmentsService.reject(id, tenant, body.reason);
  }
}

// Backward-compatible alias for legacy frontend callers still using /api/v1/bin-master.
@Controller()
export class InventoryAdjustmentsLegacyLookupController {
  constructor(
    private readonly inventoryAdjustmentsService: InventoryAdjustmentsService,
  ) {}

  @Get("bin-master")
  getBinMaster(@Query("warehouse_id") warehouseId: string) {
    return this.inventoryAdjustmentsService.getBinMaster(warehouseId);
  }
}
