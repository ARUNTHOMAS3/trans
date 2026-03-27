import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from "@nestjs/common";
import { Observable, from } from "rxjs";
import { switchMap, tap } from "rxjs/operators";
import { SupabaseService } from "../../modules/supabase/supabase.service";

interface RouteEntry {
  pattern: RegExp;
  table: string;
  module: string;
}

/** URL segment → Supabase table + module mapping for all auditable routes. */
const ROUTE_TABLE_MAP: RouteEntry[] = [
  // Accountant — order matters: specific sub-routes before catch-all
  { pattern: /\/accountant\/manual-journals\/[0-9a-fA-F-]{36}/, table: "accounts_manual_journals", module: "accountant" },
  { pattern: /\/accountant\/recurring-journals\/[0-9a-fA-F-]{36}/, table: "accounts_recurring_journals", module: "accountant" },
  { pattern: /\/accountant\/journal-templates\/[0-9a-fA-F-]{36}/, table: "accounts_journal_templates", module: "accountant" },
  { pattern: /\/accountant\/[0-9a-fA-F-]{36}/, table: "accounts", module: "accountant" },
  // Products
  { pattern: /\/products\/[0-9a-fA-F-]{36}/, table: "products", module: "items" },
  // Price lists
  { pattern: /\/price-lists\/[0-9a-fA-F-]{36}/, table: "price_lists", module: "items" },
  // Sales
  { pattern: /\/sales\/customers\/[0-9a-fA-F-]{36}/, table: "customers", module: "sales" },
  { pattern: /^\/api\/v1\/sales$/, table: "sales_orders", module: "sales" },
  { pattern: /\/sales\/[0-9a-fA-F-]{36}/, table: "sales_orders", module: "sales" },
  // Purchases
  { pattern: /\/purchase-orders\/[0-9a-fA-F-]{36}/, table: "purchase_orders", module: "purchases" },
  { pattern: /^\/api\/v1\/purchase-orders$/, table: "purchase_orders", module: "purchases" },
  { pattern: /\/vendors\/[0-9a-fA-F-]{36}/, table: "vendors", module: "purchases" },
  { pattern: /^\/api\/v1\/vendors$/, table: "vendors", module: "purchases" },
  // Settings
  { pattern: /\/branches\/[0-9a-fA-F-]{36}/, table: "settings_branches", module: "settings" },
  { pattern: /^\/api\/v1\/branches$/, table: "settings_branches", module: "settings" },
  { pattern: /\/warehouses-settings\/[0-9a-fA-F-]{36}/, table: "settings_warehouses", module: "settings" },
  { pattern: /^\/api\/v1\/warehouses-settings$/, table: "settings_warehouses", module: "settings" },
  { pattern: /\/outlets\/[0-9a-fA-F-]{36}/, table: "outlets", module: "settings" },
  { pattern: /^\/api\/v1\/outlets$/, table: "outlets", module: "settings" },
  // Transaction series
  { pattern: /\/transaction-series\/[0-9a-fA-F-]{36}/, table: "transaction_series", module: "settings" },
  { pattern: /^\/api\/v1\/transaction-series$/, table: "transaction_series", module: "settings" },
];

const UUID_RE =
  /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/;

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(private readonly supabaseService: SupabaseService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const method: string = (request.method ?? "").toUpperCase();

    if (!["POST", "PUT", "PATCH", "DELETE"].includes(method)) {
      return next.handle();
    }

    const url: string = request.originalUrl ?? request.url ?? "";
    const entry = this.resolveEntry(url);

    if (!entry) return next.handle();

    const recordId = this.extractId(url);
    const orgId: string =
      (request.headers?.["x-org-id"] as string | undefined) ??
      "00000000-0000-0000-0000-000000000000";
    const userId: string =
      (request.headers?.["x-user-id"] as string | undefined) ??
      (request.user?.sub as string | undefined) ??
      "00000000-0000-0000-0000-000000000000";
    const actorName: string =
      (request.headers?.["x-actor-name"] as string | undefined) ?? "system";

    // DELETE & UPDATE: fetch existing record before handler
    if ((method === "DELETE" || method === "PUT" || method === "PATCH") && recordId) {
      return from(this.fetchOldValues(entry.table, recordId)).pipe(
        switchMap((oldValues) =>
          next.handle().pipe(
            tap(() => {
              this.writeAuditLog({
                table_name: entry.table,
                record_id: recordId,
                action: method === "DELETE" ? "DELETE" : "UPDATE",
                old_values: oldValues,
                new_values: method === "DELETE" ? null : (request.body ?? null),
                user_id: userId,
                org_id: orgId,
                actor_name: actorName,
                module_name: entry.module,
                source: "api",
              }).catch((err) =>
                console.error("[AuditInterceptor] Failed to write log:", err),
              );
            }),
          ),
        ),
      );
    }

    // POST (INSERT): capture created record ID from response
    if (method === "POST") {
      return next.handle().pipe(
        tap((responseBody) => {
          const createdId = this.extractCreatedId(responseBody) ?? recordId ?? "00000000-0000-0000-0000-000000000000";
          this.writeAuditLog({
            table_name: entry.table,
            record_id: createdId,
            action: "INSERT",
            old_values: null,
            new_values: request.body ?? null,
            user_id: userId,
            org_id: orgId,
            actor_name: actorName,
            module_name: entry.module,
            source: "api",
          }).catch((err) =>
            console.error("[AuditInterceptor] Failed to write log:", err),
          );
        }),
      );
    }

    return next.handle();
  }

  private resolveEntry(url: string): RouteEntry | null {
    for (const entry of ROUTE_TABLE_MAP) {
      if (entry.pattern.test(url)) return entry;
    }
    return null;
  }

  private extractId(url: string): string | null {
    return url.match(UUID_RE)?.[0] ?? null;
  }

  /** Extract the created record's ID from a POST response body. */
  private extractCreatedId(body: any): string | null {
    if (!body) return null;
    if (typeof body === "object") {
      // { data: { id: '...' } } or { id: '...' }
      const candidate = body?.data?.id ?? body?.id;
      if (typeof candidate === "string" && UUID_RE.test(candidate)) return candidate;
    }
    return null;
  }

  private async fetchOldValues(
    table: string,
    id: string,
  ): Promise<Record<string, unknown> | null> {
    try {
      const client = this.supabaseService.getClient();
      const { data } = await client
        .from(table)
        .select("*")
        .eq("id", id)
        .single();
      return (data as Record<string, unknown> | null) ?? null;
    } catch {
      return null;
    }
  }

  private async writeAuditLog(entry: {
    table_name: string;
    record_id: string;
    action: string;
    old_values: Record<string, unknown> | null;
    new_values: unknown;
    user_id: string;
    org_id: string;
    actor_name: string;
    module_name: string;
    source: string;
  }): Promise<void> {
    const client = this.supabaseService.getClient();
    await client.from("audit_logs").insert({
      table_name: entry.table_name,
      record_id: entry.record_id,
      action: entry.action,
      old_values: entry.old_values,
      new_values: entry.new_values,
      user_id: entry.user_id,
      org_id: entry.org_id,
      actor_name: entry.actor_name,
      module_name: entry.module_name,
      source: entry.source,
    });
  }
}
