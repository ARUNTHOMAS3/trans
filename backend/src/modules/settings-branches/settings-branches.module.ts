import { Module } from "@nestjs/common";
import { SettingsBranchesService } from "./settings-branches.service";
import { SettingsBranchesController } from "./settings-branches.controller";
import { SupabaseModule } from "../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [SettingsBranchesController],
  providers: [SettingsBranchesService],
  exports: [SettingsBranchesService],
})
export class SettingsBranchesModule {}
