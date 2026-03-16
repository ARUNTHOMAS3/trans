import { Module } from "@nestjs/common";
import { APP_INTERCEPTOR } from "@nestjs/core";
import { ScheduleModule } from "@nestjs/schedule";
import { AuditInterceptor } from "./common/interceptors/audit.interceptor";
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
  ],
  controllers: [],
  providers: [
    {
      provide: APP_INTERCEPTOR,
      useClass: AuditInterceptor,
    },
  ],
})
export class AppModule {}
