import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from "@nestjs/common";
import { Observable, from } from "rxjs";
import { switchMap, tap } from "rxjs/operators";
import { SupabaseService } from "../../modules/supabase/supabase.service";

/** URL segment → Supabase table mapping for PUT/PATCH audit coverage. */
const ROUTE_TABLE_MAP: Array<{ pattern: RegExp; table: string }> = [
  {
    pattern: /\/accountant\/manual-journals\/[0-9a-fA-F-]{36}/,
    table: "accounts_manual_journals",
  },
  {
    pattern: /\/accountant\/recurring-journals\/[0-9a-fA-F-]{36}/,
    table: "accounts_recurring_journals",
  },
  {
    pattern: /\/accountant\/journal-templates\/[0-9a-fA-F-]{36}/,
    table: "accounts_journal_templates",
  },
  {
    pattern: /\/accountant\/[0-9a-fA-F-]{36}/,
    table: "accounts",
  },
  {
    pattern: /\/products\/[0-9a-fA-F-]{36}/,
    table: "products",
  },
];

const UUID_RE =
  /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/;

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(private readonly supabaseService: SupabaseService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const method: string = request.method ?? "";

    if (!["PUT", "PATCH"].includes(method.toUpperCase())) {
      return next.handle();
    }

    const url: string = request.originalUrl ?? request.url ?? "";
    const table = this.resolveTable(url);
    const recordId = this.extractId(url);

    if (!table || !recordId) {
      return next.handle();
    }

    const userId: string | null =
      (request.headers?.["x-user-id"] as string | undefined) ??
      (request.user?.sub as string | undefined) ??
      null;

    return from(this.fetchOldValues(table, recordId)).pipe(
      switchMap((oldValues) =>
        next.handle().pipe(
          tap(() => {
            // Fire-and-forget — never block the response.
            this.writeAuditLog({
              table_name: table,
              record_id: recordId,
              action: "UPDATE",
              old_values: oldValues,
              new_values: request.body ?? null,
              user_id: userId,
            }).catch((err) => {
              console.error("[AuditInterceptor] Failed to write log:", err);
            });
          }),
        ),
      ),
    );
  }

  private resolveTable(url: string): string | null {
    for (const entry of ROUTE_TABLE_MAP) {
      if (entry.pattern.test(url)) return entry.table;
    }
    return null;
  }

  private extractId(url: string): string | null {
    return url.match(UUID_RE)?.[0] ?? null;
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
    user_id: string | null;
  }): Promise<void> {
    const client = this.supabaseService.getClient();
    await client.from("audit_logs").insert({
      table_name: entry.table_name,
      record_id: entry.record_id,
      action: entry.action,
      old_values: entry.old_values,
      new_values: entry.new_values,
      user_id: entry.user_id,
    });
  }
}
