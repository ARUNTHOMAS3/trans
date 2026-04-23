import { Module } from "@nestjs/common";
import { VendorsModule } from "./vendors/vendors.module";
import { PurchaseOrdersModule } from "./purchase-orders/purchase-orders.module";
import { PurchaseReceivesModule } from "./purchase-receives/purchase-receives.module";

@Module({
  imports: [VendorsModule, PurchaseOrdersModule, PurchaseReceivesModule],
  controllers: [],
  providers: [],
  exports: [VendorsModule, PurchaseOrdersModule, PurchaseReceivesModule],
})
export class PurchasesModule {}
