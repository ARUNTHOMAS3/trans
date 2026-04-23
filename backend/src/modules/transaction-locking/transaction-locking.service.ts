import { Injectable } from "@nestjs/common";
import { db } from "../../db/db";
import { transactionLocks } from "../../db/schema";
import { eq, and } from "drizzle-orm";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Injectable()
export class TransactionLockingService {
  private readonly defaultOrgId = "00000000-0000-0000-0000-000000000000";

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
}
