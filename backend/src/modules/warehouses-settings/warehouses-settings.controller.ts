import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Param,
  Body,
  HttpStatus,
} from "@nestjs/common";
import { WarehousesSettingsService } from "./warehouses-settings.service";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Controller("warehouses-settings")
export class WarehousesSettingsController {
  constructor(
    private readonly warehousesSettingsService: WarehousesSettingsService,
  ) {}

  @Get()
  async findAll(@Tenant() tenant: TenantContext) {
    try {
      return await this.warehousesSettingsService.findAll(tenant);
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get(":id")
  async findOne(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    const warehouse = await this.warehousesSettingsService.findOne(id, tenant);
    if (!warehouse)
      return {
        statusCode: HttpStatus.NOT_FOUND,
        message: "Warehouse not found",
      };
    return warehouse;
  }

  @Post()
  async create(@Tenant() tenant: TenantContext, @Body() body: any) {
    try {
      const data = await this.warehousesSettingsService.create(body, tenant);
      return { data, message: "Warehouse created successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Put(":id")
  @Patch(":id")
  async update(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() body: any,
  ) {
    try {
      const data = await this.warehousesSettingsService.update(
        id,
        tenant,
        body,
      );
      return { data, message: "Warehouse updated successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Delete(":id")
  async remove(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    try {
      await this.warehousesSettingsService.remove(id, tenant);
      return { message: "Warehouse deleted successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }
}
