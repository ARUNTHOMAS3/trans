import { Module } from "@nestjs/common";
import { ScheduleModule } from "@nestjs/schedule";
import { SupabaseModule } from "./modules/supabase/supabase.module";
import { PriceListModule } from "./modules/products/pricelist/pricelist.module";
import { ProductsModule } from "./modules/products/products.module";
import { SalesModule } from "./modules/sales/sales.module";
import { LookupsModule } from "./modules/lookups/lookups.module";
import { HealthModule } from "./modules/health/health.module";
import { AccountantModule } from "./modules/accountant/accountant.module";
import { InventoryModule } from "./modules/inventory/inventory.module";
import { PurchasesModule } from "./modules/purchases/purchases.module";
import { DocumentsModule } from "./modules/documents/documents.module";
import { ReportsModule } from "./modules/reports/reports.module";
import { SequencesModule } from "./sequences/sequences.module";
import { TransactionLockingModule } from "./modules/transaction-locking/transaction-locking.module";
import { OutletsModule } from "./modules/outlets/outlets.module";

@Module({
  imports: [
    ScheduleModule.forRoot(),
    // AuthModule, // Temporarily disabled for build phase
    SupabaseModule,
    PriceListModule,
    ProductsModule,
    SalesModule,
    LookupsModule,
    HealthModule,
    AccountantModule,
    InventoryModule,
    PurchasesModule,
    ReportsModule,
    DocumentsModule,
    SequencesModule,
    TransactionLockingModule,
    OutletsModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
