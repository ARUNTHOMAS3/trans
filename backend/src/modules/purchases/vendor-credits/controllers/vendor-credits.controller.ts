import { Controller, Post, Body, Get, Param, Query, Delete, Put } from '@nestjs/common';
import { VendorCreditsService } from '../services/vendor-credits.service';
import { Tenant } from '../../../../common/decorators/tenant.decorator';
import { TenantContext } from '../../../../common/middleware/tenant.middleware';
import { CreateVendorCreditDto } from '../dto/create-vendor-credit.dto';

@Controller('vendor-credits')
export class VendorCreditsController {
  constructor(private readonly vendorCreditsService: VendorCreditsService) {}

  @Get()
  async getVendorCredits(
    @Tenant() tenant: TenantContext,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('search') search?: string,
    @Query('status') status?: string,
  ) {
    return this.vendorCreditsService.findAll(
      tenant,
      page ? +page : 1,
      limit ? +limit : 100,
      search,
      status,
    );
  }

  @Get(':id')
  async getVendorCredit(
    @Tenant() tenant: TenantContext,
    @Param('id') id: string,
  ) {
    return this.vendorCreditsService.findOne(id, tenant);
  }

  @Post()
  async createVendorCredit(
    @Tenant() tenant: TenantContext,
    @Body() dto: CreateVendorCreditDto,
  ) {
    return this.vendorCreditsService.create(tenant, dto);
  }

  @Put(':id')
  async updateVendorCredit(
    @Tenant() tenant: TenantContext,
    @Param('id') id: string,
    @Body() dto: Partial<CreateVendorCreditDto>,
  ) {
    return this.vendorCreditsService.update(id, tenant, dto);
  }

  @Delete(':id')
  async deleteVendorCredit(
    @Tenant() tenant: TenantContext,
    @Param('id') id: string,
  ) {
    return this.vendorCreditsService.remove(id, tenant);
  }
}
