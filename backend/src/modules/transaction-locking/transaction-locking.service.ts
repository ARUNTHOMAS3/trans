import { Injectable } from "@nestjs/common";
import { db } from "../../db/db";
import { transactionLocks } from "../../db/schema";
import { eq, and } from "drizzle-orm";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { SupabaseService } from "../supabase/supabase.service";

@Injectable()
export class TransactionLockingService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private getEntityFilter(tenant: TenantContext) {
    return eq(transactionLocks.entityId, tenant.entityId);
  }

  async findAll(tenant: TenantContext) {
    return await db.query.transactionLocks.findMany({
      where: this.getEntityFilter(tenant),
    });
  }

  async upsertLock(tenant: TenantContext, data: any) {
    const { moduleName, lockDate, reason } = data;

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
        .set({ lockDate: new Date(lockDate), reason, updatedAt: new Date() })
        .where(eq(transactionLocks.id, existing.id))
        .returning();
    } else {
      return await db
        .insert(transactionLocks)
        .values({
          orgId: tenant.orgId,
          entityId: tenant.entityId,
          moduleName,
          lockDate: new Date(lockDate),
          reason,
        })
        .returning();
    }
  }

  async deleteLock(tenant: TenantContext, moduleName: string) {
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

  async updateConfiguration(
    tenant: TenantContext,
    id: string,
    body: any,
  ) {
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
