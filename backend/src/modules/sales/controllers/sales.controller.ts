import { Controller, Get, Query, BadRequestException } from "@nestjs/common";
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
}
