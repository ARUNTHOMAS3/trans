import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Body,
  Param,
} from "@nestjs/common";
import { TransactionLockingService } from "./transaction-locking.service";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Controller("transaction-locking")
export class TransactionLockingController {
  constructor(private readonly service: TransactionLockingService) {}

  @Get()
  async findAll(@Tenant() tenant: TenantContext) {
    return this.service.findAll(tenant);
  }

  @Get("configurations")
  async findConfigurations(@Tenant() tenant: TenantContext) {
    return this.service.findConfigurations(tenant);
  }

  @Get("negative-stock-policy")
  async getNegativeStockPolicy(@Tenant() tenant: TenantContext) {
    return this.service.getNegativeStockPolicy(tenant);
  }

  @Put("negative-stock-policy")
  async setNegativeStockPolicy(
    @Tenant() tenant: TenantContext,
    @Body() data: any,
  ) {
    return this.service.setNegativeStockPolicy(tenant, data?.mode);
  }

  @Post("configurations")
  async createConfiguration(
    @Tenant() tenant: TenantContext,
    @Body() data: any,
  ) {
    return this.service.createConfiguration(tenant, data);
  }

  @Patch("configurations/:id")
  async updateConfiguration(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() data: any,
  ) {
    return this.service.updateConfiguration(tenant, id, data);
  }

  @Delete("configurations/:id")
  async deleteConfiguration(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    return this.service.deleteConfiguration(tenant, id);
  }

  @Post()
  async upsert(@Tenant() tenant: TenantContext, @Body() data: any) {
    return this.service.upsertLock(tenant, data);
  }

  @Delete(":moduleName")
  async remove(
    @Tenant() tenant: TenantContext,
    @Param("moduleName") moduleName: string,
  ) {
    return this.service.deleteLock(tenant, moduleName);
  }
}
