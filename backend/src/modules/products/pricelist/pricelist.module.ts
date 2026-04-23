import { Module } from "@nestjs/common";
import { PriceListController } from "./pricelist.controller";
import { SupabaseModule } from "../../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [PriceListController],
  providers: [],
})
export class PriceListModule {}
