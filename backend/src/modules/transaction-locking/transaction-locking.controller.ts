import {
  Controller,
  Get,
  Post,
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
