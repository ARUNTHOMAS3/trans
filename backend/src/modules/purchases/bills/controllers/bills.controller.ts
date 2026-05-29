import { Controller, Post, Body, Get } from "@nestjs/common";
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

  @Get()
  async getBills(@Tenant() tenant: TenantContext) {
    // Stub for now to avoid crash on frontend fetch
    return { data: [], meta: { total: 0 } };
  }
}
