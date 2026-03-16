import { Injectable } from "@nestjs/common";
import { db } from "../../db/db";
import { transactionLocks } from "../../db/schema";
import { eq, and } from "drizzle-orm";

@Injectable()
export class TransactionLockingService {
  private readonly defaultOrgId = "00000000-0000-0000-0000-000000000000";

  async findAll(orgId: string = this.defaultOrgId) {
    return await db.query.transactionLocks.findMany({
      where: eq(transactionLocks.orgId, orgId),
    });
  }

  async upsertLock(orgId: string = this.defaultOrgId, data: any) {
    const { moduleName, lockDate, reason } = data;

    // Check if exists
    const existing = await db.query.transactionLocks.findFirst({
      where: and(
        eq(transactionLocks.orgId, orgId),
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
          orgId,
          moduleName,
          lockDate: new Date(lockDate),
          reason,
        })
        .returning();
    }
  }

  async deleteLock(moduleName: string, orgId: string = this.defaultOrgId) {
    return await db
      .delete(transactionLocks)
      .where(
        and(
          eq(transactionLocks.orgId, orgId),
          eq(transactionLocks.moduleName, moduleName),
        ),
      )
      .returning();
  }
}
