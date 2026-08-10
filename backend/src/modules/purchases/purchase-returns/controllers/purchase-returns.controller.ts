import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
} from "@nestjs/common";
import { Tenant } from "../../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { PurchaseReturnsService } from "../services/purchase-returns.service";

@Controller("purchase-returns")
export class PurchaseReturnsController {
  constructor(
    private readonly purchaseReturnsService: PurchaseReturnsService
  ) {}

  @Get("next-number")
  getNextNumber(@Tenant() tenant: TenantContext) {
    return this.purchaseReturnsService.getNextNumber(tenant);
  }

  @Get()
  findAll(
    @Tenant() tenant: TenantContext,
    @Query("page") page?: string,
    @Query("limit") limit?: string,
    @Query("search") search?: string,
    @Query("status") status?: string
  ) {
    return this.purchaseReturnsService.findAll(
      tenant,
      page ? +page : 1,
      limit ? +limit : 100,
      search,
      status
    );
  }

  @Get(":id")
  findOne(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.purchaseReturnsService.findOne(tenant, id);
  }

  @Post()
  create(@Tenant() tenant: TenantContext, @Body() dto: any) {
    return this.purchaseReturnsService.create(tenant, dto);
  }

  @Put(":id")
  update(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() dto: any
  ) {
    return this.purchaseReturnsService.update(tenant, id, dto);
  }

  @Delete(":id")
  remove(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.purchaseReturnsService.remove(tenant, id);
  }
}
