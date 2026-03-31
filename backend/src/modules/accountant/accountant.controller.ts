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

@Controller("accountant")
export class AccountantController {
  constructor(
    private readonly accountantService: AccountantService,
    private readonly cronService: RecurringJournalsCronService,
  ) {}

  // --- Static Accounts Routes ---

  @Get()
  findAll(
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.accountantService.findAll(orgId, outletId);
  }

  @Get("search")
  search(
    @Query("q") query: string,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.accountantService.search(query, orgId, outletId);
  }

  @Get("group/:group")
  findByGroup(
    @Param("group") group: string,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.accountantService.findByGroup(group, orgId, outletId);
  }

  @Get("metadata")
  findMetadata() {
    return this.accountantService.findMetadata();
  }

  @Post()
  create(@Body() data: any) {
    console.log("📥 INCOMING POST /accountant:", JSON.stringify(data, null, 2));
    return this.accountantService.create(data);
  }

  // --- Manual Journal Routes (static before :id routes) ---

  @Get("manual-journals")
  findManualJournals(@Query("orgId") orgId?: string) {
    return this.accountantService.findManualJournals(orgId);
  }

  @Get("manual-journals/:id([0-9a-fA-F-]{36})")
  findManualJournal(@Param("id") id: string, @Query("orgId") orgId?: string) {
    return this.accountantService.findManualJournal(id, orgId);
  }

  @Post("manual-journals")
  createManualJournal(@Body() data: any, @Query("orgId") orgId?: string) {
    return this.accountantService.createManualJournal(data, orgId);
  }

  @Put("manual-journals/:id([0-9a-fA-F-]{36})")
  updateManualJournal(
    @Param("id") id: string,
    @Body() data: any,
    @Query("orgId") orgId?: string,
  ) {
    return this.accountantService.updateManualJournal(id, data, orgId);
  }

  @Delete("manual-journals/:id([0-9a-fA-F-]{36})")
  deleteManualJournal(@Param("id") id: string, @Query("orgId") orgId?: string) {
    return this.accountantService.deleteManualJournal(id, orgId);
  }

  @Post("manual-journals/:id([0-9a-fA-F-]{36})/status")
  async updateStatus(
    @Param("id") id: string,
    @Body() data: any,
    @Query("orgId") orgId?: string,
  ) {
    return this.accountantService.updateManualJournalStatus(
      id,
      data.status,
      orgId,
    );
  }

  @Get("manual-journals/:id([0-9a-fA-F-]{36})/attachments")
  findManualJournalAttachments(
    @Param("id") id: string,
    @Query("orgId") orgId?: string,
  ) {
    return this.accountantService.findManualJournalAttachments(id, orgId);
  }

  @Post("manual-journals/:id([0-9a-fA-F-]{36})/attachments")
  uploadManualJournalAttachments(
    @Param("id") id: string,
    @Body() data: any,
    @Query("orgId") orgId?: string,
  ) {
    return this.accountantService.uploadManualJournalAttachments(
      id,
      data,
      orgId,
    );
  }

  @Post("manual-journals/:id([0-9a-fA-F-]{36})/clone")
  cloneManualJournal(@Param("id") id: string, @Query("orgId") orgId?: string) {
    return this.accountantService.cloneManualJournal(id, orgId);
  }

  @Post("manual-journals/:id([0-9a-fA-F-]{36})/reverse")
  reverseManualJournal(
    @Param("id") id: string,
    @Query("orgId") orgId?: string,
  ) {
    return this.accountantService.reverseManualJournal(id, orgId);
  }

  @Post("manual-journals/:id([0-9a-fA-F-]{36})/template")
  createTemplateFromManualJournal(
    @Param("id") id: string,
    @Query("orgId") orgId?: string,
  ) {
    return this.accountantService.createTemplateFromManualJournal(id, orgId);
  }

  @Get("fiscal-years")
  findFiscalYears(@Query("orgId") orgId?: string) {
    return this.accountantService.findFiscalYears(orgId);
  }

  @Post("fiscal-years")
  saveFiscalYear(@Body() data: any, @Query("orgId") orgId?: string) {
    return this.accountantService.saveFiscalYear(data, orgId);
  }

  @Get("journal-number-settings")
  findJournalNumberSettings(
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
    @Query("userId") userId?: string,
  ) {
    return this.accountantService.findJournalNumberSettings({
      orgId,
      outletId,
      userId,
    });
  }

  @Get("journal-number-settings/next")
  getNextJournalNumber(
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
    @Query("userId") userId?: string,
  ) {
    return this.accountantService.getNextJournalNumber({
      orgId,
      outletId,
      userId,
    });
  }

  @Get("journal-settings")
  findJournalSettingsAlias(
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
    @Query("userId") userId?: string,
  ) {
    return this.accountantService.findJournalNumberSettings({
      orgId,
      outletId,
      userId,
    });
  }

  @Post("journal-number-settings")
  updateJournalNumberSettings(@Body() data: any) {
    return this.accountantService.updateJournalNumberSettings(data);
  }

  @Get("journal-templates")
  findJournalTemplates(
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.accountantService.findJournalTemplates({ orgId, outletId });
  }

  @Get("journal-templates/:id([0-9a-fA-F-]{36})")
  findJournalTemplate(@Param("id") id: string, @Query("orgId") orgId?: string) {
    return this.accountantService.findJournalTemplate(id, orgId);
  }

  @Post("journal-templates")
  createJournalTemplate(@Body() data: any) {
    return this.accountantService.createJournalTemplate(data);
  }

  @Put("journal-templates/:id([0-9a-fA-F-]{36})")
  updateJournalTemplate(@Param("id") id: string, @Body() data: any) {
    return this.accountantService.updateJournalTemplate(id, data);
  }

