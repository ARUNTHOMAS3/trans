import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
} from "@nestjs/common";
import { Tenant } from "../../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { PurchaseReceivesService } from "../services/purchase-receives.service";
import { CreatePurchaseReceiveDto } from "../dto/create-purchase-receive.dto";
import { UpdatePurchaseReceiveDto } from "../dto/update-purchase-receive.dto";

@Controller("purchase-receives")
export class PurchaseReceivesController {
  constructor(
    private readonly purchaseReceivesService: PurchaseReceivesService,
  ) {}

  @Post()
  create(
    @Tenant() tenant: TenantContext,
    @Body() createDto: CreatePurchaseReceiveDto,
  ) {
    return this.purchaseReceivesService.create(createDto, tenant);
  }

  @Get()
  findAll(
    @Tenant() tenant: TenantContext,
    @Query("page") page?: number,
    @Query("limit") limit?: number,
    @Query("search") search?: string,
    @Query("status") status?: string,
  ) {
    return this.purchaseReceivesService.findAll(
      tenant,
      page ? +page : 1,
      limit ? +limit : 100,
      search,
      status,
    );
  }

  @Get("next-number")
  getNextNumber(
    @Tenant() tenant: TenantContext,
    @Query("prefix") prefix?: string,
  ) {
    return this.purchaseReceivesService.getNextNumber(tenant, prefix);
  }

  @Get(":id")
  findOne(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.purchaseReceivesService.findOne(id, tenant);
  }

  @Patch(":id")
  update(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() updateDto: UpdatePurchaseReceiveDto,
  ) {
    return this.purchaseReceivesService.update(id, updateDto, tenant);
  }

  @Delete(":id")
  remove(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.purchaseReceivesService.remove(id, tenant);
  }
}
