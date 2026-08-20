import { Injectable, NotFoundException } from "@nestjs/common";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../../supabase/supabase.service";
import { client } from "../../../../db/db";

@Injectable()
export class PurchaseReturnsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getNextNumber(tenant: TenantContext, prefix: string = "PRT-") {
    const safePrefix = prefix || "PRT-";
    const data = await client.unsafe(
      `SELECT purchase_return_number FROM purchase_returns WHERE entity_id = $1 ORDER BY created_at DESC LIMIT 10`,
      [tenant.entityId],
    );

    let maxNumber = 0;
    if (data && data.length > 0) {
      for (const row of data) {
        const numStr = row.purchase_return_number;
        if (numStr) {
          const match = numStr.match(/(\d+)$/);
          if (match) {
            const val = parseInt(match[1], 10);
            if (val > maxNumber) maxNumber = val;
          }
        }
      }
    }

    const nextNum = maxNumber + 1;
    const formatted = `${safePrefix}${nextNum.toString().padStart(5, "0")}`;
    return {
      prefix: safePrefix,
      nextNumber: nextNum,
      formatted,
    };
  }

  async findAll(
    tenant: TenantContext,
    page: number = 1,
    limit: number = 100,
    search?: string,
    status?: string
  ) {
    let sqlQuery = `SELECT * FROM purchase_returns WHERE entity_id = $1`;
    const params: any[] = [tenant.entityId];

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      sqlQuery += ` AND purchase_return_number ILIKE $${params.length}`;
    }

    if (status && status.toLowerCase() !== "all") {
      params.push(status.toLowerCase());
      sqlQuery += ` AND status = $${params.length}`;
    }

    const offset = (page - 1) * limit;
    sqlQuery += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    const data = await client.unsafe(sqlQuery, [...params, limit, offset]);

    for (const pr of data ?? []) {
      const items = await client.unsafe(
        `SELECT * FROM purchase_return_items WHERE purchase_return_id = $1`,
        [pr.id],
      );
      for (const item of items ?? []) {
        const batches = await client.unsafe(
          `SELECT * FROM purchase_return_item_batches WHERE purchase_return_item_id = $1`,
          [item.id],
        );
        item.purchase_return_item_batches = batches ?? [];
      }
      pr.purchase_return_items = items ?? [];
    }

    return data || [];
  }

  async findOne(tenant: TenantContext, id: string) {
    const rows = await client.unsafe(
      `SELECT * FROM purchase_returns WHERE id = $1 AND entity_id = $2 LIMIT 1`,
      [id, tenant.entityId],
    );

    const data = rows[0];
    if (!data) {
      throw new NotFoundException(`Purchase Return with ID ${id} not found`);
    }

    const items = await client.unsafe(
      `SELECT * FROM purchase_return_items WHERE purchase_return_id = $1`,
      [id],
    );

    for (const item of items ?? []) {
      const batches = await client.unsafe(
        `SELECT * FROM purchase_return_item_batches WHERE purchase_return_item_id = $1`,
        [item.id],
      );
      item.purchase_return_item_batches = batches ?? [];
    }
    data.purchase_return_items = items ?? [];

    return data;
  }

  async create(tenant: TenantContext, dto: any) {
    const { items, ...headerData } = dto;
    headerData.entity_id = tenant.entityId;

    const keys = Object.keys(headerData);
    const cols = keys.map((k) => `"${k}"`).join(", ");
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");
    const values: any[] = Object.values(headerData);

    let header: any;
    try {
      const rows = await client.unsafe(
        `INSERT INTO purchase_returns (${cols}) VALUES (${placeholders}) RETURNING *`,
        values,
      );
      header = rows[0];
    } catch (headerErr: any) {
      throw new Error(`Failed to create purchase return: ${headerErr.message}`);
    }

    if (items && Array.isArray(items)) {
      for (const item of items) {
        const { batches, ...itemData } = item;
        itemData.purchase_return_id = header.id;

        const iKeys = Object.keys(itemData);
        const iCols = iKeys.map((k) => `"${k}"`).join(", ");
        const iPlaceholders = iKeys.map((_, i) => `$${i + 1}`).join(", ");
        const iValues: any[] = Object.values(itemData);

        try {
          const itemRows = await client.unsafe(
            `INSERT INTO purchase_return_items (${iCols}) VALUES (${iPlaceholders}) RETURNING *`,
            iValues,
          );
          const createdItem = itemRows[0];

          if (batches && Array.isArray(batches) && createdItem) {
            for (const batch of batches) {
              batch.purchase_return_item_id = createdItem.id;
              const bKeys = Object.keys(batch);
              const bCols = bKeys.map((k) => `"${k}"`).join(", ");
              const bPlaceholders = bKeys.map((_, i) => `$${i + 1}`).join(", ");
              const bValues: any[] = Object.values(batch);

              await client.unsafe(
                `INSERT INTO purchase_return_item_batches (${bCols}) VALUES (${bPlaceholders})`,
                bValues,
              );
            }
          }
        } catch {
          // ignore single item insert error
        }
      }
    }

    return this.findOne(tenant, header.id);
  }

  async update(tenant: TenantContext, id: string, dto: any) {
    const { items, ...headerData } = dto;

    const keys = Object.keys(headerData);
    if (keys.length > 0) {
      const setClauses = keys.map((k, i) => `"${k}" = $${i + 1}`).join(", ");
      const values: any[] = Object.values(headerData);

      await client.unsafe(
        `UPDATE purchase_returns SET ${setClauses} WHERE id = $${keys.length + 1} AND entity_id = $${keys.length + 2}`,
        [...values, id, tenant.entityId],
      );
    }

    if (items && Array.isArray(items)) {
      await client.unsafe(
        `DELETE FROM purchase_return_items WHERE purchase_return_id = $1`,
        [id],
      );

      for (const item of items) {
        const { batches, ...itemData } = item;
        itemData.purchase_return_id = id;

        const iKeys = Object.keys(itemData);
        const iCols = iKeys.map((k) => `"${k}"`).join(", ");
        const iPlaceholders = iKeys.map((_, i) => `$${i + 1}`).join(", ");
        const iValues: any[] = Object.values(itemData);

        try {
          const itemRows = await client.unsafe(
            `INSERT INTO purchase_return_items (${iCols}) VALUES (${iPlaceholders}) RETURNING *`,
            iValues,
          );
          const createdItem = itemRows[0];

          if (batches && Array.isArray(batches) && createdItem) {
            for (const batch of batches) {
              batch.purchase_return_item_id = createdItem.id;
              const bKeys = Object.keys(batch);
              const bCols = bKeys.map((k) => `"${k}"`).join(", ");
              const bPlaceholders = bKeys.map((_, i) => `$${i + 1}`).join(", ");
              const bValues: any[] = Object.values(batch);

              await client.unsafe(
                `INSERT INTO purchase_return_item_batches (${bCols}) VALUES (${bPlaceholders})`,
                bValues,
              );
            }
          }
        } catch {
          // ignore single item update error
        }
      }
    }

    return this.findOne(tenant, id);
  }

  async remove(tenant: TenantContext, id: string) {
    try {
      await client.unsafe(
        `DELETE FROM purchase_returns WHERE id = $1 AND entity_id = $2`,
        [id, tenant.entityId],
      );
    } catch (error: any) {
      throw new Error(`Failed to delete purchase return: ${error.message}`);
    }

    return { success: true };
  }
}
