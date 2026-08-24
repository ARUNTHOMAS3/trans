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
} from '@nestjs/common';
import { Tenant } from '../../../../common/decorators/tenant.decorator';
import { TenantContext } from '../../../../common/middleware/tenant.middleware';
import { SalesReturnsService } from '../services/sales-returns.service';
import { CreateSalesReturnDto } from '../dto/create-sales-return.dto';
import { UpdateSalesReturnDto } from '../dto/update-sales-return.dto';
import { UpdateSalesReturnStatusDto } from '../dto/update-sales-return-status.dto';
import { CreateSalesReturnReceiveDto } from '../dto/create-sales-return-receive.dto';

@Controller('sales-returns')
export class SalesReturnsController {
  constructor(private readonly salesReturnsService: SalesReturnsService) {}

    @Get('lookups/warehouses')
  async getWarehouses(@Tenant() tenant: TenantContext) {
    return this.salesReturnsService.getWarehouses(tenant);
  }

  @Get('next-number')
  async getNextNumber(
    @Tenant() tenant: TenantContext,
    @Query('prefix') prefix?: string,
  ) {
    return this.salesReturnsService.getNextNumber(tenant, prefix);
  }

  // Declared before `:id` so the literal segment wins the route match.
  @Get('customer-history')
  async getCustomerItemHistory(
    @Tenant() tenant: TenantContext,
    @Query('customerId') customerId: string,
    @Query('excludeReturnId') excludeReturnId?: string,
  ) {
    if (!customerId) return [];
    return this.salesReturnsService.getCustomerItemHistory(
      customerId,
      tenant,
      excludeReturnId,
    );
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

  @Get(':id/history')
  async getHistory(@Param('id') id: string, @Tenant() tenant: TenantContext) {
    return this.salesReturnsService.getHistory(id, tenant);
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

  @Patch(':id/status')
  async updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateSalesReturnStatusDto,
    @Tenant() tenant: TenantContext,
  ) {
    return this.salesReturnsService.updateStatus(id, dto.status, tenant);
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

