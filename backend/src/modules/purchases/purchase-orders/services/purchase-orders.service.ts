import { Injectable, NotFoundException } from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { CreatePurchaseOrderDto } from "../dto/create-purchase-order.dto";
import { UpdatePurchaseOrderDto } from "../dto/update-purchase-order.dto";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";

@Injectable()
export class PurchaseOrdersService {
  constructor(private readonly supabaseService: SupabaseService) {}

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
    const payload = {
      ...(createPurchaseOrderDto as any),
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
