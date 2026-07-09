import { Module } from "@nestjs/common";
import { SupabaseModule } from "../../supabase/supabase.module";
import { SequencesModule } from "../../../sequences/sequences.module";
import { AccountantModule } from "../../accountant/accountant.module";
import { ExpensesController } from "./controllers/expenses.controller";
import { ExpensesService } from "./services/expenses.service";

@Module({
  imports: [SupabaseModule, SequencesModule, AccountantModule],
  controllers: [ExpensesController],
  providers: [ExpensesService],
  exports: [ExpensesService],
})
export class ExpensesModule {}
