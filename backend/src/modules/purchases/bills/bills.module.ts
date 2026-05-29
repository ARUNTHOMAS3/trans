import { Module } from "@nestjs/common";
import { BillsController } from "./controllers/bills.controller";
import { BillsService } from "./services/bills.service";
import { SupabaseModule } from "../../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [BillsController],
  providers: [BillsService],
  exports: [BillsService],
})
export class BillsModule {}
