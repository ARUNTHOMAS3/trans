import { BadRequestException, Injectable } from "@nestjs/common";
import { db, client } from "../../db/db";
import { transactionLocks } from "../../db/schema";
import { eq, and } from "drizzle-orm";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { SupabaseService } from "../supabase/supabase.service";

@Injectable()
export class TransactionLockingService {
  private static readonly negativeStockConfigurationName =
    "Negative Stock Transaction Locking";

  constructor(private readonly supabaseService: SupabaseService) {}

  private getEntityFilter(tenant: TenantContext) {
    return eq(transactionLocks.entityId, tenant.entityId);
  }

  async findAll(tenant: TenantContext) {
    return await db.query.transactionLocks.findMany({
      where: this.getEntityFilter(tenant),
    });
  }

  async getNegativeStockPolicy(tenant: TenantContext) {
    try {
      const data = await client.unsafe(
        `SELECT id, allow_or_restrict_actions, status FROM record_locking
         WHERE entity_id = $1 AND lock_configuration_name = $2
         ORDER BY created_at ASC LIMIT 1`,
        [
          tenant.entityId,
          TransactionLockingService.negativeStockConfigurationName,
        ],
      );

      const configuration = data?.[0];
      const allowsNegativeStock =
        configuration?.status !== false &&
        configuration?.allow_or_restrict_actions === "Allow";
      return { mode: allowsNegativeStock ? "allow" : "restrict" };
    } catch (error) {
      throw new Error(
        `Failed to fetch negative stock policy: ${(error as Error).message}`,
      );
    }
  }

  async setNegativeStockPolicy(tenant: TenantContext, value: unknown) {
    const mode = value?.toString().trim().toLowerCase();
    if (mode !== "allow" && mode !== "restrict") {
      throw new BadRequestException(
        "Negative stock policy must be allow or restrict",
      );
    }

    try {
      const existingRows = await client.unsafe(
        `SELECT id FROM record_locking WHERE entity_id = $1 AND lock_configuration_name = $2 ORDER BY created_at ASC LIMIT 1`,
        [
          tenant.entityId,
          TransactionLockingService.negativeStockConfigurationName,
        ],
      );

      const actionText = mode === "allow" ? "Allow" : "Restrict";

      if (existingRows?.[0]?.id) {
        await client.unsafe(
          `UPDATE record_locking SET
             allow_or_restrict_actions = $1,
             status = true,
             updated_at = NOW()
           WHERE id = $2 AND entity_id = $3`,
          [actionText, existingRows[0].id, tenant.entityId],
        );
      } else {
        await client.unsafe(
          `INSERT INTO record_locking (entity_id, module, lock_configuration_name, description, allow_or_restrict_actions, lock_records_for, status)
           VALUES ($1, 'Inventory', $2, 'Controls whether transaction locking is allowed while accounting stock is negative.', $3, 'Negative accounting stock', true)`,
          [
            tenant.entityId,
            TransactionLockingService.negativeStockConfigurationName,
            actionText,
          ],
        );
      }

      return { mode };
    } catch (error) {
      throw new Error(`Failed to save negative stock policy: ${(error as Error).message}`);
    }
  }

  private async assertNegativeStockPolicyAllowsLock(tenant: TenantContext) {
    const { mode } = await this.getNegativeStockPolicy(tenant);
    if (mode === "allow") return;

    try {
      const data = await client.unsafe(
        `SELECT product_id, warehouse_id, stock_on_hand FROM v_accounting_stock WHERE entity_id = $1 AND stock_on_hand < 0 LIMIT 1`,
        [tenant.entityId],
      );

      if (data && data.length > 0) {
        throw new BadRequestException(
          "Transactions cannot be locked while accounting stock is negative. Correct the negative stock or change the policy to Allow.",
        );
      }
    } catch (error) {
      if (error instanceof BadRequestException) throw error;
      throw new Error(`Failed to verify accounting stock: ${(error as Error).message}`);
    }
  }

  async upsertLock(tenant: TenantContext, data: any) {
    const moduleName = this.normalizeModuleName(data?.moduleName);
    const lockDate = new Date(data?.lockDate);
    const reason = data?.reason?.toString().trim();
    if (Number.isNaN(lockDate.getTime())) {
      throw new BadRequestException("A valid lock date is required");
    }
    if (!reason) {
      throw new BadRequestException("A lock reason is required");
    }
    await this.assertNegativeStockPolicyAllowsLock(tenant);

    const existing = await db.query.transactionLocks.findFirst({
      where: and(
        this.getEntityFilter(tenant),
        eq(transactionLocks.moduleName, moduleName),
      ),
    });

    if (existing) {
      return await db
        .update(transactionLocks)
        .set({ lockDate, reason, updatedAt: new Date() })
        .where(eq(transactionLocks.id, existing.id))
        .returning();
    } else {
      return await db
        .insert(transactionLocks)
        .values({
          orgId: tenant.orgId,
          entityId: tenant.entityId,
          moduleName,
          lockDate,
          reason,
        })
        .returning();
    }
  }

