import { Module } from "@nestjs/common";
import { PaymentsMadeController } from "./controllers/payments-made.controller";
import { PaymentsMadeService } from "./services/payments-made.service";
import { SupabaseModule } from "../../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [PaymentsMadeController],
  providers: [PaymentsMadeService],
  exports: [PaymentsMadeService],
})
export class PaymentsMadeModule {}
