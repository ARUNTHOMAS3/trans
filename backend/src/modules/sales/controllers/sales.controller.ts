import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Headers,
  Query,
  Param,
  BadRequestException,
} from "@nestjs/common";
import { HsnSacService } from "../services/hsn-sac.service";
import { SalesService } from "../services/sales.service";

@Controller("sales")
export class SalesController {
  constructor(
    private readonly hsnSacService: HsnSacService,
    private readonly salesService: SalesService,
  ) { }

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
  async createSalesOrder(
    @Body() body: any,
    @Headers("x-org-id") orgId: string,
  ) {
    return this.salesService.createSalesOrder(
      body,
      orgId || "00000000-0000-0000-0000-000000000000",
    );
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
  async createPayment(
    @Body() body: any,
    @Headers("x-org-id") orgId: string,
  ) {
    return this.salesService.createPayment(
      body,
      orgId || "00000000-0000-0000-0000-000000000000",
    );
  }

  @Get("payment-links")
  async getPaymentLinks() {
    return this.salesService.getPaymentLinks();
  }

  @Post("payment-links")
  async createPaymentLink(
    @Body() body: any,
    @Headers("x-org-id") orgId: string,
  ) {
    return this.salesService.createPaymentLink(
      body,
      orgId || "00000000-0000-0000-0000-000000000000",
    );
  }

  @Get("eway-bills")
  async getEWayBills() {
    return this.salesService.getEWayBills();
  }

  @Post("eway-bills")
  async createEWayBill(
    @Body() body: any,
    @Headers("x-org-id") orgId: string,
  ) {
    return this.salesService.createEWayBill(
      body,
      orgId || "00000000-0000-0000-0000-000000000000",
    );
  }

  @Put(":id")
  async updateSalesOrder(
    @Param("id") id: string,
    @Body() body: any,
    @Headers("x-org-id") orgId: string,
  ) {
    return this.salesService.updateSalesOrder(
      id,
      body,
      orgId || "00000000-0000-0000-0000-000000000000",
    );
  }

  // Must be last — dynamic segment catches anything not matched above
  @Get(":id")
  async getSalesOrderById(@Param("id") id: string) {
    return this.salesService.getSalesOrderById(id);
  }
}
