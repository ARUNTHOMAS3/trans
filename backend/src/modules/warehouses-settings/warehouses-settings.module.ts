import { Module } from "@nestjs/common";
import { WarehousesSettingsService } from "./warehouses-settings.service";
import { WarehousesSettingsController } from "./warehouses-settings.controller";
import { SupabaseModule } from "../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [WarehousesSettingsController],
  providers: [WarehousesSettingsService],
  exports: [WarehousesSettingsService],
})
export class WarehousesSettingsModule {}
