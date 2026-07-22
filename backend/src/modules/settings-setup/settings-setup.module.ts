import { Module } from "@nestjs/common";
import { SupabaseModule } from "../supabase/supabase.module";
import { SettingsSetupController } from "./settings-setup.controller";
import { SettingsSetupService } from "./settings-setup.service";

@Module({
  imports: [SupabaseModule],
  controllers: [SettingsSetupController],
  providers: [SettingsSetupService],
})
export class SettingsSetupModule {}
