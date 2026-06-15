import { Controller, Post, Body, Get, Param, Query, Delete, Put } from "@nestjs/common";
import { BillsService } from "../services/bills.service";
import { Tenant } from "../../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";

@Controller("bills")
export class BillsController {
  constructor(private readonly billsService: BillsService) {}

  @Post()
  async createBill(
    @Tenant() tenant: TenantContext,
    @Body() createBillDto: any,
  ) {
    return this.billsService.createBill(tenant.entityId, createBillDto);
  }

  @Put(":id")
  async updateBill(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() updateBillDto: any,
  ) {
    return this.billsService.updateBill(id, tenant.entityId, updateBillDto);
  }

  @Get()
  async getBills(
    @Tenant() tenant: TenantContext,
    @Query("page") page?: number,
    @Query("limit") limit?: number,
    @Query("search") search?: string,
    @Query("status") status?: string,
  ) {
    return this.billsService.findAll(
      tenant,
      page ? +page : 1,
      limit ? +limit : 100,
      search,
      status,
    );
  }

  @Get(":id")
  async getBill(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    return this.billsService.findOne(id, tenant);
  }

  @Post(":id/status")
  async updateStatus(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() body: { status: string; reason: string },
  ) {
    return this.billsService.updateBillStatus(
      id,
      tenant.entityId,
      body.status,
      body.reason,
    );
  }

  @Delete(":id")
  async deleteBill(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    return this.billsService.remove(id, tenant);
  }
}
