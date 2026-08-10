import { Injectable } from "@nestjs/common";
import { sql } from "drizzle-orm";
import { db } from "../../../db/db";
import { TenantContext } from "../../../common/middleware/tenant.middleware";

export interface ReportFavoriteRecord {
  id: string;
  report: string;
  createdAt: Date | string | null;
}

export interface ReportFavoriteSaveResult {
  record: ReportFavoriteRecord;
  created: boolean;
}

@Injectable()
export class ReportsFavoritesRepository {
  private static readonly moduleName = "Reports";

  private rowsFrom(result: unknown): Record<string, unknown>[] {
    if (Array.isArray(result)) return result as Record<string, unknown>[];
    const maybeRows = (result as { rows?: unknown })?.rows;
    return Array.isArray(maybeRows) ? (maybeRows as Record<string, unknown>[]) : [];
  }

  private mapRow(row: Record<string, unknown>): ReportFavoriteRecord {
    return {
      id: String(row.id ?? ""),
      report: String(row.report ?? row.column_name ?? ""),
      createdAt: (row.createdAt ?? row.created_at ?? null) as Date | string | null,
    };
  }

  private entityId(tenant: TenantContext): string {
    return tenant.entityId?.toString().trim() || "";
  }

  private userId(tenant: TenantContext): string {
    return tenant.userId?.toString().trim() || "";
  }

  async findAll(tenant: TenantContext): Promise<ReportFavoriteRecord[]> {
    const result = await db.execute(sql`
      SELECT
        id,
        column_name AS report,
        created_at AS "createdAt"
      FROM favorites
      WHERE entity_id = ${this.entityId(tenant)}
        AND users_id = ${this.userId(tenant)}
        AND module_name = ${ReportsFavoritesRepository.moduleName}
      ORDER BY created_at DESC
    `);

    return this.rowsFrom(result).map((row) => this.mapRow(row));
  }

  async findOne(
    tenant: TenantContext,
    report: string,
  ): Promise<ReportFavoriteRecord | null> {
    const result = await db.execute(sql`
      SELECT
        id,
        column_name AS report,
        created_at AS "createdAt"
      FROM favorites
      WHERE entity_id = ${this.entityId(tenant)}
        AND users_id = ${this.userId(tenant)}
        AND module_name = ${ReportsFavoritesRepository.moduleName}
        AND column_name = ${report}
      LIMIT 1
    `);

    const [row] = this.rowsFrom(result);
    return row ? this.mapRow(row) : null;
  }

  async save(
    tenant: TenantContext,
    report: string,
  ): Promise<ReportFavoriteSaveResult> {
    const existing = await this.findOne(tenant, report);
    if (existing) {
      return { record: existing, created: false };
    }

    const result = await db.execute(sql`
      INSERT INTO favorites (entity_id, users_id, module_name, column_name)
      VALUES (
        ${this.entityId(tenant)},
        ${this.userId(tenant)},
        ${ReportsFavoritesRepository.moduleName},
        ${report}
      )
      RETURNING id, column_name AS report, created_at AS "createdAt"
    `);

    const [row] = this.rowsFrom(result);
    return { record: this.mapRow(row ?? {}), created: true };
  }

  async remove(tenant: TenantContext, report: string): Promise<boolean> {
    const result = await db.execute(sql`
      DELETE FROM favorites
      WHERE entity_id = ${this.entityId(tenant)}
        AND users_id = ${this.userId(tenant)}
        AND module_name = ${ReportsFavoritesRepository.moduleName}
        AND column_name = ${report}
      RETURNING id
    `);

    return this.rowsFrom(result).length > 0;
  }
}
