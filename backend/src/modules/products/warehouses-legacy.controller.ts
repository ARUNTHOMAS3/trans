import { Controller, Get } from "@nestjs/common";
import { ProductsService } from "./products.service";

@Controller()
export class WarehousesLegacyController {
  constructor(private readonly productsService: ProductsService) {}

  // Backward-compatible alias for callers using /api/v1/warehouses.
  @Get("warehouses")
  getWarehouses() {
    return this.productsService.getWarehouses();
  }
}

