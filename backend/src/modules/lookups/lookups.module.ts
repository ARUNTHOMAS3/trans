import { Module } from "@nestjs/common";
import { LookupsController } from "./lookups.controller";
import { GlobalLookupsController } from "./global-lookups.controller";
import { SupabaseModule } from "../supabase/supabase.module";
import { AccountantModule } from "../accountant/accountant.module";

@Module({
  imports: [SupabaseModule, AccountantModule],
  controllers: [LookupsController, GlobalLookupsController],
  providers: [],
  exports: [],
})
export class LookupsModule {}
