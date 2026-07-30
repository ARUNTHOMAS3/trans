import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Query,
  Param,
  BadRequestException,
  ParseUUIDPipe,
} from "@nestjs/common";
import { HsnSacService } from "../services/hsn-sac.service";
import { SalesService } from "../services/sales.service";
import { Tenant } from "../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../common/middleware/tenant.middleware";

@Controller("sales")
export class SalesController {
  constructor(
    private readonly hsnSacService: HsnSacService,
    private readonly salesService: SalesService,
  ) {}

  @Get()
  async getList(
    @Query("type") type: string,
    @Query("page") page: string,
    @Query("pageSize") pageSize: string,
    @Tenant() tenant: TenantContext,
  ) {
    if (!type) throw new BadRequestException("Type is required");
    const p = page ? parseInt(page, 10) : 1;
    const ps = pageSize ? parseInt(pageSize, 10) : 50;
    return this.salesService.getSalesByType(type, tenant.entityId, p, ps);
  }

  @Get("awaiting-po-approvals")
  async getAwaitingPoApprovals(@Tenant() tenant: TenantContext) {
    return this.salesService.getAwaitingPoApprovals(tenant);
  }

  @Post("awaiting-po-approvals/approve")
  async approvePurchaseOrders(
    @Body() body: { poIds: string[] },
    @Tenant() tenant: TenantContext,
  ) {
    if (!body.poIds || !Array.isArray(body.poIds) || body.poIds.length === 0) {
      throw new BadRequestException("poIds is required and must be a non-empty array");
    }
    return this.salesService.approvePurchaseOrders(body.poIds, tenant);
  }

  @Get("customer/:customerId")
  async getSalesOrdersByCustomer(
    @Param("customerId") customerId: string,
    @Tenant() tenant: TenantContext,
  ) {
    if (!customerId) {
      throw new BadRequestException("Customer ID is required");
    }

    return this.salesService.getSalesOrdersByCustomer(
      customerId,
      tenant.entityId,
    );
  }

  @Post()
  async createSalesOrder(@Body() body: any, @Tenant() tenant: TenantContext) {
    return this.salesService.createSalesOrder(body, tenant.entityId);
  }

  @Get("hsn/search")
  async searchHsn(@Query("query") query: string) {
    if (!query) throw new BadRequestException("Query is required");
    return this.hsnSacService.searchHsnSac(query, "HSN");
  }

  @Get("sac/search")
  async searchSac(@Query("query") query: string) {
    if (!query) throw new BadRequestException("Query is required");
    return this.hsnSacService.searchHsnSac(query, "SAC");
  }

  @Get("search")
  async searchHsnSac(
    @Query("query") query: string,
    @Query("type") type: "HSN" | "SAC",
  ) {
    if (!query) throw new BadRequestException("Query is required");
    if (type !== "HSN" && type !== "SAC") {
      throw new BadRequestException("Type must be HSN or SAC");
    }
    return this.hsnSacService.searchHsnSac(query, type);
  }

  @Get("payments")
  async getPayments(@Tenant() tenant: TenantContext) {
    return this.salesService.getPayments(tenant.entityId);
  }

  @Post("payments")
  async createPayment(@Body() body: any, @Tenant() tenant: TenantContext) {
    return this.salesService.createPayment(body, tenant.entityId);
  }

  @Get("payment-links")
  async getPaymentLinks(@Tenant() tenant: TenantContext) {
    return this.salesService.getPaymentLinks(tenant.entityId);
  }

  @Post("payment-links")
  async createPaymentLink(@Body() body: any, @Tenant() tenant: TenantContext) {
    return this.salesService.createPaymentLink(body, tenant.entityId);
  }

  @Get("eway-bills")
  async getEWayBills(@Tenant() tenant: TenantContext) {
    return this.salesService.getEWayBills(tenant.entityId);
  }

  @Post("eway-bills")
  async createEWayBill(@Body() body: any, @Tenant() tenant: TenantContext) {
    return this.salesService.createEWayBill(body, tenant.entityId);
  }

  @Get("invoices")
  async getInvoices(@Tenant() tenant: TenantContext) {
    return this.salesService.getInvoices(tenant.entityId);
  }

  @Get("invoices/:id")
  async getInvoiceById(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    if (!id) {
      throw new BadRequestException("Invoice ID is required");
    }
    return this.salesService.getInvoiceById(id, tenant.entityId);
  }

  @Post("invoices")
  async createInvoice(@Body() body: any, @Tenant() tenant: TenantContext) {
    return this.salesService.createInvoice(body, tenant.entityId);
  }

  @Put("invoices/:id")
  async updateInvoice(
    @Param("id") id: string,
    @Body() body: any,
    @Tenant() tenant: TenantContext,
  ) {
    if (!id) {
      throw new BadRequestException("Invoice ID is required");
    }
    return this.salesService.updateInvoice(id, body, tenant.entityId);
  }

  @Put(":id([0-9a-fA-F-]{36})")
  async updateSalesOrder(
    @Param("id", new ParseUUIDPipe({ version: "4" })) id: string,
    @Body() body: any,
    @Tenant() tenant: TenantContext,
  ) {
    return this.salesService.updateSalesOrder(id, body, tenant.entityId);
  }

  @Post(":id/status")
  async updateStatus(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() body: { status: string; reason: string },
  ) {
    return this.salesService.updateSalesOrderStatus(
      id,
      tenant.entityId,
      body.status,
      body.reason,
    );
  }

  // Must be last — dynamic segment catches anything not matched above
  @Get(":id([0-9a-fA-F-]{36})")
  async getSalesOrderById(
    @Param("id", new ParseUUIDPipe({ version: "4" })) id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.salesService.getSalesOrderById(id, tenant.entityId);
  }
}
