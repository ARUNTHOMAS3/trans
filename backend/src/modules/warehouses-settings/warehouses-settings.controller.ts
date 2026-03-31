import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  HttpStatus,
} from "@nestjs/common";
import { WarehousesSettingsService } from "./warehouses-settings.service";

@Controller("warehouses-settings")
export class WarehousesSettingsController {
  constructor(
    private readonly warehousesSettingsService: WarehousesSettingsService,
  ) {}

  @Get()
  async findAll(@Query("org_id") orgId: string) {
    if (!orgId)
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    try {
      return await this.warehousesSettingsService.findAll(orgId);
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get(":id")
  async findOne(@Param("id") id: string, @Query("org_id") orgId: string) {
    if (!orgId)
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    const warehouse = await this.warehousesSettingsService.findOne(id, orgId);
    if (!warehouse)
      return {
        statusCode: HttpStatus.NOT_FOUND,
        message: "Warehouse not found",
      };
    return warehouse;
  }

  @Post()
  async create(@Body() body: any) {
    try {
      const data = await this.warehousesSettingsService.create(body);
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
  async update(@Param("id") id: string, @Body() body: any) {
    const orgId = body.org_id;
    if (!orgId)
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    try {
      const data = await this.warehousesSettingsService.update(id, orgId, body);
      return { data, message: "Warehouse updated successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Delete(":id")
  async remove(@Param("id") id: string, @Query("org_id") orgId: string) {
    if (!orgId)
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    try {
      await this.warehousesSettingsService.remove(id, orgId);
      return { message: "Warehouse deleted successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }
}
