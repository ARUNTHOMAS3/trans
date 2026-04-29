import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Put,
  Delete,
  Query,
} from "@nestjs/common";
import { Tenant } from "../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { PicklistsService } from "../services/picklists.service";

@Controller("picklists")
export class PicklistsController {
  constructor(private readonly picklistsService: PicklistsService) {}

  @Get()
  findAll(
    @Tenant() tenant: TenantContext,
    @Query("page") page: string,
    @Query("limit") limit: string,
    @Query("search") search?: string,
    @Query("status") status?: string,
  ) {
    return this.picklistsService.findAll(
      tenant,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 100,
      search,
      status,
    );
  }

  // Must be ABOVE :id so NestJS matches "warehouse/xxx/items" first
  @Get("warehouse/:warehouseId/items")
  getWarehouseItems(
    @Tenant() tenant: TenantContext,
    @Param("warehouseId") warehouseId: string,
    @Query("page") page?: string,
    @Query("limit") limit?: string,
    @Query("search") search?: string,
    @Query("customerId") customerId?: string,
    @Query("productId") productId?: string,
    @Query("salesOrderId") salesOrderId?: string,
  ) {
    return this.picklistsService.getWarehouseItems(
      warehouseId,
      tenant,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 100,
      search,
      customerId,
      productId,
      salesOrderId,
    );
  }

  @Get(":id")
  findOne(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.picklistsService.findOne(id, tenant);
  }

  @Post()
  create(@Tenant() tenant: TenantContext, @Body() createDto: any) {
    return this.picklistsService.create(createDto, tenant);
  }

  @Put(":id")
  update(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() updateDto: any,
  ) {
    return this.picklistsService.update(id, updateDto, tenant);
  }

  @Delete(":id")
  remove(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.picklistsService.remove(id, tenant);
  }
}
