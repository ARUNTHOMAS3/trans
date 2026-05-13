import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
} from "@nestjs/common";
import { AccountantService } from "./accountant.service";
import { RecurringJournalsCronService } from "./recurring-journals.cron.service";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Controller("accountant")
export class AccountantController {
  constructor(
    private readonly accountantService: AccountantService,
    private readonly cronService: RecurringJournalsCronService,
  ) {}

  // --- Static Accounts Routes ---

  @Get()
  findAll(@Tenant() tenant: TenantContext) {
    return this.accountantService.findAll(tenant);
  }

  @Get("search")
  search(@Query("q") query: string, @Tenant() tenant: TenantContext) {
    return this.accountantService.search(query, tenant);
  }

  @Get("group/:group")
  findByGroup(@Param("group") group: string, @Tenant() tenant: TenantContext) {
    return this.accountantService.findByGroup(group, tenant);
  }

  @Get("metadata")
  findMetadata() {
    return this.accountantService.findMetadata();
  }

  @Post()
  create(@Body() data: any, @Tenant() tenant: TenantContext) {
    return this.accountantService.create(data, tenant);
  }

  // --- Manual Journal Routes (static before :id routes) ---

  @Get("manual-journals")
  findManualJournals(@Tenant() tenant: TenantContext) {
    return this.accountantService.findManualJournals(tenant);
  }

  @Get("manual-journals/:id([0-9a-fA-F-]{36})")
  findManualJournal(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.findManualJournal(id, tenant);
  }

  @Post("manual-journals")
  createManualJournal(
    @Body() data: any,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.createManualJournal(data, tenant);
  }

  @Put("manual-journals/:id([0-9a-fA-F-]{36})")
  updateManualJournal(
    @Param("id") id: string,
    @Body() data: any,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.updateManualJournal(id, data, tenant);
  }

  @Delete("manual-journals/:id([0-9a-fA-F-]{36})")
  deleteManualJournal(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.deleteManualJournal(id, tenant);
  }

  @Post("manual-journals/:id([0-9a-fA-F-]{36})/status")
  async updateStatus(
    @Param("id") id: string,
    @Body() data: any,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.updateManualJournalStatus(
      id,
      data.status,
      tenant,
    );
  }

  @Get("manual-journals/:id([0-9a-fA-F-]{36})/attachments")
  findManualJournalAttachments(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.findManualJournalAttachments(id, tenant);
  }

  @Post("manual-journals/:id([0-9a-fA-F-]{36})/attachments")
  uploadManualJournalAttachments(
    @Param("id") id: string,
    @Body() data: any,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.uploadManualJournalAttachments(
      id,
      data,
      tenant,
    );
  }

  @Post("manual-journals/:id([0-9a-fA-F-]{36})/clone")
  cloneManualJournal(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.cloneManualJournal(id, tenant);
  }

  @Post("manual-journals/:id([0-9a-fA-F-]{36})/reverse")
  reverseManualJournal(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.reverseManualJournal(id, tenant);
  }

  @Post("manual-journals/:id([0-9a-fA-F-]{36})/template")
  createTemplateFromManualJournal(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.createTemplateFromManualJournal(id, tenant);
  }

  @Get("fiscal-years")
  findFiscalYears(@Tenant() tenant: TenantContext) {
    return this.accountantService.findFiscalYears(tenant);
  }

  @Post("fiscal-years")
  saveFiscalYear(
    @Body() data: any,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.saveFiscalYear(data, tenant);
  }

  @Get("journal-number-settings")
  findJournalNumberSettings(@Tenant() tenant: TenantContext) {
    return this.accountantService.findJournalNumberSettings(tenant);
  }

  @Get("journal-number-settings/next")
  getNextJournalNumber(@Tenant() tenant: TenantContext) {
    return this.accountantService.getNextJournalNumber(tenant);
  }

  @Get("journal-settings")
  findJournalSettingsAlias(@Tenant() tenant: TenantContext) {
    return this.accountantService.findJournalNumberSettings(tenant);
  }

  @Post("journal-number-settings")
  updateJournalNumberSettings(
    @Tenant() tenant: TenantContext,
    @Body() data: any,
  ) {
    return this.accountantService.updateJournalNumberSettings(data, tenant);
  }

  @Get("journal-templates")
  findJournalTemplates(@Tenant() tenant: TenantContext) {
    return this.accountantService.findJournalTemplates(tenant);
  }

  @Get("journal-templates/:id([0-9a-fA-F-]{36})")
  findJournalTemplate(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.findJournalTemplate(id, tenant);
  }

  @Post("journal-templates")
  createJournalTemplate(@Tenant() tenant: TenantContext, @Body() data: any) {
    return this.accountantService.createJournalTemplate(data, tenant);
  }

  @Put("journal-templates/:id([0-9a-fA-F-]{36})")
  updateJournalTemplate(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
    @Body() data: any,
  ) {
    return this.accountantService.updateJournalTemplate(id, data, tenant);
  }

  @Delete("journal-templates/:id([0-9a-fA-F-]{36})")
  deleteJournalTemplate(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.deleteJournalTemplate(id, tenant);
  }

