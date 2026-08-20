import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { db } from "../../db/db";
import { settingsTransactionSeries } from "../../db/schema";
import { eq, and } from "drizzle-orm";

@Injectable()
export class TransactionSeriesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(tenant: TenantContext) {
    if (!tenant.entityId) return [];

    const rows = await db
      .select()
      .from(settingsTransactionSeries)
      .where(eq(settingsTransactionSeries.entityId, tenant.entityId));

    return (rows ?? []).map((row) => ({
      id: row.id,
      entity_id: row.entityId,
      name: row.name,
      code: row.code,
      branch_code: row.branchCode,
      warehouse_code: row.warehouseCode,
      modules: row.modules,
      created_at: row.createdAt,
      updated_at: row.updatedAt,
    }));
  }

  async findOne(id: string, tenant: TenantContext) {
    if (!tenant.entityId) return null;

    const rows = await db
      .select()
      .from(settingsTransactionSeries)
      .where(
        and(
          eq(settingsTransactionSeries.id, id),
          eq(settingsTransactionSeries.entityId, tenant.entityId),
        ),
      )
      .limit(1);

    const row = rows[0];
    if (!row) return null;
    return {
      id: row.id,
      entity_id: row.entityId,
      name: row.name,
      code: row.code,
      branch_code: row.branchCode,
      warehouse_code: row.warehouseCode,
      modules: row.modules,
      created_at: row.createdAt,
      updated_at: row.updatedAt,
    };
  }

  async create(tenant: TenantContext, dto: any) {
    if (!tenant.entityId) throw new Error("Entity context required");

    const [row] = await db
      .insert(settingsTransactionSeries)
      .values({
        entityId: tenant.entityId,
        name: dto.name,
        code: dto.code ?? null,
        branchCode: dto.branch_code ?? null,
        warehouseCode: dto.warehouse_code ?? null,
        modules: dto.modules ?? [],
      })
      .returning();

    return {
      id: row.id,
      entity_id: row.entityId,
      name: row.name,
      code: row.code,
      branch_code: row.branchCode,
      warehouse_code: row.warehouseCode,
      modules: row.modules,
      created_at: row.createdAt,
      updated_at: row.updatedAt,
    };
  }

  async update(id: string, tenant: TenantContext, dto: any) {
    if (!tenant.entityId) throw new Error("Entity context required");

    const [row] = await db
      .update(settingsTransactionSeries)
      .set({
        name: dto.name,
        code: dto.code ?? null,
        branchCode: dto.branch_code ?? null,
        warehouseCode: dto.warehouse_code ?? null,
        modules: dto.modules ?? [],
        updatedAt: new Date(),
      })
      .where(
        and(
          eq(settingsTransactionSeries.id, id),
          eq(settingsTransactionSeries.entityId, tenant.entityId),
        ),
      )
      .returning();

    if (!row) return null;
    return {
      id: row.id,
      entity_id: row.entityId,
      name: row.name,
      code: row.code,
      branch_code: row.branchCode,
      warehouse_code: row.warehouseCode,
      modules: row.modules,
      created_at: row.createdAt,
      updated_at: row.updatedAt,
    };
  }

  async remove(id: string, tenant: TenantContext) {
    if (!tenant.entityId) return { success: true };

    await db
      .delete(settingsTransactionSeries)
      .where(
        and(
          eq(settingsTransactionSeries.id, id),
          eq(settingsTransactionSeries.entityId, tenant.entityId),
        ),
      );

    return { success: true };
  }
}
