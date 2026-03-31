import { Injectable, NotFoundException } from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { CreatePurchaseReceiveDto } from "../dto/create-purchase-receive.dto";
import { UpdatePurchaseReceiveDto } from "../dto/update-purchase-receive.dto";

@Injectable()
export class PurchaseReceivesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(
    page: number = 1,
    limit: number = 100,
    search?: string,
    status?: string,
  ) {
    const offset = (page - 1) * limit;

    let query = this.supabaseService
      .getClient()
      .from("purchases_purchase_receives")
      .select(`*`, { count: "exact" })
      .range(offset, offset + limit - 1);

    if (search) {
      query = query.or(
        `purchase_receive_number.ilike.%${search}%,purchase_order_number.ilike.%${search}%,vendor_name.ilike.%${search}%`,
      );
    }

    if (status) {
      query = query.eq("status", status);
    }

    const { data, error, count } = await query;

    if (error) {
      throw new Error(`Failed to fetch purchase receives: ${error.message}`);
    }

    return {
      data,
      meta: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil((count || 0) / limit),
      },
    };
  }

  async findOne(id: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchases_purchase_receives")
      .select(
        `
        *,
        purchases_purchase_receive_items(*)
      `,
      )
      .eq("id", id)
      .single();

    if (error) {
      throw new NotFoundException(`Purchase Receive with ID ${id} not found`);
    }

    return data;
  }

  async create(createDto: CreatePurchaseReceiveDto) {
    // 1. Create the parent record
    const { items, ...receiveData } = createDto;
    
    const { data: receive, error: receiveError } = await this.supabaseService
      .getClient()
      .from("purchases_purchase_receives")
      .insert([receiveData])
      .select()
      .single();

    if (receiveError) {
      throw new Error(`Failed to create purchase receive: ${receiveError.message}`);
    }

    // 2. Create the child items
    if (items && items.length > 0) {
      const itemsToInsert = items.map(item => ({
        ...item,
        purchase_receive_id: receive.id
      }));

      const { error: itemsError } = await this.supabaseService
        .getClient()
        .from("purchases_purchase_receive_items")
        .insert(itemsToInsert);

      if (itemsError) {
        throw new Error(`Failed to create purchase receive items: ${itemsError.message}`);
      }
    }

    return this.findOne(receive.id);
  }

  async update(id: string, updateDto: UpdatePurchaseReceiveDto) {
    const { items, ...updateData } = updateDto;

    if (Object.keys(updateData).length > 0) {
      const { error } = await this.supabaseService
        .getClient()
        .from("purchases_purchase_receives")
        .update(updateData)
        .eq("id", id);

      if (error) {
        throw new Error(`Failed to update purchase receive: ${error.message}`);
      }
    }

    // Only updating the parent record for simplicity, item updates would typically
    // involve deleting existing and re-inserting, or a more complex sync.
    
    return this.findOne(id);
  }

  async remove(id: string) {
    const { error } = await this.supabaseService
      .getClient()
      .from("purchases_purchase_receives")
      .delete()
      .eq("id", id);

    if (error) {
      throw new Error(`Failed to delete purchase receive: ${error.message}`);
    }

    return { message: "Purchase Receive deleted successfully" };
  }
}
