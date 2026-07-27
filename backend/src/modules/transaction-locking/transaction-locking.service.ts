import { BadRequestException, Injectable } from "@nestjs/common";
import { db } from "../../db/db";
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
    const { data, error } = await this.supabaseService
      .getClient()
      .from("record_locking")
      .select("id, allow_or_restrict_actions, status")
      .eq("entity_id", tenant.entityId)
      .eq(
        "lock_configuration_name",
        TransactionLockingService.negativeStockConfigurationName,
      )
      .order("created_at", { ascending: true })
      .limit(1);

    if (error) {
      throw new Error(
        `Failed to fetch negative stock policy: ${error.message}`,
      );
    }

    const configuration = data?.[0];
    const allowsNegativeStock =
      configuration?.status !== false &&
      configuration?.allow_or_restrict_actions === "Allow";
    return { mode: allowsNegativeStock ? "allow" : "restrict" };
  }

  async setNegativeStockPolicy(tenant: TenantContext, value: unknown) {
    const mode = value?.toString().trim().toLowerCase();
    if (mode !== "allow" && mode !== "restrict") {
      throw new BadRequestException(
        "Negative stock policy must be allow or restrict",
      );
    }

    const client = this.supabaseService.getClient();
    const { data: existingRows, error: findError } = await client
      .from("record_locking")
      .select("id")
      .eq("entity_id", tenant.entityId)
      .eq(
        "lock_configuration_name",
        TransactionLockingService.negativeStockConfigurationName,
      )
      .order("created_at", { ascending: true })
      .limit(1);

    if (findError) {
      throw new Error(
        `Failed to fetch negative stock policy: ${findError.message}`,
      );
    }

    const payload = {
      entity_id: tenant.entityId,
      module: "Inventory",
      lock_configuration_name:
        TransactionLockingService.negativeStockConfigurationName,
      description:
        "Controls whether transaction locking is allowed while accounting stock is negative.",
      allow_or_restrict_actions: mode === "allow" ? "Allow" : "Restrict",
      lock_records_for: "Negative accounting stock",
      status: true,
      updated_at: new Date().toISOString(),
    };

    const existingId = existingRows?.[0]?.id;
    const query = existingId
      ? client
          .from("record_locking")
          .update(payload)
          .eq("id", existingId)
          .eq("entity_id", tenant.entityId)
      : client
          .from("record_locking")
          .insert({ ...payload, created_at: new Date().toISOString() });
    const { error } = await query;

    if (error) {
      throw new Error(`Failed to save negative stock policy: ${error.message}`);
    }

    return { mode };
  }

  private async assertNegativeStockPolicyAllowsLock(tenant: TenantContext) {
    const { mode } = await this.getNegativeStockPolicy(tenant);
    if (mode === "allow") return;

    const { data, error } = await this.supabaseService
      .getClient()
      .from("v_accounting_stock")
      .select("product_id, warehouse_id, stock_on_hand")
      .eq("entity_id", tenant.entityId)
      .lt("stock_on_hand", 0)
      .limit(1);

    if (error) {
      throw new Error(`Failed to verify accounting stock: ${error.message}`);
    }
    if (data && data.length > 0) {
      throw new BadRequestException(
        "Transactions cannot be locked while accounting stock is negative. Correct the negative stock or change the policy to Allow.",
      );
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

    // Check if exists
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
    const { data, error } = await this.supabaseService
      .getClient()
      .from("record_locking")
      .select("*")
      .eq("entity_id", tenant.entityId)
      .order("created_at", { ascending: true });

    if (error) {
      throw new Error(`Failed to fetch lock configurations: ${error.message}`);
    }

    return data ?? [];
  }

  async createConfiguration(tenant: TenantContext, body: any) {
    const payload = this.toConfigurationPayload(tenant, body, true);
    const { data, error } = await this.supabaseService
      .getClient()
      .from("record_locking")
      .insert(payload)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create lock configuration: ${error.message}`);
    }

    return data;
  }

  async updateConfiguration(tenant: TenantContext, id: string, body: any) {
    const payload = this.toConfigurationPayload(tenant, body, false);
    const { data, error } = await this.supabaseService
      .getClient()
      .from("record_locking")
      .update(payload)
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update lock configuration: ${error.message}`);
    }

    return data;
  }

  async deleteConfiguration(tenant: TenantContext, id: string) {
    const { error } = await this.supabaseService
      .getClient()
      .from("record_locking")
      .delete()
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (error) {
      throw new Error(`Failed to delete lock configuration: ${error.message}`);
    }

    return { success: true };
  }

  private toConfigurationPayload(
    tenant: TenantContext,
    body: any,
    creating: boolean,
  ) {
    const payload: Record<string, unknown> = {
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
