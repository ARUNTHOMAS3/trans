import { Body, Controller, Get, Param, Post, Query } from "@nestjs/common";
import { Tenant } from "../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { CreditNotesService } from "./credit-notes.service";
import { CreateCreditNoteDto } from "./dto/create-credit-note.dto";

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

  @Get(":id")
  async findOne(@Param("id") id: string, @Tenant() tenant: TenantContext) {
    return this.creditNotesService.findOne(id, tenant);
  }
}
