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
import { Tenant } from "../../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { CreateExpenseAttachmentDto, CreateExpenseDto } from "../dto/create-expense.dto";
import { ListExpensesQueryDto } from "../dto/list-expenses-query.dto";
import { UpdateExpenseDto } from "../dto/update-expense.dto";
import { ExpensesService } from "../services/expenses.service";

@Controller("expenses")
export class ExpensesController {
  constructor(private readonly expensesService: ExpensesService) {}

  @Post()
  create(
    @Tenant() tenant: TenantContext,
    @Body() createDto: CreateExpenseDto,
  ) {
    return this.expensesService.create(createDto, tenant);
  }

  @Get()
  findAll(
    @Tenant() tenant: TenantContext,
    @Query() query: ListExpensesQueryDto,
  ) {
    return this.expensesService.findAll(tenant, query);
  }

  @Get("employees")
  employees(@Tenant() tenant: TenantContext) {
    return this.expensesService.getEmployees(tenant);
  }

  @Get(":id([0-9a-fA-F-]{36})")
  findOne(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.expensesService.findOne(id, tenant);
  }

  @Put(":id([0-9a-fA-F-]{36})")
  update(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
    @Body() updateDto: UpdateExpenseDto,
  ) {
    return this.expensesService.update(id, updateDto, tenant);
  }

  @Delete(":id([0-9a-fA-F-]{36})")
  remove(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.expensesService.remove(id, tenant);
  }

  @Get(":id([0-9a-fA-F-]{36})/history")
  history(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.expensesService.history(id, tenant);
  }

  @Get(":id([0-9a-fA-F-]{36})/journal")
  journal(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.expensesService.journal(id, tenant);
  }

  @Get(":id([0-9a-fA-F-]{36})/attachments")
  attachments(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.expensesService.attachments(id, tenant);
  }

  @Post(":id([0-9a-fA-F-]{36})/attachments")
  uploadAttachment(
    @Param("id") id: string,
    @Body() attachmentDto: CreateExpenseAttachmentDto,
    @Tenant() tenant: TenantContext,
  ) {
    return this.expensesService.uploadAttachment(id, attachmentDto, tenant);
  }

  @Delete(":id([0-9a-fA-F-]{36})/attachments/:attachmentId([0-9a-fA-F-]{36})")
  deleteAttachment(
    @Param("id") id: string,
    @Param("attachmentId") attachmentId: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.expensesService.deleteAttachment(id, attachmentId, tenant);
  }

  @Get(":id([0-9a-fA-F-]{36})/mileage")
  mileage(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.expensesService.mileage(id, tenant);
  }
}
