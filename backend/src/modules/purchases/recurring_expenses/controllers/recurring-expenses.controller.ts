import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Patch,
  Param,
  Body,
  Query,
} from "@nestjs/common";
import { RecurringExpensesService } from "../services/recurring-expenses.service";
import { RecurringExpensesCronService } from "../services/recurring-expenses.cron.service";
import { CreateRecurringExpenseDto } from "../dto/create-recurring-expense.dto";
import { UpdateRecurringExpenseDto } from "../dto/update-recurring-expense.dto";
import { BulkUpdateRecurringExpensesDto } from "../dto/bulk-update-recurring-expenses.dto";
import { ListRecurringExpensesQueryDto } from "../dto/list-recurring-expenses-query.dto";
import { Tenant } from "../../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";

@Controller("recurring-expenses")
export class RecurringExpensesController {
  constructor(
    private readonly recurringExpensesService: RecurringExpensesService,
    private readonly cronService: RecurringExpensesCronService,
  ) {}

  @Get("trigger-cron")
  async triggerCron() {
    await this.cronService.processRecurringExpenses();
    return { success: true, message: "Recurring expenses evaluated." };
  }

  @Post()
  create(
    @Tenant() tenant: TenantContext,
    @Body() createDto: CreateRecurringExpenseDto,
  ) {
    return this.recurringExpensesService.create(createDto, tenant);
  }

  @Get()
  findAll(
    @Tenant() tenant: TenantContext,
    @Query() query: ListRecurringExpensesQueryDto,
  ) {
    return this.recurringExpensesService.findAll(tenant, {
      ...query,
      vendor_id: query.vendor_id ?? (query as ListRecurringExpensesQueryDto & { vendorId?: string }).vendorId,
    });
  }

  @Get(":id([0-9a-fA-F-]{36})")
  findOne(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.recurringExpensesService.findOne(id, tenant);
  }

  @Put(":id([0-9a-fA-F-]{36})")
  update(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
    @Body() updateDto: UpdateRecurringExpenseDto,
  ) {
    return this.recurringExpensesService.update(id, updateDto, tenant);
  }

  @Post("bulk-update")
  bulkUpdate(
    @Tenant() tenant: TenantContext,
    @Body() bulkUpdateDto: BulkUpdateRecurringExpensesDto,
  ) {
    return this.recurringExpensesService.bulkUpdate(
      tenant,
      bulkUpdateDto.ids,
      bulkUpdateDto.updateData,
    );
  }

  @Delete("bulk")
  removeBulk(
    @Tenant() tenant: TenantContext,
    @Body("ids") ids: string[],
  ) {
    return this.recurringExpensesService.removeBulk(ids, tenant);
  }

  @Delete(":id([0-9a-fA-F-]{36})")
  remove(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.recurringExpensesService.remove(id, tenant);
  }

  @Patch(":id([0-9a-fA-F-]{36})/stop")
  stop(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.recurringExpensesService.stop(id, tenant);
  }

  @Patch(":id([0-9a-fA-F-]{36})/start")
  start(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.recurringExpensesService.start(id, tenant);
  }

  @Post(":id([0-9a-fA-F-]{36})/create-expense")
  createExpenseNow(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
    @Body("run_date") runDate?: string,
  ) {
    return this.recurringExpensesService.createExpenseNow(id, tenant, runDate);
  }

  @Get(":id([0-9a-fA-F-]{36})/overview")
  overview(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.recurringExpensesService.overview(id, tenant);
  }

  @Get(":id([0-9a-fA-F-]{36})/runs")
  runs(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.recurringExpensesService.runs(id, tenant);
  }

  @Get(":id([0-9a-fA-F-]{36})/history")
  history(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.recurringExpensesService.history(id, tenant);
  }

  @Get(":id([0-9a-fA-F-]{36})/receipts")
  receipts(@Tenant() tenant: TenantContext, @Param("id") id: string) {
    return this.recurringExpensesService.receipts(id, tenant);
  }

  @Post(":id([0-9a-fA-F-]{36})/receipts")
  uploadReceipt(
    @Param("id") id: string,
    @Body() filePayload: any,
    @Tenant() tenant: TenantContext,
  ) {
    return this.recurringExpensesService.uploadReceipt(id, filePayload, tenant);
  }

  @Delete(":id([0-9a-fA-F-]{36})/receipts/:receiptId([0-9a-fA-F-]{36})")
  deleteReceipt(
    @Param("id") id: string,
    @Param("receiptId") receiptId: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.recurringExpensesService.deleteReceipt(id, receiptId, tenant);
  }

  @Get(":id([0-9a-fA-F-]{36})/expenses")
  getRelatedExpenses(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.recurringExpensesService.getRelatedExpenses(id, tenant);
  }
}
