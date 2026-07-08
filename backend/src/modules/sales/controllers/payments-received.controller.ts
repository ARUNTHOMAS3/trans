import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from "@nestjs/common";
import { Tenant } from "../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { CreatePaymentReceivedDto } from "../dto/create-payment-received.dto";
import { UpdatePaymentReceivedDto } from "../dto/update-payment-received.dto";
import { PaymentsReceivedService } from "../services/payments-received.service";

@Controller("sales/payments-received")
export class PaymentsReceivedController {
  constructor(
    private readonly paymentsReceivedService: PaymentsReceivedService,
  ) {}

  @Post()
  create(
    @Tenant() tenant: TenantContext,
    @Body() body: CreatePaymentReceivedDto,
  ) {
    return this.paymentsReceivedService.create(tenant, body);
  }

  @Get()
  findAll(
    @Tenant() tenant: TenantContext,
    @Query("page", new ParseIntPipe({ optional: true })) page?: number,
    @Query("limit", new ParseIntPipe({ optional: true })) limit?: number,
    @Query("search") search?: string,
    @Query("status") status?: string,
  ) {
    return this.paymentsReceivedService.findAll(
      tenant,
      page ?? 1,
      limit ?? 100,
      search,
      status,
    );
  }

  @Get("invoice-customers")
  getInvoiceCustomers(@Tenant() tenant: TenantContext) {
    return this.paymentsReceivedService.getInvoiceCustomers(tenant);
  }

  @Get("unpaid-invoices")
  getUnpaidInvoices(
    @Tenant() tenant: TenantContext,
    @Query("customerId", new ParseUUIDPipe({ version: "4" })) customerId: string,
  ) {
    return this.paymentsReceivedService.getUnpaidInvoices(tenant, customerId);
  }

  @Get(":id")
  findOne(
    @Tenant() tenant: TenantContext,
    @Param("id", new ParseUUIDPipe({ version: "4" })) id: string,
  ) {
    return this.paymentsReceivedService.findOne(id, tenant);
  }

  @Patch(":id")
  update(
    @Tenant() tenant: TenantContext,
    @Param("id", new ParseUUIDPipe({ version: "4" })) id: string,
    @Body() body: UpdatePaymentReceivedDto,
  ) {
    return this.paymentsReceivedService.update(id, tenant, body);
  }
}
