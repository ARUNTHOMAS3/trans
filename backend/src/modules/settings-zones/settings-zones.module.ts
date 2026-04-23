import { Module } from "@nestjs/common";
import { SupabaseModule } from "../supabase/supabase.module";
import { SettingsZonesController } from "./settings-zones.controller";
import { SettingsZonesService } from "./settings-zones.service";

@Module({
  imports: [SupabaseModule],
  controllers: [SettingsZonesController],
  providers: [SettingsZonesService],
})
export class SettingsZonesModule {}
