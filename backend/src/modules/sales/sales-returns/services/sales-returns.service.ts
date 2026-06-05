import { Injectable, NotFoundException } from '@nestjs/common';
import { TenantContext } from '../../../../common/middleware/tenant.middleware';
import { SupabaseService } from '../../../supabase/supabase.service';
import { CreateSalesReturnDto } from '../dto/create-sales-return.dto';
import { UpdateSalesReturnDto } from '../dto/update-sales-return.dto';
import { CreateSalesReturnReceiveDto } from '../dto/create-sales-return-receive.dto';

@Injectable()
export class SalesReturnsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private escapeRegExp(value: string) {
    return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  private async getNextRmaNumber(tenant: TenantContext, prefix = 'RMA-') {
    const safePrefix = prefix || 'RMA-';
    const regexPattern = `^${this.escapeRegExp(safePrefix)}[0-9]+$`;

    const { data, error } = await this.supabaseService
      .getClient()
      .from('sales_returns')
      .select('rma_number')
      .eq('entity_id', tenant.entityId)
      .filter('rma_number', 'match', regexPattern)
      .order('rma_number', { ascending: false })
      .limit(1000);

    if (error) throw new Error(`Failed to generate RMA number: ${error.message}`);

    let maxNumber = 0;
    for (const row of data ?? []) {
      const match = row.rma_number.match(/(\d+)$/);
      if (match) {
        const num = parseInt(match[1], 10);
        if (num > maxNumber) maxNumber = num;
      }
    }

    return {
      prefix: safePrefix,
      nextNumber: maxNumber + 1,
      formatted: `${safePrefix}${(maxNumber + 1).toString().padStart(5, '0')}`,
    };
  }

  async getNextNumber(tenant: TenantContext, prefix?: string) {
    return this.getNextRmaNumber(tenant, prefix ?? 'RMA-');
  }

  private async insertItems(returnId: string, items: CreateSalesReturnDto['items'], tenant: TenantContext) {
    if (!items?.length) return;

    const rows = items.map((item) => ({
      sales_return_id: returnId,
      product_id: item.product_id,
      sales_invoice_item_id: item.sales_invoice_item_id ?? null,
      invoiced_qty: item.invoiced_qty ?? 0,
      already_returned_qty: item.already_returned_qty ?? 0,
      return_qty: item.return_qty ?? 0,
      receivable_qty: item.receivable_qty ?? item.return_qty ?? 0,
      credit_only_qty: item.credit_only_qty ?? 0,
      remarks: item.remarks ?? null,
    }));

    const { error } = await this.supabaseService
      .getClient()
      .from('sales_return_items')
      .insert(rows);

    if (error) throw new Error(`Failed to insert sales return items: ${error.message}`);
  }

  private async deleteReceiveCascade(receiveId: string) {
    const client = this.supabaseService.getClient();

    const { data: receiveItems, error: receiveItemsError } = await client
      .from('sales_return_receive_items')
      .select('id')
      .eq('sales_return_receive_id', receiveId);

    if (receiveItemsError) {
      throw new Error(`Failed to fetch receive items: ${receiveItemsError.message}`);
    }

    const receiveItemIds = (receiveItems ?? [])
      .map((row) => row.id as string)
      .filter((id) => !!id);

    if (receiveItemIds.length > 0) {
      const { error: batchDeleteError } = await client
        .from('sales_return_receive_batches')
        .delete()
        .in('sales_return_receive_item_id', receiveItemIds);

      if (batchDeleteError) {
        throw new Error(`Failed to delete receive batches: ${batchDeleteError.message}`);
      }
    }

    const { error: itemDeleteError } = await client
      .from('sales_return_receive_items')
      .delete()
      .eq('sales_return_receive_id', receiveId);

    if (itemDeleteError) {
      throw new Error(`Failed to delete receive items: ${itemDeleteError.message}`);
    }

    const { error: receiveDeleteError } = await client
      .from('sales_return_receives')
      .delete()
      .eq('id', receiveId);

    if (receiveDeleteError) {
      throw new Error(`Failed to delete sales return receive: ${receiveDeleteError.message}`);
    }
  }

