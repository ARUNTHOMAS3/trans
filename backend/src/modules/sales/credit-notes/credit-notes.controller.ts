import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
} from "@nestjs/common";
import { Tenant } from "../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { CreditNotesService } from "./credit-notes.service";
import { CreateCreditNoteDto } from "./dto/create-credit-note.dto";
import { ApplyCreditNoteToInvoicesDto } from "./dto/apply-credit-note-to-invoices.dto";

@Controller("credit-notes")
export class CreditNotesController {
  constructor(private readonly creditNotesService: CreditNotesService) {}


  @Get()
  async findAll(
    @Tenant() tenant: TenantContext,
    @Query("page") page?: string,
    @Query("limit") limit?: string,
    @Query("search") search?: string,
    @Query("status") status?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 100;
    return this.creditNotesService.findAll(
      tenant,
      pageNum,
      limitNum,
      search,
      status,
    );
  }

  @Post()
  async create(
    @Body() dto: CreateCreditNoteDto,
    @Tenant() tenant: TenantContext,
  ) {
    return this.creditNotesService.create(dto, tenant);
  }

  @Get("lookups/warehouses")
  async getWarehouses(@Tenant() tenant: TenantContext) {
    return this.creditNotesService.getWarehouses(tenant);
  }

  @Get(":id/journal")
  async getJournal(@Param("id") id: string, @Tenant() tenant: TenantContext) {
    return this.creditNotesService.getJournal(id, tenant);
  }

  @Get(":id/eligible-invoices")
  async getEligibleInvoices(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.creditNotesService.getEligibleInvoices(id, tenant);
  }

  @Post(":id/apply-to-invoices")
  async applyToInvoices(
    @Param("id") id: string,
    @Body() dto: ApplyCreditNoteToInvoicesDto,
    @Tenant() tenant: TenantContext,
  ) {
    return this.creditNotesService.applyToInvoices(id, dto, tenant);
  }

  @Get(":id")
  async findOne(@Param("id") id: string, @Tenant() tenant: TenantContext) {
    return this.creditNotesService.findOne(id, tenant);
  }

  @Put(":id")
  async update(
    @Param("id") id: string,
    @Body() dto: CreateCreditNoteDto,
    @Tenant() tenant: TenantContext,
  ) {
    return this.creditNotesService.update(id, dto, tenant);
  }

  @Delete(":id")
  async remove(@Param("id") id: string, @Tenant() tenant: TenantContext) {
    return this.creditNotesService.remove(id, tenant);
  }
}