  @Get("contacts")
  findContacts(@Tenant() tenant: TenantContext) {
    return this.accountantService.findContacts(tenant);
  }

  @Get("contacts/search")
  searchContacts(@Query("q") query: string, @Tenant() tenant: TenantContext) {
    return this.accountantService.searchContacts(query, tenant);
  }

  // --- Recurring Journal Routes ---

  @Get("recurring-journals/trigger-cron")
  async triggerCron() {
    await this.cronService.processRecurringJournals();
    return { success: true, message: "Recurring journals evaluated." };
  }

  @Get("recurring-journals")
  findRecurringJournals(@Tenant() tenant: TenantContext) {
    return this.accountantService.findRecurringJournals(tenant);
  }

  @Get("recurring-journals/:id([0-9a-fA-F-]{36})")
  findRecurringJournal(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.findRecurringJournal(id, tenant);
  }

  @Get("recurring-journals/:id([0-9a-fA-F-]{36})/child-journals")
  findChildJournals(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.findRecurringChildJournals(id, tenant);
  }

  @Post("recurring-journals")
  createRecurringJournal(@Tenant() tenant: TenantContext, @Body() data: any) {
    return this.accountantService.createRecurringJournal(data, tenant);
  }

  @Post("recurring-journals/:id([0-9a-fA-F-]{36})/generate")
  generateChildJournal(@Param("id") id: string, @Tenant() tenant: TenantContext) {
    return this.accountantService.generateManualJournalFromRecurring(id, tenant);
  }

  @Post("recurring-journals/:id([0-9a-fA-F-]{36})/clone")
  cloneRecurringJournal(@Param("id") id: string, @Tenant() tenant: TenantContext) {
    return this.accountantService.cloneRecurringJournal(id, tenant);
  }

  @Put("recurring-journals/:id([0-9a-fA-F-]{36})")
  updateRecurringJournal(
    @Param("id") id: string,
    @Body() data: any,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.updateRecurringJournal(id, data, tenant);
  }

  @Put("recurring-journals/:id([0-9a-fA-F-]{36})/status")
  updateRecurringJournalStatus(
    @Param("id") id: string,
    @Body() data: { status: string },
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.updateRecurringJournalStatus(
      id,
      data.status,
      tenant,
    );
  }

  @Delete("recurring-journals/:id([0-9a-fA-F-]{36})")
  deleteRecurringJournal(@Param("id") id: string, @Tenant() tenant: TenantContext) {
    return this.accountantService.deleteRecurringJournal(id, tenant);
  }

  @Get("transactions/search")
  searchTransactions(
    @Query("accountId") accountId?: string,
    @Query("startDate") startDate?: string,
    @Query("endDate") endDate?: string,
    @Query("minAmount") minAmount?: number,
    @Query("maxAmount") maxAmount?: number,
    @Query("limit") limit?: number,
    @Tenant() tenant?: TenantContext,
  ) {
    return this.accountantService.searchTransactions({
      accountId,
      startDate,
      endDate,
      minAmount,
      maxAmount,
      limit,
      tenant: tenant as TenantContext,
    });
  }

  @Post("transactions/bulk-update")
  bulkUpdateTransactions(
    @Body() data: { transactionIds: string[]; targetAccountId: string },
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.bulkUpdateTransactions(
      data.transactionIds,
      data.targetAccountId,
      tenant,
    );
  }

  @Post("opening-balances")
  saveOpeningBalances(@Tenant() tenant: TenantContext, @Body() data: any) {
    return this.accountantService.saveOpeningBalances({ ...data, tenant });
  }

  // --- Transaction Locking Routes ---

  @Get("transaction-locking")
  findTransactionLocks(@Tenant() tenant: TenantContext) {
    return this.accountantService.findTransactionLocks(tenant);
  }

  @Post("transaction-locking")
  lockModule(
    @Body() data: any,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.lockModule(data, tenant);
  }

  @Delete("transaction-locking/:moduleName")
  unlockModule(
    @Param("moduleName") moduleName: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.unlockModule(moduleName, tenant);
  }

  // --- Dynamic Accounts Routes (must be last) ---

  @Get(":id([0-9a-fA-F-]{36})/journal-usage")
  checkJournalUsage(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.checkAccountJournalUsage(id, tenant);
  }

  @Get(":id([0-9a-fA-F-]{36})")
  findOne(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.findOne(id, tenant);
  }

  @Get(":id([0-9a-fA-F-]{36})/transactions")
  getTransactions(
    @Param("id") id: string,
    @Query("limit") limit?: number,
    @Tenant() tenant?: TenantContext,
  ) {
    return this.accountantService.getTransactions(
      id,
      limit,
      tenant as TenantContext,
    );
  }

  @Get(":id([0-9a-fA-F-]{36})/closing-balance")
  getClosingBalance(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.getClosingBalance(id, tenant);
  }

  @Put(":id([0-9a-fA-F-]{36})")
  update(
    @Param("id") id: string,
    @Body() data: any,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.update(id, data, tenant);
  }

  @Delete(":id([0-9a-fA-F-]{36})")
  remove(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.accountantService.remove(id, tenant);
  }
}
