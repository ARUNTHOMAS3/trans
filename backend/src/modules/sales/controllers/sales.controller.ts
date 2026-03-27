import { Controller, Get, Post, Body, Headers, Query, Param, BadRequestException } from "@nestjs/common";
import { HsnSacService } from "../services/hsn-sac.service";
import { SalesService } from "../services/sales.service";

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

  @Post()
  async createSalesOrder(
    @Body() body: any,
    @Headers('x-org-id') orgId: string,
  ) {
    return this.salesService.createSalesOrder(body, orgId || '00000000-0000-0000-0000-000000000000');
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

  // Must be last — dynamic segment catches anything not matched above
  @Get(':id')
  async getSalesOrderById(@Param('id') id: string) {
    return this.salesService.getSalesOrderById(id);
  }
}
