import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../modules/supabase/supabase.service";
import { TenantContext } from "../common/middleware/tenant.middleware";
import { db, client } from "../db/db";
import { transactionalSequence } from "../db/schema";
import { eq, and, sql } from "drizzle-orm";

@Injectable()
export class SequencesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getSequence(module: string, tenant: TenantContext, _branchId?: string) {
    if (!tenant.entityId) {
      throw new Error("Tenant entityId is missing");
    }

    const rows = await db
      .select()
      .from(transactionalSequence)
      .where(
        and(
          eq(transactionalSequence.module, module),
          eq(transactionalSequence.entityId, tenant.entityId),
          eq(transactionalSequence.isActive, true),
        ),
      )
      .limit(1);

    let data = rows[0]
      ? {
          id: rows[0].id,
          module: rows[0].module,
          prefix: rows[0].prefix,
          next_number: rows[0].nextNumber,
          suffix: rows[0].suffix,
          padding: rows[0].padding,
          entity_id: rows[0].entityId,
          is_active: rows[0].isActive,
        }
      : null;

    if (data) {
      const tableMapping: Record<
        string,
        { table: string; column: string; prefix: string }
      > = {
        vendor: { table: "vendors", column: "vendor_number", prefix: "VEN-" },
        customer: {
          table: "customers",
          column: "customer_number",
          prefix: "CUS-",
        },
        sale: { table: "sales_orders", column: "sale_number", prefix: "SO-" },
        purchase: {
          table: "purchase_orders",
          column: "order_number",
          prefix: "PO-",
        },
        inventory_packages: {
          table: "inventory_packages",
          column: "package_number",
          prefix: "PKG-",
        },
      };

      if (tableMapping[module]) {
        const { table, column } = tableMapping[module];
        const prefix = data.prefix;
        const sanitizedTable = table.replace(/[^a-zA-Z0-9_]/g, "");
        const sanitizedColumn = column.replace(/[^a-zA-Z0-9_]/g, "");

        try {
          const latestItems = await client.unsafe(
            `SELECT "${sanitizedColumn}" FROM "${sanitizedTable}" WHERE "${sanitizedColumn}" ILIKE $1 AND entity_id = $2 ORDER BY "${sanitizedColumn}" DESC LIMIT 10`,
            [`${prefix}%`, tenant.entityId],
          );

          if (latestItems && latestItems.length > 0) {
            let maxNum = 0;
            for (const item of latestItems) {
              const val = item[sanitizedColumn] as string;
              if (val && val.toLowerCase().startsWith(prefix.toLowerCase())) {
                let numPart = val.substring(prefix.length);
                if (data.suffix) {
                  numPart = numPart.replace(new RegExp(data.suffix, "i"), "");
                }
                const parsed = parseInt(numPart, 10);
                if (!isNaN(parsed) && parsed > maxNum) {
                  maxNum = parsed;
                }
              }
            }
            if (maxNum >= data.next_number) {
              data.next_number = maxNum + 1;
              await db
                .update(transactionalSequence)
                .set({
                  nextNumber: data.next_number,
                  updatedAt: new Date(),
                })
                .where(eq(transactionalSequence.id, data.id));
            }
          } else {
            const countRes = await client.unsafe(
              `SELECT count(*)::int as count FROM "${sanitizedTable}" WHERE entity_id = $1`,
              [tenant.entityId],
            );
            const count = countRes[0]?.count ?? 0;
            if (count === 0 && data.next_number !== 1) {
              data.next_number = 1;
              await db
                .update(transactionalSequence)
                .set({ nextNumber: 1, updatedAt: new Date() })
                .where(eq(transactionalSequence.id, data.id));
            }
          }
        } catch (err) {
          console.error(`[SequencesService] Error checking max sequence for ${module}:`, err);
        }
      }
      return data;
    }

