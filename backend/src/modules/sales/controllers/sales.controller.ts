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
  async getList(@Query("type") type: string) {
    if (!type) throw new BadRequestException("Type is required");
    return this.salesService.getSalesByType(type);
  }

  @Get("customer/:customerId")
  async getSalesOrdersByCustomer(@Param("customerId") customerId: string) {
    if (!customerId) {
      throw new BadRequestException("Customer ID is required");
    }

    return this.salesService.getSalesOrdersByCustomer(customerId);
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
  async getPayments() {
    return this.salesService.getPayments();
  }

  @Post("payments")
  async createPayment(@Body() body: any, @Tenant() tenant: TenantContext) {
    return this.salesService.createPayment(body, tenant.entityId);
  }

  @Get("payment-links")
  async getPaymentLinks() {
    return this.salesService.getPaymentLinks();
  }

  @Post("payment-links")
  async createPaymentLink(@Body() body: any, @Tenant() tenant: TenantContext) {
    return this.salesService.createPaymentLink(body, tenant.entityId);
  }

  @Get("eway-bills")
  async getEWayBills() {
    return this.salesService.getEWayBills();
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

  @Put(":id([0-9a-fA-F-]{36})")
  async updateSalesOrder(
    @Param("id", new ParseUUIDPipe({ version: "4" })) id: string,
    @Body() body: any,
    @Tenant() tenant: TenantContext,
  ) {
    return this.salesService.updateSalesOrder(id, body, tenant.entityId);
  }

  // Must be last — dynamic segment catches anything not matched above
  @Get(":id([0-9a-fA-F-]{36})")
  async getSalesOrderById(
    @Param("id", new ParseUUIDPipe({ version: "4" })) id: string,
  ) {
    return this.salesService.getSalesOrderById(id);
  }
}
