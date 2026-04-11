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
import { SettingsBranchesService } from "./settings-branches.service";

@Controller("branches")
export class SettingsBranchesController {
  constructor(private readonly settingsBranchesService: SettingsBranchesService) {}

  @Get("business-types")
  async findBusinessTypes(@Query("org_id") orgId: string) {
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      return await this.settingsBranchesService.findBusinessTypes(orgId);
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
      const data = await this.settingsBranchesService.createBusinessType(body);
      return { data, message: "Business type created successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get()
  async findAll(@Query("org_id") orgId: string) {
    if (!orgId)
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    try {
      return await this.settingsBranchesService.findAll(orgId);
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
    const branch = await this.settingsBranchesService.findOne(id, orgId);
    if (!branch)
      return { statusCode: HttpStatus.NOT_FOUND, message: "Branch not found" };
    return branch;
  }

  @Post()
  async create(@Body() body: any) {
    try {
      const data = await this.settingsBranchesService.create(body);
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
  async update(@Param("id") id: string, @Body() body: any) {
    const orgId = body.org_id;
    if (!orgId)
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    try {
      const data = await this.settingsBranchesService.update(id, orgId, body);
      return { data, message: "Branch updated successfully" };
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
      await this.settingsBranchesService.remove(id, orgId);
      return { message: "Branch deleted successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }
}
