import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
} from "@nestjs/common";
import { Tenant } from "../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import {
  CreateTransferOrderDto,
  ListTransferOrdersQuery,
  TransferOrdersService,
  UpdateTransferOrderDto,
} from "../services/transfer-orders.service";

@Controller(["transfer-orders", "stock-transfers"])
export class TransferOrdersController {
  constructor(private readonly transferOrdersService: TransferOrdersService) {}

  @Get()
  findAll(
    @Tenant() tenant: TenantContext,
    @Query() query: ListTransferOrdersQuery,
  ) {
    return this.transferOrdersService.findAll(tenant, query);
  }

  @Get(":id")
  findOne(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.transferOrdersService.findOne(id, tenant);
  }

  @Post()
  create(
    @Tenant() tenant: TenantContext,
    @Body() createDto: CreateTransferOrderDto,
  ) {
    return this.transferOrdersService.create(createDto, tenant);
  }

  @Put(":id")
  update(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() updateDto: UpdateTransferOrderDto,
  ) {
    return this.transferOrdersService.update(id, updateDto, tenant);
  }

  @Post(":id/initiate")
  initiate(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.transferOrdersService.initiateTransfer(id, tenant);
  }

  @Post(":id/approve")
  approve(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.transferOrdersService.approveTransfer(id, tenant);
  }

  @Delete(":id")
  remove(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.transferOrdersService.deleteTransfer(id, tenant);
  }
}
