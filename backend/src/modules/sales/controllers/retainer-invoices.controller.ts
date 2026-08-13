import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Post,
  Put,
  Query,
} from "@nestjs/common";
import { Tenant } from "../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { RetainerInvoicesService } from "../services/retainer-invoices.service";

@Controller("sales/retainer-invoices")
export class RetainerInvoicesController {
  constructor(
    private readonly retainerInvoicesService: RetainerInvoicesService,
  ) {}

  @Get()
  findAll(
    @Tenant() tenant: TenantContext,
    @Query("page", new ParseIntPipe({ optional: true })) page?: number,
    @Query("limit", new ParseIntPipe({ optional: true })) limit?: number,
    @Query("search") search?: string,
    @Query("status") status?: string,
  ) {
    return this.retainerInvoicesService.findAll(
      tenant,
      page ?? 1,
      limit ?? 100,
      search,
      status,
    );
  }

  @Get(":id")
  findOne(
    @Param("id", new ParseUUIDPipe({ version: "4" })) id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.retainerInvoicesService.findOne(id, tenant);
  }

  @Post()
  create(@Tenant() tenant: TenantContext, @Body() body: any) {
    return this.retainerInvoicesService.create(tenant, body);
  }

  @Put(":id")
  update(
    @Param("id", new ParseUUIDPipe({ version: "4" })) id: string,
    @Tenant() tenant: TenantContext,
    @Body() body: any,
  ) {
    return this.retainerInvoicesService.update(id, tenant, body);
  }

  @Delete(":id")
  remove(
    @Param("id", new ParseUUIDPipe({ version: "4" })) id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.retainerInvoicesService.delete(id, tenant);
  }
}
