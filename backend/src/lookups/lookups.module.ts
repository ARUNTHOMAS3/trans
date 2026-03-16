import { Module } from "@nestjs/common";
import { LookupsController } from "./lookups.controller";
import { GlobalLookupsController } from "./global-lookups.controller";
import { SupabaseModule } from "../modules/supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [LookupsController, GlobalLookupsController],
  providers: [],
  exports: [],
})
export class LookupsModule {}
