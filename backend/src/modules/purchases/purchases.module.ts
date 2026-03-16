import { Module } from "@nestjs/common";
import { VendorsModule } from "./vendors/vendors.module";
import { PurchaseOrdersModule } from "./purchase-orders/purchase-orders.module";

@Module({
  imports: [VendorsModule, PurchaseOrdersModule],
  controllers: [],
  providers: [],
  exports: [VendorsModule, PurchaseOrdersModule],
})
export class PurchasesModule {}
