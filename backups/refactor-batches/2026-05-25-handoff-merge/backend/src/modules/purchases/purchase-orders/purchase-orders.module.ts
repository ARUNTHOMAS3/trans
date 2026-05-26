import { Module } from "@nestjs/common";
import { PurchaseOrdersController } from "./controllers/purchase-orders.controller";
import { PurchaseOrdersService } from "./services/purchase-orders.service";
import { SupabaseModule } from "../../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [PurchaseOrdersController],
  providers: [PurchaseOrdersService],
  exports: [PurchaseOrdersService],
})
export class PurchaseOrdersModule {}
