import { Module } from "@nestjs/common";
import { SupabaseModule } from "../supabase/supabase.module";
import { SettingsCustomizationController } from "./settings-customization.controller";
import { SettingsCustomizationService } from "./settings-customization.service";

@Module({
  imports: [SupabaseModule],
  controllers: [SettingsCustomizationController],
  providers: [SettingsCustomizationService],
})
export class SettingsCustomizationModule {}
