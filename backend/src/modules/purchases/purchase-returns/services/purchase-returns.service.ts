import { Injectable, NotFoundException } from "@nestjs/common";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../../supabase/supabase.service";

@Injectable()
export class PurchaseReturnsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getNextNumber(tenant: TenantContext, prefix: string = "PRT-") {
    const safePrefix = prefix || "PRT-";
    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchase_returns")
      .select("purchase_return_number")
      .eq("entity_id", tenant.entityId)
      .order("created_at", { ascending: false })
      .limit(10);

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
    let query = this.supabaseService
      .getClient()
      .from("purchase_returns")
      .select("*, purchase_return_items(*, purchase_return_item_batches(*))")
      .eq("entity_id", tenant.entityId);

    if (search) {
      query = query.ilike("purchase_return_number", `%${search}%`);
    }

    if (status && status.toLowerCase() !== "all") {
      query = query.eq("status", status.toLowerCase());
    }

    const from = (page - 1) * limit;
    const to = from + limit - 1;
    const { data, error } = await query
      .order("created_at", { ascending: false })
      .range(from, to);

    if (error) {
      throw new Error(`Failed to fetch purchase returns: ${error.message}`);
    }

    return data || [];
  }

  async findOne(tenant: TenantContext, id: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchase_returns")
      .select("*, purchase_return_items(*, purchase_return_item_batches(*))")
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .single();

    if (error || !data) {
      throw new NotFoundException(`Purchase Return with ID ${id} not found`);
    }

    return data;
  }

  async create(tenant: TenantContext, dto: any) {
    const { items, ...headerData } = dto;
    headerData.entity_id = tenant.entityId;

    const { data: header, error: headerErr } = await this.supabaseService
      .getClient()
      .from("purchase_returns")
      .insert(headerData)
      .select()
      .single();

    if (headerErr) {
      throw new Error(`Failed to create purchase return: ${headerErr.message}`);
    }

    if (items && Array.isArray(items)) {
      for (const item of items) {
        const { batches, ...itemData } = item;
        itemData.purchase_return_id = header.id;

        const { data: createdItem, error: itemErr } = await this.supabaseService
          .getClient()
          .from("purchase_return_items")
          .insert(itemData)
          .select()
          .single();

        if (itemErr) continue;

        if (batches && Array.isArray(batches)) {
          for (const batch of batches) {
            batch.purchase_return_item_id = createdItem.id;
            await this.supabaseService
              .getClient()
              .from("purchase_return_item_batches")
              .insert(batch);
          }
        }
      }
    }

    return this.findOne(tenant, header.id);
  }

  async update(tenant: TenantContext, id: string, dto: any) {
    const { items, ...headerData } = dto;

    await this.supabaseService
      .getClient()
      .from("purchase_returns")
      .update(headerData)
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (items && Array.isArray(items)) {
      await this.supabaseService
        .getClient()
        .from("purchase_return_items")
        .delete()
        .eq("purchase_return_id", id);

      for (const item of items) {
        const { batches, ...itemData } = item;
        itemData.purchase_return_id = id;

        const { data: createdItem, error: itemErr } = await this.supabaseService
          .getClient()
          .from("purchase_return_items")
          .insert(itemData)
          .select()
          .single();

        if (itemErr) continue;

        if (batches && Array.isArray(batches)) {
          for (const batch of batches) {
            batch.purchase_return_item_id = createdItem.id;
            await this.supabaseService
              .getClient()
              .from("purchase_return_item_batches")
              .insert(batch);
          }
        }
      }
    }

    return this.findOne(tenant, id);
  }

  async remove(tenant: TenantContext, id: string) {
    const { error } = await this.supabaseService
      .getClient()
      .from("purchase_returns")
      .delete()
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (error) {
      throw new Error(`Failed to delete purchase return: ${error.message}`);
    }

    return { success: true };
  }
}
