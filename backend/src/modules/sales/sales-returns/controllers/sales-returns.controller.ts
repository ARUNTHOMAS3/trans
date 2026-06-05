import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { Tenant } from '../../../../common/decorators/tenant.decorator';
import { TenantContext } from '../../../../common/middleware/tenant.middleware';
import { SalesReturnsService } from '../services/sales-returns.service';
import { CreateSalesReturnDto } from '../dto/create-sales-return.dto';
import { UpdateSalesReturnDto } from '../dto/update-sales-return.dto';
import { CreateSalesReturnReceiveDto } from '../dto/create-sales-return-receive.dto';

@Controller('sales-returns')
export class SalesReturnsController {
  constructor(private readonly salesReturnsService: SalesReturnsService) {}

  @Get('next-number')
  async getNextNumber(
    @Tenant() tenant: TenantContext,
    @Query('prefix') prefix?: string,
  ) {
    return this.salesReturnsService.getNextNumber(tenant, prefix);
  }

  @Get()
  async findAll(
    @Tenant() tenant: TenantContext,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
    @Query('status') status?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 100;
    return this.salesReturnsService.findAll(tenant, pageNum, limitNum, search, status);
  }

  @Get(':id')
  async findOne(@Param('id') id: string, @Tenant() tenant: TenantContext) {
    return this.salesReturnsService.findOne(id, tenant);
  }

  @Post()
  async create(
    @Body() dto: CreateSalesReturnDto,
    @Tenant() tenant: TenantContext,
  ) {
    return this.salesReturnsService.create(dto, tenant);
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateSalesReturnDto,
    @Tenant() tenant: TenantContext,
  ) {
    return this.salesReturnsService.update(id, dto, tenant);
  }

  @Get(':id/receives')
  async getReceives(@Param('id') id: string, @Tenant() tenant: TenantContext) {
    return this.salesReturnsService.getReceives(id, tenant);
  }

  @Post(':id/receives')
  async createReceive(
    @Param('id') id: string,
    @Body() dto: CreateSalesReturnReceiveDto,
    @Tenant() tenant: TenantContext,
  ) {
    return this.salesReturnsService.createReceive(id, dto, tenant);
  }

  @Delete(':id/receives/:receiveId')
  async removeReceive(
    @Param('id') id: string,
    @Param('receiveId') receiveId: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.salesReturnsService.removeReceive(id, receiveId, tenant);
  }

  @Delete(':id')
  async remove(@Param('id') id: string, @Tenant() tenant: TenantContext) {
    return this.salesReturnsService.remove(id, tenant);
  }
}
