import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  HttpStatus,
} from "@nestjs/common";
import { OutletsService } from "./outlets.service";

@Controller("outlets")
export class OutletsController {
  constructor(private readonly outletsService: OutletsService) {}

  @Get()
  async findAll(@Query("org_id") orgId: string) {
    if (!orgId) {
      return { statusCode: HttpStatus.BAD_REQUEST, message: "org_id is required" };
    }
    try {
      const data = await this.outletsService.findAll(orgId);
      return data;
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get(":id")
  async findOne(@Param("id") id: string, @Query("org_id") orgId: string) {
    if (!orgId) {
      return { statusCode: HttpStatus.BAD_REQUEST, message: "org_id is required" };
    }
    const outlet = await this.outletsService.findOne(id, orgId);
    if (!outlet) {
      return { statusCode: HttpStatus.NOT_FOUND, message: "Location not found" };
    }
    return outlet;
  }

  @Post()
  async create(@Body() body: any) {
    try {
      const data = await this.outletsService.create(body);
      return { data, message: "Location created successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Patch(":id")
  async update(
    @Param("id") id: string,
    @Body() body: any,
  ) {
    try {
      const orgId = body.org_id;
      if (!orgId) {
        return { statusCode: HttpStatus.BAD_REQUEST, message: "org_id is required" };
      }
      const data = await this.outletsService.update(id, orgId, body);
      return { data, message: "Location updated successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Patch(":id/contacts")
  async updateContacts(
    @Param("id") id: string,
    @Query("org_id") orgId: string,
    @Body() body: any,
  ) {
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      const data = await this.outletsService.updateContacts(id, orgId, body);
      return { data, message: "Contacts updated successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Delete(":id")
  async remove(@Param("id") id: string, @Query("org_id") orgId: string) {
    if (!orgId) {
      return { statusCode: HttpStatus.BAD_REQUEST, message: "org_id is required" };
    }
    try {
      await this.outletsService.remove(id, orgId);
      return { message: "Location deleted successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }
}
