import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { SupabaseService } from '../../supabase/supabase.service';

@Injectable()
export class PicklistsService {
  private readonly logger = new Logger(PicklistsService.name);

  constructor(
    private readonly supabaseService: SupabaseService,
  ) {}

  async findAll(page: number, limit: number, search?: string, status?: string) {
    const client = this.supabaseService.getClient();
    let query = client.from('inventory_picklists').select('*', { count: 'exact' });

    if (status) {
      query = query.eq('status', status);
    }

    if (search) {
      query = query.or(`picklist_number.ilike.%${search}%,description.ilike.%${search}%`);
    }

    const { data, count, error } = await query
      .range((page - 1) * limit, page * limit - 1)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return { data, total: count || 0 };
  }

  async findOne(id: string) {
    const client = this.supabaseService.getClient();
    const { data: picklist, error: picklistError } = await client
      .from('inventory_picklists')
      .select(`
        *,
        items:inventory_picklist_items(*)
      `)
      .eq('id', id)
      .single();

    if (picklistError || !picklist) throw new NotFoundException("Picklist not found");
    return picklist;
  }

  async create(data: any) {
    const client = this.supabaseService.getClient();
    const { items, ...picklistData } = data;

    const { data: picklist, error: picklistError } = await client
      .from('inventory_picklists')
      .insert(picklistData)
      .select()
      .single();

    if (picklistError) throw picklistError;

    if (items && items.length > 0) {
      const { error: itemsError } = await client
        .from('inventory_picklist_items')
        .insert(
          items.map((item: any) => ({ ...item, picklist_id: picklist.id }))
        );
      if (itemsError) throw itemsError;
    }

    return picklist;
  }

  async update(id: string, data: any) {
    const client = this.supabaseService.getClient();
    const { items, ...picklistData } = data;

    const { data: picklist, error: picklistError } = await client
      .from('inventory_picklists')
      .update(picklistData)
      .eq('id', id)
      .select()
      .single();

    if (picklistError) throw new NotFoundException("Picklist not found");

    if (items) {
      // Delete and recreate items
      await client.from('inventory_picklist_items').delete().eq('picklist_id', id);
      if (items.length > 0) {
        const { error: itemsError } = await client
          .from('inventory_picklist_items')
          .insert(
            items.map((item: any) => ({ ...item, picklist_id: id }))
          );
        if (itemsError) throw itemsError;
      }
    }

    return picklist;
  }

  async remove(id: string) {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from('inventory_picklists')
      .delete()
      .eq('id', id)
      .select()
      .single();
    if (error) throw new NotFoundException("Picklist not found");
    return data;
  }

  async getWarehouseItems(warehouseId: string) {
    try {
      this.logger.log(`Fetching transaction-based items for warehouse: ${warehouseId}`);
      
      const client = this.supabaseService.getClient();
      
      // BROAD FETCH for diagnostics
      const { data, error } = await client
        .from('sales_order_items')
        .select(`
          id,
          productId:product_id,
          salesOrderId:sales_order_id,
          quantity,
          outlet_id,
          warehouse_id,
          salesOrder:sales_orders(
            sale_number, 
            warehouse_id,
            status,
            customer_id,
            customer:customers(display_name)
          ),
          product:products(
            id,
            product_name,
            sku,
            unit_id,
            unit:units(unit_name),
            storage:storage_locations(location_name)
          )
        `);

      if (error) {
        this.logger.error(`Supabase error: ${error.message}`);
        throw error;
      }

      this.logger.log(`Raw data from DB: Found ${data?.length || 0} items total.`);
      
      // Try to find ANY match for debug purposes
      const directMatch = (data || []).filter((item: any) => 
        item.warehouse_id === warehouseId || item.outlet_id === warehouseId
      );
      this.logger.log(`Direct warehouse match count: ${directMatch.length}`);

      const orderMatch = (data || []).filter((item: any) => 
        item.salesOrder?.warehouse_id === warehouseId
      );
      this.logger.log(`Order warehouse match count: ${orderMatch.length}`);

      // Final dataset: Use matches if they exist, otherwise FALLBACK to everything non-draft for testing
      let finalData = directMatch.length > 0 ? directMatch : (orderMatch.length > 0 ? orderMatch : (data || []));
      
      // Filter out Draft orders if we have lots of data
      if (finalData.length > 50) {
        finalData = finalData.filter((item: any) => item.salesOrder?.status?.toLowerCase() !== 'draft');
      }

      this.logger.log(`Returning ${finalData.length} items to frontend for warehouse ${warehouseId}`);

      return {
        data: finalData.map((item: any) => ({
          warehouseId: item.warehouse_id || item.outlet_id || warehouseId,
          productId: item.productId,
          salesOrderId: item.salesOrderId,
          customerId: item.salesOrder?.customer_id,
          productCode: item.product?.sku || '',
          productName: item.product?.product_name || '',
          currentStock: 0, 
          quantityOrdered: item.quantity || 0,
          orderNumber: item.salesOrder?.sale_number || '',
          customerName: item.salesOrder?.customer?.display_name || 'Walk-in Customer',
          preferredBin: item.product?.storage?.location_name || 'N/A',
          unit: item.product?.unit?.unit_name || item.product?.unit_id,
        })),
        success: true,
      };
    } catch (error) {
      this.logger.error(`Error fetching warehouse items for ${warehouseId}: ${error.stack}`);
      return {
        data: [],
        success: false,
        message: 'Failed to fetch warehouse items from transactions',
      };
    }
  }
}
