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
      .from('picklist_master')
      .select('*', { count: 'exact' })
      .eq('entity_id', tenant.entityId);

    if (status) {
      query = query.eq('status', status);
    }

    if (search) {
      query = query.or(`picklist_no.ilike.%${search}%,notes.ilike.%${search}%`);
    }

    const { data, count, error } = await query
      .range((page - 1) * limit, page * limit - 1)
      .order('created_at', { ascending: false });

    if (error) throw error;

    const rows = data || [];

    // Resolve warehouse names
    const warehouseIds = [...new Set(rows.map((r: any) => r.warehouse_id).filter(Boolean))];
    let warehouseMap = new Map<string, string>();
    if (warehouseIds.length > 0) {
      const { data: warehouses } = await client
        .from('warehouses')
        .select('id, name')
        .in('id', warehouseIds);
      warehouseMap = new Map((warehouses || []).map((w: any) => [w.id, w.name]));
    }

    // Resolve customer_name and sales_order_number from picklist_items
    const picklistIds = rows.map((r: any) => r.id);
    let picklistItemsMap = new Map<string, { customer_name: string | null; sales_order_number: string | null }>();
    if (picklistIds.length > 0) {
      const { data: items } = await client
        .from('picklist_items')
        .select('picklist_id, sales_order_id')
        .in('picklist_id', picklistIds);

      // Get unique sales_order_ids
      const soIds = [...new Set((items || []).map((i: any) => i.sales_order_id).filter(Boolean))];
      let soMap = new Map<string, { sale_number: string; customer_id: string | null }>();
      if (soIds.length > 0) {
        const { data: salesOrders } = await client
          .from('sales_orders')
          .select('id, sale_number, customer_id')
          .in('id', soIds);
        soMap = new Map((salesOrders || []).map((so: any) => [so.id, { sale_number: so.sale_number, customer_id: so.customer_id }]));
      }

      // Get unique customer_ids
      const customerIds = [...new Set([...soMap.values()].map(so => so.customer_id).filter(Boolean))] as string[];
      let customerMap = new Map<string, string>();
      if (customerIds.length > 0) {
        const { data: customers } = await client
          .from('customers')
          .select('id, display_name')
          .in('id', customerIds);
        customerMap = new Map((customers || []).map((c: any) => [c.id, c.display_name]));
      }

      // For each picklist, get first item's SO info
      for (const picklistId of picklistIds) {
        const firstItem = (items || []).find((i: any) => i.picklist_id === picklistId && i.sales_order_id);
        if (firstItem) {
          const soInfo = soMap.get(firstItem.sales_order_id);
          picklistItemsMap.set(picklistId, {
            customer_name: soInfo?.customer_id ? customerMap.get(soInfo.customer_id) || null : null,
            sales_order_number: soInfo?.sale_number || null,
          });
        }
      }
    }

    return {
      data: rows.map((row: any) => {
        const itemInfo = picklistItemsMap.get(row.id);
        return {
          id: row.id,
          picklist_number: row.picklist_no,
          date: row.picklist_date,
          status: row.status,
          assignee: row.assignee_id,
          location: warehouseMap.get(row.warehouse_id) || row.warehouse_id,
          notes: row.notes,
          customer_name: itemInfo?.customer_name || null,
          sales_order_number: itemInfo?.sales_order_number || null,
        };
      }),
      total: count || 0,
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();

    // Fetch master record
    const { data: picklist, error: picklistError } = await client
      .from('picklist_master')
      .select('*')
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .single();

    if (picklistError || !picklist) throw new NotFoundException('Picklist not found');

    // Resolve warehouse name
    let warehouseName = picklist.warehouse_id;
    if (picklist.warehouse_id) {
      const { data: wh } = await client
        .from('warehouses')
        .select('name')
        .eq('id', picklist.warehouse_id)
        .maybeSingle();
      if (wh) warehouseName = wh.name;
    }

    // Fetch items
    const { data: items, error: itemsError } = await client
      .from('picklist_items')
      .select('*')
      .eq('picklist_id', id);

    if (itemsError) {
      this.logger.error(`Error fetching picklist items: ${itemsError.message}`);
    }

    // Resolve product names
    const productIds = [...new Set((items || []).map((i: any) => i.product_id).filter(Boolean))];
    let productMap = new Map<string, string>();
    if (productIds.length > 0) {
      const { data: products } = await client
        .from('products')
        .select('id, product_name')
        .in('id', productIds);
      productMap = new Map((products || []).map((p: any) => [p.id, p.product_name]));
    }

    // Resolve sales order numbers and customer names
    const soIds = [...new Set((items || []).map((i: any) => i.sales_order_id).filter(Boolean))];
    let soMap = new Map<string, { sale_number: string; customer_id: string | null }>();
    if (soIds.length > 0) {
      const { data: salesOrders } = await client
        .from('sales_orders')
        .select('id, sale_number, customer_id')
        .in('id', soIds);
      soMap = new Map((salesOrders || []).map((so: any) => [so.id, { sale_number: so.sale_number, customer_id: so.customer_id }]));
    }

    const customerIds = [...new Set([...soMap.values()].map(so => so.customer_id).filter(Boolean))] as string[];
    let customerMap = new Map<string, string>();
    if (customerIds.length > 0) {
      const { data: customers } = await client
        .from('customers')
        .select('id, display_name')
        .in('id', customerIds);
      customerMap = new Map((customers || []).map((c: any) => [c.id, c.display_name]));
    }

    // Fetch batch allocations for each item
    const itemIds = (items || []).map((i: any) => i.id);
    let batchAllocations: any[] = [];
    if (itemIds.length > 0) {
      const { data: batches, error: batchError } = await client
        .from('picklist_batch_allocation')
        .select('*')
        .in('picklist_item_id', itemIds);

      if (batchError) {
        this.logger.error(`Error fetching batch allocations: ${batchError.message}`);
      }

      const rawBatches = batches || [];
      const batchIds = [...new Set(rawBatches.map((b: any) => b.batch_id).filter(Boolean))];
      const binIds = [...new Set(rawBatches.map((b: any) => b.bin_id).filter(Boolean))];
      const layerIds = [...new Set(rawBatches.map((b: any) => b.layer_id).filter(Boolean))];

      let batchMap = new Map<string, any>();
      if (batchIds.length > 0) {
        const { data: batchRows } = await client
          .from('batch_master')
          .select('id, batch_no, expiry_date, unit_pack, manufacture_batch_number, manufacture_exp')
          .in('id', batchIds);
        batchMap = new Map((batchRows || []).map((r: any) => [r.id, r]));
      }

      let binMap = new Map<string, any>();
      if (binIds.length > 0) {
        const { data: binRows } = await client
          .from('bin_master')
          .select('id, bin_code')
          .in('id', binIds);
        binMap = new Map((binRows || []).map((r: any) => [r.id, r]));
      }

      let layerMap = new Map<string, any>();
      if (layerIds.length > 0) {
        const { data: layerRows } = await client
          .from('batch_stock_layers')
          .select('id, mrp, purchase_rate')
          .in('id', layerIds);
        layerMap = new Map((layerRows || []).map((r: any) => [r.id, r]));
      }

      batchAllocations = rawBatches.map((b: any) => {
        const batch = b.batch_id ? batchMap.get(b.batch_id) : null;
        const bin = b.bin_id ? binMap.get(b.bin_id) : null;
        const layer = b.layer_id ? layerMap.get(b.layer_id) : null;
        return {
          ...b,
          // Flatten related data so UI mapping works consistently.
          bin_code: bin?.bin_code ?? null,
          batch_no: batch?.batch_no ?? null,
          expiry_date: batch?.expiry_date ?? null,
          mrp: layer?.mrp ?? null,
          ptr: layer?.purchase_rate ?? null,
          unit_pack: batch?.unit_pack ?? null,
          mfg_date: batch?.manufacture_exp ?? null,
          mfg_batch: batch?.manufacture_batch_number ?? null,
        };
      });
    }

    // Merge batch allocations into items, with resolved names
    const itemsWithBatches = (items || []).map((item: any) => {
      const soInfo = soMap.get(item.sales_order_id);
      return {
        ...item,
        product_name: productMap.get(item.product_id) || item.product_id,
        sales_order_number: soInfo?.sale_number || null,
        customer_name: soInfo?.customer_id ? customerMap.get(soInfo.customer_id) || null : null,
        batch_allocations: batchAllocations.filter((b: any) => b.picklist_item_id === item.id),
      };
    });

    // Get first item's customer/SO for header
    const firstItemWithSO = itemsWithBatches.find((i: any) => i.sales_order_number);

    return {
      id: picklist.id,
      picklist_number: picklist.picklist_no,
      date: picklist.picklist_date,
      status: picklist.status,
      assignee: picklist.assignee_id,
      location: warehouseName,
      notes: picklist.notes,
      customer_name: firstItemWithSO?.customer_name || null,
      sales_order_number: firstItemWithSO?.sales_order_number || null,
      items: itemsWithBatches,
    };
  }

  async create(data: any, tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const { items, ...headerData } = data;

    // Insert into picklist_master
    const { data: picklist, error: picklistError } = await client
      .from('picklist_master')
      .insert({
        picklist_no: headerData.picklist_no,
        entity_id: tenant.entityId,
        warehouse_id: headerData.warehouse_id,
        assignee_id: headerData.assignee_id || null,
        picklist_date: headerData.picklist_date,
        status: headerData.status || 'DRAFT',
        notes: headerData.notes || null,
      })
      .select()
      .single();

    if (picklistError) {
      this.logger.error(`Error creating picklist_master: ${picklistError.message}`);
      throw picklistError;
    }

    // Insert picklist_items and their batch_allocations
    if (items && items.length > 0) {
      for (const item of items) {
        const { data: picklistItem, error: itemError } = await client
          .from('picklist_items')
          .insert({
            picklist_id: picklist.id,
            product_id: item.product_id,
            sales_order_id: item.sales_order_id || null,
            sales_order_line_id: item.sales_order_line_id || null,
            qty_ordered: item.qty_ordered || 0,
            qty_to_pick: item.qty_to_pick || 0,
            qty_picked: item.qty_picked || 0,
          })
          .select()
          .single();

        if (itemError) {
          this.logger.error(`Error creating picklist_item: ${itemError.message}`);
          throw itemError;
        }

        // Insert batch allocations for this item
        if (item.batch_allocations && item.batch_allocations.length > 0) {
          const batchRows = item.batch_allocations.map((ba: any) => ({
            picklist_item_id: picklistItem.id,
            batch_id: ba.batch_id,
            layer_id: ba.layer_id,
            warehouse_id: ba.warehouse_id || headerData.warehouse_id,
            bin_id: ba.bin_id,
            qty: ba.qty || 0,
            foc_qty: ba.foc_qty || 0,
          }));

          const { error: batchError } = await client
            .from('picklist_batch_allocation')
            .insert(batchRows);

          if (batchError) {
            this.logger.error(`Error creating batch allocations: ${batchError.message}`);
            throw batchError;
          }
        }
      }
    }

    return {
      id: picklist.id,
      picklist_number: picklist.picklist_no,
      date: picklist.picklist_date,
      status: picklist.status,
    };
  }

  async update(id: string, data: any, tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const { items, ...headerData } = data;

    // Update picklist_master
    const updatePayload: any = {};
    if (headerData.picklist_no !== undefined) updatePayload.picklist_no = headerData.picklist_no;
    if (headerData.warehouse_id !== undefined) updatePayload.warehouse_id = headerData.warehouse_id;
    if (headerData.assignee_id !== undefined) updatePayload.assignee_id = headerData.assignee_id;
    if (headerData.picklist_date !== undefined) updatePayload.picklist_date = headerData.picklist_date;
    if (headerData.status !== undefined) updatePayload.status = headerData.status;
    if (headerData.notes !== undefined) updatePayload.notes = headerData.notes;

    const { data: picklist, error: picklistError } = await client
      .from('picklist_master')
      .update(updatePayload)
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .select()
      .single();

    if (picklistError) throw new NotFoundException('Picklist not found');

    // If items are provided, delete old and recreate
    if (items) {
      // Fetch old item ids
      const { data: oldItems } = await client
        .from('picklist_items')
        .select('id')
        .eq('picklist_id', id);

      const oldItemIds = (oldItems || []).map((i: any) => i.id);

      // Delete batch allocations for old items
      if (oldItemIds.length > 0) {
        await client
          .from('picklist_batch_allocation')
          .delete()
          .in('picklist_item_id', oldItemIds);
      }

      // Delete old items
      await client
        .from('picklist_items')
        .delete()
        .eq('picklist_id', id);

      // Insert new items and allocations
      for (const item of items) {
        const { data: picklistItem, error: itemError } = await client
          .from('picklist_items')
          .insert({
            picklist_id: id,
            product_id: item.product_id,
            sales_order_id: item.sales_order_id || null,
            sales_order_line_id: item.sales_order_line_id || null,
            qty_ordered: item.qty_ordered || 0,
            qty_to_pick: item.qty_to_pick || 0,
            qty_picked: item.qty_picked || 0,
          })
          .select()
          .single();

        if (itemError) throw itemError;

        if (item.batch_allocations && item.batch_allocations.length > 0) {
          const batchRows = item.batch_allocations.map((ba: any) => ({
            picklist_item_id: picklistItem.id,
            batch_id: ba.batch_id,
            layer_id: ba.layer_id,
            warehouse_id: ba.warehouse_id || headerData.warehouse_id || picklist.warehouse_id,
            bin_id: ba.bin_id,
            qty: ba.qty || 0,
            foc_qty: ba.foc_qty || 0,
          }));

          const { error: batchError } = await client
            .from('picklist_batch_allocation')
            .insert(batchRows);

          if (batchError) throw batchError;
        }
      }
    }

    return {
      id: picklist.id,
      picklist_number: picklist.picklist_no,
      date: picklist.picklist_date,
      status: picklist.status,
    };
  }

  async remove(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();

    // Fetch item ids
    const { data: items } = await client
      .from('picklist_items')
      .select('id')
      .eq('picklist_id', id);

    const itemIds = (items || []).map((i: any) => i.id);

    // Delete batch allocations
    if (itemIds.length > 0) {
      await client
        .from('picklist_batch_allocation')
        .delete()
        .in('picklist_item_id', itemIds);
    }

    // Delete items
    await client
      .from('picklist_items')
      .delete()
      .eq('picklist_id', id);

    // Delete master
    const { data, error } = await client
      .from('picklist_master')
      .delete()
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .select()
      .single();

    if (error) throw new NotFoundException('Picklist not found');
    return data;
  }

  /**
   * Returns the next auto-generated picklist number.
   * Looks for the highest PL-XXXXX in the entity's picklist_master,
   * and returns the next sequential number.
   */
  async getNextNumber(tenant: TenantContext) {
    const client = this.supabaseService.getClient();

    const { data, error } = await client
      .from('picklist_master')
      .select('picklist_no')
      .eq('entity_id', tenant.entityId)
      .like('picklist_no', 'PL-%');

    if (error) {
      this.logger.error(`Error fetching next number: ${error.message}`);
      return { next_number: 1, prefix: 'PL-', formatted: 'PL-00001' };
    }

    let maxNumber = 0;
    for (const row of data || []) {
      const match = (row.picklist_no as string).match(/^PL-(\d+)$/);
      if (match) {
        const num = parseInt(match[1], 10);
        if (num > maxNumber) maxNumber = num;
      }
    }

    const nextNum = maxNumber + 1;
    return {
      next_number: nextNum,
      prefix: 'PL-',
      formatted: `PL-${String(nextNum).padStart(5, '0')}`,
    };
  }

  async getWarehouseItems(
    warehouseId: string,
    tenant: TenantContext,
    page: number = 1,
    limit: number = 100,
    search?: string,
    customerId?: string,
    productId?: string,
    salesOrderId?: string,
    sortBy?: string,
    sortOrder?: string,
  ) {
    try {
      this.logger.log(`Fetching items for warehouse: ${warehouseId} (Page: ${page}, Limit: ${limit})`);

      const client = this.supabaseService.getClient();

      // Source of truth for popup rows: sales_order_items filtered by selected warehouse.
      let query = client
        .from('sales_order_items')
        .select(`
          id,
          product_id,
          sales_order_id,
          quantity,
          free_quantity,
          warehouse_id,
          sales_orders!inner(
            id,
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
        `, { count: 'exact' })
        .eq('warehouse_id', warehouseId)
        .eq('entity_id', tenant.entityId);

      // Apply Filters (support comma-separated IDs for multi-select)
      if (customerId) {
        const ids = customerId.split(',').map(id => id.trim()).filter(Boolean);
        if (ids.length > 0) {
          query = query.in('sales_orders.customer_id', ids);
        }
      }
      if (productId) {
        const ids = productId.split(',').map(id => id.trim()).filter(Boolean);
        if (ids.length > 0) {
          query = query.in('product_id', ids);
        }
      }
      if (salesOrderId) {
        const ids = salesOrderId.split(',').map(id => id.trim()).filter(Boolean);
        if (ids.length > 0) {
          query = query.in('sales_order_id', ids);
        }
      }

      // Apply Search
      if (search) {
        query = query.or(`products.product_name.ilike.%${search}%,products.sku.ilike.%${search}%,sales_orders.sale_number.ilike.%${search}%`);
      }

      const ascending = (sortOrder ?? 'desc') === 'asc';
      if (sortBy === 'salesOrder') {
        query = query.order('sale_number', { referencedTable: 'sales_orders', ascending });
      } else {
        query = query.order('created_at', { referencedTable: 'sales_orders', ascending: false });
      }

      // Apply Pagination
      const { data: orderItems, count, error } = await query
        .range((page - 1) * limit, page * limit - 1)
        .order('id', { ascending: false });

      if (error) {
        this.logger.error(`sales_order_items query error: ${error.message}`);
        throw error;
      }

      const items = orderItems ?? [];
      this.logger.log(`Loaded ${items.length} sales_order_items rows for warehouse ${warehouseId}`);

      return {
        data: items.map((item: any) => ({
          id: item.id || '',
          warehouseId: item.warehouse_id || warehouseId,
          productId: item.product_id || '',
          salesOrderId: item.sales_order_id || '',
          salesOrderLineId: item.id || '',
          customerId: item.sales_orders?.customer_id || '',
          productCode: item.products?.sku || '',
          productName: item.products?.product_name || '',
          currentStock: 0,
          quantityOnHand: 0,
          availableQuantity:
              (Number(item.quantity) || 0),
          quantityToPick:
              (Number(item.quantity) || 0),
          quantityOrdered:
              (Number(item.quantity) || 0),
          orderNumber: item.sales_orders?.sale_number || '',
          customerName: item.sales_orders?.customers?.display_name || 'Walk-in Customer',
          preferredBin: item.products?.storage_conditions?.location_name || 'N/A',
          unit: item.products?.units?.unit_name || item.products?.unit_id || '',
        })),
        meta: {
          page,
          limit,
          total: count || 0,
        },
        total: count || 0,
        success: true,
      };
    } catch (error) {
      this.logger.error(
        `Error fetching warehouse items for ${warehouseId}: ${error instanceof Error ? error.stack : String(error)}`
      );
      return {
        data: [],
        meta: {
          page,
          limit,
          total: 0,
        },
        total: 0,
        success: false,
        message: 'Failed to fetch warehouse items from transactions',
      };
    }
  }

  /**
   * Returns bin_code values from bin_master for a given warehouse.
   * Used by the batch popup dropdown.
   */
  async getWarehouseBins(
    warehouseId: string,
    tenant: TenantContext,
    search?: string,
  ) {
    try {
      const client = this.supabaseService.getClient();

      let query = client
        .from('bin_master')
        .select('id, bin_code, is_active')
        .eq('warehouse_id', warehouseId)
        .eq('entity_id', tenant.entityId)
        .eq('is_active', true)
        .order('bin_code', { ascending: true });

      if (search) {
        query = query.ilike('bin_code', `%${search}%`);
      }

      const { data, error } = await query.limit(200);

      if (error) {
        this.logger.error(`bin_master query error: ${error.message}`);
        throw error;
      }

      return {
        data: (data ?? []).map((bin: any) => ({
          id: bin.id,
          binCode: bin.bin_code,
        })),
        success: true,
      };
    } catch (error) {
      this.logger.error(
        `Error fetching bins for warehouse ${warehouseId}: ${error instanceof Error ? error.message : String(error)}`
      );
      return { data: [], success: false };
    }
  }
}
