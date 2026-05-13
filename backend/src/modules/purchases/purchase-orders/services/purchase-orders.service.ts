import { Injectable, NotFoundException } from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { CreatePurchaseOrderDto } from "../dto/create-purchase-order.dto";
import { UpdatePurchaseOrderDto } from "../dto/update-purchase-order.dto";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";

@Injectable()
export class PurchaseOrdersService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private async getNextPurchaseOrderNumber(tenant: TenantContext) {
    const regexPattern = "^PO-[0-9]+$";
    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchase_orders")
      .select("order_number")
      .eq("entity_id", tenant.entityId)
      .filter("order_number", "match", regexPattern)
      .limit(1000);

    if (error) {
      throw new Error(
        `Failed to generate next purchase order number: ${error.message}`,
      );
    }

    let maxNumber = 0;
    for (const row of data ?? []) {
      const raw = row.order_number as string | null;
      if (raw == null) continue;
      const match = /^PO-(\d+)$/.exec(raw);
      if (match == null) continue;
      const num = Number.parseInt(match[1], 10);
      if (!Number.isNaN(num) && num > maxNumber) {
        maxNumber = num;
      }
    }

    const nextNumber = maxNumber + 1;
    const padding = 5;
    return {
      prefix: "PO-",
      nextNumber,
      padding,
      formatted: `PO-${nextNumber.toString().padStart(padding, "0")}`,
    };
  }

  async getNextNumber(tenant: TenantContext) {
    return this.getNextPurchaseOrderNumber(tenant);
  }

  async findAll(
    tenant: TenantContext,
    page: number = 1,
    limit: number = 100,
    search?: string,
    status?: string,
    vendorId?: string,
  ) {
    const offset = (page - 1) * limit;

    let query = this.supabaseService
      .getClient()
      .from("purchase_orders")
      .select(
        `
        *,
        vendor:vendors(display_name, company_name)
      `,
        { count: "exact" },
      )
      .eq("entity_id", tenant.entityId)
      .range(offset, offset + limit - 1);

    if (search) {
      query = query.or(
        `order_number.ilike.%${search}%,reference_number.ilike.%${search}%`,
      );
    }

    if (status) {
      query = query.eq("status", status);
    }

    if (vendorId) {
      query = query.eq("vendor_id", vendorId);
    }

    const { data, error, count } = await query;

    if (error) {
      throw new Error(`Failed to fetch purchase orders: ${error.message}`);
    }

    return {
      data,
      meta: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchase_orders")
      .select(
        `
        *,
        vendor:vendors(*),
        items:purchase_order_items(*, product:products(*))
      `,
      )
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .single();

    if (error) {
      throw new NotFoundException(`Purchase Order with ID ${id} not found`);
    }

    return data;
  }

  async create(createPurchaseOrderDto: CreatePurchaseOrderDto, tenant: TenantContext) {
    const { items, ...poData } = createPurchaseOrderDto;
    const payload = {
      ...(poData as any),
      entity_id: tenant.entityId,
    };
    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchase_orders")
      .insert([payload])
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create purchase order: ${error.message}`);
    }

    if (items && items.length > 0) {
      const itemsPayload = items.map((item) => ({
        ...(item as any),
        purchase_order_id: data.id,
        entity_id: tenant.entityId,
      }));

      const { error: itemsError } = await this.supabaseService
        .getClient()
        .from("purchase_order_items")
        .insert(itemsPayload);

      if (itemsError) {
        throw new Error(
          `Failed to create purchase order items: ${itemsError.message}`,
        );
      }
    }

    return data;
  }

  async update(
    id: string,
    tenant: TenantContext,
    updatePurchaseOrderDto: UpdatePurchaseOrderDto,
  ) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchase_orders")
      .update(updatePurchaseOrderDto)
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update purchase order: ${error.message}`);
    }

    if (!data) {
      throw new NotFoundException(`Purchase Order with ID ${id} not found`);
    }

    return data;
  }

  async remove(id: string, tenant: TenantContext) {
    const { error } = await this.supabaseService
      .getClient()
      .from("purchase_orders")
      .delete()
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (error) {
      throw new Error(`Failed to delete purchase order: ${error.message}`);
    }

    return { message: "Purchase Order deleted successfully" };
  }
}