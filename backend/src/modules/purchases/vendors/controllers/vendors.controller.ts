import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
} from "@nestjs/common";
import { VendorsService } from "../services/vendors.service";
import { CreateVendorDto } from "../dto/create-vendor.dto";
import { UpdateVendorDto } from "../dto/update-vendor.dto";
import { Tenant } from "../../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";

@Controller("vendors")
export class VendorsController {
  constructor(private readonly vendorsService: VendorsService) {}

  @Get()
  async findAll(
    @Tenant() tenant: TenantContext,
    @Query("page") page: number = 1,
    @Query("limit") limit: number = 100,
    @Query("search") search?: string,
  ) {
    return this.vendorsService.findAll(tenant, page, limit, search);
  }

  @Get(":id")
  async findOne(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    return this.vendorsService.findOne(id, tenant);
  }

  @Post()
  async create(
    @Tenant() tenant: TenantContext,
    @Body() createVendorDto: CreateVendorDto,
  ) {
    return this.vendorsService.create(createVendorDto, tenant);
  }

  @Put(":id")
  async update(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() updateVendorDto: UpdateVendorDto,
  ) {
    return this.vendorsService.update(id, updateVendorDto, tenant);
  }

  @Delete(":id")
  async remove(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    return this.vendorsService.remove(id, tenant);
  }
}
