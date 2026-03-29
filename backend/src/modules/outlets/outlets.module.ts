import { Module } from "@nestjs/common";
import { BranchesModule } from "../branches/branches.module";
import { OutletsService } from "./outlets.service";
import { OutletsController } from "./outlets.controller";
import { SupabaseModule } from "../supabase/supabase.module";
import { WarehousesSettingsModule } from "../warehouses-settings/warehouses-settings.module";

@Module({
  imports: [SupabaseModule, BranchesModule, WarehousesSettingsModule],
  controllers: [OutletsController],
  providers: [OutletsService],
  exports: [OutletsService],
})
export class OutletsModule {}
