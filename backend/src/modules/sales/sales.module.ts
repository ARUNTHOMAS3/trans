import { Module } from "@nestjs/common";
import { CustomersController } from "./controllers/customers.controller";
import { SalesController } from "./controllers/sales.controller";
import { CustomersService } from "./services/customers.service";
import { HsnSacService } from "./services/hsn-sac.service";
import { AccountantModule } from "../accountant/accountant.module";
import { SupabaseModule } from "../supabase/supabase.module";
import { SalesService } from "./services/sales.service";
import { SequencesModule } from "../../sequences/sequences.module";
import { SalesReturnsController } from "./controllers/sales-returns.controller";
import { SalesReturnsService } from "./services/sales-returns.service";
import { PaymentsReceivedController } from "./controllers/payments-received.controller";
import { PaymentsReceivedService } from "./services/payments-received.service";

@Module({
  imports: [AccountantModule, SupabaseModule, SequencesModule],
  controllers: [
    CustomersController,
    SalesController,
    SalesReturnsController,
    PaymentsReceivedController,
  ],
  providers: [
    CustomersService,
    HsnSacService,
    SalesService,
    SalesReturnsService,
    PaymentsReceivedService,
  ],
  exports: [
    CustomersService,
    HsnSacService,
    SalesService,
    SalesReturnsService,
    PaymentsReceivedService,
  ],
})
export class SalesModule {}
