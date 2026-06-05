import { Module } from "@nestjs/common";
import { PurchaseOrdersController } from "./controllers/purchase-orders.controller";
import { PurchaseOrdersService } from "./services/purchase-orders.service";
import { SupabaseModule } from "../../supabase/supabase.module";
import { SequencesModule } from "../../../sequences/sequences.module";

@Module({
  imports: [SupabaseModule, SequencesModule],
  controllers: [PurchaseOrdersController],
  providers: [PurchaseOrdersService],
  exports: [PurchaseOrdersService],
})
export class PurchaseOrdersModule {}
