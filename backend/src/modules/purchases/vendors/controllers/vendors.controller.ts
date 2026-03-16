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

@Controller("vendors")
export class VendorsController {
  constructor(private readonly vendorsService: VendorsService) {}

  @Get()
  async findAll(
    @Query("page") page: number = 1,
    @Query("limit") limit: number = 100,
    @Query("search") search?: string,
  ) {
    return this.vendorsService.findAll(page, limit, search);
  }

  @Get(":id")
  async findOne(@Param("id") id: string) {
    return this.vendorsService.findOne(id);
  }

  @Post()
  async create(@Body() createVendorDto: CreateVendorDto) {
    return this.vendorsService.create(createVendorDto);
  }

  @Put(":id")
  async update(
    @Param("id") id: string,
    @Body() updateVendorDto: UpdateVendorDto,
  ) {
    return this.vendorsService.update(id, updateVendorDto);
  }

  @Delete(":id")
  async remove(@Param("id") id: string) {
    return this.vendorsService.remove(id);
  }
}