  @Delete("journal-templates/:id([0-9a-fA-F-]{36})")
  deleteJournalTemplate(
    @Param("id") id: string,
    @Query("orgId") orgId?: string,
  ) {
    return this.accountantService.deleteJournalTemplate(id, orgId);
  }

  @Get("contacts")
  findContacts(@Query("orgId") orgId?: string) {
    return this.accountantService.findContacts(orgId);
  }

  @Get("contacts/search")
  searchContacts(@Query("q") query: string, @Query("orgId") orgId?: string) {
    return this.accountantService.searchContacts(query, orgId);
  }

  // --- Recurring Journal Routes ---

  @Get("recurring-journals/trigger-cron")
  async triggerCron() {
    await this.cronService.processRecurringJournals();
    return { success: true, message: "Recurring journals evaluated." };
  }

  @Get("recurring-journals")
  findRecurringJournals(@Query("orgId") orgId?: string) {
    return this.accountantService.findRecurringJournals(orgId);
  }

  @Get("recurring-journals/:id([0-9a-fA-F-]{36})")
  findRecurringJournal(
    @Param("id") id: string,
    @Query("orgId") orgId?: string,
  ) {
    return this.accountantService.findRecurringJournal(id, orgId);
  }

  @Get("recurring-journals/:id([0-9a-fA-F-]{36})/child-journals")
  findChildJournals(@Param("id") id: string, @Query("orgId") orgId?: string) {
    return this.accountantService.findRecurringChildJournals(id, orgId);
  }

  @Post("recurring-journals")
  createRecurringJournal(@Body() data: any) {
    return this.accountantService.createRecurringJournal(data);
  }

  @Post("recurring-journals/:id([0-9a-fA-F-]{36})/generate")
  generateChildJournal(@Param("id") id: string) {
    return this.accountantService.generateManualJournalFromRecurring(id);
  }

  @Post("recurring-journals/:id([0-9a-fA-F-]{36})/clone")
  cloneRecurringJournal(@Param("id") id: string) {
    return this.accountantService.cloneRecurringJournal(id);
  }

  @Put("recurring-journals/:id([0-9a-fA-F-]{36})")
  updateRecurringJournal(@Param("id") id: string, @Body() data: any) {
    return this.accountantService.updateRecurringJournal(id, data);
  }

  @Put("recurring-journals/:id([0-9a-fA-F-]{36})/status")
  updateRecurringJournalStatus(
    @Param("id") id: string,
    @Body() data: { status: string },
  ) {
    return this.accountantService.updateRecurringJournalStatus(id, data.status);
  }

  @Delete("recurring-journals/:id([0-9a-fA-F-]{36})")
  deleteRecurringJournal(@Param("id") id: string) {
    return this.accountantService.deleteRecurringJournal(id);
  }

  @Get("transactions/search")
  searchTransactions(
    @Query("accountId") accountId?: string,
    @Query("startDate") startDate?: string,
    @Query("endDate") endDate?: string,
    @Query("minAmount") minAmount?: number,
    @Query("maxAmount") maxAmount?: number,
    @Query("limit") limit?: number,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.accountantService.searchTransactions({
      accountId,
      startDate,
      endDate,
      minAmount,
      maxAmount,
      limit,
      orgId,
      outletId,
    });
  }

  @Post("transactions/bulk-update")
  bulkUpdateTransactions(
    @Body() data: { transactionIds: string[]; targetAccountId: string },
  ) {
    return this.accountantService.bulkUpdateTransactions(
      data.transactionIds,
      data.targetAccountId,
    );
  }

  @Post("opening-balances")
  saveOpeningBalances(@Body() data: any) {
    return this.accountantService.saveOpeningBalances(data);
  }

  // --- Transaction Locking Routes ---

  @Get("transaction-locking")
  findTransactionLocks(@Query("orgId") orgId?: string) {
    return this.accountantService.findTransactionLocks(orgId);
  }

  @Post("transaction-locking")
  lockModule(@Body() data: any, @Query("orgId") orgId?: string) {
    return this.accountantService.lockModule(data, orgId);
  }

  @Delete("transaction-locking/:moduleName")
  unlockModule(
    @Param("moduleName") moduleName: string,
    @Query("orgId") orgId?: string,
  ) {
    return this.accountantService.unlockModule(moduleName, orgId);
  }

  // --- Dynamic Accounts Routes (must be last) ---

  @Get(":id([0-9a-fA-F-]{36})/journal-usage")
  checkJournalUsage(@Param("id") id: string, @Query("orgId") orgId?: string) {
    return this.accountantService.checkAccountJournalUsage(id, orgId);
  }

  @Get(":id([0-9a-fA-F-]{36})")
  findOne(@Param("id") id: string, @Query("orgId") orgId?: string) {
    return this.accountantService.findOne(id, orgId);
  }

  @Get(":id([0-9a-fA-F-]{36})/transactions")
  getTransactions(
    @Param("id") id: string,
    @Query("limit") limit?: number,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.accountantService.getTransactions(id, limit, orgId, outletId);
  }

  @Get(":id([0-9a-fA-F-]{36})/closing-balance")
  getClosingBalance(
    @Param("id") id: string,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.accountantService.getClosingBalance(id, orgId, outletId);
  }

  @Put(":id([0-9a-fA-F-]{36})")
  update(@Param("id") id: string, @Body() data: any) {
    return this.accountantService.update(id, data);
  }

  @Delete(":id([0-9a-fA-F-]{36})")
  remove(@Param("id") id: string, @Query("orgId") orgId?: string) {
    return this.accountantService.remove(id, orgId);
  }
}
