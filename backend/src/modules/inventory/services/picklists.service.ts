import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { TenantContext } from '../../../common/middleware/tenant.middleware';
import { SupabaseService } from '../../supabase/supabase.service';

@Injectable()
export class PicklistsService {
  private readonly logger = new Logger(PicklistsService.name);

  constructor(
    private readonly supabaseService: SupabaseService,
  ) {}

  async findAll(
    tenant: TenantContext,
    page: number,
    limit: number,
    search?: string,
    status?: string,
  ) {
    const client = this.supabaseService.getClient();
    let query = client
      .from('inventory_picklists')
      .select('*', { count: 'exact' })
      .eq('entity_id', tenant.entityId);

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

  async findOne(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const { data: picklist, error: picklistError } = await client
      .from('inventory_picklists')
      .select(`
        *,
        items:inventory_picklist_items(*)
      `)
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .single();

    if (picklistError || !picklist) throw new NotFoundException("Picklist not found");
    return picklist;
  }

  async create(data: any, tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const { items, ...picklistData } = data;

    const { data: picklist, error: picklistError } = await client
      .from('inventory_picklists')
      .insert({ ...picklistData, entity_id: tenant.entityId })
      .select()
      .single();

    if (picklistError) throw picklistError;

    if (items && items.length > 0) {
      const { error: itemsError } = await client
        .from('inventory_picklist_items')
        .insert(
          items.map((item: any) => ({
            ...item,
            picklist_id: picklist.id,
            entity_id: tenant.entityId,
          }))
        );
      if (itemsError) throw itemsError;
    }

    return picklist;
  }

  async update(id: string, data: any, tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const { items, ...picklistData } = data;

    const { data: picklist, error: picklistError } = await client
      .from('inventory_picklists')
      .update(picklistData)
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .select()
      .single();

    if (picklistError) throw new NotFoundException("Picklist not found");

    if (items) {
      // Delete and recreate items
      await client
        .from('inventory_picklist_items')
        .delete()
        .eq('picklist_id', id)
        .eq('entity_id', tenant.entityId);
      if (items.length > 0) {
        const { error: itemsError } = await client
          .from('inventory_picklist_items')
          .insert(
            items.map((item: any) => ({
              ...item,
              picklist_id: id,
              entity_id: tenant.entityId,
            }))
          );
        if (itemsError) throw itemsError;
      }
    }

    return picklist;
  }

  async remove(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from('inventory_picklists')
      .delete()
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .select()
      .single();
    if (error) throw new NotFoundException("Picklist not found");
    return data;
  }

  async getWarehouseItems(warehouseId: string, tenant: TenantContext) {
    try {
      this.logger.log(`Fetching items for warehouse: ${warehouseId}`);

      const client = this.supabaseService.getClient();

      // Source of truth for popup rows: sales_order_items filtered by selected warehouse.
      const { data: orderItems, error } = await client
        .from('sales_order_items')
        .select(`
          id,
          product_id,
          sales_order_id,
          quantity,
          free_quantity,
          warehouse_id,
          sales_orders!inner(
            sale_number,
            status,
            customer_id,
            customers!inner(display_name)
          ),
          products!inner(
            id,
            product_name,
            sku,
            unit_id,
            units(unit_name),
            storage_conditions(location_name)
          )
        `)
        .eq('warehouse_id', warehouseId)
        .eq('entity_id', tenant.entityId);

      if (error) {
        this.logger.error(`sales_order_items query error: ${error.message}`);
        throw error;
      }

      const items = orderItems ?? [];
      this.logger.log(`Loaded ${items.length} sales_order_items rows for warehouse ${warehouseId}`);

      return {
        data: items.map((item: any) => ({
          warehouseId: item.warehouse_id || warehouseId,
          productId: item.product_id || '',
          salesOrderId: item.sales_order_id || '',
          customerId: item.sales_orders?.customer_id || '',
          productCode: item.products?.sku || '',
          productName: item.products?.product_name || '',
          currentStock: 0,
          quantityOnHand: 0,
          availableQuantity:
              (Number(item.quantity) || 0) + (Number(item.free_quantity) || 0),
          quantityToPick:
              (Number(item.quantity) || 0) + (Number(item.free_quantity) || 0),
          quantityOrdered:
              (Number(item.quantity) || 0) + (Number(item.free_quantity) || 0),
          orderNumber: item.sales_orders?.sale_number || '',
          customerName: item.sales_orders?.customers?.display_name || 'Walk-in Customer',
          preferredBin: item.products?.storage_conditions?.location_name || 'N/A',
          unit: item.products?.units?.unit_name || item.products?.unit_id || '',
        })),
        success: true,
      };
    } catch (error) {
      this.logger.error(
        `Error fetching warehouse items for ${warehouseId}: ${error instanceof Error ? error.stack : String(error)}`
      );
      return {
        data: [],
        success: false,
        message: 'Failed to fetch warehouse items from transactions',
      };
    }
  }
}
