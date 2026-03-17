import { Module } from "@nestjs/common";
import { CustomersController } from "./controllers/customers.controller";
import { SalesController } from "./controllers/sales.controller";
import { CustomersService } from "./services/customers.service";
import { HsnSacService } from "./services/hsn-sac.service";
import { AccountantModule } from "../accountant/accountant.module";
import { SupabaseModule } from "../supabase/supabase.module";
import { SalesService } from "./services/sales.service";

@Module({
  imports: [AccountantModule, SupabaseModule],
  controllers: [CustomersController, SalesController],
  providers: [CustomersService, HsnSacService, SalesService],
  exports: [CustomersService, HsnSacService, SalesService],
})
export class SalesModule {}
