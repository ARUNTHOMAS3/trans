import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from "@nestjs/common";
import { Tenant } from "../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { CreateSalesReturnDto } from "../dto/create-sales-return.dto";
import { UpdateSalesReturnStatusDto } from "../dto/update-sales-return-status.dto";
import { SalesReturnsService } from "../services/sales-returns.service";

@Controller("sales/returns")
export class SalesReturnsController {
  constructor(private readonly salesReturnsService: SalesReturnsService) {}

  @Post()
  create(@Tenant() tenant: TenantContext, @Body() body: CreateSalesReturnDto) {
    return this.salesReturnsService.create(tenant, body);
  }

  @Get()
  findAll(
    @Tenant() tenant: TenantContext,
    @Query("page", new ParseIntPipe({ optional: true })) page?: number,
    @Query("limit", new ParseIntPipe({ optional: true })) limit?: number,
    @Query("search") search?: string,
    @Query("status") status?: string,
  ) {
    return this.salesReturnsService.findAll(
      tenant,
      page ?? 1,
      limit ?? 100,
      search,
      status,
    );
  }

  @Get(":id")
  findOne(
    @Tenant() tenant: TenantContext,
    @Param("id", new ParseUUIDPipe({ version: "4" })) id: string,
  ) {
    return this.salesReturnsService.findOne(id, tenant);
  }

  @Patch(":id/status")
  updateStatus(
    @Tenant() tenant: TenantContext,
    @Param("id", new ParseUUIDPipe({ version: "4" })) id: string,
    @Body() body: UpdateSalesReturnStatusDto,
  ) {
    return this.salesReturnsService.updateStatus(id, tenant, body.status);
  }
}
