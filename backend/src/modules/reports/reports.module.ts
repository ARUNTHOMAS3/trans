import { Module } from "@nestjs/common";
import { ReportsController } from "./reports.controller";
import { ReportsService } from "./reports.service";
import { SalesReportsRepository } from "./repositories/sales-reports.repository";
import { InventoryReportsRepository } from "./repositories/inventory-reports.repository";
import { PurchasesExpensesReportsRepository } from "./repositories/purchases-expenses-reports.repository";
import { ReportsFavoritesRepository } from "./repositories/reports-favorites.repository";
import { SalesReportsService } from "./services/sales-reports.service";
import { InventoryReportsService } from "./services/inventory-reports.service";
import { PurchasesExpensesReportsService } from "./services/purchases-expenses-reports.service";
import { ReportsFavoritesService } from "./services/reports-favorites.service";
import { SupabaseModule } from "../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [ReportsController],
  providers: [
    ReportsService,
    SalesReportsRepository,
    SalesReportsService,
    InventoryReportsRepository,
    InventoryReportsService,
    PurchasesExpensesReportsRepository,
    PurchasesExpensesReportsService,
    ReportsFavoritesRepository,
    ReportsFavoritesService,
  ],
  exports: [
    ReportsService,
    SalesReportsService,
    InventoryReportsService,
    PurchasesExpensesReportsService,
    ReportsFavoritesService,
  ],
})
export class ReportsModule {}
