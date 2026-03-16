import { Module } from "@nestjs/common";
import { CustomersController } from "./controllers/customers.controller";
import { SalesController } from "./controllers/sales.controller";
import { CustomersService } from "./services/customers.service";
import { HsnSacService } from "./services/hsn-sac.service";
import { AccountantModule } from "../accountant/accountant.module";

@Module({
  imports: [AccountantModule],
  controllers: [CustomersController, SalesController],
  providers: [CustomersService, HsnSacService],
  exports: [CustomersService, HsnSacService],
})
export class SalesModule {}