  async deleteLock(tenant: TenantContext, moduleName: string) {
    moduleName = this.normalizeModuleName(moduleName);
    return await db
      .delete(transactionLocks)
      .where(
        and(
          this.getEntityFilter(tenant),
          eq(transactionLocks.moduleName, moduleName),
        ),
      )
      .returning();
  }

  private normalizeModuleName(value: unknown) {
    const normalized = value?.toString().trim().toLowerCase();
    const modules: Record<string, string> = {
      sales: "Sales",
      purchases: "Purchases",
      banking: "Banking",
      accountant: "Accountant",
    };
    const moduleName = normalized ? modules[normalized] : null;
    if (!moduleName) {
      throw new BadRequestException(
        "Lock module must be Sales, Purchases, Banking, or Accountant",
      );
    }
    return moduleName;
  }

  async findConfigurations(tenant: TenantContext) {
    try {
      const data = await client.unsafe(
        `SELECT * FROM record_locking WHERE entity_id = $1 ORDER BY created_at ASC`,
        [tenant.entityId],
      );
      return data ?? [];
    } catch (error) {
      throw new Error(`Failed to fetch lock configurations: ${(error as Error).message}`);
    }
  }

  async createConfiguration(tenant: TenantContext, body: any) {
    const payload = this.toConfigurationPayload(tenant, body, true);
    try {
      const rows = await client.unsafe(
        `INSERT INTO record_locking (entity_id, module, lock_configuration_name, description, allow_or_restrict_actions, lock_records_for, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
        [
          payload.entity_id,
          payload.module,
          payload.lock_configuration_name,
          payload.description ?? null,
          payload.allow_or_restrict_actions,
          payload.lock_records_for,
          payload.status ?? true,
        ],
      );
      return rows[0];
    } catch (error) {
      throw new Error(`Failed to create lock configuration: ${(error as Error).message}`);
    }
  }

  async updateConfiguration(tenant: TenantContext, id: string, body: any) {
    const payload = this.toConfigurationPayload(tenant, body, false);
    try {
      const rows = await client.unsafe(
        `UPDATE record_locking SET
           module = COALESCE($1, module),
           lock_configuration_name = COALESCE($2, lock_configuration_name),
           description = COALESCE($3, description),
           allow_or_restrict_actions = COALESCE($4, allow_or_restrict_actions),
           lock_records_for = COALESCE($5, lock_records_for),
           status = COALESCE($6, status),
           updated_at = NOW()
         WHERE id = $7 AND entity_id = $8 RETURNING *`,
        [
          payload.module ?? null,
          payload.lock_configuration_name ?? null,
          payload.description ?? null,
          payload.allow_or_restrict_actions ?? null,
          payload.lock_records_for ?? null,
          payload.status ?? null,
          id,
          tenant.entityId,
        ],
      );
      return rows[0];
    } catch (error) {
      throw new Error(`Failed to update lock configuration: ${(error as Error).message}`);
    }
  }

  async deleteConfiguration(tenant: TenantContext, id: string) {
    try {
      await client.unsafe(
        `DELETE FROM record_locking WHERE id = $1 AND entity_id = $2`,
        [id, tenant.entityId],
      );
      return { success: true };
    } catch (error) {
      throw new Error(`Failed to delete lock configuration: ${(error as Error).message}`);
    }
  }

  private toConfigurationPayload(
    tenant: TenantContext,
    body: any,
    creating: boolean,
  ): Record<string, any> {
    const payload: Record<string, any> = {
      entity_id: tenant.entityId,
      updated_at: new Date().toISOString(),
    };

    const copy = (from: string, to = from) => {
      if (body?.[from] !== undefined) payload[to] = body[from];
    };
    const requireText = (from: string, to = from) => {
      const value = body?.[from]?.toString().trim();
      if (creating && !value) throw new Error(`${from} is required`);
      if (value !== undefined) payload[to] = value;
    };

    requireText("module");
    requireText("lock_configuration_name");
    copy("description");
    if (creating || body?.allow_or_restrict_actions !== undefined) {
      const action = body?.allow_or_restrict_actions?.toString() ?? "";
      payload.allow_or_restrict_actions = action.startsWith("Allow")
        ? "Allow"
        : "Restrict";
    }
    requireText("lock_records_for");
    if (body?.status !== undefined) payload.status = body.status === true;

    return payload;
  }
}
