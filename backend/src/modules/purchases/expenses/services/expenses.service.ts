import { v4 as uuidv4 } from "uuid";
import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { SequencesService } from "../../../../sequences/sequences.service";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { R2StorageService } from "../../../accountant/r2-storage.service";
import {
  AMOUNT_TAX_MODES,
  EXPENSE_MODES,
  EXPENSE_STATUSES,
  EXPENSE_TYPES,
} from "../constants/expense.constants";
import {
  CreateExpenseAttachmentDto,
  CreateExpenseDto,
  CreateExpenseItemDto,
  CreateExpenseMileageDto,
} from "../dto/create-expense.dto";
import { ListExpensesQueryDto } from "../dto/list-expenses-query.dto";
import { UpdateExpenseDto } from "../dto/update-expense.dto";

type AuditAction = "CREATE" | "UPDATE" | "DELETE";
type ExpenseTransactionType = "Expense";
type ExpenseSourceType = "expense";

interface DbExpenseRow extends Record<string, unknown> {
  amount?: unknown;
  subtotal?: unknown;
  tax_amount?: unknown;
  total_amount?: unknown;
  mark_up_by?: unknown;
  reverse_charge?: boolean | null;
  is_itemized?: boolean | null;
  is_billable?: boolean | null;
  expense_mode?: string | null;
  expense_type?: string | null;
  amount_tax_mode?: string | null;
  status?: string | null;
  expense_account_id?: string | null;
  paid_through_account_id?: string | null;
  expense_date?: string | null;
  expense_number?: string | null;
  invoice_number?: string | null;
  vendor_id?: string | null;
  customer_id?: string | null;
  notes?: string | null;
  id?: string;
}

interface ExpensePageResult {
  rows: any[];
  total: number;
  totalPages: number;
}

interface DbExpenseItemRow extends Record<string, unknown> {
  line_no?: unknown;
  amount?: unknown;
  tax_amount?: unknown;
  expense_account_id?: unknown;
}

interface DbAttachmentRow extends Record<string, unknown> {
  id?: string;
  expense_id?: string;
  file_name?: string;
  original_file_name?: string | null;
  file_url?: string;
  file_type?: string | null;
  file_size?: unknown;
  uploaded_by?: string | null;
  remarks?: string | null;
  created_at?: string | null;
}

interface DbMileageRow extends Record<string, unknown> {
  distance?: unknown;
  rate_per_km?: unknown;
  odometer_start?: unknown;
  odometer_end?: unknown;
  amount?: unknown;
}

interface AccountLookupRow {
  id?: string | null;
  user_account_name?: string | null;
  system_account_name?: string | null;
  account_code?: string | null;
}

interface AccountTransactionInsertRow {
  entity_id: string;
  org_id: string;
  account_id: string;
  transaction_date: string;
  transaction_type: ExpenseTransactionType;
  reference_number: string | null;
  description: string;
  debit: number;
  credit: number;
  source_id: string;
  source_type: ExpenseSourceType;
  contact_id: null;
  contact_type: null;
}

