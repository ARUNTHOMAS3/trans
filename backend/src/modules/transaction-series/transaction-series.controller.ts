import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
} from "@nestjs/common";
import { TransactionSeriesService } from "./transaction-series.service";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Controller("transaction-series")
export class TransactionSeriesController {
  constructor(private readonly service: TransactionSeriesService) {}

  @Get()
  async findAll(@Tenant() tenant: TenantContext) {
    return await this.service.findAll(tenant);
  }

  @Get(":id")
  async findOne(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.service.findOne(id, tenant);
  }

  @Post()
  async create(@Tenant() tenant: TenantContext, @Body() body: any) {
    return this.service.create(tenant, body);
  }

  @Patch(":id")
  async update(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() body: any,
  ) {
    return this.service.update(id, tenant, body);
  }

  @Delete(":id")
  async remove(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.service.remove(id, tenant);
  }
}