  async findAll(tenant: TenantContext, page = 1, limit = 100, search?: string, status?: string) {
    const offset = (page - 1) * limit;

    let query = this.supabaseService
      .getClient()
      .from('sales_returns')
      .select('*, items:sales_return_items(*)', { count: 'exact' })
      .eq('entity_id', tenant.entityId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (search) {
      query = query.or(`rma_number.ilike.%${search}%,reference_number.ilike.%${search}%`);
    }
    if (status && status.toLowerCase() !== 'all') {
      query = query.eq('status', status.toLowerCase());
    }

    const { data, error, count } = await query;
    if (error) throw new Error(`Failed to fetch sales returns: ${error.message}`);

    return {
      data: data ?? [],
      meta: { total: count, page, limit, totalPages: Math.ceil((count ?? 0) / limit) },
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from('sales_returns')
      .select('*, items:sales_return_items(*)')
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .single();

    if (error) throw new NotFoundException(`Sales Return ${id} not found`);
    return data;
  }

  async create(dto: CreateSalesReturnDto, tenant: TenantContext) {
    const { items, ...headerData } = dto;

    const { data: created, error } = await this.supabaseService
      .getClient()
      .from('sales_returns')
      .insert([{ ...headerData, entity_id: tenant.entityId }])
      .select()
      .single();

    if (error) throw new Error(`Failed to create sales return: ${error.message}`);

    await this.insertItems(created.id, items, tenant);
    return { ...created, items: [] };
  }

  async update(id: string, dto: UpdateSalesReturnDto, tenant: TenantContext) {
    const { items, ...headerData } = dto;

    if (Object.keys(headerData).length > 0) {
      const { error } = await this.supabaseService
        .getClient()
        .from('sales_returns')
        .update(headerData)
        .eq('id', id)
        .eq('entity_id', tenant.entityId);

      if (error) throw new Error(`Failed to update sales return: ${error.message}`);
    }

    if (items) {
      await this.supabaseService
        .getClient()
        .from('sales_return_items')
        .delete()
        .eq('sales_return_id', id);

      await this.insertItems(id, items, tenant);
    }

    return this.findOne(id, tenant);
  }

  async createReceive(salesReturnId: string, dto: CreateSalesReturnReceiveDto, tenant: TenantContext) {
    const hasBatches = (dto.items ?? []).some((item) => (item.batches?.length ?? 0) > 0);
    if (hasBatches && !dto.warehouse_id) {
      throw new Error('Warehouse is required to save receive batches.');
    }

    const { data: existing } = await this.supabaseService
      .getClient()
      .from('sales_return_receives')
      .select('id')
      .eq('sales_return_id', salesReturnId)
      .eq('entity_id', tenant.entityId);

    const receiveCount = (existing?.length ?? 0) + 1;
    const receiveNumber = `RR-${receiveCount.toString().padStart(5, '0')}`;

    const { data: receive, error } = await this.supabaseService
      .getClient()
      .from('sales_return_receives')
      .insert([{
        sales_return_id: salesReturnId,
        entity_id: tenant.entityId,
        receive_number: receiveNumber,
        receive_date: dto.receive_date,
        warehouse_id: dto.warehouse_id ?? null,
        notes: dto.notes ?? null,
        status: 'received',
      }])
      .select()
      .single();

    if (error) throw new Error(`Failed to create receive: ${error.message}`);

    const client = this.supabaseService.getClient();
    const receiveItemRecords: Array<{
      id: string;
      product_id: string;
      batches?: CreateSalesReturnReceiveDto['items'][number]['batches'];
    }> = [];

    for (const item of dto.items ?? []) {
      const { data: receiveItem, error: itemError } = await client
        .from('sales_return_receive_items')
        .insert([{
          sales_return_receive_id: receive.id,
          product_id: item.product_id,
          sales_return_item_id: item.sales_return_item_id ?? null,
          receiving_qty: item.receiving_qty,
          return_qty: item.return_qty ?? 0,
          already_received_qty: item.already_received_qty ?? 0,
          remarks: item.remarks ?? null,
        }])
        .select('id, product_id')
        .single();

      if (itemError) {
        throw new Error(`Failed to insert receive items: ${itemError.message}`);
      }

      receiveItemRecords.push({
        id: receiveItem.id,
        product_id: receiveItem.product_id,
        batches: item.batches,
      });
    }

    for (const [index, record] of receiveItemRecords.entries()) {
      const batches = dto.items?.[index]?.batches ?? [];
      if (!batches.length) continue;

      const batchRows = batches.map((batch) => ({
        sales_return_receive_item_id: record.id,
        batch_id: batch.batch_id,
        layer_id: batch.layer_id ?? null,
        warehouse_id: batch.warehouse_id ?? dto.warehouse_id ?? null,
        bin_id: batch.bin_id,
        quantity: batch.quantity,
        foc_quantity: batch.foc_quantity ?? 0,
        purchase_rate: batch.purchase_rate ?? null,
        mrp: batch.mrp ?? null,
        expiry_date: batch.expiry_date ?? null,
        manufacture_date: batch.manufacture_date ?? null,
        manufacture_batch_no: batch.manufacture_batch_no ?? null,
      }));

      const { error: batchError } = await client
        .from('sales_return_receive_batches')
        .insert(batchRows);

      if (batchError) {
        throw new Error(`Failed to insert receive batches: ${batchError.message}`);
      }
    }

    // Mark the parent sales return as received
    await client
      .from('sales_returns')
      .update({ status: 'received' })
      .eq('id', salesReturnId)
      .eq('entity_id', tenant.entityId);

    return { ...receive, items: dto.items ?? [] };
  }

  async getReceives(salesReturnId: string, tenant: TenantContext) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from('sales_return_receives')
      .select('*, items:sales_return_receive_items(*)')
      .eq('sales_return_id', salesReturnId)
      .eq('entity_id', tenant.entityId)
      .order('created_at', { ascending: false });

    if (error) throw new Error(`Failed to fetch receives: ${error.message}`);
    return data ?? [];
  }

  async remove(id: string, tenant: TenantContext) {
    const { data: receives, error: receiveFetchError } = await this.supabaseService
      .getClient()
      .from('sales_return_receives')
      .select('id')
      .eq('sales_return_id', id)
      .eq('entity_id', tenant.entityId);

    if (receiveFetchError) {
      throw new Error(`Failed to fetch sales return receives: ${receiveFetchError.message}`);
    }

    for (const receive of receives ?? []) {
      await this.deleteReceiveCascade(receive.id as string);
    }

    await this.supabaseService
      .getClient()
      .from('sales_return_items')
      .delete()
      .eq('sales_return_id', id);

    const { error } = await this.supabaseService
      .getClient()
      .from('sales_returns')
      .delete()
      .eq('id', id)
      .eq('entity_id', tenant.entityId);

    if (error) throw new Error(`Failed to delete sales return: ${error.message}`);
    return { message: 'Sales return deleted successfully' };
  }

  async removeReceive(salesReturnId: string, receiveId: string, tenant: TenantContext) {
    const { data: receive, error } = await this.supabaseService
      .getClient()
      .from('sales_return_receives')
      .select('id, sales_return_id')
      .eq('id', receiveId)
      .eq('sales_return_id', salesReturnId)
      .eq('entity_id', tenant.entityId)
      .single();

    if (error || !receive) {
      throw new NotFoundException(`Sales Return Receive ${receiveId} not found`);
    }

    await this.deleteReceiveCascade(receiveId);

    const { data: remainingReceives, error: remainingError } = await this.supabaseService
      .getClient()
      .from('sales_return_receives')
      .select('id')
      .eq('sales_return_id', salesReturnId)
      .eq('entity_id', tenant.entityId);

    if (remainingError) {
      throw new Error(`Failed to refresh sales return receives: ${remainingError.message}`);
    }

    if ((remainingReceives ?? []).length === 0) {
      await this.supabaseService
        .getClient()
        .from('sales_returns')
        .update({ status: 'approved' })
        .eq('id', salesReturnId)
        .eq('entity_id', tenant.entityId);
    }

    return { message: 'Sales return receive deleted successfully' };
  }
}