@Injectable()
export class ExpensesService {
  private readonly logger = new Logger(ExpensesService.name);
  private static readonly mileageExpenseAccountName = "Fuel/Mileage Expenses";
  private static readonly accountTransactionType: ExpenseTransactionType = "Expense";
  private static readonly accountTransactionSourceType: ExpenseSourceType = "expense";

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly sequencesService: SequencesService,
    private readonly r2StorageService: R2StorageService,
  ) {}

  private get client() {
    return this.supabaseService.getClient();
  }

  private logTaxDebug(stage: string, value: unknown) {
    this.logger.log(
      [
        "========== TAX DEBUG ==========",
        `Stage: ${stage}`,
        `Value: ${
          typeof value === "string" ? value : JSON.stringify(value, null, 2)
        }`,
        "==============================",
      ].join("\n"),
    );
  }

  private todayDateString(): string {
    return new Date().toISOString().slice(0, 10);
  }

  async getEmployees(tenant: TenantContext) {
    const { data, error } = await this.client
      .from("users")
      .select("id, full_name")
      .eq("entity_id", tenant.entityId)
      .eq("is_active", true)
      .order("full_name", { ascending: true });

    if (error) {
      throw new BadRequestException(
        `Failed to load employees: ${error.message}`,
      );
    }

    return (data ?? []).map((row: any) => ({
      id: row.id?.toString?.() ?? "",
      full_name: row.full_name?.toString?.().trim() ?? "",
    }));
  }

  private normalizeExpenseMode(mode?: string | null): string {
    const value = mode?.toString().trim().toUpperCase();
    return EXPENSE_MODES.includes(value as (typeof EXPENSE_MODES)[number])
      ? value!
      : "RECORD_EXPENSE";
  }

  private normalizeExpenseStatus(status?: string | null): string {
    const value = status?.toString().trim().toUpperCase();
    return EXPENSE_STATUSES.includes(value as (typeof EXPENSE_STATUSES)[number])
      ? value!
      : "RECORDED";
  }

  private normalizeAmountTaxMode(mode?: string | null): string {
    const value = mode?.toString().trim().toUpperCase();
    return AMOUNT_TAX_MODES.includes(value as (typeof AMOUNT_TAX_MODES)[number])
      ? value!
      : "EXCLUSIVE";
  }

  private normalizeExpenseType(type?: string | null): string {
    const value = type?.toString().trim().toUpperCase();
    return EXPENSE_TYPES.includes(value as (typeof EXPENSE_TYPES)[number])
      ? value!
      : "SERVICES";
  }

  private parseNumber(value: unknown, fallback = 0): number {
    if (value === null || value === undefined || value === "") return fallback;
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  private mapDbToDto(row: DbExpenseRow | null): DbExpenseRow | null {
    if (!row) return null;
    return {
      ...row,
      amount: this.parseNumber(row.amount),
      subtotal: this.parseNumber(row.subtotal),
      tax_amount: this.parseNumber(row.tax_amount),
      total_amount: this.parseNumber(row.total_amount),
      mark_up_by:
        row.mark_up_by === null || row.mark_up_by === undefined
          ? null
          : this.parseNumber(row.mark_up_by),
      reverse_charge: row.reverse_charge ?? false,
      is_itemized: row.is_itemized ?? false,
      is_billable: row.is_billable ?? false,
      expense_mode: this.normalizeExpenseMode(row.expense_mode),
      expense_type: this.normalizeExpenseType(row.expense_type),
      amount_tax_mode: this.normalizeAmountTaxMode(row.amount_tax_mode),
      status: this.normalizeExpenseStatus(row.status),
    };
  }

  private mapExpenseItem(row: DbExpenseItemRow) {
    return {
      ...row,
      line_no: parseInt(row.line_no?.toString?.() ?? "0", 10) || 0,
      amount: this.parseNumber(row.amount),
      tax_amount: this.parseNumber(row.tax_amount),
    };
  }

  private mapAttachment(row: DbAttachmentRow) {
    return {
      id: row.id,
      expense_id: row.expense_id,
      file_name: row.file_name,
      original_file_name: row.original_file_name ?? null,
      file_url: row.file_url,
      file_type: row.file_type ?? null,
      file_size: this.parseNumber(row.file_size),
      uploaded_by: row.uploaded_by ?? null,
      remarks: row.remarks ?? null,
      created_at: row.created_at ?? null,
    };
  }

  private async resolveAttachmentFileUrl(
    keyOrUrl?: string | null,
  ): Promise<string> {
    const value = keyOrUrl?.trim() ?? "";
    if (!value) return "";
    if (value.startsWith("data:")) return value;

    try {
      if (value.startsWith("http://") || value.startsWith("https://")) {
        const bucket = process.env.CLOUDFLARE_BUCKET_NAME?.trim();
        if (!bucket) {
          return value;
        }

        const marker = `/${bucket}/`;
        const markerIndex = value.indexOf(marker);
        if (markerIndex === -1) {
          return value;
        }

        const key = value.substring(markerIndex + marker.length);
        return await this.r2StorageService.getPresignedUrl(key);
      }

      return await this.r2StorageService.getPresignedUrl(value);
    } catch (error) {
      this.logger.warn(
        `Failed to resolve expense attachment preview URL for ${value}: ${error instanceof Error ? error.message : String(error)}`,
      );
      return value;
    }
  }

  private async hydrateAttachment(row: DbAttachmentRow) {
    const mapped = this.mapAttachment(row);
    return {
      ...mapped,
      file_url: await this.resolveAttachmentFileUrl(mapped.file_url),
    };
  }

  private mapMileage(row: DbMileageRow | null) {
    if (!row) return null;
    return {
      ...row,
      distance: this.parseNumber(row.distance),
      rate_per_km: this.parseNumber(row.rate_per_km),
      odometer_start: this.parseNumber(row.odometer_start),
      odometer_end: this.parseNumber(row.odometer_end),
      amount: this.parseNumber(row.amount),
    };
  }

  private calculateMileageAmount(mileage: CreateExpenseMileageDto) {
    return this.parseNumber(mileage.distance) * this.parseNumber(mileage.rate_per_km);
  }

  private buildHistorySummary(
    action: string,
    snapshot: Record<string, unknown> | null,
    changedColumns: string[],
  ): string {
    const upperAction = action.toUpperCase();
    if (upperAction === "CREATE" || upperAction === "INSERT") {
      const amount = this.parseNumber(snapshot?.["total_amount"] ?? snapshot?.["amount"]);
      return `Expense Created for ${this.formatAmount(amount)}`;
    }
    if (upperAction === "DELETE") {
      return "Expense Deleted.";
    }
    return "Expense Updated.";
  }

  private formatAmount(amount: number): string {
    return `₹${amount.toFixed(2)}`;
  }

  private accountDisplayName(account?: AccountLookupRow | null): string {
    return (
      account?.user_account_name ||
      account?.system_account_name ||
      account?.account_code ||
      account?.id ||
      "-"
    );
  }

  private async resolveAccountNameMap(accountIds: Array<string | null | undefined>) {
    const ids = Array.from(
      new Set(
        accountIds
          .map((value) => value?.toString().trim())
          .filter(Boolean) as string[],
      ),
    );
    const accountMap = new Map<string, string>();
    if (!ids.length) {
      return accountMap;
    }

    const { data, error } = await this.client
      .from("accounts")
      .select("id,user_account_name,system_account_name,account_code")
      .in("id", ids);
    if (error) {
      throw new BadRequestException(
        `Failed to resolve accounts for journal: ${error.message}`,
      );
    }

    for (const account of data ?? []) {
      const id = account.id?.toString?.();
      if (!id) continue;
      accountMap.set(id, this.accountDisplayName(account));
    }

    return accountMap;
  }

  private async findAccountIdByExactName(
    field: "user_account_name" | "system_account_name",
    value: string,
    tenant: TenantContext,
    entityScoped: boolean,
  ): Promise<string | null> {
    let query = this.client
      .from("accounts")
      .select("id")
      .eq(field, value)
      .limit(1);
    if (entityScoped) {
      query = query.eq("entity_id", tenant.entityId);
    }
    const { data, error } = await query.maybeSingle();
    if (error) {
      throw new BadRequestException(
        `Failed to resolve mileage expense account: ${error.message}`,
      );
    }
    return data?.id?.toString?.() ?? null;
  }

  private async resolveMileageExpenseAccountId(
    tenant: TenantContext,
  ): Promise<string | null> {
    for (const entityScoped of [true, false]) {
      const byUserName = await this.findAccountIdByExactName(
        "user_account_name",
        ExpensesService.mileageExpenseAccountName,
        tenant,
        entityScoped,
      );
      if (byUserName) {
        return byUserName;
      }
      const bySystemName = await this.findAccountIdByExactName(
        "system_account_name",
        ExpensesService.mileageExpenseAccountName,
        tenant,
        entityScoped,
      );
      if (bySystemName) {
        return bySystemName;
      }
    }
    return null;
  }

  private resolveExpenseAccountLabel(row: any, expenseAccount: any): string | null {
    if (expenseAccount) {
      return this.accountDisplayName(expenseAccount);
    }
    if (this.normalizeExpenseMode(row?.expense_mode) === "RECORD_MILEAGE") {
      return ExpensesService.mileageExpenseAccountName;
    }
    return null;
  }

  private buildExpenseJournalDescription(expense: any, lineNo?: number): string {
    const expenseNumber = expense.expense_number?.toString?.().trim();
    if (lineNo && lineNo > 0) {
      return expenseNumber
        ? `Expense ${expenseNumber} line ${lineNo}`
        : `Expense line ${lineNo}`;
    }
    return expenseNumber ? `Expense ${expenseNumber}` : "Expense";
  }

  private buildMileageJournalFallbackEntry(expense: any) {
    const debit =
      this.parseNumber(expense.total_amount, 0) ||
      this.parseNumber(expense.amount, 0);
    return {
      id: `mileage-fallback-${expense.id}`,
      account_id: "",
      account_name: ExpensesService.mileageExpenseAccountName,
      transaction_date:
        expense.expense_date?.toString?.() || new Date().toISOString(),
      transaction_type: "Expense",
      reference_number: expense.expense_number?.toString?.().trim() || null,
      description: this.buildExpenseJournalDescription(expense),
      debit,
      credit: 0,
      source_id: expense.id,
      source_type: "expense",
      created_at: null,
    };
  }

  private async resolvePostingExpenseAccountId(
    expense: DbExpenseRow,
    tenant: TenantContext,
  ) {
    if (this.normalizeExpenseMode(expense?.expense_mode) === "RECORD_MILEAGE") {
      return this.resolveMileageExpenseAccountId(tenant);
    }
    const expenseAccountId = expense.expense_account_id?.toString?.().trim();
    if (expenseAccountId) {
      return expenseAccountId;
    }
    return null;
  }

  private buildAccountTransactionsPayload(
    expense: DbExpenseRow,
    items: DbExpenseItemRow[],
    tenant: TenantContext,
    expenseAccountId: string | null,
  ) {
    const transactionDate =
      expense.expense_date?.toString?.() || new Date().toISOString();
    const referenceNumber = expense.expense_number?.toString?.().trim() || null;
    const sourceId = expense.id ?? "";
    const paidThroughAccountId =
      expense.paid_through_account_id?.toString?.().trim() || null;
    const payload: AccountTransactionInsertRow[] = [];

    if (expense.is_itemized === true && items.length > 0) {
      let totalDebit = 0;
      for (const item of items) {
        const accountId = item.expense_account_id?.toString?.().trim();
        if (!accountId) continue;
        const debit =
          this.parseNumber(item.amount, 0) + this.parseNumber(item.tax_amount, 0);
        totalDebit += debit;
        payload.push({
          entity_id: tenant.entityId,
          org_id: tenant.orgId,
          account_id: accountId,
          transaction_date: transactionDate,
          transaction_type: ExpensesService.accountTransactionType,
          reference_number: referenceNumber,
          description: this.buildExpenseJournalDescription(
            expense,
            parseInt(item.line_no?.toString?.() ?? "0", 10) || 0,
          ),
          debit,
          credit: 0,
          source_id: sourceId,
          source_type: ExpensesService.accountTransactionSourceType,
          contact_id: null,
          contact_type: null,
        });
      }

      if (paidThroughAccountId) {
        payload.push({
          entity_id: tenant.entityId,
          org_id: tenant.orgId,
          account_id: paidThroughAccountId,
          transaction_date: transactionDate,
          transaction_type: ExpensesService.accountTransactionType,
          reference_number: referenceNumber,
          description: this.buildExpenseJournalDescription(expense),
          debit: 0,
          credit: totalDebit,
          source_id: sourceId,
          source_type: ExpensesService.accountTransactionSourceType,
          contact_id: null,
          contact_type: null,
        });
      }
    } else {
      const debit =
        this.parseNumber(expense.total_amount, 0) ||
        this.parseNumber(expense.amount, 0);
      if (expenseAccountId) {
        payload.push({
          entity_id: tenant.entityId,
          org_id: tenant.orgId,
          account_id: expenseAccountId,
          transaction_date: transactionDate,
          transaction_type: ExpensesService.accountTransactionType,
          reference_number: referenceNumber,
          description: this.buildExpenseJournalDescription(expense),
          debit,
          credit: 0,
          source_id: sourceId,
          source_type: ExpensesService.accountTransactionSourceType,
          contact_id: null,
          contact_type: null,
        });
      }
      if (paidThroughAccountId) {
        payload.push({
          entity_id: tenant.entityId,
          org_id: tenant.orgId,
          account_id: paidThroughAccountId,
          transaction_date: transactionDate,
          transaction_type: ExpensesService.accountTransactionType,
          reference_number: referenceNumber,
          description: this.buildExpenseJournalDescription(expense),
          debit: 0,
          credit: debit,
          source_id: sourceId,
          source_type: ExpensesService.accountTransactionSourceType,
          contact_id: null,
          contact_type: null,
        });
      }
    }

    return payload.filter((row) => {
      const debit = this.parseNumber(row.debit, 0);
      const credit = this.parseNumber(row.credit, 0);
      return row.account_id && (Math.abs(debit) > 0.00001 || Math.abs(credit) > 0.00001);
    });
  }

  private async appendAccountTransactionsForExpense(
    expense: any,
    items: any[],
    tenant: TenantContext,
  ) {
    const sourceId = expense.id?.toString?.().trim();
    if (!sourceId) return [];

    // 1. Clear any existing lines for this expense only
    await this.client
      .from("journal_entry_lines")
      .delete()
      .eq("entity_id", tenant.entityId)
      .eq("source_id", sourceId);

    // 2. Find or create journal_entries header for EXPENSE only
    const { data: existingJE } = await this.client
      .from("journal_entries")
      .select("id, created_by")
      .eq("entity_id", tenant.entityId)
      .eq("source_document_type", "EXPENSE")
      .eq("source_document_id", sourceId)
      .maybeSingle();

    const journalEntryId = existingJE?.id || uuidv4();

    if (existingJE?.id) {
      await this.client
        .from("journal_entry_lines")
        .delete()
        .eq("journal_entry_id", existingJE.id);
    }

    const expenseNumber = expense.expense_number?.toString?.().trim() || "EXP";
    const expenseDate = expense.expense_date?.toString?.().trim() || new Date().toISOString().split("T")[0];
    const defaultOrgId = tenant.orgId || "00000000-0000-0000-0000-000000000000";

    // 3. Upsert header in journal_entries
    const jeHeader = {
      id: journalEntryId,
      org_id: defaultOrgId,
      entity_id: tenant.entityId,
      fiscal_year_id: null,
      journal_number: `JE-${expenseNumber}`,
      journal_type: "EXPENSE",
      journal_date: expenseDate,
      posting_date: expenseDate,
      reference_number: expense.reference_number || expenseNumber,
      narration: expense.notes || `Expense ${expenseNumber}`,
      source_module: "PURCHASES",
      source_document_type: "EXPENSE",
      source_document_id: sourceId,
      currency_code: "INR",
      exchange_rate: 1.0,
      status: "POSTED",
      created_by: (existingJE as any)?.created_by || tenant.userId || null,
      updated_by: tenant.userId || null,
      updated_at: new Date().toISOString(),
    };

    if (existingJE?.id) {
      await this.client
        .from("journal_entries")
        .update(jeHeader)
        .eq("id", journalEntryId);
    } else {
      await this.client
        .from("journal_entries")
        .insert({
          ...jeHeader,
          created_at: new Date().toISOString(),
        });
    }

    // 4. Build double-entry lines
    const expenseAccountId = await this.resolvePostingExpenseAccountId(
      expense,
      tenant,
    );
    const payload = this.buildAccountTransactionsPayload(
      expense,
      items,
      tenant,
      expenseAccountId,
    );
    if (!payload.length) {
      return [];
    }

    const linesToInsert = payload.map((row) => {
      const { transaction_type, ...cleanRow } = row as any;
      return {
        id: uuidv4(),
        journal_entry_id: journalEntryId,
        ...cleanRow,
        source_id: sourceId,
        source_type: "EXPENSE",
        contact_id: expense.vendor_id || null,
        contact_type: expense.vendor_id ? "vendor" : null,
      };
    });

    // 5. Insert double-entry lines into journal_entry_lines
    const { data, error } = await this.client
      .from("journal_entry_lines")
      .insert(linesToInsert)
      .select("*");

    if (error) {
      throw new BadRequestException(
        `Failed to post expense account transactions: ${error.message}`,
      );
    }

    // 6. Save journal_id backlink in expenses table
    try {
      await this.client
        .from("expenses")
        .update({ journal_id: journalEntryId })
        .eq("id", sourceId);
    } catch (backlinkErr) {
      console.error("Error updating expenses journal_id:", backlinkErr);
    }

    return data ?? [];
  }

  private async writeAuditLogEntry(params: {
    tenant: TenantContext;
    tableName: string;
    recordId: string;
    action: AuditAction;
    oldValues: Record<string, unknown> | null;
    newValues: Record<string, unknown> | null;
    changedColumns?: string[];
    actorName?: string | null;
    actorUserId?: string | null;
    source?: string | null;
    moduleName?: string | null;
    requestId?: string | null;
  }) {
    const orgId = params.tenant.orgId?.toString().trim();
    const userId =
      params.actorUserId?.toString().trim() ??
      params.tenant.userId?.toString().trim();
    if (!orgId || !userId) {
      return;
    }

    const resolvedActorName =
      params.actorName?.toString().trim() ||
      (await this.resolveUserNameMap([userId], params.tenant.entityId)).get(userId) ||
      userId;

    await this.client.from("audit_logs").insert({
      table_name: params.tableName,
      record_id: params.recordId,
      action: params.action,
      old_values: params.oldValues,
      new_values: params.newValues,
      user_id: userId,
      org_id: orgId,
      entity_id: params.tenant.entityId,
      actor_name: resolvedActorName,
      schema_name: "public",
      record_pk: params.recordId,
      changed_columns: Array.from(
        new Set((params.changedColumns ?? []).filter(Boolean)),
      ),
      source: params.source?.trim() || "system",
      module_name: params.moduleName?.trim() || "expenses",
      request_id: params.requestId?.toString().trim() || null,
    });
  }

  private async resolveUserNameMap(
    userIds: Array<string | null | undefined>,
    entityId: string | null,
  ) {
    const ids = Array.from(
      new Set(
        userIds
          .map((value) => value?.toString().trim())
          .filter(Boolean) as string[],
      ),
    );
    const userMap = new Map<string, string>();
    if (!ids.length) {
      return userMap;
    }

    const attachUsers = (rows: any[] | null | undefined) => {
      for (const row of rows ?? []) {
        const id = row.id?.toString?.();
        if (!id || userMap.has(id)) continue;
        const name = row.full_name?.toString?.().trim() ||
          row.email?.toString?.().trim() ||
          id;
        userMap.set(id, name);
      }
    };

    const scopedUsers = await this.client
      .from("users")
      .select("id,full_name,email")
      .in("id", ids)
      .eq("entity_id", entityId);
    attachUsers(scopedUsers.data);

    if (userMap.size < ids.length) {
      const fallbackUsers = await this.client
        .from("users")
        .select("id,full_name,email")
        .in("id", ids);
      attachUsers(fallbackUsers.data);
    }

    return userMap;
  }

  private async resolveRecurringProfileNameMap(
    recurringIds: Array<string | null | undefined>,
    entityId: string | null,
  ) {
    const ids = Array.from(
      new Set(
        recurringIds
          .map((value) => value?.toString().trim())
          .filter(Boolean) as string[],
      ),
    );
    const profileMap = new Map<string, string>();
    if (!ids.length) {
      return profileMap;
    }

    const attachProfiles = (rows: any[] | null | undefined) => {
      for (const row of rows ?? []) {
        const id = row.id?.toString?.();
        if (!id || profileMap.has(id)) continue;
        const name =
          row.profile_name?.toString?.().trim() ||
          row.invoice_number?.toString?.().trim() ||
          id;
        profileMap.set(id, name);
      }
    };

    const scopedProfiles = await this.client
      .from("recurring_expenses")
      .select("id,profile_name,invoice_number")
      .in("id", ids)
      .eq("entity_id", entityId);
    attachProfiles(scopedProfiles.data);

    if (profileMap.size < ids.length) {
      const fallbackProfiles = await this.client
        .from("recurring_expenses")
        .select("id,profile_name,invoice_number")
        .in("id", ids);
      attachProfiles(fallbackProfiles.data);
    }

    return profileMap;
  }

  private replaceRecurringProfileIdsInHistory(
    historyChanges: string[],
    recurringProfileMap: Map<string, string>,
  ) {
    return historyChanges.map((value) => {
      const match = value.match(/^Recurring profile linked \(([0-9a-fA-F-]{36})\)$/);
      if (!match) {
        return value;
      }

      const profileName = recurringProfileMap.get(match[1]);
      return profileName
        ? `Recurring profile linked (${profileName})`
        : "Recurring profile linked";
    });
  }

  private async assertReferenceExists(
    table: string,
    id: string,
    tenant: TenantContext,
    options?: {
      entityScoped?: boolean;
      select?: string;
      label?: string;
      allowGlobal?: boolean;
      column?: string;
    },
  ) {
    this.logTaxDebug("assertReferenceExists input", {
      table,
      column: options?.column ?? "id",
      id,
      entityId: tenant.entityId,
      allowGlobal: options?.allowGlobal ?? false,
      entityScoped: options?.entityScoped ?? true,
    });
    const column = options?.column ?? "id";
    let query = this.client.from(table).select(options?.select ?? column).eq(column, id);
    if (options?.entityScoped !== false) {
      query = query.eq("entity_id", tenant.entityId);
    }
    const { data, error } = await query.maybeSingle();
    this.logTaxDebug("assertReferenceExists scoped query result", {
      table,
      id,
      result: data,
      error: error?.message ?? null,
    });
    if (error) {
      throw new BadRequestException(
        `Failed to validate ${options?.label ?? table}: ${error.message}`,
      );
    }
    if (!data && options?.allowGlobal && options?.entityScoped !== false) {
      const fallback = await this.client
        .from(table)
        .select(options?.select ?? column)
        .eq(column, id)
        .maybeSingle();
      this.logTaxDebug("assertReferenceExists global fallback result", {
        table,
        id,
        result: fallback.data,
        error: fallback.error?.message ?? null,
      });
      if (fallback.error) {
        throw new BadRequestException(
          `Failed to validate ${options?.label ?? table}: ${fallback.error.message}`,
        );
      }
      if (fallback.data) {
        return fallback.data;
      }
    }
    if (!data) {
      throw new BadRequestException(
        `${options?.label ?? table} not found for ID ${id}`,
      );
    }
    return data;
  }

  private async assertTaxReferenceExists(
    id: string,
    tenant: TenantContext,
    label: string,
  ) {
    try {
      return await this.assertReferenceExists("tax_rates", id, tenant, {
        label,
        entityScoped: false,
        allowGlobal: true,
      });
    } catch (rateError) {
      return this.assertReferenceExists("tax_groups", id, tenant, {
        label,
        entityScoped: false,
        allowGlobal: true,
      });
    }
  }

  private async validateForeignKeys(
    dto: CreateExpenseDto | UpdateExpenseDto,
    tenant: TenantContext,
  ) {
    this.logTaxDebug(
      "before validateForeignKeys item.tax_id values",
      (dto.items ?? []).map((item, index) => ({
        row: index + 1,
        tax_id: item.tax_id ?? null,
      })),
    );
    if (dto.expense_account_id) {
      await this.assertReferenceExists("accounts", dto.expense_account_id, tenant, {
        label: "Expense account",
      });
    }
    if (dto.paid_through_account_id) {
      await this.assertReferenceExists("accounts", dto.paid_through_account_id, tenant, {
        label: "Paid through account",
      });
    }
    if (dto.vendor_id) {
      await this.assertReferenceExists("vendors", dto.vendor_id, tenant, {
        label: "Vendor",
      });
    }
    if (dto.customer_id) {
      await this.assertReferenceExists("customers", dto.customer_id, tenant, {
        label: "Customer",
      });
    }
    if (dto.currency_code) {
      const normalizedCurrencyCode = dto.currency_code.trim().toUpperCase();
      const { data, error } = await this.client
        .from("currencies")
        .select("id")
        .eq("code", normalizedCurrencyCode)
        .eq("is_active", true)
        .maybeSingle();
      if (error) {
        throw new BadRequestException(
          `Failed to validate currency: ${error.message}`,
        );
      }
      if (!data) {
        throw new BadRequestException(
          `Currency not found for code ${normalizedCurrencyCode}`,
        );
      }
    }
    if (dto.tax_id) {
      await this.assertTaxReferenceExists(dto.tax_id, tenant, "Tax");
    }
    if (dto.recurring_expense_id) {
      await this.assertReferenceExists(
        "recurring_expenses",
        dto.recurring_expense_id,
        tenant,
        { label: "Recurring expense" },
      );
    }
    for (const item of dto.items ?? []) {
      await this.assertReferenceExists("accounts", item.expense_account_id, tenant, {
        label: "Expense item account",
      });
      if (item.tax_id) {
        await this.assertTaxReferenceExists(
          item.tax_id,
          tenant,
          "Expense item tax",
        );
      }
    }
    if (dto.mileage?.employee_id) {
      await this.assertReferenceExists("users", dto.mileage.employee_id, tenant, {
        label: "Employee",
      });
    }
  }

  private calculateItemTotals(
    items: CreateExpenseItemDto[],
    amountTaxMode: string,
  ) {
    let subtotal = 0;
    let taxAmount = 0;
    for (const item of items) {
      subtotal += this.parseNumber(item.amount);
      taxAmount += this.parseNumber(item.tax_amount);
    }
    const totalAmount =
      this.normalizeAmountTaxMode(amountTaxMode) === "INCLUSIVE"
        ? subtotal
        : subtotal + taxAmount;
    return { subtotal, taxAmount, totalAmount };
  }

  private async buildExpensePayload(
    dto: CreateExpenseDto | UpdateExpenseDto,
    tenant: TenantContext,
    options?: {
      existing?: any;
      expenseNumber?: string | null;
    },
  ) {
    const mode = this.normalizeExpenseMode(
      dto.expense_mode ?? options?.existing?.expense_mode,
    );
    const isItemized = dto.is_itemized ?? options?.existing?.is_itemized ?? false;
    const amountTaxMode = this.normalizeAmountTaxMode(
      dto.amount_tax_mode ?? options?.existing?.amount_tax_mode,
    );

    let subtotal =
      dto.subtotal ?? this.parseNumber(options?.existing?.subtotal, 0);
    let taxAmount =
      dto.tax_amount ?? this.parseNumber(options?.existing?.tax_amount, 0);
    let totalAmount =
      dto.total_amount ?? this.parseNumber(options?.existing?.total_amount, 0);
    let amount = dto.amount ?? this.parseNumber(options?.existing?.amount, 0);

    if (isItemized) {
      const items = dto.items ?? [];
      if (!items.length) {
        throw new BadRequestException(
          "Itemized expense requires at least one expense item row.",
        );
      }
      const totals = this.calculateItemTotals(items, amountTaxMode);
      subtotal = totals.subtotal;
      taxAmount = totals.taxAmount;
      totalAmount = totals.totalAmount;
      amount = totalAmount;
    } else {
      subtotal = dto.subtotal ?? amount;
      taxAmount = dto.tax_amount ?? taxAmount;
      totalAmount =
        dto.total_amount ??
        (amountTaxMode === "INCLUSIVE" ? amount : amount + taxAmount);
    }

    if (mode === "RECORD_MILEAGE") {
      if (!dto.mileage) {
        throw new BadRequestException(
          "Mileage payload is required for RECORD_MILEAGE expenses.",
        );
      }
      if (this.parseNumber(dto.mileage.distance) <= 0) {
        throw new BadRequestException("Mileage distance must be greater than 0.");
      }
      if (
        dto.mileage.calculation_type === "ODOMETER_READING" &&
        dto.mileage.odometer_start !== undefined &&
        dto.mileage.odometer_end !== undefined &&
        this.parseNumber(dto.mileage.odometer_end) <
          this.parseNumber(dto.mileage.odometer_start)
      ) {
        throw new BadRequestException(
          "Mileage end odometer must be greater than or equal to start odometer.",
        );
      }
    }

    if (amount <= 0) {
      throw new BadRequestException("Expense amount must be greater than 0.");
    }

    const resolvedExpenseAccountId =
      mode === "RECORD_MILEAGE"
        ? dto.expense_account_id ??
          options?.existing?.expense_account_id ??
          (await this.resolveMileageExpenseAccountId(tenant))
        : dto.expense_account_id ?? options?.existing?.expense_account_id ?? null;

    const resolvedCustomerId =
      dto.customer_id ?? options?.existing?.customer_id ?? null;
    const resolvedIsBillable = resolvedCustomerId
      ? dto.is_billable ?? options?.existing?.is_billable ?? false
      : false;
    const rawMarkupBy =
      dto.mark_up_by !== undefined
        ? dto.mark_up_by
        : options?.existing?.mark_up_by;
    let resolvedMarkupBy: number | null = null;
    if (resolvedCustomerId && resolvedIsBillable) {
      if (
        rawMarkupBy !== undefined &&
        rawMarkupBy !== null &&
        rawMarkupBy.toString().trim() !== ""
      ) {
        const parsedMarkupBy = Number(rawMarkupBy);
        if (!Number.isFinite(parsedMarkupBy) || parsedMarkupBy < 0) {
          throw new BadRequestException(
            "Mark up by must be a valid number greater than or equal to 0.",
          );
        }
        resolvedMarkupBy = parsedMarkupBy;
      }
    }

    if (mode !== "RECORD_MILEAGE" && !isItemized && !resolvedExpenseAccountId) {
      throw new BadRequestException("Expense account is required.");
    }

    const payload: Record<string, unknown> = {
      expense_number:
        dto.expense_number ?? options?.expenseNumber ?? options?.existing?.expense_number,
      expense_date: dto.expense_date ?? options?.existing?.expense_date ?? this.todayDateString(),
      expense_mode: mode,
      status: this.normalizeExpenseStatus(dto.status ?? options?.existing?.status),
      is_itemized: isItemized,
      expense_account_id: resolvedExpenseAccountId,
      paid_through_account_id:
        dto.paid_through_account_id ?? options?.existing?.paid_through_account_id,
      amount,
      currency_code:
        dto.currency_code ?? options?.existing?.currency_code ?? "INR",
      expense_type: this.normalizeExpenseType(
        dto.expense_type ?? options?.existing?.expense_type,
      ),
      hsn_sac_code: dto.hsn_sac_code ?? options?.existing?.hsn_sac_code ?? null,
      vendor_id: dto.vendor_id ?? options?.existing?.vendor_id ?? null,
      customer_id: resolvedCustomerId,
      mark_up_by: resolvedMarkupBy,
      gst_treatment:
        dto.gst_treatment ?? options?.existing?.gst_treatment ?? null,
      source_of_supply:
        dto.source_of_supply ?? options?.existing?.source_of_supply ?? null,
      destination_of_supply:
        dto.destination_of_supply ??
        options?.existing?.destination_of_supply ??
        null,
      reverse_charge:
        dto.reverse_charge ?? options?.existing?.reverse_charge ?? false,
      tax_id: dto.tax_id ?? options?.existing?.tax_id ?? null,
      amount_tax_mode: amountTaxMode,
      invoice_number:
        dto.invoice_number ?? options?.existing?.invoice_number ?? null,
      notes: dto.notes ?? options?.existing?.notes ?? null,
      is_billable: resolvedIsBillable,
      subtotal,
      tax_amount: taxAmount,
      total_amount: totalAmount,
      recurring_expense_id:
        dto.recurring_expense_id ?? options?.existing?.recurring_expense_id ?? null,
      entity_id: tenant.entityId,
      updated_by: tenant.userId,
    };

    if (!options?.existing) {
      payload.created_by = tenant.userId;
      payload.is_delete = false;
    }

    return payload;
  }

  private async fetchExpenseRow(id: string, tenant: TenantContext) {
    const { data, error } = await this.client
      .from("expenses")
      .select("*")
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .or("is_delete.is.null,is_delete.eq.false")
      .maybeSingle();
    if (error) {
      throw new BadRequestException(`Failed to fetch expense: ${error.message}`);
    }
    if (!data) {
      throw new NotFoundException(`Expense with ID ${id} not found`);
    }
    return data;
  }

  private async syncItems(
    expenseId: string,
    items: CreateExpenseItemDto[] | undefined,
  ) {
    if (!items?.length) {
      const { error } = await this.client
        .from("expense_items")
        .delete()
        .eq("expense_id", expenseId);
      if (error) {
        throw new BadRequestException(
          `Failed to clear expense items: ${error.message}`,
        );
      }
      return [];
    }

    const { error: clearError } = await this.client
      .from("expense_items")
      .delete()
      .eq("expense_id", expenseId);
    if (clearError) {
      throw new BadRequestException(
        `Failed to clear expense items: ${clearError.message}`,
      );
    }

    const inserted: any[] = [];
    for (let index = 0; index < items.length; index += 1) {
      const item = items[index];
      const payload = {
        expense_id: expenseId,
        line_no: item.line_no ?? index + 1,
        expense_account_id: item.expense_account_id,
        notes: item.notes ?? null,
        tax_id: item.tax_id ?? null,
        tax_amount: this.parseNumber(item.tax_amount),
        amount: this.parseNumber(item.amount),
      };
      this.logTaxDebug("immediately before inserting into expense_items", payload);

      const { data, error } = await this.client
        .from("expense_items")
        .insert([payload])
        .select()
        .single();
      if (error) {
        throw new BadRequestException(
          `Failed to insert expense item: ${error.message}`,
        );
      }
      inserted.push(this.mapExpenseItem(data));
    }

    return inserted;
  }

  private async syncMileage(
    expenseId: string,
    mileage: CreateExpenseMileageDto | undefined,
  ) {
    const current = await this.client
      .from("expense_mileage")
      .select("*")
      .eq("expense_id", expenseId)
      .maybeSingle();
    if (current.error) {
      throw new BadRequestException(
        `Failed to fetch current mileage row: ${current.error.message}`,
      );
    }

    if (!mileage) {
      if (current.data?.id) {
        const { error } = await this.client
          .from("expense_mileage")
          .delete()
          .eq("expense_id", expenseId);
        if (error) {
          throw new BadRequestException(
            `Failed to delete mileage row: ${error.message}`,
          );
        }
      }
      return null;
    }

    const payload = {
      expense_id: expenseId,
      employee_id: mileage.employee_id ?? null,
      calculation_type: mileage.calculation_type,
      distance: this.parseNumber(mileage.distance),
      distance_unit: mileage.distance_unit,
      odometer_start:
        mileage.odometer_start !== undefined
          ? this.parseNumber(mileage.odometer_start)
          : null,
      odometer_end:
        mileage.odometer_end !== undefined
          ? this.parseNumber(mileage.odometer_end)
          : null,
      rate_per_km: this.parseNumber(mileage.rate_per_km),
      amount: this.parseNumber(this.calculateMileageAmount(mileage)),
    };

    if (current.data?.id) {
      const { data, error } = await this.client
        .from("expense_mileage")
        .update(payload)
        .eq("expense_id", expenseId)
        .select()
        .single();
      if (error) {
        throw new BadRequestException(
          `Failed to update mileage row: ${error.message}`,
        );
      }
      return this.mapMileage(data);
    }

    const { data, error } = await this.client
      .from("expense_mileage")
      .insert([payload])
      .select()
      .single();
    if (error) {
      throw new BadRequestException(
        `Failed to create mileage row: ${error.message}`,
      );
    }
    return this.mapMileage(data);
  }

  private async insertAttachments(
    expenseId: string,
    attachments: CreateExpenseAttachmentDto[] | undefined,
    tenant: TenantContext,
  ) {
    if (!attachments?.length) return [];
    const payload = attachments.map((attachment) => ({
      expense_id: expenseId,
      file_name: attachment.file_name,
      original_file_name:
        attachment.original_file_name ?? attachment.file_name,
      file_url: attachment.file_url,
      file_type: attachment.file_type ?? null,
      file_size: attachment.file_size ?? 0,
      uploaded_by: tenant.userId,
      remarks: attachment.remarks ?? null,
      is_delete: false,
    }));

    const { data, error } = await this.client
      .from("expense_attachments")
      .insert(payload)
      .select("*");
    if (error) {
      throw new BadRequestException(
        `Failed to insert expense attachments: ${error.message}`,
      );
    }
    return await Promise.all(
      (data ?? []).map((row: any) => this.hydrateAttachment(row)),
    );
  }

  private async fetchItems(expenseId: string) {
    const { data, error } = await this.client
      .from("expense_items")
      .select("*")
      .eq("expense_id", expenseId)
      .order("line_no", { ascending: true });
    if (error) {
      throw new BadRequestException(
        `Failed to fetch expense items: ${error.message}`,
      );
    }
    const accountNameMap = await this.resolveAccountNameMap(
      (data ?? []).map((row: any) => row.expense_account_id?.toString?.()),
    );
    return (data ?? []).map((row: any) => {
      const mapped = this.mapExpenseItem(row);
      const expenseAccountId = row.expense_account_id?.toString?.() ?? "";
      return {
        ...mapped,
        expense_account_name: expenseAccountId
          ? accountNameMap.get(expenseAccountId) ?? null
          : null,
      };
    });
  }

  private async fetchFirstItemAccountIdMap(expenseIds: string[]) {
    const expenseAccountMap = new Map<string, string>();
    if (!expenseIds.length) {
      return expenseAccountMap;
    }

    const { data, error } = await this.client
      .from("expense_items")
      .select("expense_id,expense_account_id,line_no")
      .in("expense_id", expenseIds)
      .order("expense_id", { ascending: true })
      .order("line_no", { ascending: true });
    if (error) {
      throw new BadRequestException(
        `Failed to fetch expense item accounts: ${error.message}`,
      );
    }

    for (const row of data ?? []) {
      const expenseId = row.expense_id?.toString?.() ?? "";
      const expenseAccountId = row.expense_account_id?.toString?.() ?? "";
      if (!expenseId || !expenseAccountId || expenseAccountMap.has(expenseId)) {
        continue;
      }
      expenseAccountMap.set(expenseId, expenseAccountId);
    }

    return expenseAccountMap;
  }

  private async fetchAttachments(expenseId: string) {
    const { data, error } = await this.client
      .from("expense_attachments")
      .select("*")
      .eq("expense_id", expenseId)
      .or("is_delete.is.null,is_delete.eq.false")
      .order("created_at", { ascending: false });
    if (error) {
      throw new BadRequestException(
        `Failed to fetch expense attachments: ${error.message}`,
      );
    }
    return await Promise.all(
      (data ?? []).map((row: any) => this.hydrateAttachment(row)),
    );
  }

  private async fetchMileage(expenseId: string) {
    const { data, error } = await this.client
      .from("expense_mileage")
      .select("*")
      .eq("expense_id", expenseId)
      .maybeSingle();
    if (error) {
      throw new BadRequestException(
        `Failed to fetch expense mileage: ${error.message}`,
      );
    }
    return this.mapMileage(data);
  }

  private async attachLookups(rows: any[]) {
    if (!rows.length) return rows;

    const expenseIds = Array.from(new Set(rows.map((row) => row.id).filter(Boolean)));
    const firstItemAccountIdMap = await this.fetchFirstItemAccountIdMap(expenseIds);
    const accountIds = Array.from(
      new Set(
        rows
          .flatMap((row) => [
            row.expense_account_id,
            row.paid_through_account_id,
            firstItemAccountIdMap.get(row.id?.toString?.() ?? ""),
          ])
          .filter(Boolean),
      ),
    );
    const vendorIds = Array.from(
      new Set(rows.map((row) => row.vendor_id).filter(Boolean)),
    );
    const customerIds = Array.from(
      new Set(rows.map((row) => row.customer_id).filter(Boolean)),
    );
    const userIds = Array.from(
      new Set(
        rows
          .flatMap((row) => [row.created_by, row.updated_by])
          .filter(Boolean),
      ),
    );

    const accountMap = new Map<string, any>();
    if (accountIds.length > 0) {
      const { data } = await this.client
        .from("accounts")
        .select("id,user_account_name,system_account_name,account_code")
        .in("id", accountIds);
      for (const account of data ?? []) {
        accountMap.set(account.id, account);
      }
    }

    const vendorMap = new Map<string, any>();
    if (vendorIds.length > 0) {
      const { data } = await this.client
        .from("vendors")
        .select("id,display_name,company_name")
        .in("id", vendorIds);
      for (const vendor of data ?? []) {
        vendorMap.set(vendor.id, vendor);
      }
    }

    const customerMap = new Map<string, any>();
    if (customerIds.length > 0) {
      const { data } = await this.client
        .from("customers")
        .select("id,display_name,company_name")
        .in("id", customerIds);
      for (const customer of data ?? []) {
        customerMap.set(customer.id, customer);
      }
    }

    const userMap = await this.resolveUserNameMap(userIds, rows[0]?.entity_id);
    const attachmentCountMap = new Map<string, number>();
    if (expenseIds.length > 0) {
      const { data } = await this.client
        .from("expense_attachments")
        .select("expense_id")
        .or("is_delete.is.null,is_delete.eq.false")
        .in("expense_id", expenseIds);
      for (const attachment of data ?? []) {
        const expenseId = attachment.expense_id?.toString?.();
        if (!expenseId) continue;
        attachmentCountMap.set(
          expenseId,
          (attachmentCountMap.get(expenseId) ?? 0) + 1,
        );
      }
    }

    return rows.map((row) => {
      const firstItemExpenseAccountId =
        firstItemAccountIdMap.get(row.id?.toString?.() ?? "") ?? null;
      const resolvedExpenseAccountId =
        row.expense_account_id ?? firstItemExpenseAccountId;
      const expenseAccount = resolvedExpenseAccountId
        ? accountMap.get(resolvedExpenseAccountId)
        : null;
      const paidThrough = row.paid_through_account_id
        ? accountMap.get(row.paid_through_account_id)
        : null;
      const vendor = row.vendor_id ? vendorMap.get(row.vendor_id) : null;
      const customer = row.customer_id ? customerMap.get(row.customer_id) : null;
      const attachmentCount = attachmentCountMap.get(row.id?.toString?.() ?? "") ?? 0;

      return {
        ...this.mapDbToDto(row),
        expense_account_id: resolvedExpenseAccountId,
        expense_account_name: this.resolveExpenseAccountLabel(
          row,
          expenseAccount,
        ),
        paid_through_account_name:
          paidThrough?.user_account_name ||
          paidThrough?.system_account_name ||
          paidThrough?.account_code ||
          null,
        vendor_name:
          vendor?.display_name || vendor?.company_name || null,
        customer_name:
          customer?.display_name || customer?.company_name || null,
        created_by_name: row.created_by
          ? userMap.get(row.created_by.toString()) ?? null
          : null,
        updated_by_name: row.updated_by
          ? userMap.get(row.updated_by.toString()) ?? null
          : null,
        attachment_count: attachmentCount,
        has_attachments: attachmentCount > 0,
      };
    });
  }

  private normalizeFavoriteFilter(filter?: string | null): string {
    return filter?.toString().trim().toLowerCase() || "all";
  }

  private resolveSortField(query: ListExpensesQueryDto): string {
    return query.sort_by?.toString().trim() || "date";
  }

  private resolveSortAscending(query: ListExpensesQueryDto): boolean {
    return query.sort_direction?.toString().trim().toLowerCase() === "asc";
  }

  private requiresLookupPagination(query: ListExpensesQueryDto): boolean {
    const favoriteFilter = this.normalizeFavoriteFilter(query.favorite_filter);
    const sortField = this.resolveSortField(query);
    return (
      favoriteFilter === "with_receipts" ||
      favoriteFilter === "without_receipts" ||
      sortField === "expenseAccount" ||
      sortField === "reference" ||
      sortField === "vendorName" ||
      sortField === "customerName"
    );
  }

  private buildExpenseListRequest(
    tenant: TenantContext,
    query: ListExpensesQueryDto,
    select = "*",
  ) {
    let request = this.client
      .from("expenses")
      .select(select, { count: "exact" })
      .eq("entity_id", tenant.entityId)
      .or("is_delete.is.null,is_delete.eq.false");

    if (query.search) {
      request = request.or(
        `expense_number.ilike.%${query.search}%,invoice_number.ilike.%${query.search}%,notes.ilike.%${query.search}%`,
      );
    }
    if (query.status) {
      request = request.eq("status", this.normalizeExpenseStatus(query.status));
    }
    if (query.expense_mode) {
      request = request.eq(
        "expense_mode",
        this.normalizeExpenseMode(query.expense_mode),
      );
    }
    if (query.vendor_id) {
      request = request.eq("vendor_id", query.vendor_id);
    }
    if (query.customer_id) {
      request = request.eq("customer_id", query.customer_id);
    }
    if (query.is_itemized !== undefined) {
      request = request.eq("is_itemized", query.is_itemized);
    }

    const favoriteFilter = this.normalizeFavoriteFilter(query.favorite_filter);
    if (favoriteFilter === "billable") {
      request = request.eq("is_billable", true);
    } else if (favoriteFilter === "non_billable") {
      request = request.eq("is_billable", false);
    }

    return request;
  }

  private buildReferenceSortValue(row: any): string {
    return (
      row.invoice_number?.toString?.().trim() ||
      row.expense_number?.toString?.().trim() ||
      ""
    );
  }

  private compareValues(left: unknown, right: unknown): number {
    if (typeof left === "number" && typeof right === "number") {
      return left - right;
    }

    return left
      .toString()
      .toLowerCase()
      .localeCompare(right.toString().toLowerCase(), undefined, {
        numeric: true,
        sensitivity: "base",
      });
  }

  private sortMappedExpenses(rows: any[], field: string, ascending: boolean): any[] {
    const sorted = [...rows];
    sorted.sort((leftRow, rightRow) => {
      let leftValue: unknown;
      let rightValue: unknown;

      switch (field) {
        case "expenseAccount":
          leftValue = leftRow.expense_account_name ?? "";
          rightValue = rightRow.expense_account_name ?? "";
          break;
        case "reference":
          leftValue = this.buildReferenceSortValue(leftRow);
          rightValue = this.buildReferenceSortValue(rightRow);
          break;
        case "vendorName":
          leftValue = leftRow.vendor_name ?? "";
          rightValue = rightRow.vendor_name ?? "";
          break;
        case "customerName":
          leftValue = leftRow.customer_name ?? "";
          rightValue = rightRow.customer_name ?? "";
          break;
        case "amount":
          leftValue = Number(leftRow.amount ?? 0);
          rightValue = Number(rightRow.amount ?? 0);
          break;
        case "status":
          leftValue = leftRow.status ?? "";
          rightValue = rightRow.status ?? "";
          break;
        case "date":
        default:
          leftValue = leftRow.expense_date ?? "";
          rightValue = rightRow.expense_date ?? "";
          break;
      }

      const comparison = this.compareValues(leftValue, rightValue);
      if (comparison !== 0) {
        return ascending ? comparison : -comparison;
      }

      return this.compareValues(
        leftRow.created_at ?? "",
        rightRow.created_at ?? "",
      );
    });
    return sorted;
  }

  private applyMappedFavoriteFilter(rows: any[], filter?: string | null): any[] {
    const favoriteFilter = this.normalizeFavoriteFilter(filter);
    switch (favoriteFilter) {
      case "with_receipts":
        return rows.filter((row) => row.has_attachments === true);
      case "without_receipts":
        return rows.filter((row) => row.has_attachments !== true);
      default:
        return rows;
    }
  }

  private async fetchLookupPaginatedExpenses(
    tenant: TenantContext,
    query: ListExpensesQueryDto,
    page: number,
    limit: number,
    offset: number,
  ): Promise<ExpensePageResult> {
    const { data, error } = await this.buildExpenseListRequest(tenant, query).order(
      "created_at",
      { ascending: false },
    );
    if (error) {
      this.logger.error(
        `findAll:error entity=${tenant.entityId} page=${page} limit=${limit} message=${error.message}`,
      );
      throw new BadRequestException(`Failed to fetch expenses: ${error.message}`);
    }

    const mapped = await this.attachLookups(data ?? []);
    const filtered = this.applyMappedFavoriteFilter(mapped, query.favorite_filter);
    const sorted = this.sortMappedExpenses(
      filtered,
      this.resolveSortField(query),
      this.resolveSortAscending(query),
    );
    const rows = sorted.slice(offset, offset + limit);
    const total = sorted.length;

    return {
      rows,
      total,
      totalPages: total === 0 ? 1 : Math.ceil(total / limit),
    };
  }

  async create(createDto: CreateExpenseDto, tenant: TenantContext) {
    await this.validateForeignKeys(createDto, tenant);

    const generatedExpenseNumber =
      createDto.expense_number ||
      (await this.sequencesService.getNextNumberFormatted("expense", tenant));
    const expensePayload = await this.buildExpensePayload(createDto, tenant, {
      expenseNumber: generatedExpenseNumber,
    });
    let createdExpenseId: string | null = null;
    let createdAttachments: any[] = [];

    try {
      const { data: expense, error: expenseError } = await this.client
        .from("expenses")
        .insert([expensePayload])
        .select("*")
        .single();
      if (expenseError) {
        throw new BadRequestException(
          `Failed to create expense: ${expenseError.message}`,
        );
      }
      createdExpenseId = expense.id;
      const items = expensePayload.is_itemized
        ? await this.syncItems(expense.id, createDto.items)
        : [];
      const mileage =
        expensePayload.expense_mode === "RECORD_MILEAGE"
          ? await this.syncMileage(expense.id, createDto.mileage)
          : await this.syncMileage(expense.id, undefined);
      createdAttachments = await this.insertAttachments(
        expense.id,
        createDto.attachments,
        tenant,
      );

      await this.sequencesService.incrementSequence(
        "expense",
        tenant,
        generatedExpenseNumber,
      );

      const attached = await this.attachLookups([expense]);
      const detail = attached[0];
      detail.items = items;
      detail.attachments = createdAttachments;
      detail.mileage = mileage;
      await this.appendAccountTransactionsForExpense(expense, items, tenant);

      await this.writeAuditLogEntry({
        tenant,
        tableName: "expenses",
        recordId: expense.id,
        action: "CREATE",
        oldValues: null,
        newValues: {
          ...detail,
          history_changes: [`Expense created for ${this.formatAmount(detail.total_amount ?? detail.amount)}`],
        },
        changedColumns: Object.keys(expensePayload),
      });

      return detail;
    } catch (error) {
      if (createdExpenseId) {
        await this.client
          .from("journal_entry_lines")
          .delete()
          .eq("entity_id", tenant.entityId)
          .eq("source_id", createdExpenseId)
          .eq("source_type", "expense");
        await this.client.from("expense_attachments").delete().eq("expense_id", createdExpenseId);
        await this.client.from("expense_items").delete().eq("expense_id", createdExpenseId);
        await this.client.from("expense_mileage").delete().eq("expense_id", createdExpenseId);
        await this.client.from("expenses").delete().eq("id", createdExpenseId);
      }
      throw error;
    }
  }

  async findAll(tenant: TenantContext, query: ListExpensesQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 100;
    const offset = (page - 1) * limit;
    const sortField = this.resolveSortField(query);
    const sortAscending = this.resolveSortAscending(query);

    let mapped: any[] = [];
    let total = 0;
    let totalPages = 1;

    if (this.requiresLookupPagination(query)) {
      const result = await this.fetchLookupPaginatedExpenses(
        tenant,
        query,
        page,
        limit,
        offset,
      );
      mapped = result.rows;
      total = result.total;
      totalPages = result.totalPages;
    } else {
      let request = this.buildExpenseListRequest(tenant, query);
      switch (sortField) {
        case "amount":
          request = request.order("amount", { ascending: sortAscending });
          break;
        case "status":
          request = request.order("status", { ascending: sortAscending });
          break;
        case "date":
        default:
          request = request.order("expense_date", { ascending: sortAscending });
          break;
      }
      request = request.order("created_at", { ascending: false });

      const { data, error, count } = await request.range(offset, offset + limit - 1);
      if (error) {
        this.logger.error(
          `findAll:error entity=${tenant.entityId} page=${page} limit=${limit} message=${error.message}`,
        );
        throw new BadRequestException(
          `Failed to fetch expenses: ${error.message}`,
        );
      }

      mapped = await this.attachLookups(data ?? []);
      total = count ?? 0;
      totalPages = total === 0 ? 1 : Math.ceil(total / limit);
    }

    return {
      data: mapped,
      meta: {
        page,
        limit,
        total,
        totalPages,
      },
      total,
      success: true,
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const expense = await this.fetchExpenseRow(id, tenant);
    const [detail] = await this.attachLookups([expense]);
    const [items, attachments, mileage] = await Promise.all([
      this.fetchItems(id),
      this.fetchAttachments(id),
      this.normalizeExpenseMode(expense.expense_mode) === "RECORD_MILEAGE"
        ? this.fetchMileage(id)
        : Promise.resolve(null),
    ]);
    return {
      ...detail,
      items,
      attachments,
      mileage,
    };
  }

  async update(id: string, updateDto: UpdateExpenseDto, tenant: TenantContext) {
    const existing = await this.fetchExpenseRow(id, tenant);
    if (
      updateDto.expense_mode &&
      this.normalizeExpenseMode(updateDto.expense_mode) !==
        this.normalizeExpenseMode(existing.expense_mode)
    ) {
      throw new BadRequestException(
        "Expense mode cannot be changed after creation.",
      );
    }

    await this.validateForeignKeys(
      {
        ...existing,
        ...updateDto,
      },
      tenant,
    );

    const payload = await this.buildExpensePayload(
      {
        ...existing,
        ...updateDto,
      },
      tenant,
      { existing },
    );
    const changedColumns = Object.keys(payload).filter((key) => {
      const before = existing[key];
      const after = payload[key];
      return JSON.stringify(before ?? null) !== JSON.stringify(after ?? null);
    });

    const historyChanges: string[] = [];
    let recurringProfileName: string | null = null;
    if (
      changedColumns.includes("recurring_expense_id") &&
      payload.recurring_expense_id
    ) {
      const recurringProfile = await this.assertReferenceExists(
        "recurring_expenses",
        String(payload.recurring_expense_id),
        tenant,
        {
          label: "Recurring expense",
          select: "id,profile_name",
        },
      );
      recurringProfileName =
        (recurringProfile as any)?.profile_name?.toString?.().trim() || null;
    }
    if (changedColumns.includes("amount")) {
      historyChanges.push(
        `Amount changed from ${this.formatAmount(this.parseNumber(existing.amount))} to ${this.formatAmount(this.parseNumber(payload.amount))}`,
      );
    }
    if (changedColumns.includes("status")) {
      historyChanges.push(
        `Status changed from ${existing.status ?? "-"} to ${payload.status}`,
      );
    }
    if (changedColumns.includes("recurring_expense_id")) {
      if (payload.recurring_expense_id) {
        historyChanges.push("Expense converted to recurring");
        historyChanges.push(
          recurringProfileName
            ? `Recurring profile linked (${recurringProfileName})`
            : "Recurring profile linked",
        );
      } else {
        historyChanges.push("Recurring profile unlinked");
      }
    }
    if (changedColumns.length === 0 && !updateDto.items && !updateDto.mileage) {
      return this.findOne(id, tenant);
    }

    const { data: updated, error } = await this.client
      .from("expenses")
      .update(payload)
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .select("*")
      .single();
    if (error) {
      throw new BadRequestException(
        `Failed to update expense: ${error.message}`,
      );
    }
    const isItemized = payload.is_itemized === true;
    const items = isItemized
      ? updateDto.items !== undefined
        ? await this.syncItems(id, updateDto.items)
        : await this.fetchItems(id)
      : await this.syncItems(id, []);
    const mileage =
      payload.expense_mode === "RECORD_MILEAGE"
        ? await this.syncMileage(id, updateDto.mileage)
        : await this.syncMileage(id, undefined);

    const [detail] = await this.attachLookups([updated]);
    detail.items = items;
    detail.attachments = await this.fetchAttachments(id);
    detail.mileage = mileage;
    await this.appendAccountTransactionsForExpense(updated, items, tenant);

    await this.writeAuditLogEntry({
      tenant,
      tableName: "expenses",
      recordId: id,
      action: "UPDATE",
      oldValues: this.mapDbToDto(existing),
      newValues: {
        ...detail,
        history_changes:
          historyChanges.length > 0 ? historyChanges : ["Expense updated."],
      },
      changedColumns: [
        ...changedColumns,
        ...(updateDto.items ? ["expense_items"] : []),
        ...(updateDto.mileage ? ["expense_mileage"] : []),
      ],
    });

    return detail;
  }

  async remove(id: string, tenant: TenantContext) {
    const existing = await this.fetchExpenseRow(id, tenant);
    const { data, error } = await this.client
      .from("expenses")
      .update({
        is_delete: true,
        status: "DELETED",
        updated_by: tenant.userId,
      })
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .select("id,status")
      .single();
    if (error) {
      throw new BadRequestException(
        `Failed to delete expense: ${error.message}`,
      );
    }

    await this.writeAuditLogEntry({
      tenant,
      tableName: "expenses",
      recordId: id,
      action: "DELETE",
      oldValues: this.mapDbToDto(existing),
      newValues: null,
      changedColumns: ["is_delete", "status"],
    });

    return data;
  }

  async history(id: string, tenant: TenantContext) {
    await this.fetchExpenseRow(id, tenant);
    const { data, error } = await this.client
      .from("audit_logs")
      .select(
        "id, action, actor_name, user_id, created_at, changed_columns, old_values, new_values, source",
      )
      .eq("entity_id", tenant.entityId)
      .eq("table_name", "expenses")
      .eq("record_id", id)
      .order("created_at", { ascending: false });
    if (error) {
      throw new BadRequestException(
        `Failed to fetch expense audit history: ${error.message}`,
      );
    }

    const actorNameMap = await this.resolveUserNameMap(
      (data ?? []).map((row: any) => row.user_id?.toString()),
      tenant.entityId,
    );

      const recurringProfileIds = Array.from(
        new Set(
          (data ?? []).flatMap((row: any) => {
            const ids: string[] = [];
            const newValues =
              row.new_values && typeof row.new_values === "object"
                ? row.new_values
                : null;
            const rawHistory =
              newValues &&
              Array.isArray((newValues as any).history_changes)
                ? ((newValues as any).history_changes as unknown[])
                : [];
            for (const rawValue of rawHistory) {
              const value = String(rawValue);
              const match = value.match(
                /^Recurring profile linked \(([0-9a-fA-F-]{36})\)$/,
              );
              if (match) {
                ids.push(match[1]);
              }
            }
            return ids;
          }),
        ),
      );
      const recurringProfileMap = await this.resolveRecurringProfileNameMap(
        recurringProfileIds,
        tenant.entityId,
      );

      return (data ?? []).map((row: any) => {
      const upperAction = row.action?.toString().toUpperCase() ?? "";
      const newValues =
        row.new_values && typeof row.new_values === "object"
          ? row.new_values
          : null;
      const changedColumns = Array.isArray(row.changed_columns)
        ? row.changed_columns.filter(Boolean)
        : [];
      const actorNameRaw = row.actor_name?.toString().trim() ?? "";
      const actorName =
        (actorNameRaw &&
          !/^[0-9a-fA-F-]{36}$/.test(actorNameRaw) &&
          actorNameRaw.toUpperCase() !== "AUTO"
          ? actorNameRaw
          : null) ??
        (row.user_id
          ? actorNameMap.get(row.user_id.toString().trim())
          : null) ??
        (actorNameRaw.length > 0 ? actorNameRaw : "AUTO");
      const historyChangesRaw =
        newValues &&
        Array.isArray((newValues as any).history_changes) &&
        (newValues as any).history_changes.length > 0
          ? ((newValues as any).history_changes as unknown[])
              .map((value) => String(value))
              .filter(Boolean)
          : [];
      const historyChanges = this.replaceRecurringProfileIdsInHistory(
        historyChangesRaw,
        recurringProfileMap,
      );
      const summaryBase = this.buildHistorySummary(
        row.action,
        (newValues ?? row.old_values) as Record<string, unknown> | null,
        changedColumns,
      );
      const normalizedBase = summaryBase.trim().toLowerCase();
      const summary = upperAction === "UPDATE" && historyChanges.length > 0
        ? `${summaryBase} ${historyChanges.join(". ")}${historyChanges.join(". ").trim().endsWith(".") ? "" : "."}`
        : historyChanges.some(
              (value) => value.trim().toLowerCase() === normalizedBase,
            )
          ? summaryBase
          : summaryBase;

      return {
        id: row.id,
        action: row.action,
        actor_name: actorName,
        created_at: row.created_at,
        source: row.source,
        changed_columns: changedColumns,
        old_values: row.old_values,
        new_values: row.new_values,
        summary,
        field_changes: historyChanges,
      };
    });
  }

  async journal(id: string, tenant: TenantContext) {
    const expense = await this.fetchExpenseRow(id, tenant);
    const journalId = expense.journal_id?.toString?.().trim();
    let query = this.client
      .from("journal_entry_lines")
      .select("*")
      .eq("entity_id", tenant.entityId);

    if (journalId) {
      query = query.or(`source_id.eq.${id},journal_entry_id.eq.${journalId}`);
    } else {
      query = query.eq("source_id", id);
    }

    const { data, error } = await query
      .order("transaction_date", { ascending: true })
      .order("created_at", { ascending: true });
    if (error) {
      throw new BadRequestException(
        `Failed to fetch expense journal: ${error.message}`,
      );
    }

    const accountNameMap = await this.resolveAccountNameMap(
      (data ?? []).map((row: any) => row.account_id),
    );

    const entries = (data ?? []).map((row: any) => ({
      id: row.id,
      account_id: row.account_id,
      account_name:
        this.normalizeExpenseMode(expense?.expense_mode) === "RECORD_MILEAGE" &&
        this.parseNumber(row.debit, 0) > 0 &&
        this.parseNumber(row.credit, 0) === 0
          ? accountNameMap.get(row.account_id?.toString?.() ?? "") ??
            ExpensesService.mileageExpenseAccountName
          : accountNameMap.get(row.account_id?.toString?.() ?? "") ?? "-",
      transaction_date: row.transaction_date,
      transaction_type: row.transaction_type ?? "Expense",
      reference_number: row.reference_number ?? null,
      description: row.description ?? null,
      debit: this.parseNumber(row.debit),
      credit: this.parseNumber(row.credit),
      source_id: row.source_id,
      source_type: row.source_type ?? "expense",
      created_at: row.created_at ?? null,
    }));

    const isMileageExpense =
      this.normalizeExpenseMode(expense?.expense_mode) === "RECORD_MILEAGE";
    const hasDebitEntry = entries.some(
      (row) =>
        this.parseNumber(row.debit, 0) > 0 &&
        this.parseNumber(row.credit, 0) === 0,
    );

    if (isMileageExpense && !hasDebitEntry) {
      return [this.buildMileageJournalFallbackEntry(expense), ...entries];
    }

    return entries;
  }

  async attachments(id: string, tenant: TenantContext) {
    await this.fetchExpenseRow(id, tenant);
    return this.fetchAttachments(id);
  }

  async uploadAttachment(
    id: string,
    attachmentDto: CreateExpenseAttachmentDto,
    tenant: TenantContext,
  ) {
    await this.fetchExpenseRow(id, tenant);
    const payload = {
      expense_id: id,
      file_name: attachmentDto.file_name,
      original_file_name:
        attachmentDto.original_file_name ?? attachmentDto.file_name,
      file_url: attachmentDto.file_url,
      file_type: attachmentDto.file_type ?? null,
      file_size: attachmentDto.file_size ?? 0,
      uploaded_by: tenant.userId,
      remarks: attachmentDto.remarks ?? null,
      is_delete: false,
    };

    const { data, error } = await this.client
      .from("expense_attachments")
      .insert([payload])
      .select("*")
      .single();
    if (error) {
      throw new BadRequestException(
        `Failed to save expense attachment: ${error.message}`,
      );
    }

    const mapped = this.mapAttachment(data);
    const resolved = await this.hydrateAttachment(data);
    await this.writeAuditLogEntry({
      tenant,
      tableName: "expense_attachments",
      recordId: mapped.id,
      action: "CREATE",
      oldValues: null,
      newValues: mapped,
      changedColumns: [
        "expense_id",
        "file_name",
        "file_url",
        "file_size",
        "uploaded_by",
      ],
    });

    return resolved;
  }

  async deleteAttachment(
    id: string,
    attachmentId: string,
    tenant: TenantContext,
  ) {
    await this.fetchExpenseRow(id, tenant);
    const { data: existing, error: existingError } = await this.client
      .from("expense_attachments")
      .select("*")
      .eq("id", attachmentId)
      .eq("expense_id", id)
      .or("is_delete.is.null,is_delete.eq.false")
      .maybeSingle();
    if (existingError) {
      throw new BadRequestException(
        `Failed to fetch expense attachment: ${existingError.message}`,
      );
    }
    if (!existing) {
      throw new NotFoundException(
        `Expense attachment with ID ${attachmentId} not found`,
      );
    }

    const { error } = await this.client
      .from("expense_attachments")
      .update({ is_delete: true })
      .eq("id", attachmentId)
      .eq("expense_id", id);
    if (error) {
      throw new BadRequestException(
        `Failed to delete expense attachment: ${error.message}`,
      );
    }

    await this.writeAuditLogEntry({
      tenant,
      tableName: "expense_attachments",
      recordId: attachmentId,
      action: "DELETE",
      oldValues: this.mapAttachment(existing),
      newValues: null,
      changedColumns: [
        "expense_id",
        "file_name",
        "file_url",
        "file_size",
        "uploaded_by",
      ],
    });

    return true;
  }

  async mileage(id: string, tenant: TenantContext) {
    const expense = await this.fetchExpenseRow(id, tenant);
    if (this.normalizeExpenseMode(expense.expense_mode) !== "RECORD_MILEAGE") {
      throw new BadRequestException(
        "Mileage details are available only for RECORD_MILEAGE expenses.",
      );
    }
    return this.fetchMileage(id);
  }
}
