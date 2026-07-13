import { Controller, Post, Body, Get, Param, Query, Delete, Put } from "@nestjs/common";
import { PaymentsMadeService } from "../services/payments-made.service";
import { Tenant } from "../../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";

@Controller("payments-made")
export class PaymentsMadeController {
  constructor(private readonly paymentsMadeService: PaymentsMadeService) {}

  @Post()
  async createPaymentMade(
    @Tenant() tenant: TenantContext,
    @Body() dto: any,
  ) {
    console.log('--- Incoming Create Payment Made DTO ---');
    console.log(JSON.stringify(dto, null, 2));
    return this.paymentsMadeService.createPayment(tenant, dto);
  }

  @Get()
  async getPayments(
    @Tenant() tenant: TenantContext,
    @Query("page") page?: number,
    @Query("limit") limit?: number,
    @Query("search") search?: string,
    @Query("status") status?: string,
    @Query("vendorId") vendorId?: string,
  ) {
    console.log('--- Incoming Get Payments Query ---', { page, limit, search, status, vendorId });
    return this.paymentsMadeService.findAll(
      tenant,
      page ? +page : 1,
      limit ? +limit : 100,
      search,
      status,
      vendorId,
    );
  }

  @Get("settings")
  async getSettings(@Tenant() tenant: TenantContext) {
    return this.paymentsMadeService.getSettings(tenant);
  }

  @Get("next-number")
  async getNextNumber(@Tenant() tenant: TenantContext) {
    return this.paymentsMadeService.getNextNumber(tenant);
  }

  @Get(":id")
  async getPayment(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    return this.paymentsMadeService.findOne(id, tenant);
  }

  @Put(":id")
  async updatePayment(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() dto: any,
  ) {
    return this.paymentsMadeService.updatePayment(id, tenant, dto);
  }

  @Delete(":id")
  async deletePayment(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    return this.paymentsMadeService.remove(id, tenant);
  }
}
