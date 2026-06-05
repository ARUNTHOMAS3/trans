import { Module } from "@nestjs/common";
import { PurchaseReceivesController } from "./controllers/purchase-receives.controller";
import { PurchaseReceivesService } from "./services/purchase-receives.service";
import { SupabaseModule } from "../../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [PurchaseReceivesController],
  providers: [PurchaseReceivesService],
  exports: [PurchaseReceivesService],
})
export class PurchaseReceivesModule {}
