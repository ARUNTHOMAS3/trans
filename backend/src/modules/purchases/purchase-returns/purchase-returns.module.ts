import { Module } from "@nestjs/common";
import { PurchaseReturnsController } from "./controllers/purchase-returns.controller";
import { PurchaseReturnsService } from "./services/purchase-returns.service";
import { SupabaseModule } from "../../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [PurchaseReturnsController],
  providers: [PurchaseReturnsService],
  exports: [PurchaseReturnsService],
})
export class PurchaseReturnsModule {}
