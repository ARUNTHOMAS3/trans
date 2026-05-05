import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Put,
  Delete,
  Query,
} from "@nestjs/common";
import { Tenant } from "../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { PackagesService } from "../services/packages.service";

@Controller("inventory-packages")
export class PackagesController {
  constructor(private readonly packagesService: PackagesService) { }
  @Get("next-number")
  getNextNumber(@Tenant() tenant: TenantContext) {
    return this.packagesService.getNextNumber(tenant);
  }


  @Get()
  findAll(
    @Tenant() tenant: TenantContext,
    @Query("page") page: string,
    @Query("limit") limit: string,
    @Query("search") search?: string,
    @Query("status") status?: string,
  ) {
    return this.packagesService.findAll(
      tenant,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 100,
      search,
      status,
    );
  }

  @Get(":id")
  findOne(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.packagesService.findOne(id, tenant);
  }

  @Post()
  create(@Tenant() tenant: TenantContext, @Body() createDto: any) {
    // Note: Assuming a way to get userId. For now, defaulting to null or passing from tenant if available.
    // TenantContext doesn't typically contain userId in this project, but we'll use a placeholder or check if it exists
    const userId = (tenant as any).userId || null;
    return this.packagesService.create(createDto, tenant, userId);
  }

  @Put(":id")
  update(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() updateDto: any,
  ) {
    return this.packagesService.update(id, updateDto, tenant);
  }

  @Delete(":id")
  remove(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.packagesService.remove(id, tenant);
  }
}
