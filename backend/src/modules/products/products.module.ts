// PATH: backend/src/products/products.module.ts

import { Module } from "@nestjs/common";
import {
  ProductsController,
  BranchInventoryController,
} from "./products.controller";
import { ProductsService } from "./products.service";
import { AccountantModule } from "../accountant/accountant.module";

@Module({
  imports: [AccountantModule],
  controllers: [ProductsController, BranchInventoryController],
  providers: [ProductsService],
})
export class ProductsModule {}
