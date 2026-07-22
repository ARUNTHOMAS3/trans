import { Module } from "@nestjs/common";
import { SupabaseModule } from "../supabase/supabase.module";
import { SettingsTaxesController } from "./settings-taxes.controller";
import { SettingsTaxesService } from "./settings-taxes.service";

@Module({
  imports: [SupabaseModule],
  controllers: [SettingsTaxesController],
  providers: [SettingsTaxesService],
  exports: [SettingsTaxesService],
})
export class SettingsTaxesModule {}
