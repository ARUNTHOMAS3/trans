import { Injectable, NotFoundException } from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { CreatePurchaseOrderDto } from "../dto/create-purchase-order.dto";
import { UpdatePurchaseOrderDto } from "../dto/update-purchase-order.dto";

@Injectable()
export class PurchaseOrdersService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(
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

  async findOne(id: string) {
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
      .single();

    if (error) {
      throw new NotFoundException(`Purchase Order with ID ${id} not found`);
    }

    return data;
  }

  async create(createPurchaseOrderDto: CreatePurchaseOrderDto) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchase_orders")
      .insert([createPurchaseOrderDto])
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create purchase order: ${error.message}`);
    }

    return data;
  }

  async update(id: string, updatePurchaseOrderDto: UpdatePurchaseOrderDto) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchase_orders")
      .update(updatePurchaseOrderDto)
      .eq("id", id)
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

  async remove(id: string) {
    const { error } = await this.supabaseService
      .getClient()
      .from("purchase_orders")
      .delete()
      .eq("id", id);

    if (error) {
      throw new Error(`Failed to delete purchase order: ${error.message}`);
    }

    return { message: "Purchase Order deleted successfully" };
  }

  async getSettings() {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("transactional_sequences")
      .select("*")
      .eq("module", "purchase_order")
      .single();

    if (error && error.code !== "PGRST116") {
      throw new Error(`Failed to fetch PO settings: ${error.message}`);
    }

    return (
      data || {
        prefix: "PO-",
        nextNumber: 1,
        padding: 6,
      }
    );
  }

  async getNextNumber() {
    const settings = await this.getSettings();
    const nextNum = settings.next_number || settings.nextNumber || 1;
    const prefix = settings.prefix || "PO-";
    const padding = settings.padding || 6;

    const formattedNumber = `${prefix}${nextNum.toString().padStart(padding, "0")}`;
    return { nextNumber: formattedNumber, raw: nextNum };
  }
}
