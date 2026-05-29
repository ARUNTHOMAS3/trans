import { Module } from "@nestjs/common";
import { VendorsModule } from "./vendors/vendors.module";
import { PurchaseOrdersModule } from "./purchase-orders/purchase-orders.module";
import { PurchaseReceivesModule } from "./purchase-receives/purchase-receives.module";
import { BillsModule } from "./bills/bills.module";

@Module({
  imports: [VendorsModule, PurchaseOrdersModule, PurchaseReceivesModule, BillsModule],
  controllers: [],
  providers: [],
  exports: [VendorsModule, PurchaseOrdersModule, PurchaseReceivesModule, BillsModule],
})
export class PurchasesModule {}
