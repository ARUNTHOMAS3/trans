import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Put,
  Param,
  Delete,
  Query,
} from "@nestjs/common";
import { PurchaseOrdersService } from "../services/purchase-orders.service";
import { CreatePurchaseOrderDto } from "../dto/create-purchase-order.dto";
import { UpdatePurchaseOrderDto } from "../dto/update-purchase-order.dto";
import { Tenant } from "../../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";

@Controller("purchase-orders")
export class PurchaseOrdersController {
  constructor(private readonly purchaseOrdersService: PurchaseOrdersService) {}

  @Post()
  create(
    @Tenant() tenant: TenantContext,
    @Body() createPurchaseOrderDto: CreatePurchaseOrderDto,
  ) {
    return this.purchaseOrdersService.create(createPurchaseOrderDto, tenant);
  }

  @Get()
  findAll(
    @Tenant() tenant: TenantContext,
    @Query("page") page?: number,
    @Query("limit") limit?: number,
    @Query("search") search?: string,
    @Query("status") status?: string,
    @Query("vendorId") vendorId?: string,
    @Query("vendor_id") vendorIdSnake?: string,
  ) {
    const resolvedVendorId = vendorId ?? vendorIdSnake;
    return this.purchaseOrdersService.findAll(
      tenant,
      page ? +page : 1,
      limit ? +limit : 100,
      search,
      status,
      resolvedVendorId,
    );
  }

  @Get("next-number")
  getNextNumber(@Tenant() tenant: TenantContext) {
    return this.purchaseOrdersService.getNextNumber(tenant);
  }

  @Get("settings")
  getSettings(@Tenant() tenant: TenantContext) {
    return this.purchaseOrdersService.getSettings(tenant);
  }

  @Post("settings")
  updateSettings(@Tenant() tenant: TenantContext, @Body() body: any) {
    return this.purchaseOrdersService.updateSettings(tenant, body ?? {});
  }

  @Get(":id([0-9a-fA-F-]{36})")
  findOne(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.purchaseOrdersService.findOne(id, tenant);
  }

  @Patch(":id([0-9a-fA-F-]{36})")
  @Put(":id([0-9a-fA-F-]{36})")
  update(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
    @Body() updatePurchaseOrderDto: UpdatePurchaseOrderDto,
  ) {
    return this.purchaseOrdersService.update(
      id,
      tenant,
      updatePurchaseOrderDto,
    );
  }

  @Delete(":id([0-9a-fA-F-]{36})")
  remove(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.purchaseOrdersService.remove(id, tenant);
  }
}
