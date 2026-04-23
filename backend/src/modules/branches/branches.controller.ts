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
import { BranchesService } from "./branches.service";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Controller("branches")
export class BranchesController {
  constructor(private readonly branchesService: BranchesService) {}

  @Get("business-types")
  async findBusinessTypes(@Tenant() tenant: TenantContext) {
    try {
      return await this.branchesService.findBusinessTypes(tenant);
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Post("business-types")
  async createBusinessType(@Body() body: any) {
    if (!body?.business_type && !body?.code) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "business_type or code is required",
      };
    }
    try {
      const data = await this.branchesService.createBusinessType(body);
      return { data, message: "Business type created successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get()
  async findAll(@Tenant() tenant: TenantContext) {
    try {
      return await this.branchesService.findAll(tenant);
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get(":id")
  async findOne(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    const branch = await this.branchesService.findOne(id, tenant);
    if (!branch)
      return { statusCode: HttpStatus.NOT_FOUND, message: "Branch not found" };
    return branch;
  }

  @Post()
  async create(@Tenant() tenant: TenantContext, @Body() body: any) {
    try {
      const data = await this.branchesService.create(body, tenant);
      return { data, message: "Branch created successfully" };
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
      const data = await this.branchesService.update(id, tenant, body);
      return { data, message: "Branch updated successfully" };
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
      await this.branchesService.remove(id, tenant);
      return { message: "Branch deleted successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }
}
