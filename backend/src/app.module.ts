import { MiddlewareConsumer, Module, NestModule } from "@nestjs/common";
import { SentryModule } from "@sentry/nestjs/setup";
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
import { BranchesModule } from "./modules/branches/branches.module";
import { WarehousesSettingsModule } from "./modules/warehouses-settings/warehouses-settings.module";
import { GstModule } from "./modules/gst/gst.module";
import { TransactionSeriesModule } from "./modules/transaction-series/transaction-series.module";
import { UsersModule } from "./modules/users/users.module";
import { SettingsZonesModule } from "./modules/settings-zones/settings-zones.module";
import { RedisModule } from "./modules/redis/redis.module";
import { ResendModule } from "./modules/email/resend.module";
import { AuthModule } from "./common/auth/auth.module";
import { TenantMiddleware } from "./common/middleware/tenant.middleware";

@Module({
  imports: [
    SentryModule.forRoot(),
    ScheduleModule.forRoot(),
    AuthModule,
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
    BranchesModule,
    WarehousesSettingsModule,
    GstModule,
    TransactionSeriesModule,
    UsersModule,
    SettingsZonesModule,
    RedisModule,
    ResendModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(TenantMiddleware).forRoutes("*");
  }
}