    // Auto-initialize if sequence is missing for this entity
    const defaults: Record<
      string,
      { prefix: string; next_number: number; padding: number }
    > = {
      vendor: { prefix: "VEN-", next_number: 1, padding: 5 },
      customer: { prefix: "CUS-", next_number: 1, padding: 5 },
      sale: { prefix: "SO-", next_number: 1, padding: 5 },
      purchase: { prefix: "PO-", next_number: 1, padding: 5 },
      inventory_packages: { prefix: "PKG-", next_number: 1, padding: 5 },
    };

    const config = defaults[module] ?? {
      prefix: `${module.toUpperCase()}-`,
      next_number: 1,
      padding: 5,
    };

    let nextNum = config.next_number;
    const tableMapping: Record<
      string,
      { table: string; column: string; prefix: string }
    > = {
      vendor: { table: "vendors", column: "vendor_number", prefix: "VEN-" },
      customer: {
        table: "customers",
        column: "customer_number",
        prefix: "CUS-",
      },
      sale: { table: "sales_orders", column: "sale_number", prefix: "SO-" },
      purchase: {
        table: "purchase_orders",
        column: "order_number",
        prefix: "PO-",
      },
      inventory_packages: {
        table: "inventory_packages",
        column: "package_number",
        prefix: "PKG-",
      },
    };

    if (tableMapping[module]) {
      const { table, column, prefix } = tableMapping[module];
      const sanitizedTable = table.replace(/[^a-zA-Z0-9_]/g, "");
      const sanitizedColumn = column.replace(/[^a-zA-Z0-9_]/g, "");

      try {
        const latestItems = await client.unsafe(
          `SELECT "${sanitizedColumn}" FROM "${sanitizedTable}" WHERE "${sanitizedColumn}" ILIKE $1 AND entity_id = $2 ORDER BY "${sanitizedColumn}" DESC LIMIT 10`,
          [`${prefix}%`, tenant.entityId],
        );

        if (latestItems && latestItems.length > 0) {
          let maxNum = 0;
          for (const item of latestItems) {
            const val = item[sanitizedColumn] as string;
            const numPart = val.substring(prefix.length);
            const parsed = parseInt(numPart, 10);
            if (!isNaN(parsed) && parsed > maxNum) {
              maxNum = parsed;
            }
          }
          if (maxNum > 0) nextNum = maxNum + 1;
        } else {
          const countRes = await client.unsafe(
            `SELECT count(*)::int as count FROM "${sanitizedTable}" WHERE entity_id = $1`,
            [tenant.entityId],
          );
          const count = countRes[0]?.count ?? 0;
          if (count > 0) nextNum = count + 1;
        }
      } catch (err) {
        console.error(`[SequencesService] Error initializing sequence for ${module}:`, err);
      }
    }

    const [created] = await db
      .insert(transactionalSequence)
      .values({
        module,
        prefix: config.prefix,
        nextNumber: nextNum,
        padding: config.padding,
        entityId: tenant.entityId,
        isActive: true,
      })
      .returning();

