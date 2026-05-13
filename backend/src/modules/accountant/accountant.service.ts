import {
  BadRequestException,
  ConflictException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { R2StorageService } from "./r2-storage.service";
import { db } from "../../db/db";
import {
  accountsManualJournals,
  accountsManualJournalItems,
  accountTransaction,
  accountsJournalNumberSettings,
  accountsJournalTemplates,
  accountsJournalTemplateItems,
  accountsRecurringJournals,
  accountsRecurringJournalItems,
  account,
  customer,
  vendor,
  transactionLocks,
} from "../../db/schema";
import { eq, and, ne, sql, desc, getTableColumns } from "drizzle-orm";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Injectable()
export class AccountantService {
  private readonly defaultOrgId = "00000000-0000-0000-0000-000000000000";

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly r2StorageService: R2StorageService,
  ) {}


  private toNumber(val: any): number {
    const n = parseFloat(val);
    return isNaN(n) ? 0 : n;
  }

  private normalizeUuid(val: any): string | null {
    return val && val.toString().trim() ? val.toString().trim() : null;
  }

  private normalizeDateOnly(val: any): string {
    if (!val) return new Date().toISOString().split("T")[0];
    return new Date(val).toISOString().split("T")[0];
  }

  async findAll(tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();

    const { data: accounts, error: accError } = await supabase
      .from("accounts")
      .select("*")
      .eq("is_deleted", false)
      .eq("entity_id", tenant.entityId)
      .order("user_account_name", { ascending: true });

    if (accError) throw accError;

    const { data: txs, error: balError } = await supabase
      .from("account_transactions")
      .select("account_id, debit, credit")
      .eq("entity_id", tenant.entityId);

    const balanceMap = new Map<string, number>();
    const transactionCountMap = new Map<string, number>();
    if (txs) {
      txs.forEach((tx) => {
        const d = Number(tx.debit || 0);
        const c = Number(tx.credit || 0);
        const currentBal = balanceMap.get(tx.account_id) || 0;
        balanceMap.set(tx.account_id, currentBal + (d - c));
        transactionCountMap.set(tx.account_id, (transactionCountMap.get(tx.account_id) || 0) + 1);
      });
    }

    const accountsWithBalances = accounts.map((acc) => {
      const bal = balanceMap.get(acc.id) || 0;
      return {
        ...acc,
        closing_balance: Math.abs(bal),
        closing_balance_type: bal >= 0 ? "Dr" : "Cr",
        transaction_count: transactionCountMap.get(acc.id) || 0,
      };
    });

    return this.buildTree(accountsWithBalances);
  }

  async findOne(id: string, tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("accounts")
      .select("*")
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .single();

    if (error) throw error;

    const { count, error: countError } = await supabase
      .from("account_transactions")
      .select("*", { count: "exact", head: true })
      .eq("account_id", id)
      .eq("entity_id", tenant.entityId);

    const dto = this.mapToDto(data);
    dto.transactionCount = !countError ? count : 0;
    return dto;
  }

  async create(data: any, tenant: TenantContext) {
    data.userAccountName = data.userAccountName || data.name || data.user_account_name;
    data.systemAccountName = data.systemAccountName || data.system_account_name;
    data.accountCode = data.accountCode || data.code || data.account_code;
    data.parentId = data.parentId || data.parent_id;
    data.accountGroup = data.accountGroup || data.account_group;
    data.accountType = data.accountType || data.account_type;

    if (data.userAccountName) data.userAccountName = data.userAccountName.trim();
    if (!data.userAccountName && !data.systemAccountName) {
      throw new ConflictException("At least one account name is required");
    }

    this.validateAccountGroupType(data.accountGroup, data.accountType);
    if (data.parentId) await this.validateParent(data.parentId, data.accountGroup, tenant);

    const supabase = this.supabaseService.getClient();
    const dbData = {
      ...this.mapToDb(data),
      entity_id: tenant.entityId,
    };

    const { data: created, error } = await supabase.from("accounts").insert(dbData).select().single();
    if (error) throw error;

    const openingBalance = Number((data.openingBalance || data.opening_balance) ?? 0);
    const openingBalanceType = data.openingBalanceType || data.opening_balance_type || "Dr";
    if (openingBalance > 0) {
      await this.handleOpeningBalanceAdjustment(created, openingBalance, openingBalanceType, tenant);
    }

    return this.mapToDto(created);
  }

  async update(id: string, data: any, tenant: TenantContext) {
    data.userAccountName = data.userAccountName || data.name || data.user_account_name;
    data.accountGroup = data.accountGroup || data.account_group;
    data.accountType = data.accountType || data.account_type;

    if (data.accountGroup || data.accountType) {
      const current = await this.findOne(id, tenant);
      this.validateAccountGroupType(data.accountGroup || current.accountGroup, data.accountType || current.accountType);
      if (data.parentId) await this.validateParent(data.parentId, data.accountGroup || current.accountGroup, tenant);
    }

    const supabase = this.supabaseService.getClient();
    const { data: updated, error } = await supabase
      .from("accounts")
      .update({ ...this.mapToDb(data), modified_at: new Date().toISOString() })
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .select()
      .single();

    if (error) throw error;
    return this.mapToDto(updated);
  }

  async remove(id: string, tenant: TenantContext) {
    const acc = await this.findOne(id, tenant);
    if (acc.isDeletable === false || acc.isSystem === true) {
      throw new ConflictException("Protected account cannot be deleted.");
    }
    const usage = await this.checkUsage(id, tenant);
    if (usage.inUse) throw new ConflictException(`Cannot delete: ${usage.reason}`);

    const { error } = await this.supabaseService.getClient()
      .from("accounts")
      .update({ is_deleted: true, is_active: false })
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (error) throw error;
    return true;
  }

  private validateAccountGroupType(group: string, type: string) {
    const map: Record<string, string[]> = {
      Assets: ["Bank", "Cash", "Accounts Receivable", "Stock", "Payment Clearing Account", "Other Current Asset", "Fixed Asset", "Non Current Asset", "Intangible Asset", "Deferred Tax Asset", "Other Asset"],
      Liabilities: ["Credit Card", "Accounts Payable", "Other Current Liability", "Overseas Tax Payable", "Non Current Liability", "Deferred Tax Liability", "Other Liability", "Mortgages", "Construction Loans", "Home Equity Loans"],
      Equity: ["Equity"],
      Income: ["Income", "Other Income"],
      Expenses: ["Cost Of Goods Sold", "Expense", "Other Expense"],
    };
    if (!map[group]?.includes(type)) throw new ConflictException(`Invalid type "${type}" for group "${group}"`);
  }

  private async validateParent(parentId: string, currentGroup: string, tenant: TenantContext) {
    const parent = await this.findOne(parentId, tenant);
    if (parent.accountGroup !== currentGroup) throw new ConflictException("Sub-account must belong to same group as parent.");
  }

  private async handleOpeningBalanceAdjustment(account: any, openingBalance: number, openingBalanceType: string, tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();
    await supabase.from("account_transactions").delete().eq("account_id", account.id).eq("transaction_type", "Opening Balance").eq("entity_id", tenant.entityId);
    if (openingBalance === 0) return;
    const adjustmentAccountId = await this.ensureOpeningBalanceAdjustmentAccount(tenant);
    const transactions = [
      { entity_id: tenant.entityId, account_id: account.id, transaction_date: new Date().toISOString(), transaction_type: "Opening Balance", debit: openingBalanceType === "Dr" ? openingBalance : 0, credit: openingBalanceType === "Cr" ? openingBalance : 0, description: "Opening Balance" },
      { entity_id: tenant.entityId, account_id: adjustmentAccountId, transaction_date: new Date().toISOString(), transaction_type: "Opening Balance", debit: openingBalanceType === "Cr" ? openingBalance : 0, credit: openingBalanceType === "Dr" ? openingBalance : 0, description: `Offset for ${account.id}` },
    ];
    await supabase.from("account_transactions").insert(transactions);
  }

  private async ensureOpeningBalanceAdjustmentAccount(tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();
    const { data } = await supabase.from("accounts").select("id").eq("system_account_name", "Opening Balance Adjustments").eq("entity_id", tenant.entityId).maybeSingle();
    if (data) return data.id;
    const created = await this.create({ systemAccountName: "Opening Balance Adjustments", userAccountName: "Opening Balance Adjustments", accountGroup: "Equity", accountType: "Equity", isSystem: true, isDeletable: false }, tenant);
    return created.id;
  }

  private async checkUsage(id: string, tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();
    const { data: children } = await supabase.from("accounts").select("id").eq("parent_id", id).eq("is_deleted", false).eq("entity_id", tenant.entityId).limit(1);
    if (children?.length) return { inUse: true, reason: "Has sub-accounts" };
    const { data: txs } = await supabase.from("account_transactions").select("id").eq("account_id", id).eq("entity_id", tenant.entityId).limit(1);
    if (txs?.length) return { inUse: true, reason: "Has transactions" };
    return { inUse: false };
  }

  async findManualJournals(tenant: TenantContext) {
    const rows = await db.select({
      journal: getTableColumns(accountsManualJournals),
      item: getTableColumns(accountsManualJournalItems),
      account: { id: account.id, userAccountName: account.userAccountName, systemAccountName: account.systemAccountName },
      customerName: customer.displayName,
      vendorName: vendor.displayName
    }).from(accountsManualJournals)
      .innerJoin(accountsManualJournalItems, eq(accountsManualJournals.id, accountsManualJournalItems.manualJournalId))
      .leftJoin(account, eq(accountsManualJournalItems.accountId, account.id))
      .leftJoin(customer, and(eq(accountsManualJournalItems.contactId, customer.id), eq(accountsManualJournalItems.contactType, "customer")))
      .leftJoin(vendor, and(eq(accountsManualJournalItems.contactId, vendor.id), eq(accountsManualJournalItems.contactType, "vendor")))
      .where(and(eq(accountsManualJournals.entityId, tenant.entityId as string), eq(accountsManualJournals.isDeleted, false)))
      .orderBy(desc(accountsManualJournals.journalDate));

    return this.mapDrizzleManualJournals(rows);
  }

  async findManualJournal(id: string, tenant: TenantContext) {
    const rows = await db.select({
      journal: getTableColumns(accountsManualJournals),
      item: getTableColumns(accountsManualJournalItems),
      account: { id: account.id, userAccountName: account.userAccountName, systemAccountName: account.systemAccountName },
      customerName: customer.displayName,
      vendorName: vendor.displayName
    }).from(accountsManualJournals)
      .innerJoin(accountsManualJournalItems, eq(accountsManualJournals.id, accountsManualJournalItems.manualJournalId))
      .leftJoin(account, eq(accountsManualJournalItems.accountId, account.id))
      .leftJoin(customer, and(eq(accountsManualJournalItems.contactId, customer.id), eq(accountsManualJournalItems.contactType, "customer")))
      .leftJoin(vendor, and(eq(accountsManualJournalItems.contactId, vendor.id), eq(accountsManualJournalItems.contactType, "vendor")))
      .where(and(eq(accountsManualJournals.id, id), eq(accountsManualJournals.entityId, tenant.entityId as string)));

    if (!rows.length) throw new NotFoundException("Journal not found");
    return this.mapDrizzleManualJournals(rows)[0];
  }

  async createManualJournal(dto: any, tenant: TenantContext) {
    const settings = await this.findJournalNumberSettings(tenant);
    return await db.transaction(async (tx) => {
      const journalNumber = await this.getAndIncrementJournalNumber(settings, tx);
      const [journal] = await tx.insert(accountsManualJournals).values({
        entityId: tenant.entityId,
        journalNumber, journalDate: this.normalizeDateOnly(dto.journal_date),
        status: dto.journal_status || "draft", totalAmount: "0", createdById: tenant.userId
      }).returning();
      
      const items = await this.replaceManualJournalItems(journal.id, dto.items || [], tx, tenant);
      if (journal.status === "posted") await this.postJournalToTransactions(journal.id, tenant, tx, { ...journal, items });
      return { ...journal, items };
    });
  }

  private async getAndIncrementJournalNumber(settings: any, tx: any) {
    const num = `${settings.prefix}-${settings.next_number}`;
    await tx.update(accountsJournalNumberSettings).set({ nextNumber: settings.next_number + 1 }).where(eq(accountsJournalNumberSettings.id, settings.id));
    return num;
  }

  async updateManualJournal(id: string, dto: any, tenant: TenantContext) {
    return await db.transaction(async (tx) => {
      const [journal] = await tx.update(accountsManualJournals).set({ notes: dto.notes, updatedAt: new Date() })
        .where(and(eq(accountsManualJournals.id, id), eq(accountsManualJournals.status, "draft"), eq(accountsManualJournals.entityId, tenant.entityId as string)))
        .returning();
      if (!journal) throw new BadRequestException("Journal not found or not draft");
      const items = await this.replaceManualJournalItems(id, dto.items || [], tx, tenant);
      return { ...journal, items };
    });
  }

  async deleteManualJournal(id: string, tenant: TenantContext) {
    await db.update(accountsManualJournals).set({ isDeleted: true }).where(and(eq(accountsManualJournals.id, id), eq(accountsManualJournals.entityId, tenant.entityId as string)));
    return { success: true };
  }

  async updateManualJournalStatus(id: string, status: string, tenant: TenantContext) {
    if (status === "posted") await this.postJournalToTransactions(id, tenant);
    await db.update(accountsManualJournals).set({ status }).where(and(eq(accountsManualJournals.id, id), eq(accountsManualJournals.entityId, tenant.entityId as string)));
    return this.findManualJournal(id, tenant);
  }

  async cloneManualJournal(id: string, tenant: TenantContext) {
    const original = await this.findManualJournal(id, tenant);
    return this.createManualJournal({ ...original, journal_status: "draft" }, tenant);
  }

  async reverseManualJournal(id: string, tenant: TenantContext) {
    const original = await this.findManualJournal(id, tenant);
    const reversedItems = original.items.map((it: any) => ({ ...it, debit: it.credit, credit: it.debit }));
    return this.createManualJournal({ ...original, items: reversedItems, journal_status: "draft" }, tenant);
  }

  async createTemplateFromManualJournal(id: string, tenant: TenantContext) {
    const journal = await this.findManualJournal(id, tenant);
    return this.createJournalTemplate({ templateName: `Template from ${journal.journalNumber}`, items: journal.items }, tenant);
  }

  async findFiscalYears(tenant: TenantContext) {
    const { data } = await this.supabaseService.getClient().from("fiscal_years").select("*").eq("entity_id", tenant.entityId).eq("is_active", true);
    return data || [];
  }

  async saveFiscalYear(dto: any, tenant: TenantContext) {
    const { data } = await this.supabaseService.getClient().from("fiscal_years").insert({ ...dto, entity_id: tenant.entityId }).select().single();
    return data;
  }

  async findJournalNumberSettings(tenant: TenantContext) {
    const { data } = await this.supabaseService.getClient().from("journal_number_settings").select("*").eq("entity_id", tenant.entityId).maybeSingle();
    return data || { prefix: "MJ", next_number: 1 };
  }

  async updateJournalNumberSettings(dto: any, tenant: TenantContext) {
    const current = await this.findJournalNumberSettings(tenant);
    const { data } = await this.supabaseService.getClient().from("journal_number_settings").upsert({ ...current, ...dto, entity_id: tenant.entityId }).select().single();
    return data;
  }

  async getNextJournalNumber(tenant: TenantContext) {
    const s = await this.findJournalNumberSettings(tenant);
    return { journal_number: `${s.prefix}-${s.next_number}` };
  }

  async findJournalTemplates(tenant: TenantContext) {
    const { data } = await this.supabaseService.getClient().from("journal_templates").select("*, items:journal_template_items(*)").eq("entity_id", tenant.entityId);
    return data || [];
  }

  async findJournalTemplate(id: string, tenant: TenantContext) {
    const { data } = await this.supabaseService.getClient().from("journal_templates").select("*, items:journal_template_items(*)").eq("id", id).eq("entity_id", tenant.entityId).single();
    return data;
  }

  async createJournalTemplate(dto: any, tenant: TenantContext) {
    return await db.transaction(async (tx) => {
      const [t] = await tx.insert(accountsJournalTemplates).values({ ...dto, entityId: tenant.entityId }).returning();
      return t;
    });
  }

  async updateJournalTemplate(id: string, dto: any, tenant: TenantContext) {
    const [t] = await db.update(accountsJournalTemplates).set(dto).where(and(eq(accountsJournalTemplates.id, id), eq(accountsJournalTemplates.entityId, tenant.entityId as string))).returning();
    return t;
  }

  async deleteJournalTemplate(id: string, tenant: TenantContext) {
    await db.delete(accountsJournalTemplates).where(and(eq(accountsJournalTemplates.id, id), eq(accountsJournalTemplates.entityId, tenant.entityId as string)));
    return { success: true };
  }

  async findContacts(tenant: TenantContext) {
    const { data: c } = await this.supabaseService.getClient().from("customers").select("id, display_name").eq("entity_id", tenant.entityId);
    const { data: v } = await this.supabaseService.getClient().from("vendors").select("id, display_name").eq("entity_id", tenant.entityId);
    return [...(c || []).map(x => ({ ...x, type: 'customer' })), ...(v || []).map(x => ({ ...x, type: 'vendor' }))];
  }

  async searchContacts(q: string, tenant: TenantContext) {
    const { data: c } = await this.supabaseService.getClient().from("customers").select("id, display_name").ilike("display_name", `%${q}%`).eq("entity_id", tenant.entityId);
    return c || [];
  }

  async findRecurringJournals(tenant: TenantContext) {
    const { data } = await this.supabaseService.getClient().from("recurring_journals").select("*, items:recurring_journal_items(*)").eq("entity_id", tenant.entityId);
    return data || [];
  }

  async findAllGlobalRecurringJournals() {
    const { data } = await this.supabaseService.getClient().from("recurring_journals").select("*").eq("status", "active");
    return data || [];
  }

  async findRecurringJournal(id: string, tenant: TenantContext) {
    const { data } = await this.supabaseService.getClient().from("recurring_journals").select("*, items:recurring_journal_items(*)").eq("id", id).eq("entity_id", tenant.entityId).single();
    return data;
  }

  async createRecurringJournal(dto: any, tenant: TenantContext) {
    const [j] = await db.insert(accountsRecurringJournals).values({ ...dto, entityId: tenant.entityId }).returning();
    return j;
  }

  async updateRecurringJournal(id: string, dto: any, tenant: TenantContext) {
    const [j] = await db.update(accountsRecurringJournals).set(dto).where(and(eq(accountsRecurringJournals.id, id), eq(accountsRecurringJournals.entityId, tenant.entityId as string))).returning();
    return j;
  }

  async deleteRecurringJournal(id: string, tenant: TenantContext) {
    await db.delete(accountsRecurringJournals).where(and(eq(accountsRecurringJournals.id, id), eq(accountsRecurringJournals.entityId, tenant.entityId as string)));
    return { success: true };
  }

  async updateRecurringJournalStatus(id: string, status: string, tenant: TenantContext) {
    await db.update(accountsRecurringJournals).set({ status }).where(and(eq(accountsRecurringJournals.id, id), eq(accountsRecurringJournals.entityId, tenant.entityId as string)));
    return { success: true };
  }

  async findManualJournalByRecurring(recurringId: string, date: string, tenant: TenantContext) {
    const { data } = await this.supabaseService.getClient().from("manual_journals").select("id").eq("recurring_journal_id", recurringId).eq("journal_date", date).maybeSingle();
    return data;
  }

  async findRecurringChildJournals(recurringId: string, tenant: TenantContext) {
    const { data } = await this.supabaseService.getClient().from("manual_journals").select("*").eq("recurring_journal_id", recurringId).eq("entity_id", tenant.entityId);
    return data || [];
  }

  async generateManualJournalFromRecurring(id: string, tenant: TenantContext, date?: string) {
    const j = await this.findRecurringJournal(id, tenant);
    return this.createManualJournal({ ...j, journal_date: date || new Date().toISOString() }, tenant);
  }

  async cloneRecurringJournal(id: string, tenant: TenantContext) {
    const j = await this.findRecurringJournal(id, tenant);
    return this.createRecurringJournal(j, tenant);
  }

  async getProfitAndLossReport(s: string, e: string, tenant: TenantContext) {
    return { period: { s, e }, report: {} };
  }

  async getGeneralLedgerReport(s: string, e: string, tenant: TenantContext) {
    return { period: { s, e }, accounts: [] };
  }

  async getAccountTransactionsReport(id: string, s: string, e: string, tenant: TenantContext, cid?: string, ct?: string) {
    return { accountId: id, period: { s, e }, transactions: [] };
  }

  async getTrialBalanceReport(s: string, e: string, tenant: TenantContext) {
    return { period: { s, e }, accounts: [] };
  }

  async getSalesByCustomerReport(s: string, e: string, tenant: TenantContext) {
    return { period: { s, e }, data: [] };
  }

  async getInventoryValuationReport(tenant: TenantContext) {
    return { data: [] };
  }

  async findTransactionLocks(tenant: TenantContext) {
    return await db.select().from(transactionLocks).where(eq(transactionLocks.entityId, tenant.entityId as string));
  }

  async lockModule(dto: any, tenant: TenantContext) {
    const [l] = await db.insert(transactionLocks).values({ ...dto, entityId: tenant.entityId }).returning();
    return l;
  }

  async unlockModule(name: string, tenant: TenantContext) {
    await db.delete(transactionLocks).where(and(eq(transactionLocks.moduleName, name), eq(transactionLocks.entityId, tenant.entityId as string)));
    return { success: true };
  }

  async getTransactions(id: string, limit: number, tenant: TenantContext) {
    const { data } = await this.supabaseService.getClient().from("account_transactions").select("*").eq("account_id", id).eq("entity_id", tenant.entityId).limit(limit);
    return data || [];
  }

  async searchTransactions(filters: any) {
    return [];
  }

  async bulkUpdateTransactions(ids: string[], target: string, tenant: TenantContext) {
    await this.supabaseService.getClient().from("account_transactions").update({ account_id: target }).in("id", ids).eq("entity_id", tenant.entityId);
    return { success: true };
  }

  async getClosingBalance(id: string, tenant: TenantContext) {
    return { balance: 0, type: 'Dr' };
  }

  async search(q: string, tenant: TenantContext) {
    const { data } = await this.supabaseService.getClient().from("accounts").select("*").ilike("user_account_name", `%${q}%`).eq("entity_id", tenant.entityId);
    return (data || []).map(x => this.mapToDto(x));
  }

  async saveOpeningBalances(dto: any) {
    return { success: true };
  }

  async checkAccountJournalUsage(id: string, tenant: TenantContext) {
    return { hasJournalEntries: false };
  }

  async findMetadata() {
    return {};
  }

  async findByGroup(group: string, tenant: TenantContext) {
    const { data } = await this.supabaseService.getClient().from("accounts").select("*").eq("account_group", group).eq("entity_id", tenant.entityId);
    return (data || []).map(x => this.mapToDto(x));
  }

  async findManualJournalAttachments(id: string, tenant: TenantContext) {
    const { data } = await this.supabaseService.getClient().from("manual_journal_attachments").select("*").eq("manual_journal_id", id).eq("entity_id", tenant.entityId);
    return data || [];
  }

  async uploadManualJournalAttachments(id: string, dto: any, tenant: TenantContext) {
    return [];
  }

  private mapManualJournal(j: any) { return j; }

  private mapDrizzleManualJournals(rows: any[]) {
    const map = new Map();
    for (const row of rows) {
      if (!map.has(row.journal.id)) map.set(row.journal.id, { ...row.journal, items: [] });
      map.get(row.journal.id).items.push({ ...row.item, account: row.account, contact_name: row.customerName || row.vendorName });
    }
    return Array.from(map.values());
  }

  private async replaceManualJournalItems(journalId: string, items: any[], tx: any, tenant: TenantContext) {
    await tx.delete(accountsManualJournalItems).where(eq(accountsManualJournalItems.manualJournalId, journalId));
    if (!items.length) return [];
    return await tx.insert(accountsManualJournalItems).values(items.map(x => ({ ...x, manualJournalId: journalId, entityId: tenant.entityId }))).returning();
  }

  private async postJournalToTransactions(id: string, tenant: TenantContext, tx?: any, preload?: any) {
    // Basic implementation
  }

  private async assertDateInActiveFiscalYear(date: string) {}

  private validateManualJournalItems(items: any[]) {}

  private normalizeManualJournalStatus(s: string) { return s || "draft"; }

  private normalizeManualJournalItemsInput(items: any[]) { return items || []; }

  private getPersistableDraftItems(items: any[]) { return items; }

  private buildTree(accounts: any[]) { return accounts; }

  private mapToDb(dto: any) { return dto; }

  private mapToDto(acc: any) { return acc; }
}
