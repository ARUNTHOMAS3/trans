import { Injectable, NotFoundException } from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { CreatePurchaseOrderDto } from "../dto/create-purchase-order.dto";
import { UpdatePurchaseOrderDto } from "../dto/update-purchase-order.dto";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";

@Injectable()
export class PurchaseOrdersService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private async resolveDiscountAccountId(
    tenant: TenantContext,
    dto: { discount_level?: string; discount_account_id?: string },
  ) {
    if (dto.discount_account_id) {
      return dto.discount_account_id;
    }

    const { data } = await this.supabaseService
      .getClient()
      .from("accounts")
      .select("id,user_account_name,system_account_name")
      .eq("entity_id", tenant.entityId)
      .or(
        "user_account_name.ilike.%Purchase Discount%,system_account_name.ilike.%Purchase Discount%,user_account_name.ilike.%Discount%",
      )
      .limit(1)
      .maybeSingle();

    if (!data) {
      const fallback = await this.supabaseService
        .getClient()
        .from("accounts")
        .select("id")
        .eq("entity_id", tenant.entityId)
        .limit(1)
        .maybeSingle();
      return fallback.data?.id ?? null;
    }
    return data?.id ?? null;
  }

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
        vendor:vendors(display_name, company_name),
        warehouse:warehouses!warehouse_id(name)
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
        warehouse:warehouses!warehouse_id(name),
        items:purchase_order_items(*, product:products(*))
      `,
      )
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .single();

    if (error) {
      console.error("Error in findOne PO:", error);
      throw new NotFoundException(
        `Purchase Order not found: ${error.message} (code: ${error.code})`,
      );
    }

    return data;
  }

  async create(
    createPurchaseOrderDto: CreatePurchaseOrderDto,
    tenant: TenantContext,
  ) {
    const { items, org_id, branch_id, warehouse_name, ...poData } =
      createPurchaseOrderDto;
    const resolvedDiscountAccountId = await this.resolveDiscountAccountId(
      tenant,
      createPurchaseOrderDto,
    );

    let resolvedWarehouseId = createPurchaseOrderDto.warehouse_id;
    if (!resolvedWarehouseId) {
      if (
        createPurchaseOrderDto.delivery_type === "warehouse" &&
        createPurchaseOrderDto.delivery_warehouse_id
      ) {
        resolvedWarehouseId = createPurchaseOrderDto.delivery_warehouse_id;
      } else {
        const { data: wh } = await this.supabaseService
          .getClient()
          .from("warehouses")
          .select("id")
          .eq("entity_id", tenant.entityId)
          .eq("is_active", true)
          .limit(1)
          .maybeSingle();
        resolvedWarehouseId = wh?.id || null;
      }
    }

    const payload = {
      ...(poData as any),
      warehouse_id: resolvedWarehouseId,
      discount_account_id: resolvedDiscountAccountId,
      is_delete: false,
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
      const itemsPayload = items.map((item) => {
        const accountId = item.account_id || item.accounts;
        let hsnNumeric: number | null = null;
        if (
          item.hsn_code !== undefined &&
          item.hsn_code !== null &&
          item.hsn_code !== ""
        ) {
          const parsed = Number(item.hsn_code);
          if (!isNaN(parsed)) {
            hsnNumeric = parsed;
          }
        }
        return {
          ...(item as any),
          account_id: accountId,
          accounts: accountId,
          hsn_code: hsnNumeric,
          purchase_order_id: data.id,
          entity_id: tenant.entityId,
        };
      });

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
    const { items, org_id, branch_id, warehouse_name, ...poData } =
      updatePurchaseOrderDto;
    const resolvedDiscountAccountId = await this.resolveDiscountAccountId(
      tenant,
      updatePurchaseOrderDto,
    );

    let resolvedWarehouseId = updatePurchaseOrderDto.warehouse_id;
    if (updatePurchaseOrderDto.hasOwnProperty("warehouse_id") && !resolvedWarehouseId) {
      if (
        updatePurchaseOrderDto.delivery_type === "warehouse" &&
        updatePurchaseOrderDto.delivery_warehouse_id
      ) {
        resolvedWarehouseId = updatePurchaseOrderDto.delivery_warehouse_id;
      } else {
        const { data: wh } = await this.supabaseService
          .getClient()
          .from("warehouses")
          .select("id")
          .eq("entity_id", tenant.entityId)
          .eq("is_active", true)
          .limit(1)
          .maybeSingle();
        resolvedWarehouseId = wh?.id || null;
      }
    }

    const payload: any = {
      ...(poData as any),
      discount_account_id: resolvedDiscountAccountId,
    };

    if (resolvedWarehouseId) {
      payload.warehouse_id = resolvedWarehouseId;
    }
    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchase_orders")
      .update(payload)
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

    // 1. Delete all existing items for this Purchase Order
    const { error: deleteError } = await this.supabaseService
      .getClient()
      .from("purchase_order_items")
      .delete()
      .eq("purchase_order_id", id);

    if (deleteError) {
      throw new Error(
        `Failed to clean old purchase order items: ${deleteError.message}`,
      );
    }

    // 2. Insert new / updated items
    if (items && items.length > 0) {
      const itemsPayload = items.map((item) => {
        const accountId = item.account_id || item.accounts;
        let hsnNumeric: number | null = null;
        if (
          item.hsn_code !== undefined &&
          item.hsn_code !== null &&
          item.hsn_code !== ""
        ) {
          const parsed = Number(item.hsn_code);
          if (!isNaN(parsed)) {
            hsnNumeric = parsed;
          }
        }
        return {
          ...(item as any),
          account_id: accountId,
          accounts: accountId,
          hsn_code: hsnNumeric,
          purchase_order_id: id,
          entity_id: tenant.entityId,
        };
      });

      const { error: itemsError } = await this.supabaseService
        .getClient()
        .from("purchase_order_items")
        .insert(itemsPayload);

      if (itemsError) {
        throw new Error(
          `Failed to update purchase order items: ${itemsError.message}`,
        );
      }
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
