import { Module } from "@nestjs/common";
import { AccountantController } from "./accountant.controller";
import { AccountantService } from "./accountant.service";
import { SupabaseModule } from "../supabase/supabase.module";
import { RecurringJournalsCronService } from "./recurring-journals.cron.service";
import { R2StorageService } from "./r2-storage.service";
import { ReportsController } from "./reports.controller";

@Module({
  imports: [SupabaseModule],
  controllers: [AccountantController, ReportsController],
  providers: [
    AccountantService,
    RecurringJournalsCronService,
    R2StorageService,
  ],
  exports: [AccountantService, R2StorageService],
})
export class AccountantModule {}
