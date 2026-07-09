import { Module } from "@nestjs/common";
import { RecurringExpensesController } from "./controllers/recurring-expenses.controller";
import { RecurringExpensesService } from "./services/recurring-expenses.service";
import { RecurringExpensesCronService } from "./services/recurring-expenses.cron.service";
import { SupabaseModule } from "../../supabase/supabase.module";
import { SequencesModule } from "../../../sequences/sequences.module";
import { ExpensesModule } from "../expenses/expenses.module";

@Module({
  imports: [SupabaseModule, SequencesModule, ExpensesModule],
  controllers: [RecurringExpensesController],
  providers: [
    RecurringExpensesService,
    RecurringExpensesCronService,
  ],
  exports: [RecurringExpensesService],
})
export class RecurringExpensesModule {}
