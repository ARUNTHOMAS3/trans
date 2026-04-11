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
      this.logger.log(`Fetching items for warehouse: ${warehouseId}`);
      
      const client = this.supabaseService.getClient();
      
      // STEP 1: Find all sales_order IDs that belong to this warehouse
      const { data: orders, error: ordersError } = await client
        .from('sales_orders')
        .select('id')
        .eq('warehouse_id', warehouseId);

      if (ordersError) {
        this.logger.error(`Orders query error: ${ordersError.message}`);
        throw ordersError;
      }

      const orderIds: string[] = (orders || []).map((o: any) => o.id);
      this.logger.log(`Found ${orderIds.length} sales orders for warehouse ${warehouseId}`);

      // STEP 2a: Items where sales_order_items.warehouse_id matches directly
      const { data: directItems, error: directError } = await client
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
            storage:storage_conditions(location_name)
          )
        `)
        .eq('warehouse_id', warehouseId);

      if (directError) {
        this.logger.error(`Direct query error: ${directError.message}`);
      }

      // STEP 2b: Items whose parent sales_order belongs to this warehouse
      let parentItems: any[] = [];
      if (orderIds.length > 0) {
        const { data, error: parentError } = await client
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
              storage:storage_conditions(location_name)
            )
          `)
          .in('sales_order_id', orderIds)
          .is('warehouse_id', null);

        if (parentError) {
          this.logger.error(`Parent query error: ${parentError.message}`);
        }
        parentItems = data || [];
      }

      // Merge and deduplicate by item id
      const allItems = [...(directItems || []), ...parentItems];
      const seen = new Set<string>();
      const uniqueItems = allItems.filter((item: any) => {
        if (seen.has(item.id)) return false;
        seen.add(item.id);
        return true;
      });

      this.logger.log(`Direct: ${directItems?.length || 0}, Parent: ${parentItems.length}, Unique: ${uniqueItems.length}`);

      return {
        data: uniqueItems.map((item: any) => ({
          warehouseId: item.warehouse_id || item.salesOrder?.warehouse_id || warehouseId,
          productId: item.productId || '',
          salesOrderId: item.salesOrderId || '',
          customerId: item.salesOrder?.customer_id || '',
          productCode: item.product?.sku || '',
          productName: item.product?.product_name || '',
          currentStock: 0, 
          quantityOnHand: 0,
          availableQuantity: Number(item.quantity) || 0,
          quantityToPick: Number(item.quantity) || 0,
          quantityOrdered: Number(item.quantity) || 0,
          orderNumber: item.salesOrder?.sale_number || '',
          customerName: item.salesOrder?.customer?.display_name || 'Walk-in Customer',
          preferredBin: item.product?.storage?.location_name || 'N/A',
          unit: item.product?.unit?.unit_name || item.product?.unit_id || '',
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
