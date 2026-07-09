import { Module } from "@nestjs/common";
import { VendorsModule } from "./vendors/vendors.module";
import { PurchaseOrdersModule } from "./purchase-orders/purchase-orders.module";
import { PurchaseReceivesModule } from "./purchase-receives/purchase-receives.module";
import { BillsModule } from "./bills/bills.module";
import { ExpensesModule } from "./expenses/expenses.module";
import { RecurringExpensesModule } from "./recurring_expenses/recurring-expenses.module";

@Module({
  imports: [
    VendorsModule,
    PurchaseOrdersModule,
    PurchaseReceivesModule,
    BillsModule,
    ExpensesModule,
    RecurringExpensesModule,
  ],
  controllers: [],
  providers: [],
  exports: [
    VendorsModule,
    PurchaseOrdersModule,
    PurchaseReceivesModule,
    BillsModule,
    ExpensesModule,
    RecurringExpensesModule,
  ],
})
export class PurchasesModule {}
