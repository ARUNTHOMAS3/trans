import { Injectable, Logger, NotFoundException } from "@nestjs/common";
import { randomUUID } from "crypto";
import { SupabaseService } from "../../../supabase/supabase.service";
import { SequencesService } from "../../../../sequences/sequences.service";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { CreateRecurringExpenseDto } from "../dto/create-recurring-expense.dto";
import { UpdateRecurringExpenseDto } from "../dto/update-recurring-expense.dto";
import { BulkUpdateRecurringExpensesDataDto } from "../dto/bulk-update-recurring-expenses.dto";
import { ListRecurringExpensesQueryDto } from "../dto/list-recurring-expenses-query.dto";
import { CreateExpenseDto } from "../../expenses/dto/create-expense.dto";
import { ExpensesService } from "../../expenses/services/expenses.service";

@Injectable()
export class RecurringExpensesService {
  private readonly logger = new Logger(RecurringExpensesService.name);

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly sequencesService: SequencesService,
    private readonly expensesService: ExpensesService,
  ) { }

  private buildCreateExpenseDtoFromRecurringProfile(
    profile: any,
    profileId: string,
    runDate: string,
  ): CreateExpenseDto {
    return {
      expense_date: runDate,
      expense_mode: "RECORD_EXPENSE",
      status: "RECORDED",
      is_itemized: false,
      expense_account_id: profile.expense_account_id,
      paid_through_account_id: profile.paid_through_account_id,
      amount: profile.amount,
      currency_code: profile.currency_code,
      expense_type: profile.expense_type,
      hsn_sac_code: profile.hsn_sac_code,
      vendor_id: profile.vendor_id,
      customer_id: profile.customer_id,
      gst_treatment: profile.gst_treatment,
      source_of_supply: profile.source_of_supply,
      destination_of_supply: profile.destination_of_supply,
      reverse_charge: profile.reverse_charge,
      tax_id: profile.tax_id,
      amount_tax_mode: profile.amount_tax_mode,
      invoice_number: profile.invoice_number,
      notes: profile.notes,
      is_billable: profile.is_billable ?? false,
      recurring_expense_id: profileId,
    };
  }

  private normalizeRecurringExpenseStatus(status?: string | null): string {
    const normalized = status?.toString().trim().toUpperCase();
    if (normalized === "EXPIRED") {
      return "EXPIRED";
    }
    if (
      normalized === "STOPPED" ||
      normalized === "PAUSED" ||
      normalized === "COMPLETED" ||
      normalized === "CANCELLED"
    ) {
      return "STOPPED";
    }
    return "ACTIVE";
  }

  private todayDateString(): string {
    return new Date().toISOString().slice(0, 10);
  }

  private isExpiredByEndDate(
    endDate?: string | null,
    neverExpires?: boolean | null,
    todayStr: string = this.todayDateString(),
  ): boolean {
    if (neverExpires || !endDate) {
      return false;
    }
    return endDate < todayStr;
  }

  private resolvePersistedStatus(params: {
    incomingStatus?: string | null;
    existingStatus?: string | null;
    endDate?: string | null;
    neverExpires?: boolean | null;
    todayStr?: string;
  }): string {
    const todayStr = params.todayStr ?? this.todayDateString();
    if (this.isExpiredByEndDate(params.endDate, params.neverExpires, todayStr)) {
      return "EXPIRED";
    }

    const intendedStatus = this.normalizeRecurringExpenseStatus(
      params.incomingStatus ?? params.existingStatus,
    );

    if (intendedStatus === "EXPIRED") {
      return "ACTIVE";
    }

    return intendedStatus;
  }

  private async normalizeLegacyStatusesForEntity(entityId: string) {
    await this.supabaseService
      .getClient()
      .from("recurring_expenses")
      .update({ status: "STOPPED" })
      .eq("entity_id", entityId)
      .eq("is_delete", false)
      .in("status", ["PAUSED", "COMPLETED", "CANCELLED"]);
  }

  private mapDtoToDb(dto: any): any {
    const dbData: any = {};
    if (dto.profile_name !== undefined) dbData.profile_name = dto.profile_name;
    if (dto.entity_id !== undefined) dbData.entity_id = dto.entity_id;
    if (dto.repeat_every !== undefined) dbData.repeat_every = dto.repeat_every;
    if (dto.repeat_type !== undefined) dbData.repeat_type = dto.repeat_type;
    if (dto.start_date !== undefined) dbData.start_date = dto.start_date;
    if (dto.end_date !== undefined) dbData.end_date = dto.end_date;
    if (dto.never_expires !== undefined) dbData.never_expires = dto.never_expires;
    if (dto.next_run_date !== undefined) dbData.next_run_date = dto.next_run_date;
    if (dto.last_run_date !== undefined) dbData.last_run_date = dto.last_run_date;
    if (dto.status !== undefined) {
      dbData.status = this.normalizeRecurringExpenseStatus(dto.status);
    }
    if (dto.expense_account_id !== undefined) dbData.expense_account_id = dto.expense_account_id;
    if (dto.amount !== undefined) dbData.amount = dto.amount;
    if (dto.currency_code !== undefined) dbData.currency_code = dto.currency_code;
    if (dto.paid_through_account_id !== undefined) dbData.paid_through_account_id = dto.paid_through_account_id;
    if (dto.expense_type !== undefined) dbData.expense_type = dto.expense_type;
    if (dto.hsn_sac_code !== undefined) dbData.hsn_sac_code = dto.hsn_sac_code;
    if (dto.vendor_id !== undefined) dbData.vendor_id = dto.vendor_id;
    if (dto.gst_treatment !== undefined) dbData.gst_treatment = dto.gst_treatment;
    if (dto.source_of_supply !== undefined) dbData.source_of_supply = dto.source_of_supply;
    if (dto.destination_of_supply !== undefined) dbData.destination_of_supply = dto.destination_of_supply;
    if (dto.reverse_charge !== undefined) dbData.reverse_charge = dto.reverse_charge;
    if (dto.tax_id !== undefined) dbData.tax_id = dto.tax_id;
    if (dto.amount_tax_mode !== undefined) dbData.amount_tax_mode = dto.amount_tax_mode;
    if (dto.invoice_number !== undefined) dbData.invoice_number = dto.invoice_number;
    if (dto.notes !== undefined) dbData.notes = dto.notes;
    if (dto.customer_id !== undefined) dbData.customer_id = dto.customer_id;
    if (dto.is_billable !== undefined) dbData.is_billable = dto.is_billable;
    if (dto.auto_create !== undefined) dbData.auto_create = dto.auto_create;
    if (dto.created_by !== undefined) dbData.created_by = dto.created_by;
    if (dto.updated_by !== undefined) dbData.updated_by = dto.updated_by;
    return dbData;
  }

  private mapDbToDto(db: any): any {
    if (!db) return null;
    return {
      ...db,
      repeat_every: db.repeat_every != null ? parseInt(db.repeat_every, 10) : 1,
      amount: db.amount != null ? parseFloat(db.amount) : 0,
      never_expires: db.never_expires ?? true,
      reverse_charge: db.reverse_charge ?? false,
      is_billable: db.is_billable ?? false,
      auto_create: db.auto_create ?? true,
      status: this.normalizeRecurringExpenseStatus(db.status),
    };
  }

  private enforceBillableCustomerRule(
    payload: Record<string, any>,
    existingCustomerId?: string | null,
  ) {
    const effectiveCustomerId =
      payload.customer_id !== undefined ? payload.customer_id : existingCustomerId;

    if (!effectiveCustomerId) {
      payload.is_billable = false;
      return;
    }

    if (payload.is_billable === undefined) {
      payload.is_billable = false;
    }
  }

  public calculateNextRunDate(baseDateStr: string, repeatType: string, repeatEvery: number): string {
    const [year, month, day] = baseDateStr.split("-").map(Number);
    const date = new Date(Date.UTC(year, month - 1, day));
    const interval = Math.max(1, repeatEvery);
    const unit = repeatType.toLowerCase();

    if (unit.includes("week")) {
      date.setUTCDate(date.getUTCDate() + 7 * interval);
    } else if (unit.includes("month")) {
      date.setUTCMonth(date.getUTCMonth() + interval);
    } else if (unit.includes("year")) {
      date.setUTCFullYear(date.getUTCFullYear() + interval);
    } else {
      date.setUTCDate(date.getUTCDate() + interval);
    }

    const y = date.getUTCFullYear();
    const m = String(date.getUTCMonth() + 1).padStart(2, "0");
    const d = String(date.getUTCDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
  }

  private async resolveUserNameMap(
    userIds: (string | null | undefined)[],
    entityId?: string | null,
  ) {
    const ids = Array.from(
      new Set(
        userIds
          .map((value) => value?.toString().trim())
          .filter((value): value is string => Boolean(value)),
      ),
    );
    const userMap = new Map<string, string>();
    if (!ids.length) {
      return userMap;
    }

    const client = this.supabaseService.getClient();
    const attachUsers = (rows: any[] | null | undefined) => {
      for (const row of rows ?? []) {
        const id = String(row.id ?? "").trim();
        if (!id || userMap.has(id)) continue;
        const fullName = String(row.full_name ?? "").trim();
        const email = String(row.email ?? "").trim();
        userMap.set(id, fullName || email || `User ${id.slice(0, 8)}`);
      }
    };

    if (entityId) {
      const { data: scopedUsers } = await client
        .from("users")
        .select("id,full_name,email")
        .eq("entity_id", entityId)
        .in("id", ids);
      attachUsers(scopedUsers);
    }

    const unresolved = ids.filter((id) => !userMap.has(id));
    if (unresolved.length) {
      const { data: fallbackUsers } = await client
        .from("users")
        .select("id,full_name,email")
        .in("id", unresolved);
      attachUsers(fallbackUsers);
    }

    return userMap;
  }

  private formatAmount(amount: number) {
    const isInt = amount % 1 === 0;
    const fixed = amount.toFixed(isInt ? 0 : 2);
    const parts = fixed.split(".");
    const whole = parts[0];
    let formatted = "";
    for (let i = 0; i < whole.length; i++) {
      const remaining = whole.length - i;
      formatted += whole[i];
      if (remaining > 1 && remaining % 3 === 1) {
        formatted += ",";
      }
    }
    return `\u20B9${formatted}${parts[1] ? "." + parts[1] : ""}`;
  }

  private formatHistoryDate(dateStr: string | undefined | null) {
    if (!dateStr) return "-";
    const parts = dateStr.split("-");
    if (parts.length !== 3) return dateStr;
    const y = parts[0];
    const m = parseInt(parts[1], 10);
    const d = parseInt(parts[2], 10);
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const monthStr = months[m - 1] || parts[1];
    const dayStr = String(d).padStart(2, "0");
    return `${dayStr}-${monthStr}-${y}`;
  }

  private buildAuditSnapshot(record: any) {
    if (!record) return null;
    return {
      id: record.id ?? null,
      profile_name: record.profile_name ?? null,
      amount: record.amount ?? null,
      repeat_every: record.repeat_every ?? null,
      repeat_type: record.repeat_type ?? null,
      start_date: record.start_date ?? null,
      end_date: record.end_date ?? null,
      never_expires: record.never_expires ?? null,
      next_run_date: record.next_run_date ?? null,
      last_run_date: record.last_run_date ?? null,
      status: this.normalizeRecurringExpenseStatus(record.status),
      expense_account_id: record.expense_account_id ?? null,
      expense_account_name:
        record.expense_account_name ?? record.expense_account ?? null,
      paid_through_account_id: record.paid_through_account_id ?? null,
      paid_through_account_name:
        record.paid_through_account_name ?? record.paid_through ?? null,
      vendor_id: record.vendor_id ?? null,
      vendor_name:
        record.vendor_name ??
        record.vendor_nameRaw ??
        record.vendor?.display_name ??
        record.vendor?.company_name ??
        null,
      customer_id: record.customer_id ?? null,
      customer_name:
        record.customer_name ??
        record.customer_nameRaw ??
        record.customer?.display_name ??
        record.customer?.company_name ??
        null,
      is_billable: record.is_billable ?? false,
      gst_treatment: record.gst_treatment ?? null,
      notes: record.notes ?? null,
      created_by: record.created_by ?? null,
      created_by_name: record.created_by_name ?? null,
      updated_by: record.updated_by ?? null,
      updated_by_name: record.updated_by_name ?? null,
      created_at: record.created_at ?? null,
      updated_at: record.updated_at ?? null,
    };
  }

  private buildChangedAuditValues(
    oldSnapshot: Record<string, unknown> | null,
    newSnapshot: Record<string, unknown> | null,
    changedColumns: string[],
  ) {
    const uniqueColumns = Array.from(new Set(changedColumns.filter(Boolean)));
    if (!uniqueColumns.length) {
      return { oldValues: oldSnapshot, newValues: newSnapshot };
    }

    const oldValues: Record<string, unknown> = {};
    const newValues: Record<string, unknown> = {};

    for (const column of uniqueColumns) {
      oldValues[column] = oldSnapshot?.[column] ?? null;
      newValues[column] = newSnapshot?.[column] ?? null;
    }

    return { oldValues, newValues };
  }

  private buildHistorySummary(
    action: string,
    snapshot: any,
    changedColumns: string[] = [],
  ) {
    const upperAction = action.toUpperCase();
    if (upperAction === "CREATE" || upperAction === "INSERT") {
      const amount =
        snapshot?.amount != null ? parseFloat(snapshot.amount.toString()) : 0;
      return `Recurring expense created for ${this.formatAmount(amount)}`;
    }
    if (upperAction === "DELETE") {
      return "Recurring expense deleted";
    }
    if (changedColumns.includes("status")) {
      const status = this.normalizeRecurringExpenseStatus(snapshot?.status);
      if (status === "ACTIVE") {
        return "Recurring expense started.";
      }
      if (status === "EXPIRED") {
        return "Recurring expense expired.";
      }
      if (status === "STOPPED") {
        return "Recurring expense stopped.";
      }
    }
    return "Updated recurring expense";
  }

  private async writeAuditLogEntry(params: {
    tenant: TenantContext;
    tableName: string;
    recordId: string;
    action: "CREATE" | "UPDATE" | "DELETE";
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
      params.actorUserId?.toString().trim() ||
      params.tenant.userId?.toString().trim();
    if (!orgId || !userId) {
      return;
    }

    const resolvedActorName =
      params.actorName?.toString().trim() ||
      (await this.resolveUserNameMap([userId], params.tenant.entityId)).get(
        userId,
      ) ||
      userId;

    await this.supabaseService.getClient().from("audit_logs").insert({
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
      module_name: params.moduleName?.trim() || "recurring_expenses",
      request_id: params.requestId?.toString().trim() || null,
    });
  }

  private async attachLookups(rows: any[]) {
    if (!rows.length) return rows;

    const client = this.supabaseService.getClient();

    const accountIds = Array.from(
      new Set(
        rows
          .flatMap((r) => [r.expense_account_id, r.paid_through_account_id])
          .filter(Boolean),
      ),
    );
    const vendorIds = Array.from(
      new Set(rows.map((r) => r.vendor_id).filter(Boolean)),
    );
    const customerIds = Array.from(
      new Set(rows.map((r) => r.customer_id).filter(Boolean)),
    );
    const userIds = Array.from(
      new Set(
        rows
          .flatMap((r) => [r.created_by, r.updated_by])
          .filter(Boolean),
      ),
    );

    const accountMap = new Map<string, any>();
    const vendorMap = new Map<string, any>();
    const customerMap = new Map<string, any>();
    const userMap = new Map<string, string>();

    if (accountIds.length) {
      const { data: accounts } = await client
        .from("accounts")
        .select("id,user_account_name,system_account_name,account_code")
        .in("id", accountIds);
      for (const acc of accounts ?? []) {
        accountMap.set(acc.id, acc);
      }
    }

    if (vendorIds.length) {
      const { data: vendors } = await client
        .from("vendors")
        .select("id,display_name,company_name")
        .in("id", vendorIds);
      for (const ven of vendors ?? []) {
        vendorMap.set(ven.id, ven);
      }
    }

    if (customerIds.length) {
      const { data: customers } = await client
        .from("customers")
        .select("id,display_name,company_name")
        .in("id", customerIds);
      for (const cust of customers ?? []) {
        customerMap.set(cust.id, cust);
      }
    }

    if (userIds.length) {
      const resolvedUsers = await this.resolveUserNameMap(
        userIds,
        rows[0]?.entity_id,
      );
      for (const [id, name] of resolvedUsers.entries()) {
        userMap.set(id, name);
      }
    }

    return rows.map((row) => {
      const expenseAcc = row.expense_account_id ? accountMap.get(row.expense_account_id) : null;
      const paidThroughAcc = row.paid_through_account_id ? accountMap.get(row.paid_through_account_id) : null;
      const vendor = row.vendor_id ? vendorMap.get(row.vendor_id) ?? null : null;
      const customer = row.customer_id ? customerMap.get(row.customer_id) ?? null : null;
      const expenseAccountName = expenseAcc
        ? expenseAcc.user_account_name || expenseAcc.system_account_name || expenseAcc.account_code || ""
        : "";
      const paidThroughAccountName = paidThroughAcc
        ? paidThroughAcc.user_account_name || paidThroughAcc.system_account_name || paidThroughAcc.account_code || ""
        : "";
      const vendorName = vendor
        ? vendor.display_name || vendor.company_name || ""
        : "";
      const customerName = customer
        ? customer.display_name || customer.company_name || ""
        : "";
      return {
        ...row,
        expense_account_name: expenseAccountName,
        paid_through_account_name: paidThroughAccountName,
        vendor_name: vendorName,
        customer_name: customerName,
        created_by_name: row.created_by ? userMap.get(row.created_by) ?? null : null,
        updated_by_name: row.updated_by ? userMap.get(row.updated_by) ?? null : null,
        expense_account: expenseAcc
          ? expenseAccountName
          : "",
        paid_through: paidThroughAcc
          ? paidThroughAccountName
          : "",
        vendor,
        customer,
      };
    });
  }

  async create(createDto: CreateRecurringExpenseDto, tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const todayStr = this.todayDateString();

    const computedNextRunDate = this.calculateNextRunDate(
      createDto.start_date,
      createDto.repeat_type,
      createDto.repeat_every ?? 1,
    );

    const payload = this.mapDtoToDb({
      ...createDto,
      entity_id: tenant.entityId,
      created_by: tenant.userId,
      updated_by: tenant.userId,
      next_run_date: createDto.next_run_date || computedNextRunDate,
    });
    this.enforceBillableCustomerRule(payload);
    const persistedStatus = this.resolvePersistedStatus({
      incomingStatus: createDto.status,
      endDate: payload.end_date,
      neverExpires: payload.never_expires,
      todayStr,
    });
    payload.status = persistedStatus;

    if (
      payload.end_date &&
      !payload.never_expires &&
      payload.next_run_date &&
      payload.next_run_date > payload.end_date
    ) {
      payload.next_run_date = null;
    }

    const { data, error } = await client
      .from("recurring_expenses")
      .insert([payload])
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create recurring expense profile: ${error.message}`);
    }

    const [enriched] = await this.attachLookups([data]);
    const newSnapshot = this.buildAuditSnapshot(enriched);
    await this.writeAuditLogEntry({
      tenant,
      tableName: "recurring_expenses",
      recordId: data.id,
      action: "CREATE",
      oldValues: null,
      newValues: newSnapshot,
      changedColumns: Object.keys(newSnapshot ?? {}),
      actorName: enriched?.created_by_name ?? null,
      source: "system",
      moduleName: "recurring_expenses",
    });
    return this.mapDbToDto(enriched);
  }

  private normalizeRecurringSortField(field?: string) {
    switch ((field ?? "profile_name").toLowerCase()) {
      case "expense_account":
      case "expense_account_name":
        return "expense_account_name";
      case "vendor":
      case "vendor_name":
        return "vendor_name";
      case "last_expense_date":
      case "last_run_date":
        return "last_run_date";
      case "next_expense_date":
      case "next_run_date":
        return "next_run_date";
      case "amount":
        return "amount";
      case "created_time":
      case "created_at":
        return "created_at";
      case "profile":
      case "profile_name":
      default:
        return "profile_name";
    }
  }

  private applyRecurringSort(query: any, sortField: string, ascending: boolean) {
    switch (sortField) {
      case "profile_name":
      case "amount":
      case "last_run_date":
      case "next_run_date":
      case "created_at":
        return query.order(sortField, {
          ascending,
          nullsFirst: !ascending,
        });
      default:
        return query.order("created_at", { ascending: false });
    }
  }

  private compareRecurringSortValues(left: any, right: any) {
    if (left == null && right == null) return 0;
    if (left == null) return -1;
    if (right == null) return 1;

    if (typeof left === "number" && typeof right === "number") {
      return left - right;
    }

    const leftText = String(left).trim().toLowerCase();
    const rightText = String(right).trim().toLowerCase();
    return leftText.localeCompare(rightText);
  }

  private sortRecurringRows(rows: any[], sortField: string, ascending: boolean) {
    const sorted = [...rows];
    sorted.sort((left, right) => {
      let result = 0;
      switch (sortField) {
        case "expense_account_name":
          result = this.compareRecurringSortValues(
            left.expense_account_name,
            right.expense_account_name,
          );
          break;
        case "vendor_name":
          result = this.compareRecurringSortValues(left.vendor_name, right.vendor_name);
          break;
        case "last_run_date":
          result = this.compareRecurringSortValues(left.last_run_date, right.last_run_date);
          break;
        case "next_run_date":
          result = this.compareRecurringSortValues(left.next_run_date, right.next_run_date);
          break;
        case "amount":
          result = this.compareRecurringSortValues(left.amount, right.amount);
          break;
        case "created_at":
          result = this.compareRecurringSortValues(left.created_at, right.created_at);
          break;
        case "profile_name":
        default:
          result = this.compareRecurringSortValues(left.profile_name, right.profile_name);
          break;
      }
      return ascending ? result : -result;
    });
    return sorted;
  }

  async findAll(
    tenant: TenantContext,
    queryDto: ListRecurringExpensesQueryDto,
  ) {
    const page = queryDto.page ?? 1;
    const limit = queryDto.limit ?? 100;
    const offset = (page - 1) * limit;
    const client = this.supabaseService.getClient();
    const sortField = this.normalizeRecurringSortField(queryDto.sort_field);
    const sortAscending = (queryDto.sort_direction ?? "asc") === "asc";

    await this.normalizeLegacyStatusesForEntity(tenant.entityId);

    let query: any = client
      .from("recurring_expenses")
      .select("*", { count: "exact" })
      .eq("entity_id", tenant.entityId)
      .eq("is_delete", false);

    if (queryDto.search) {
      query = query.or(
        `profile_name.ilike.%${queryDto.search}%,invoice_number.ilike.%${queryDto.search}%,notes.ilike.%${queryDto.search}%`,
      );
    }

    if (queryDto.profile_name) {
      query = query.ilike("profile_name", `%${queryDto.profile_name}%`);
    }

    if (queryDto.notes) {
      query = query.ilike("notes", `%${queryDto.notes}%`);
    }

    if (queryDto.status) {
      query = query.eq(
        "status",
        this.normalizeRecurringExpenseStatus(queryDto.status),
      );
    }

    if (queryDto.vendor_id) {
      query = query.eq("vendor_id", queryDto.vendor_id);
    }

    if (queryDto.customer_id) {
      query = query.eq("customer_id", queryDto.customer_id);
    }

    if (queryDto.expense_account_id) {
      query = query.eq("expense_account_id", queryDto.expense_account_id);
    }

    if (queryDto.gst_treatment) {
      query = query.eq("gst_treatment", queryDto.gst_treatment);
    }

    if (queryDto.source_of_supply) {
      query = query.eq("source_of_supply", queryDto.source_of_supply);
    }

    if (queryDto.destination_of_supply) {
      query = query.eq("destination_of_supply", queryDto.destination_of_supply);
    }

    if (queryDto.tax_id) {
      query = query.eq("tax_id", queryDto.tax_id);
    }

    if (queryDto.start_date_from) {
      query = query.gte("start_date", queryDto.start_date_from);
    }

    if (queryDto.start_date_to) {
      query = query.lte("start_date", queryDto.start_date_to);
    }

    if (queryDto.end_date_from) {
      query = query.gte("end_date", queryDto.end_date_from);
    }

    if (queryDto.end_date_to) {
      query = query.lte("end_date", queryDto.end_date_to);
    }

    if (queryDto.amount_from !== undefined) {
      query = query.gte("amount", queryDto.amount_from);
    }

    if (queryDto.amount_to !== undefined) {
      query = query.lte("amount", queryDto.amount_to);
    }

    const requiresLookupSort =
      sortField === "expense_account_name" || sortField === "vendor_name";

    if (!requiresLookupSort) {
      query = this.applyRecurringSort(query, sortField, sortAscending).range(
        offset,
        offset + limit - 1,
      );
    }

    const { data, error, count } = await query;

    if (error) {
      throw new Error(`Failed to fetch recurring expenses: ${error.message}`);
    }

    const totalCount = count ?? 0;
    const totalPages = totalCount > 0 ? Math.ceil(totalCount / limit) : 1;

    let enriched = await this.attachLookups(data ?? []);
    if (requiresLookupSort) {
      enriched = this.sortRecurringRows(enriched, sortField, sortAscending).slice(
        offset,
        offset + limit,
      );
    }
    const mapped = enriched.map((row) => this.mapDbToDto(row));

    this.logger.debug(
      `[RECURRING_PAGINATION_TRACE][backend] total=${totalCount} page=${page} limit=${limit} totalPages=${totalPages} returned=${mapped.length}`,
    );

    return {
      data: mapped,
      meta: {
        total: totalCount,
        page,
        limit,
        totalPages,
      },
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    await this.normalizeLegacyStatusesForEntity(tenant.entityId);
    const { data, error } = await client
      .from("recurring_expenses")
      .select("*")
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .eq("is_delete", false)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to fetch recurring expense: ${error.message}`);
    }

    if (!data) {
      throw new NotFoundException(`Recurring Expense with ID ${id} not found`);
    }

    const [enriched] = await this.attachLookups([data]);
    return this.mapDbToDto(enriched);
  }

  async update(
    id: string,
    updateDto: UpdateRecurringExpenseDto,
    tenant: TenantContext,
    options?: {
      requestId?: string | null;
    },
  ) {
    const client = this.supabaseService.getClient();
    const todayStr = this.todayDateString();

    // Ensure existence
    const existing = await this.findOne(id, tenant);

    const payload = this.mapDtoToDb({
      ...updateDto,
      updated_by: tenant.userId,
      updated_at: new Date().toISOString(),
    });
    this.enforceBillableCustomerRule(payload, existing.customer_id);

    const hasSchedulingChanges =
      (updateDto.start_date !== undefined && updateDto.start_date !== existing.start_date) ||
      (updateDto.repeat_type !== undefined && updateDto.repeat_type !== existing.repeat_type) ||
      (updateDto.repeat_every !== undefined && updateDto.repeat_every !== existing.repeat_every) ||
      (updateDto.end_date !== undefined && updateDto.end_date !== existing.end_date) ||
      (updateDto.never_expires !== undefined && updateDto.never_expires !== existing.never_expires);

    if (hasSchedulingChanges) {
      const newStartDate = updateDto.start_date !== undefined ? updateDto.start_date : existing.start_date;
      const newRepeatType = updateDto.repeat_type !== undefined ? updateDto.repeat_type : existing.repeat_type;
      const newRepeatEvery = updateDto.repeat_every !== undefined ? updateDto.repeat_every : existing.repeat_every;
      const newEndDate = updateDto.never_expires === true ? null : (updateDto.end_date !== undefined ? updateDto.end_date : existing.end_date);
      const newNeverExpires = updateDto.never_expires !== undefined ? updateDto.never_expires : existing.never_expires;

      let baseDate = newStartDate;
      const startDateChanged = updateDto.start_date !== undefined && updateDto.start_date !== existing.start_date;
      if (!startDateChanged && existing.last_run_date) {
        baseDate = existing.last_run_date;
      }

      let nextRunDate: string | null = this.calculateNextRunDate(
        baseDate,
        newRepeatType,
        newRepeatEvery ?? 1,
      );

      if (newEndDate && !newNeverExpires && nextRunDate > newEndDate) {
        nextRunDate = null;
      }

      payload.next_run_date = nextRunDate;
    }

    const effectiveEndDate =
      payload.end_date !== undefined ? payload.end_date : existing.end_date;
    const effectiveNeverExpires =
      payload.never_expires !== undefined
        ? payload.never_expires
        : existing.never_expires;

    payload.status = this.resolvePersistedStatus({
      incomingStatus: updateDto.status,
      existingStatus: existing.status,
      endDate: effectiveEndDate,
      neverExpires: effectiveNeverExpires,
      todayStr,
    });

    // Capture field delta changes for history audit trail
    const changes: string[] = [];
    const changedColumns: string[] = [];

    if (updateDto.profile_name !== undefined && updateDto.profile_name !== existing.profile_name) {
      changes.push(`Profile Name changed from ${existing.profile_name || '-'} to ${updateDto.profile_name}`);
      changedColumns.push("profile_name");
    }
    if (updateDto.amount !== undefined) {
      const oldAmt = existing.amount != null ? parseFloat(existing.amount.toString()) : 0;
      const newAmt = parseFloat(updateDto.amount.toString());
      if (oldAmt !== newAmt) {
        changes.push(`Amount changed from ${this.formatAmount(oldAmt)} to ${this.formatAmount(newAmt)}`);
        changedColumns.push("amount");
      }
    }
    if (updateDto.repeat_every !== undefined) {
      const oldRep = existing.repeat_every != null ? parseInt(existing.repeat_every.toString(), 10) : 1;
      const newRep = parseInt(updateDto.repeat_every.toString(), 10);
      if (oldRep !== newRep) {
        changes.push(`Repeat Every changed from ${oldRep} to ${newRep}`);
        changedColumns.push("repeat_every");
      }
    }
    if (updateDto.repeat_type !== undefined && updateDto.repeat_type !== existing.repeat_type) {
      changes.push(`Repeat Type changed from ${existing.repeat_type || '-'} to ${updateDto.repeat_type}`);
      changedColumns.push("repeat_type");
    }
    if (updateDto.start_date !== undefined && updateDto.start_date !== existing.start_date) {
      changes.push(`Start Date changed from ${this.formatHistoryDate(existing.start_date)} to ${this.formatHistoryDate(updateDto.start_date)}`);
      changedColumns.push("start_date");
    }
    if (updateDto.end_date !== undefined && updateDto.end_date !== existing.end_date) {
      changes.push(`End Date changed from ${this.formatHistoryDate(existing.end_date)} to ${this.formatHistoryDate(updateDto.end_date)}`);
      changedColumns.push("end_date");
    }
    if (updateDto.never_expires !== undefined && updateDto.never_expires !== existing.never_expires) {
      changes.push(`Never Expires changed from ${existing.never_expires ? 'True' : 'False'} to ${updateDto.never_expires ? 'True' : 'False'}`);
      changedColumns.push("never_expires");
    }
    const normalizedIncomingStatus =
      payload.status !== undefined
        ? this.normalizeRecurringExpenseStatus(payload.status)
        : undefined;
    const normalizedExistingStatus = this.normalizeRecurringExpenseStatus(
      existing.status,
    );
    if (
      normalizedIncomingStatus !== undefined &&
      normalizedIncomingStatus !== normalizedExistingStatus
    ) {
      changes.push(
        `Status changed from ${normalizedExistingStatus} to ${normalizedIncomingStatus}`,
      );
      changedColumns.push("status");
    }
    if (updateDto.gst_treatment !== undefined && updateDto.gst_treatment !== existing.gst_treatment) {
      changes.push(`GST Treatment changed from ${existing.gst_treatment || '-'} to ${updateDto.gst_treatment}`);
      changedColumns.push("gst_treatment");
    }
    if (updateDto.notes !== undefined && updateDto.notes !== existing.notes) {
      changes.push(`Notes changed from ${existing.notes || '-'} to ${updateDto.notes}`);
      changedColumns.push("notes");
    }
    if (updateDto.auto_create !== undefined && updateDto.auto_create !== existing.auto_create) {
      changes.push(`Auto Create changed from ${existing.auto_create ? 'True' : 'False'} to ${updateDto.auto_create ? 'True' : 'False'}`);
      changedColumns.push("auto_create");
    }

    const nextRunDateBefore = existing.next_run_date;
    const nextRunDateAfter = payload.next_run_date !== undefined ? payload.next_run_date : existing.next_run_date;
    if (nextRunDateBefore !== nextRunDateAfter) {
      changes.push(`Next Expense Date changed from ${this.formatHistoryDate(nextRunDateBefore)} to ${this.formatHistoryDate(nextRunDateAfter)}`);
      changedColumns.push("next_run_date");
    }

    if (updateDto.expense_account_id !== undefined && updateDto.expense_account_id !== existing.expense_account_id) {
      const { data: oldAcc } = await client.from("accounts").select("user_account_name, system_account_name").eq("id", existing.expense_account_id).maybeSingle();
      const { data: newAcc } = await client.from("accounts").select("user_account_name, system_account_name").eq("id", updateDto.expense_account_id).maybeSingle();
      const oldName = oldAcc ? (oldAcc.user_account_name || oldAcc.system_account_name) : '-';
      const newName = newAcc ? (newAcc.user_account_name || newAcc.system_account_name) : '-';
      changes.push(`Expense Account changed from ${oldName} to ${newName}`);
      changedColumns.push("expense_account_id");
    }
    if (updateDto.paid_through_account_id !== undefined && updateDto.paid_through_account_id !== existing.paid_through_account_id) {
      const { data: oldAcc } = await client.from("accounts").select("user_account_name, system_account_name").eq("id", existing.paid_through_account_id).maybeSingle();
      const { data: newAcc } = await client.from("accounts").select("user_account_name, system_account_name").eq("id", updateDto.paid_through_account_id).maybeSingle();
      const oldName = oldAcc ? (oldAcc.user_account_name || oldAcc.system_account_name) : '-';
      const newName = newAcc ? (newAcc.user_account_name || newAcc.system_account_name) : '-';
      changes.push(`Paid Through changed from ${oldName} to ${newName}`);
      changedColumns.push("paid_through_account_id");
    }
    if (updateDto.vendor_id !== undefined && updateDto.vendor_id !== existing.vendor_id) {
      const { data: oldV } = await client.from("vendors").select("display_name").eq("id", existing.vendor_id).maybeSingle();
      const { data: newV } = await client.from("vendors").select("display_name").eq("id", updateDto.vendor_id).maybeSingle();
      const oldName = oldV ? oldV.display_name : '-';
      const newName = newV ? newV.display_name : '-';
      changes.push(`Vendor changed from ${oldName} to ${newName}`);
      changedColumns.push("vendor_id");
    }
    if (updateDto.customer_id !== undefined && updateDto.customer_id !== existing.customer_id) {
      const { data: oldC } = await client.from("customers").select("display_name").eq("id", existing.customer_id).maybeSingle();
      const { data: newC } = await client.from("customers").select("display_name").eq("id", updateDto.customer_id).maybeSingle();
      const oldName = oldC ? oldC.display_name : '-';
      const newName = newC ? newC.display_name : '-';
      changes.push(`Customer changed from ${oldName} to ${newName}`);
      changedColumns.push("customer_id");
    }
    if (
      payload.is_billable !== undefined &&
      payload.is_billable !== (existing.is_billable ?? false)
    ) {
      changes.push(
        `Billable changed from ${(existing.is_billable ?? false) ? "True" : "False"} to ${payload.is_billable ? "True" : "False"}`,
      );
      changedColumns.push("is_billable");
    }

    const { data, error } = await client
      .from("recurring_expenses")
      .update(payload)
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update recurring expense: ${error.message}`);
    }

    const [enriched] = await this.attachLookups([data]);
    if (changes.length > 0) {
      const oldSnapshot = this.buildAuditSnapshot(existing);
      const newSnapshot = this.buildAuditSnapshot(enriched);
      const auditValues = this.buildChangedAuditValues(
        oldSnapshot,
        newSnapshot,
        changedColumns,
      );
      await this.writeAuditLogEntry({
        tenant,
        tableName: "recurring_expenses",
        recordId: id,
        action: "UPDATE",
        oldValues: auditValues.oldValues,
        newValues: {
          ...auditValues.newValues,
          history_changes: changes,
        },
        changedColumns,
        actorName: enriched?.updated_by_name ?? null,
        source: "system",
        moduleName: "recurring_expenses",
        requestId: options?.requestId ?? null,
      });
    }
    return this.mapDbToDto(enriched);
  }

  async remove(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();

    // Ensure existence
    const existing = await this.findOne(id, tenant);

    const { error } = await client
      .from("recurring_expenses")
      .update({
        is_delete: true,
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (error) {
      throw new Error(`Failed to delete recurring expense: ${error.message}`);
    }

    await this.writeAuditLogEntry({
      tenant,
      tableName: "recurring_expenses",
      recordId: id,
      action: "DELETE",
      oldValues: this.buildAuditSnapshot(existing),
      newValues: { is_delete: true },
      changedColumns: ["is_delete"],
      actorName: existing?.updated_by_name ?? existing?.created_by_name ?? null,
      source: "system",
      moduleName: "recurring_expenses",
    });

    return { message: "Recurring Expense deleted successfully" };
  }

  async removeBulk(ids: string[], tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const existingRows = ids.length
      ? await Promise.all(ids.map((rowId) => this.findOne(rowId, tenant).catch(() => null)))
      : [];

    const { data, error } = await client
      .from("recurring_expenses")
      .update({
        is_delete: true,
        updated_at: new Date().toISOString(),
      })
      .in("id", ids)
      .eq("entity_id", tenant.entityId)
      .select("id");

    if (error) {
      throw new Error(`Failed to bulk delete recurring expenses: ${error.message}`);
    }

    for (const row of existingRows.filter(Boolean)) {
      await this.writeAuditLogEntry({
        tenant,
        tableName: "recurring_expenses",
        recordId: row.id,
        action: "DELETE",
        oldValues: this.buildAuditSnapshot(row),
        newValues: { is_delete: true },
        changedColumns: ["is_delete"],
        actorName: row.updated_by_name ?? row.created_by_name ?? null,
        source: "system",
        moduleName: "recurring_expenses",
      });
    }

    return { success: true, deletedCount: data?.length ?? 0 };
  }

  async bulkUpdate(
    tenant: TenantContext,
    ids: string[],
    updateData: BulkUpdateRecurringExpensesDataDto,
  ) {
    const allowedColumns = new Set<string>([
      "expense_account_id",
      "paid_through_account_id",
      "end_date",
      "repeat_every",
      "repeat_type",
      "notes",
      "vendor_id",
      "customer_id",
      "expense_type",
      "is_billable",
    ]);
    const payload = Object.fromEntries(
      Object.entries(updateData ?? {}).filter(([key, value]) => {
        return allowedColumns.has(key) && value !== undefined;
      }),
    ) as Record<string, unknown>;

    if (!ids.length) {
      throw new Error("No recurring expense IDs provided for bulk update.");
    }
    if (!Object.keys(payload).length) {
      throw new Error("No supported recurring expense fields provided.");
    }
    if (
      payload["repeat_every"] !== undefined &&
      payload["repeat_type"] === undefined
    ) {
      throw new Error("repeat_type is required when repeat_every is updated.");
    }

    if (payload["end_date"] !== undefined) {
      payload["never_expires"] = false;
    }

    const requestId = `recurring-expenses-bulk-update-${Date.now()}-${randomUUID()}`;
    const updated: any[] = [];
    const failed: Array<{ id: string; reason: string }> = [];

    for (const id of ids) {
      try {
        const row = await this.update(
          id,
          payload as UpdateRecurringExpenseDto,
          tenant,
          { requestId },
        );
        updated.push(row);
      } catch (error) {
        failed.push({
          id,
          reason: error instanceof Error ? error.message : "Unknown error",
        });
      }
    }

    return {
      requestedCount: ids.length,
      updatedCount: updated.length,
      failedCount: failed.length,
      updated,
      failed,
      requestId,
    };
  }

  async stop(id: string, tenant: TenantContext) {
    return this.update(id, { status: "STOPPED" }, tenant);
  }

  async start(id: string, tenant: TenantContext) {
    return this.update(id, { status: "ACTIVE" }, tenant);
  }

  async createExpenseNow(
    id: string,
    tenant: TenantContext,
    runDate?: string,
  ) {
    const effectiveRunDate =
      runDate?.trim() || new Date().toISOString().split("T")[0];
    return this.generateExpenseFromRecurring(id, tenant, effectiveRunDate);
  }

  async overview(id: string, tenant: TenantContext) {
    const profile = await this.findOne(id, tenant);
    const client = this.supabaseService.getClient();

    const { data: runs, error } = await client
      .from("recurring_expense_runs")
      .select("generated_amount")
      .eq("recurring_expense_id", id);

    if (error) {
      throw new Error(`Failed to fetch runs statistics: ${error.message}`);
    }

    let totalAmount = 0;
    const totalRuns = runs?.length ?? 0;
    for (const r of runs ?? []) {
      totalAmount += parseFloat(r.generated_amount?.toString() ?? "0");
    }

    return {
      id: profile.id,
      profileName: profile.profile_name,
      status: profile.status,
      nextRunDate: profile.next_run_date,
      lastRunDate: profile.last_run_date,
      totalRuns,
      totalAmount,
    };
  }

  async runs(id: string, tenant: TenantContext) {
    // Verify ownership
    await this.findOne(id, tenant);

    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("recurring_expense_runs")
      .select("*")
      .eq("recurring_expense_id", id)
      .order("created_at", { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch runs history: ${error.message}`);
    }

    const userIdsToResolve: string[] = [];
    for (const run of data ?? []) {
      try {
        if (run.remarks && run.remarks.startsWith("{")) {
          const parsed = JSON.parse(run.remarks);
          const performedBy = parsed?.performed_by?.toString?.().trim();
          const performedByName = parsed?.performed_by_name?.toString?.().trim();
          if (performedBy && !performedByName) {
            userIdsToResolve.push(performedBy);
          }
        }
      } catch (e) { }
    }
    const userNameMap = await this.resolveUserNameMap(
      userIdsToResolve,
      tenant.entityId,
    );

    return data.map((r) => {
      let performedBy = null;
      let performedByName = null;
      try {
        if (r.remarks && r.remarks.startsWith('{')) {
          const parsed = JSON.parse(r.remarks);
          if (parsed.performed_by) performedBy = parsed.performed_by;
          if (parsed.performed_by_name) performedByName = parsed.performed_by_name;
        }
      } catch (e) { }

      if (!performedByName && performedBy) {
        performedByName = userNameMap.get(String(performedBy).trim()) ?? null;
      }

      if (!performedByName) {
        performedByName = 'AUTO';
        performedBy = 'AUTO';
      }

      return {
        ...r,
        generated_amount: r.generated_amount != null ? parseFloat(r.generated_amount) : 0,
        performed_by: performedBy,
        performed_by_name: performedByName,
      };
    });
  }

  async history(id: string, tenant: TenantContext) {
    await this.findOne(id, tenant);

    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("audit_logs")
      .select(
        "id, action, actor_name, user_id, created_at, changed_columns, old_values, new_values, source",
      )
      .eq("entity_id", tenant.entityId)
      .eq("table_name", "recurring_expenses")
      .eq("record_id", id)
      .order("created_at", { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch recurring expense audit history: ${error.message}`);
    }

    const actorNameMap = await this.resolveUserNameMap(
      (data ?? []).map((row: any) => row.user_id?.toString()),
      tenant.entityId,
    );

    return (data ?? []).map((row: any) => {
      const newValues =
        row.new_values && typeof row.new_values === "object"
          ? row.new_values
          : null;
      const changedColumns = Array.isArray(row.changed_columns)
        ? row.changed_columns.filter(Boolean)
        : [];
      const actorNameRaw = row.actor_name?.toString().trim() ?? "";
      const actorName = actorNameRaw &&
        !/^[0-9a-fA-F-]{36}$/.test(actorNameRaw) &&
        actorNameRaw.toUpperCase() != "AUTO"
        ? actorNameRaw
        : (row.user_id
          ? actorNameMap.get(row.user_id.toString().trim())
          : null) ??
        (actorNameRaw.length > 0 ? actorNameRaw : "AUTO");

      const historyChanges: string[] =
        newValues &&
          Array.isArray(newValues.history_changes) &&
          newValues.history_changes.length > 0
          ? (newValues.history_changes as unknown[]).map((v) => String(v)).filter(Boolean)
          : [];

      return {
        id: row.id,
        action: row.action,
        actor_name: actorName,
        created_at: row.created_at,
        source: row.source,
        changed_columns: changedColumns,
        old_values: row.old_values,
        new_values: row.new_values,
        summary: this.buildHistorySummary(
          row.action,
          newValues ?? row.old_values,
          changedColumns,
        ),
        field_changes: historyChanges,
      };
    });
  }

  async receipts(id: string, tenant: TenantContext) {
    // Verify ownership
    await this.findOne(id, tenant);

    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("recurring_expense_receipts")
      .select("*")
      .eq("recurring_expense_id", id)
      .order("uploaded_at", { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch receipts: ${error.message}`);
    }

    return data.map((rec) => ({
      ...rec,
      file_size: rec.file_size != null ? parseInt(rec.file_size, 10) : 0,
    }));
  }

  async uploadReceipt(id: string, filePayload: any, tenant: TenantContext) {
    // Verify ownership
    await this.findOne(id, tenant);

    const client = this.supabaseService.getClient();
    const payload = {
      recurring_expense_id: id,
      file_name: filePayload.file_name,
      file_url: filePayload.file_url,
      file_size: filePayload.file_size,
      uploaded_by: tenant.userId,
    };

    const { data, error } = await client
      .from("recurring_expense_receipts")
      .insert([payload])
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to save receipt attachment: ${error.message}`);
    }

    await this.writeAuditLogEntry({
      tenant,
      tableName: "recurring_expense_receipts",
      recordId: data.id,
      action: "CREATE",
      oldValues: null,
      newValues: {
        id: data.id ?? null,
        recurring_expense_id: data.recurring_expense_id ?? id,
        file_name: data.file_name ?? null,
        file_url: data.file_url ?? null,
        file_size: data.file_size != null ? parseInt(data.file_size, 10) : null,
        uploaded_by: data.uploaded_by ?? tenant.userId ?? null,
        uploaded_at: data.uploaded_at ?? null,
      },
      changedColumns: [
        "recurring_expense_id",
        "file_name",
        "file_url",
        "file_size",
        "uploaded_by",
        "uploaded_at",
      ],
      actorUserId: tenant.userId,
      source: "system",
      moduleName: "recurring_expenses",
    });

    return {
      ...data,
      file_size: data.file_size != null ? parseInt(data.file_size, 10) : 0,
    };
  }

  async deleteReceipt(id: string, receiptId: string, tenant: TenantContext) {
    // Verify ownership
    await this.findOne(id, tenant);

    const client = this.supabaseService.getClient();
    const { data: existingReceipt, error: existingReceiptError } = await client
      .from("recurring_expense_receipts")
      .select("*")
      .eq("id", receiptId)
      .eq("recurring_expense_id", id)
      .maybeSingle();

    if (existingReceiptError) {
      throw new Error(
        `Failed to fetch receipt before delete: ${existingReceiptError.message}`,
      );
    }

    const { error } = await client
      .from("recurring_expense_receipts")
      .delete()
      .eq("id", receiptId)
      .eq("recurring_expense_id", id);

    if (error) {
      throw new Error(`Failed to delete receipt: ${error.message}`);
    }

    if (existingReceipt) {
      await this.writeAuditLogEntry({
        tenant,
        tableName: "recurring_expense_receipts",
        recordId: receiptId,
        action: "DELETE",
        oldValues: {
          id: existingReceipt.id ?? null,
          recurring_expense_id: existingReceipt.recurring_expense_id ?? id,
          file_name: existingReceipt.file_name ?? null,
          file_url: existingReceipt.file_url ?? null,
          file_size:
            existingReceipt.file_size != null
              ? parseInt(existingReceipt.file_size, 10)
              : null,
          uploaded_by: existingReceipt.uploaded_by ?? null,
          uploaded_at: existingReceipt.uploaded_at ?? null,
        },
        newValues: null,
        changedColumns: [
          "id",
          "recurring_expense_id",
          "file_name",
          "file_url",
          "file_size",
          "uploaded_by",
          "uploaded_at",
        ],
        actorUserId: tenant.userId,
        source: "system",
        moduleName: "recurring_expenses",
      });
    }

    return true;
  }

  // --- Cron Scheduler Helper Methods ---

  async findAllGlobalActiveRecurringExpenses() {
    const client = this.supabaseService.getClient();
    const today = new Date().toISOString().split("T")[0];

    const { data, error } = await client
      .from("recurring_expenses")
      .select("*")
      .eq("status", "ACTIVE")
      .eq("is_delete", false)
      .or(`next_run_date.lte.${today},and(next_run_date.is.null,start_date.lte.${today})`);

    if (error) {
      throw new Error(`Failed to fetch active global recurring profiles: ${error.message}`);
    }

    return data ?? [];
  }

  async generateExpenseFromRecurring(
    profileId: string,
    tenant: TenantContext,
    runDate: string,
  ) {
    const client = this.supabaseService.getClient();

    // Fetch fresh profile details
    const profile = await this.findOne(profileId, tenant);

    try {
      const createExpenseDto = this.buildCreateExpenseDtoFromRecurringProfile(
        profile,
        profileId,
        runDate,
      );
      const expense = await this.expensesService.create(createExpenseDto, tenant);

      // 2. Create run log
      const runPayload = {
        recurring_expense_id: profileId,
        expense_id: expense.id,
        run_date: runDate,
        generated_amount: profile.amount,
        status: "SUCCESS",
        remarks: `Auto-generated expense ${expense.expenseNumber ?? expense.id}`,
      };

      const { data: runRecord, error: runInsertError } = await client
        .from("recurring_expense_runs")
        .insert([runPayload])
        .select()
        .single();

      if (runInsertError) {
        throw new Error(`Recurring expense run insert failed: ${runInsertError.message}`);
      }

      await this.writeAuditLogEntry({
        tenant,
        tableName: "recurring_expense_runs",
        recordId: runRecord.id,
        action: "CREATE",
        oldValues: null,
        newValues: {
          id: runRecord.id ?? null,
          recurring_expense_id: runRecord.recurring_expense_id ?? profileId,
          expense_id: runRecord.expense_id ?? expense.id,
          run_date: runRecord.run_date ?? runDate,
          generated_amount:
            runRecord.generated_amount != null
              ? parseFloat(runRecord.generated_amount)
              : profile.amount,
          status: runRecord.status ?? "SUCCESS",
          remarks: runRecord.remarks ?? null,
        },
        changedColumns: [
          "recurring_expense_id",
          "expense_id",
          "run_date",
          "generated_amount",
          "status",
          "remarks",
        ],
        actorUserId: tenant.userId,
        source: "system",
        moduleName: "recurring_expenses",
      });

      return expense;
    } catch (err) {
      // Create a FAILED run log
      const runPayload = {
        recurring_expense_id: profileId,
        run_date: runDate,
        generated_amount: profile.amount,
        status: "FAILED",
        remarks: err instanceof Error ? err.message : String(err),
      };
      const { data: failedRunRecord } = await client
        .from("recurring_expense_runs")
        .insert([runPayload])
        .select()
        .single();

      if (failedRunRecord) {
        await this.writeAuditLogEntry({
          tenant,
          tableName: "recurring_expense_runs",
          recordId: failedRunRecord.id,
          action: "CREATE",
          oldValues: null,
          newValues: {
            id: failedRunRecord.id ?? null,
            recurring_expense_id:
              failedRunRecord.recurring_expense_id ?? profileId,
            expense_id: failedRunRecord.expense_id ?? null,
            run_date: failedRunRecord.run_date ?? runDate,
            generated_amount:
              failedRunRecord.generated_amount != null
                ? parseFloat(failedRunRecord.generated_amount)
                : profile.amount,
            status: failedRunRecord.status ?? "FAILED",
            remarks: failedRunRecord.remarks ?? null,
          },
          changedColumns: [
            "recurring_expense_id",
            "expense_id",
            "run_date",
            "generated_amount",
            "status",
            "remarks",
          ],
          actorUserId: tenant.userId,
          source: "system",
          moduleName: "recurring_expenses",
        });
      }

      throw err;
    }
  }

  async getRelatedExpenses(id: string, tenant: TenantContext) {
    // Verify ownership
    await this.findOne(id, tenant);

    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("expenses")
      .select("*")
      .eq("recurring_expense_id", id)
      .eq("entity_id", tenant.entityId)
      .order("expense_date", { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch related expenses: ${error.message}`);
    }

    return this.attachLookups(data || []);
  }
}
