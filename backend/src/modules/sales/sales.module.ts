import { Module } from "@nestjs/common";
import { CustomersController } from "./controllers/customers.controller";
import { SalesController } from "./controllers/sales.controller";
import { CustomersService } from "./services/customers.service";
import { HsnSacService } from "./services/hsn-sac.service";
import { AccountantModule } from "../accountant/accountant.module";
import { SupabaseModule } from "../supabase/supabase.module";
import { SalesService } from "./services/sales.service";
import { SequencesModule } from "../../sequences/sequences.module";
import { PaymentsReceivedController } from "./controllers/payments-received.controller";
import { PaymentsReceivedService } from "./services/payments-received.service";
import { RetainerInvoicesController } from "./controllers/retainer-invoices.controller";
import { RetainerInvoicesService } from "./services/retainer-invoices.service";
import { SalesReturnsModule } from "./sales-returns/sales-returns.module";
import { CreditNotesModule } from "./credit-notes/credit-notes.module";

@Module({
  imports: [
    AccountantModule, 
    SupabaseModule, 
    SequencesModule,
    SalesReturnsModule,
    CreditNotesModule,
  ],
  controllers: [
    CustomersController,
    SalesController,
    PaymentsReceivedController,
    RetainerInvoicesController,
  ],
  providers: [
    CustomersService,
    HsnSacService,
    SalesService,
    PaymentsReceivedService,
    RetainerInvoicesService,
  ],
  exports: [
    CustomersService,
    HsnSacService,
    SalesService,
    PaymentsReceivedService,
    RetainerInvoicesService,
  ],
})
export class SalesModule {}
