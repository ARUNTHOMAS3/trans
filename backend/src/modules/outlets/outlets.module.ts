import { Module } from "@nestjs/common";
import { SettingsBranchesModule } from "../settings-branches/settings-branches.module";
import { OutletsService } from "./outlets.service";
import { OutletsController } from "./outlets.controller";
import { SupabaseModule } from "../supabase/supabase.module";
import { WarehousesModule } from "../warehouses/warehouses.module";

@Module({
  imports: [SupabaseModule, SettingsBranchesModule, WarehousesModule],
  controllers: [OutletsController],
  providers: [OutletsService],
  exports: [OutletsService],
})
export class OutletsModule {}
