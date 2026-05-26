import { Body, Controller, Get, Param, Post, Put, Query } from "@nestjs/common";
import { Tenant } from "../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import {
  CompleteMoveOrderDto,
  CreateMoveOrderDto,
  ListMoveOrdersQuery,
  MoveOrdersService,
  UpdateMoveOrderDto,
} from "../services/move-orders.service";

@Controller("move-orders")
export class MoveOrdersController {
  constructor(private readonly moveOrdersService: MoveOrdersService) {}

  @Get()
  findAll(
    @Tenant() tenant: TenantContext,
    @Query() query: ListMoveOrdersQuery,
  ) {
    return this.moveOrdersService.findAll(tenant, query);
  }

  @Get(":id")
  findOne(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.moveOrdersService.findOne(id, tenant);
  }

  @Post()
  create(@Tenant() tenant: TenantContext, @Body() dto: CreateMoveOrderDto) {
    return this.moveOrdersService.create(dto, tenant);
  }

  @Put(":id")
  update(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() dto: UpdateMoveOrderDto,
  ) {
    return this.moveOrdersService.update(id, dto, tenant);
  }

  @Post(":id/complete")
  complete(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() dto: CompleteMoveOrderDto,
  ) {
    return this.moveOrdersService.complete(id, dto, tenant);
  }
}

