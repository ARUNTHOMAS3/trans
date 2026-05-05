import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { TenantContext } from '../../../common/middleware/tenant.middleware';
import { SupabaseService } from '../../supabase/supabase.service';
import { SequencesService } from '../../../sequences/sequences.service';

@Injectable()
export class PackagesService {
  private readonly logger = new Logger(PackagesService.name);

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly sequencesService: SequencesService,
  ) { }

  async findAll(
    tenant: TenantContext,
    page: number,
    limit: number,
    search?: string,
    status?: string,
  ) {
    const client = this.supabaseService.getClient();
    let query = client
      .from('inventory_packages')
      .select('*', { count: 'exact' })
      .eq('entity_id', tenant.entityId)
      .eq('is_delete', false);

    if (status) {
      query = query.eq('status', status);
    }

    if (search) {
      query = query.or(`package_number.ilike.%${search}%,notes.ilike.%${search}%`);
    }

    const { data, count, error } = await query
      .range((page - 1) * limit, page * limit - 1)
      .order('created_at', { ascending: false });

    if (error) throw error;

    const rows = data || [];

    // Resolve SO and Picklist numbers
    const allPkgIds = rows.map((r: any) => r.id);
    const { data: itemRefs } = await client
      .from('inventory_package_items')
      .select('package_id, sales_order_id, picklist_id')
      .in('package_id', allPkgIds);

    const allSoIds = [...new Set((itemRefs || []).map((r: any) => r.sales_order_id).filter(Boolean))] as string[];
    const allPlIds = [...new Set((itemRefs || []).map((r: any) => r.picklist_id).filter(Boolean))] as string[];

    let soMap = new Map<string, string>();
    if (allSoIds.length > 0) {
      const { data: sos } = await client.from('sales_orders').select('id, sale_number').in('id', allSoIds);
      soMap = new Map((sos || []).map((s: any) => [s.id, s.sale_number]));
    }

    let plMap = new Map<string, string>();
    if (allPlIds.length > 0) {
      const { data: pls } = await client.from('picklist_master').select('id, picklist_no').in('id', allPlIds);
      plMap = new Map((pls || []).map((p: any) => [p.id, p.picklist_no]));
    }

    const pkgSoNumbers = new Map<string, string[]>();
    (itemRefs || []).forEach((ref: any) => {
      const num = soMap.get(ref.sales_order_id);
      if (num) {
        const existing = pkgSoNumbers.get(ref.package_id) || [];
        if (!existing.includes(num)) {
          pkgSoNumbers.set(ref.package_id, [...existing, num]);
        }
      }
    });

    const pkgPlNumbers = new Map<string, string[]>();
    (itemRefs || []).forEach((ref: any) => {
      const num = plMap.get(ref.picklist_id);
      if (num) {
        const existing = pkgPlNumbers.get(ref.package_id) || [];
        if (!existing.includes(num)) {
          pkgPlNumbers.set(ref.package_id, [...existing, num]);
        }
      }
    });

    // Resolve customer names
    const customerIds = [...new Set(rows.map((r: any) => r.customer_id).filter(Boolean))] as string[];
    let customerMap = new Map<string, string>();
    if (customerIds.length > 0) {
      const { data: customers } = await client
        .from('customers')
        .select('id, display_name')
        .in('id', customerIds);
      customerMap = new Map((customers || []).map((c: any) => [c.id, c.display_name]));
    }

    return {
      data: rows.map((row: any) => ({
        id: row.id,
        package_number: row.package_number,
        package_date: row.package_date,
        customer_id: row.customer_id,
        customer_name: customerMap.get(row.customer_id) || null,
        status: row.status,
        notes: row.notes,
        dimension_length: row.dimension_length,
        dimension_width: row.dimension_width,
        dimension_height: row.dimension_height,
        dimension_unit: row.dimension_unit,
        weight: row.weight,
        weight_unit: row.weight_unit,
        sales_order_numbers: pkgSoNumbers.get(row.id) || [],
        picklist_numbers: pkgPlNumbers.get(row.id) || [],
      })),
      total: count || 0,
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();

    // 1. Fetch package root
    const { data: pkg, error: pkgError } = await client
      .from('inventory_packages')
      .select('*')
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .single();

    if (pkgError || !pkg) {
      this.logger.error(`Package not found: ${id}. Error: ${pkgError?.message}`);
      throw new NotFoundException('Package not found');
    }

    // Resolve customer name
    let customerName = null;
    if (pkg.customer_id) {
      const { data: cust } = await client.from('customers').select('display_name').eq('id', pkg.customer_id).maybeSingle();
      customerName = cust?.display_name || null;
    }

    // 2. Fetch items
    const { data: rawItems, error: itemsError } = await client
      .from('inventory_package_items')
      .select('*')
      .eq('package_id', id);

    if (itemsError) {
      this.logger.error(`Error fetching package items: ${itemsError.message}`);
    }

    const items = rawItems || [];

    // Resolve metadata for items
    const productIds = [...new Set(items.map((i: any) => i.product_id).filter(Boolean))] as string[];
    const soIdsFromItems = [...new Set(items.map((i: any) => i.sales_order_id).filter(Boolean))] as string[];
    const plIdsFromItems = [...new Set(items.map((i: any) => i.picklist_id).filter(Boolean))] as string[];

    let productMap = new Map<string, string>();
    if (productIds.length > 0) {
      const { data: products } = await client.from('products').select('id, product_name').in('id', productIds);
      productMap = new Map((products || []).map((p: any) => [p.id, p.product_name]));
    }

    let soMap = new Map<string, string>();
    if (soIdsFromItems.length > 0) {
      const { data: sos } = await client.from('sales_orders').select('id, sale_number').in('id', soIdsFromItems);
      soMap = new Map((sos || []).map((s: any) => [s.id, s.sale_number]));
    }

    let plMap = new Map<string, string>();
    if (plIdsFromItems.length > 0) {
      const { data: pls } = await client.from('picklist_master').select('id, picklist_no').in('id', plIdsFromItems);
      plMap = new Map((pls || []).map((p: any) => [p.id, p.picklist_no]));
    }

    // 3. Fetch sales order associations from join table
    const { data: soRefs, error: soRefsError } = await client
      .from('inventory_package_sales_orders')
      .select('sales_order_id, bin_location, batch_no, sales_order:sales_orders(sale_number)')
      .eq('package_id', id);

    if (soRefsError) {
      this.logger.error(`Error fetching SO refs: ${soRefsError.message}`);
    }

    // 4. Aggregate IDs and Numbers
    const itemSoIds = items.map((i: any) => i.sales_order_id).filter(Boolean);
    const joinSoIds = (soRefs || []).map((r: any) => r.sales_order_id).filter(Boolean);
    const sales_order_ids = [...new Set([...itemSoIds, ...joinSoIds])] as string[];

    const itemSoNums = items.map((i: any) => soMap.get(i.sales_order_id)).filter(Boolean);
    const joinSoNums = (soRefs || []).map((r: any) => r.sales_order?.sale_number).filter(Boolean);
    const sales_order_numbers = [...new Set([...itemSoNums, ...joinSoNums])] as string[];

    const picklist_ids = [...new Set(items.map((i: any) => i.picklist_id).filter(Boolean))] as string[];
    const picklist_numbers = [...new Set(items.map((i: any) => plMap.get(i.picklist_id)).filter(Boolean))] as string[];

    return {
      ...pkg,
      customer_name: customerName,
      items: items.map((item: any) => ({
        ...item,
        item_name: productMap.get(item.product_id) || null,
        sales_order_number: soMap.get(item.sales_order_id) || null,
        picklist_number: plMap.get(item.picklist_id) || null,
      })),
      sales_order_ids,
      picklist_ids,
      sales_order_numbers,
      picklist_numbers,
      sales_order_refs: (soRefs || []).map((r: any) => ({
        sales_order_id: r.sales_order_id,
        sale_number: r.sales_order?.sale_number,
        bin_location: r.bin_location,
        batch_no: r.batch_no,
      })),
    };
  }

  async create(createDto: any, tenant: TenantContext, userId: string) {
    const client = this.supabaseService.getClient();
    const { items, sales_order_ids, picklist_ids, ...packageData } = createDto;

    const generatedNumber = await this.generatePackageNumber(tenant);

    const { data: newPkg, error: pkgError } = await client
      .from('inventory_packages')
      .insert({
        ...packageData,
        package_number: packageData.package_number || generatedNumber,
        entity_id: tenant.entityId,
        created_by: userId,
        is_delete: false,
      })
      .select()
      .single();

    if (pkgError) throw pkgError;

    const usedNumber = packageData.package_number || generatedNumber;
    await this.sequencesService.incrementSequence('inventory_packages', tenant, usedNumber);

    if (items && items.length > 0) {
      const itemsToInsert = items.map((item: any) => ({
        ...item,
        package_id: newPkg.id,
        entity_id: tenant.entityId,
      }));

      const { error: itemsError } = await client
        .from('inventory_package_items')
        .insert(itemsToInsert);

      if (itemsError) {
        this.logger.error(`Error inserting package items: ${itemsError.message}`);
        throw new Error(`Failed to save package items: ${itemsError.message}`);
      }
    }

    if (sales_order_ids && sales_order_ids.length > 0) {
      const soRefsToInsert = sales_order_ids.map((so: any) => {
        const isObject = typeof so === 'object';
        return {
          package_id: newPkg.id,
          sales_order_id: isObject ? so.sales_order_id : so,
          entity_id: tenant.entityId,
          bin_location: isObject ? so.bin_location : null,
          batch_no: isObject ? so.batch_no : null,
        };
      });

      const { error: soRefsError } = await client
        .from('inventory_package_sales_orders')
        .insert(soRefsToInsert);

      if (soRefsError) {
        this.logger.error(`Error inserting SO refs: ${soRefsError.message}`);
        throw new Error(`Failed to save sales order references: ${soRefsError.message}`);
      }
    }



    return this.findOne(newPkg.id, tenant);
  }

  async update(id: string, updateDto: any, tenant: TenantContext) {
    const client = this.supabaseService.getClient();

    const { items, sales_order_ids, picklist_ids, ...packageData } = updateDto;

    const { data: pkg, error: pkgError } = await client
      .from('inventory_packages')
      .update({
        ...packageData,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .select()
      .single();

    if (pkgError) throw pkgError;

    // Handle items updates
    if (items !== undefined) {
      // 1. Remove existing items
      await client.from('inventory_package_items').delete().eq('package_id', id);

      // 2. Insert new items
      if (items.length > 0) {
        const itemsToInsert = items.map((item: any) => ({
          ...item,
          package_id: id,
          entity_id: tenant.entityId,
        }));
        const { error: itemsError } = await client.from('inventory_package_items').insert(itemsToInsert);
        if (itemsError) throw itemsError;
      }
    }

    // Handle Sales Order associations
    if (sales_order_ids !== undefined) {
      // 1. Remove existing refs
      await client.from('inventory_package_sales_orders').delete().eq('package_id', id);

      // 2. Insert new refs
      if (sales_order_ids && sales_order_ids.length > 0) {
        const refsToInsert = sales_order_ids.map((so: any) => {
          const isObject = typeof so === 'object';
          return {
            package_id: id,
            sales_order_id: isObject ? so.sales_order_id : so,
            entity_id: tenant.entityId,
            bin_location: isObject ? so.bin_location : null,
            batch_no: isObject ? so.batch_no : null,
          };
        });
        const { error: soRefsError } = await client.from('inventory_package_sales_orders').insert(refsToInsert);
        if (soRefsError) throw soRefsError;
      }
    }

    return this.findOne(id, tenant);
  }

  async getNextNumber(tenant: TenantContext) {
    try {
      const formatted = await this.generatePackageNumber(tenant);
      const next_number = parseInt(formatted.split('-')[1], 10);

      return {
        next_number: next_number,
        prefix: 'PKG-',
        formatted: formatted,
      };
    } catch (e) {
      this.logger.error(`Error fetching next package number: ${e.message}`);
      return { next_number: 1, prefix: 'PKG-', formatted: 'PKG-00001' };
    }
  }

  /**
   * Generates a unique package number following the rules:
   * 1. Smallest missing positive number starting from 1.
   * 2. Format: PKG-XXXXX (5 digits, zero-padded).
   * 3. Loop until a truly unique number is found in the DB.
   */
  private async generatePackageNumber(tenant: TenantContext): Promise<string> {
    const client = this.supabaseService.getClient();

    // 1. Fetch all existing package numbers starting with 'PKG-'
    const { data: existingPackages, error } = await client
      .from('inventory_packages')
      .select('package_number')
      .eq('entity_id', tenant.entityId)
      .like('package_number', 'PKG-%');

    if (error) {
      this.logger.error(`Error fetching existing package numbers: ${error.message}`);
      throw error;
    }

    // 2. Extract numeric parts and 3. Sort them
    const existingNumbers = (existingPackages || [])
      .map((pkg: any) => {
        const match = pkg.package_number.match(/PKG-(\d+)/);
        return match ? parseInt(match[1], 10) : null;
      })
      .filter((num: any) => num !== null)
      .sort((a: number, b: number) => a - b);

    // 4. Find the smallest missing positive number
    let nextNum = 1;
    for (const num of existingNumbers) {
      if (num === nextNum) {
        nextNum++;
      } else if (num > nextNum) {
        break; // Found a gap
      }
    }

    // 5. Format and 6. Double-check uniqueness in a loop
    let isUnique = false;
    let formattedNumber = '';

    while (!isUnique) {
      formattedNumber = `PKG-${nextNum.toString().padStart(5, '0')}`;
      
      const { data: duplicate, error: dupError } = await client
        .from('inventory_packages')
        .select('id')
        .eq('entity_id', tenant.entityId)
        .eq('package_number', formattedNumber)
        .maybeSingle();

      if (dupError) {
        this.logger.error(`Error checking duplicate package number: ${dupError.message}`);
        throw dupError;
      }

      if (!duplicate) {
        isUnique = true;
      } else {
        nextNum++; // Increment and try again
      }
    }

    return formattedNumber;
  }

  async remove(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();

    const { error } = await client
      .from('inventory_packages')
      .update({ is_delete: true })
      .eq('id', id)
      .eq('entity_id', tenant.entityId);

    if (error) throw error;
  }
}
