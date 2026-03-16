import { Module } from "@nestjs/common";
import { CurrenciesController } from "./currencies.controller";
import { CurrenciesService } from "./currencies.service";
import { SupabaseModule } from "../modules/supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [CurrenciesController],
  providers: [CurrenciesService],
  exports: [CurrenciesService],
})
export class CurrenciesModule {}
