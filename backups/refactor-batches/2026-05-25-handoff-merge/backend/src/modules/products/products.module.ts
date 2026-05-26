// PATH: backend/src/products/products.module.ts

import { Module } from "@nestjs/common";
import {
  ProductsController,
  BranchInventoryController,
} from "./products.controller";
import { ProductsService } from "./products.service";
import { AccountantModule } from "../accountant/accountant.module";
import { WarehousesLegacyController } from "./warehouses-legacy.controller";

@Module({
  imports: [AccountantModule],
  controllers: [
    ProductsController,
    BranchInventoryController,
    WarehousesLegacyController,
  ],
  providers: [ProductsService],
})
export class ProductsModule {}