    return {
      id: created.id,
      module: created.module,
      prefix: created.prefix,
      next_number: created.nextNumber,
      suffix: created.suffix,
      padding: created.padding,
      entity_id: created.entityId,
      is_active: created.isActive,
    };
  }

  async getNextNumberFormatted(
    module: string,
    tenant: TenantContext,
    branchId?: string,
  ) {
    const settings = await this.getSequence(module, tenant, branchId);
    return this.formatSequence(
      settings.prefix,
      settings.next_number,
      settings.padding,
      settings.suffix,
    );
  }

  private formatSequence(
    prefix: string,
    num: number,
    padding: number,
    suffix: string = "",
  ) {
    const paddedNum = num.toString().padStart(padding, "0");
    return `${prefix}${paddedNum}${suffix}`;
  }

  async incrementSequence(
    module: string,
    tenant: TenantContext,
    usedNumber?: string,
    branchId?: string,
  ) {
    const settings = await this.getSequence(module, tenant, branchId);

    const currentFormatted = this.formatSequence(
      settings.prefix,
      settings.next_number,
      settings.padding,
      settings.suffix,
    );

    let nextNumber = settings.next_number;

    if (!usedNumber || usedNumber === currentFormatted) {
      nextNumber = settings.next_number + 1;
    } else if (usedNumber.startsWith(settings.prefix)) {
      try {
        const numPart = usedNumber
          .substring(settings.prefix.length)
          .replace(settings.suffix || "", "");
        const parsed = parseInt(numPart, 10);
        if (!isNaN(parsed) && parsed >= settings.next_number) {
          nextNumber = parsed + 1;
        } else {
          return settings;
        }
      } catch (e) {
        nextNumber = settings.next_number + 1;
      }
    } else {
      return settings;
    }

    const [updated] = await db
      .update(transactionalSequence)
      .set({ nextNumber, updatedAt: new Date() })
      .where(eq(transactionalSequence.id, settings.id))
      .returning();

    return {
      id: updated.id,
      module: updated.module,
      prefix: updated.prefix,
      next_number: updated.nextNumber,
      suffix: updated.suffix,
      padding: updated.padding,
      entity_id: updated.entityId,
      is_active: updated.isActive,
    };
  }

  async checkDuplicate(module: string, number: string, tenant: TenantContext) {
    const tableConfigs: Record<string, { table: string; column: string }> = {
      vendor: { table: "vendors", column: "vendor_number" },
      customer: { table: "customers", column: "customer_number" },
    };

    const config = tableConfigs[module];
    if (!config) return { exists: false };

    const sanitizedTable = config.table.replace(/[^a-zA-Z0-9_]/g, "");
    const sanitizedColumn = config.column.replace(/[^a-zA-Z0-9_]/g, "");

    const rows = await client.unsafe(
      `SELECT "${sanitizedColumn}" FROM "${sanitizedTable}" WHERE "${sanitizedColumn}" = $1 AND entity_id = $2 LIMIT 1`,
      [number, tenant.entityId],
    );

    return { exists: rows.length > 0 };
  }

  async updateSettings(
    module: string,
    tenant: TenantContext,
    updateDto: {
      prefix?: string;
      nextNumber?: number;
      padding?: number;
      suffix?: string;
      branchId?: string;
    },
  ) {
    if (!tenant.entityId) {
      throw new Error("Tenant entityId is missing");
    }

    const updateData: Record<string, any> = { updatedAt: new Date() };
    if (updateDto.prefix !== undefined) updateData.prefix = updateDto.prefix;
    if (updateDto.nextNumber !== undefined)
      updateData.nextNumber = updateDto.nextNumber;
    if (updateDto.padding !== undefined) updateData.padding = updateDto.padding;
    if (updateDto.suffix !== undefined) updateData.suffix = updateDto.suffix;

    const existingRows = await db
      .select({ id: transactionalSequence.id })
      .from(transactionalSequence)
      .where(
        and(
          eq(transactionalSequence.module, module),
          eq(transactionalSequence.entityId, tenant.entityId),
        ),
      )
      .limit(1);

    const existing = existingRows[0];

    if (existing) {
      const [updated] = await db
        .update(transactionalSequence)
        .set(updateData)
        .where(eq(transactionalSequence.id, existing.id))
        .returning();

      return {
        id: updated.id,
        module: updated.module,
        prefix: updated.prefix,
        next_number: updated.nextNumber,
        suffix: updated.suffix,
        padding: updated.padding,
        entity_id: updated.entityId,
        is_active: updated.isActive,
      };
    } else {
      const [created] = await db
        .insert(transactionalSequence)
        .values({
          module,
          entityId: tenant.entityId,
          isActive: true,
          prefix: updateDto.prefix ?? "",
          nextNumber: updateDto.nextNumber ?? 1,
          padding: updateDto.padding ?? 5,
          suffix: updateDto.suffix ?? "",
          ...updateData,
        })
        .returning();

      return {
        id: created.id,
        module: created.module,
        prefix: created.prefix,
        next_number: created.nextNumber,
        suffix: created.suffix,
        padding: created.padding,
        entity_id: created.entityId,
        is_active: created.isActive,
      };
    }
  }
}
