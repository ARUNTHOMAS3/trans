import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { TenantContext } from '../../../../common/middleware/tenant.middleware';
import { SupabaseService } from '../../../supabase/supabase.service';
import { CreateSalesReturnDto } from '../dto/create-sales-return.dto';
import { UpdateSalesReturnDto } from '../dto/update-sales-return.dto';
import { CreateSalesReturnReceiveDto } from '../dto/create-sales-return-receive.dto';
import { WarehousesSettingsService } from '../../../warehouses-settings/warehouses-settings.service';

@Injectable()
export class SalesReturnsService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly warehousesSettingsService: WarehousesSettingsService,
  ) {}

  async getWarehouses(tenant: TenantContext) {
    const data = await this.warehousesSettingsService.findAll(tenant);
    return { data };
  }

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

  private async getNextReceiveNumber(tenant: TenantContext, prefix = 'RR-') {
    const safePrefix = prefix || 'RR-';
    const regexPattern = `^${this.escapeRegExp(safePrefix)}[0-9]+$`;

    const { data, error } = await this.supabaseService
      .getClient()
      .from('sales_return_receives')
      .select('receive_number')
      .eq('entity_id', tenant.entityId)
      .filter('receive_number', 'match', regexPattern)
      .order('receive_number', { ascending: false })
      .limit(1000);

    if (error) throw new Error(`Failed to generate receive number: ${error.message}`);

    let maxNumber = 0;
    for (const row of data ?? []) {
      const match = row.receive_number.match(/(\d+)$/);
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

    const { data: oldLedger } = await client
      .from('batch_transactions')
      .select('layer_id, qty_in')
      .eq('ref_id', receiveId)
      .eq('trans_type', 'SALES_RETURN_RECEIVES');

    if (oldLedger && oldLedger.length > 0) {
      for (const tx of oldLedger) {
        if (!tx.layer_id) continue;
        const { data: currentLayer } = await client
          .from('batch_stock_layers')
          .select('qty')
          .eq('id', tx.layer_id)
          .single();
        if (currentLayer) {
          const newQty = Math.max(0, (Number(currentLayer.qty) || 0) - Number(tx.qty_in));
          await client
            .from('batch_stock_layers')
            .update({ qty: newQty, updated_at: new Date().toISOString() })
            .eq('id', tx.layer_id);
        }
      }

      const { error: ledgerError } = await client
        .from('batch_transactions')
        .delete()
        .eq('ref_id', receiveId)
        .eq('trans_type', 'SALES_RETURN_RECEIVES');
        
      if (ledgerError) {
        throw new Error(`Failed to delete receive ledger: ${ledgerError.message}`);
      }
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

    const enrichedData = await this.enrichSalesReturnItemsWithReceivedQty(data ?? []);

    return {
      data: enrichedData,
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
    const enriched = await this.enrichSalesReturnItemsWithReceivedQty([data]);
    return enriched[0];
  }

  /// Returns persisted events for this return and credit notes whose explicit
  /// SALES_RETURN source link belongs to the authenticated tenant.
  async getHistory(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const { data: salesReturn, error: salesReturnError } = await client
      .from('sales_returns')
      .select('id, rma_number, created_at, approved_at, status')
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .maybeSingle();

    if (salesReturnError) {
      throw new Error(`Failed to load sales return history: ${salesReturnError.message}`);
    }
    if (!salesReturn) {
      throw new NotFoundException(`Sales Return ${id} not found`);
    }

    const { data: creditNotes, error: creditNotesError } = await client
      .from('credit_notes')
      .select('id, credit_note_number, created_at, status')
      .eq('entity_id', tenant.entityId)
      .eq('source_type', 'SALES_RETURN')
      .eq('source_id', id)
      .or('is_delete.is.null,is_delete.eq.false')
      .order('created_at', { ascending: false });

    if (creditNotesError) {
      throw new Error(`Failed to load related credit note history: ${creditNotesError.message}`);
    }

    const events: Array<{
      id: string;
      kind: 'sales_return' | 'credit_note';
      timestamp: string;
      message: string;
    }> = [];

    if (salesReturn.created_at) {
      events.push({
        id: `sales-return-created-${salesReturn.id}`,
        kind: 'sales_return',
        timestamp: salesReturn.created_at,
        message: `Sales Return ${salesReturn.rma_number} created.`,
      });
    }

    if (salesReturn.approved_at) {
      events.push({
        id: `sales-return-approved-${salesReturn.id}`,
        kind: 'sales_return',
        timestamp: salesReturn.approved_at,
        message: `Sales Return ${salesReturn.rma_number} approved.`,
      });
    }

    for (const creditNote of creditNotes ?? []) {
      if (!creditNote.created_at) continue;
      events.push({
        id: `credit-note-created-${creditNote.id}`,
        kind: 'credit_note',
        timestamp: creditNote.created_at,
        message: `Credit Note ${creditNote.credit_note_number} created from Sales Return ${salesReturn.rma_number}.`,
      });
    }

    events.sort((a, b) => b.timestamp.localeCompare(a.timestamp));
    return events;
  }

  private async validateReturnQuantities(
    customerId: string,
    items: CreateSalesReturnDto['items'],
    tenant: TenantContext,
    excludeReturnId?: string,
  ) {
    if (!items || items.length === 0) return;

    const history = await this.getCustomerItemHistory(
      customerId,
      tenant,
      excludeReturnId,
    );

    const historyMap = new Map<string, { invoiced_qty: number; returned_qty: number }>();
    for (const h of history) {
      historyMap.set(h.product_id, {
        invoiced_qty: h.invoiced_qty,
        returned_qty: h.returned_qty,
      });
    }

    for (const item of items) {
      const hist = historyMap.get(item.product_id);
      const invoiced = hist?.invoiced_qty ?? 0;
      const returned = hist?.returned_qty ?? 0;
      const allowance = invoiced - returned;
      const requested = (item.return_qty ?? 0) + (item.credit_only_qty ?? 0);

      if (requested > allowance) {
        throw new BadRequestException(
          `Requested return quantity ${requested} exceeds the allowed limit of ${allowance < 0 ? 0 : allowance} for product ${item.product_id} (Invoiced: ${invoiced}, Already Returned: ${returned})`,
        );
      }
    }
  }

  async create(dto: CreateSalesReturnDto, tenant: TenantContext) {
    const { items, ...headerData } = dto;

    await this.validateReturnQuantities(headerData.customer_id, items, tenant);

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

    if (headerData.customer_id && items) {
      await this.validateReturnQuantities(headerData.customer_id, items, tenant, id);
    }

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

    const receiveNumberObj = await this.getNextReceiveNumber(tenant);
    const receiveNumber = receiveNumberObj.formatted;

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

      // Returned goods physically re-enter stock, so each batch has to land on
      // a stock layer. `v_physical_stock` is a view over `batch_stock_layers`,
      // so this is what makes the quantity visible there.
      for (const batch of batches) {
        await this.addReturnedStockToLayer(
          batch,
          record.product_id,
          dto.warehouse_id,
          receive.id,
          receive.receive_number,
          tenant,
        );
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

  /**
   * Adds a received batch's quantity back into `batch_stock_layers`.
   *
   * `v_physical_stock` is a view that sums `qty + foc_qty` over this table per
   * (product, entity, warehouse) — it cannot be written to directly, so this is
   * what makes returned goods show as on-hand stock.
   *
   * A layer is keyed by (batch, product, entity, warehouse, bin): an existing
   * one is incremented so repeat receives into the same bin accumulate rather
   * than fragmenting into duplicate layers. Mirrors the purchase-receive path
   * in `purchase-receives.service.ts`, differing only in `ref_type`, which is
   * stamped `SALES_RETURN_RECEIVES` so a layer traces back to the receive that
   * created it via `ref_id`.
   */
  private async addReturnedStockToLayer(
    batch: {
      batch_id?: string;
      bin_id?: string;
      warehouse_id?: string;
      quantity?: number;
      foc_quantity?: number;
      purchase_rate?: number;
      mrp?: number;
    },
    productId: string,
    headerWarehouseId: string | undefined,
    receiveId: string,
    receiveNumber: string,
    tenant: TenantContext,
  ) {
    const client = this.supabaseService.getClient();
    const warehouseId = batch.warehouse_id ?? headerWarehouseId;

    // Every one of these is NOT NULL on batch_stock_layers. Skip rather than
    // fail the whole receive — the receive rows are already persisted and are
    // the record of what came back.
    if (!batch.batch_id || !batch.bin_id || !warehouseId) {
      return;
    }

    const qty = Number(batch.quantity ?? 0);
    const focQty = Number(batch.foc_quantity ?? 0);
    if (qty === 0 && focQty === 0) return;

    const { data: existingLayer, error: getLayerError } = await client
      .from('batch_stock_layers')
      .select('id, qty, foc_qty')
      .eq('batch_id', batch.batch_id)
      .eq('product_id', productId)
      .eq('entity_id', tenant.entityId)
      .eq('warehouse_id', warehouseId)
      .eq('bin_id', batch.bin_id)
      .maybeSingle();

    if (getLayerError) {
      throw new Error(
        `Failed to query batch stock layer: ${getLayerError.message}`,
      );
    }

    let layerId: string;

    if (existingLayer) {
      const { error } = await client
        .from('batch_stock_layers')
        .update({
          qty: Number(existingLayer.qty ?? 0) + qty,
          foc_qty: Number(existingLayer.foc_qty ?? 0) + focQty,
          updated_at: new Date().toISOString(),
        })
        .eq('id', existingLayer.id);

      if (error) {
        throw new Error(`Failed to update batch stock layer: ${error.message}`);
      }
      layerId = existingLayer.id;
    } else {
      const { data: newLayer, error } = await client
        .from('batch_stock_layers')
        .insert({
          batch_id: batch.batch_id,
          product_id: productId,
          entity_id: tenant.entityId,
          warehouse_id: warehouseId,
          bin_id: batch.bin_id,
          qty,
          foc_qty: focQty,
          purchase_rate: batch.purchase_rate ?? 0,
          mrp: batch.mrp ?? 0,
          ref_type: 'SALES_RETURN_RECEIVES',
          ref_id: receiveId,
        })
        .select('id')
        .single();

      if (error) {
        throw new Error(`Failed to insert batch stock layer: ${error.message}`);
      }
      layerId = newLayer.id;
    }

    // The layer holds the running balance; this is the movement ledger that
    // explains how the balance got there. Every other stock path writes both
    // (see purchase-receives.service.ts) — reporting reads the ledger, so a
    // layer without one is stock that appears from nowhere.
    const { error: transError } = await client
      .from('batch_transactions')
      .insert({
        batch_id: batch.batch_id,
        layer_id: layerId,
        product_id: productId,
        entity_id: tenant.entityId,
        warehouse_id: warehouseId,
        bin_id: batch.bin_id,
        trans_type: 'SALES_RETURN_RECEIVES',
        qty_in: qty + focQty,
        rate: batch.purchase_rate ?? 0,
        ref_id: receiveId,
        ref_no: receiveNumber,
      });

    if (transError) {
      throw new Error(
        `Failed to create batch transaction: ${transError.message}`,
      );
    }
  }

  async getReceives(salesReturnId: string, tenant: TenantContext) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from('sales_return_receives')
      .select('*, items:sales_return_receive_items(*, batches:sales_return_receive_batches(*, batch:batch_master(batch_no)))')
      .eq('sales_return_id', salesReturnId)
      .eq('entity_id', tenant.entityId)
      .order('created_at', { ascending: false });

    if (error) throw new Error(`Failed to fetch receives: ${error.message}`);
    return data ?? [];
  }

  /**
   * Per-product history for one customer: how much has been invoiced to them,
   * and how much they have already returned. Drives the INVOICED / RETURNED
   * columns on the sales return form.
   *
   * Both sides are aggregated in two steps rather than a join, because
   * PostgREST cannot group across an embedded resource.
   */
  async getCustomerItemHistory(
    customerId: string,
    tenant: TenantContext,
    excludeReturnId?: string,
  ) {
    const client = this.supabaseService.getClient();
    const entityId = tenant.entityId;

    const invoicedByProduct = new Map<string, number>();
    const returnedByProduct = new Map<string, number>();

    const addTo = (map: Map<string, number>, key: unknown, value: unknown) => {
      const productId = typeof key === 'string' ? key : '';
      if (!productId) return;
      const qty = Number(value ?? 0);
      map.set(productId, (map.get(productId) ?? 0) + (isNaN(qty) ? 0 : qty));
    };

    // ── Invoiced ────────────────────────────────────────────────────────────
    const { data: invoices, error: invoiceError } = await client
      .from('invoice_master')
      .select('id')
      .eq('customer_id', customerId)
      .eq('entity_id', entityId)
      .or('is_delete.is.null,is_delete.eq.false');

    if (invoiceError) {
      throw new Error(`Failed to load customer invoices: ${invoiceError.message}`);
    }

    const invoiceIds = (invoices ?? []).map((row) => row.id as string);
    if (invoiceIds.length > 0) {
      const { data: invoiceItems, error: invoiceItemsError } = await client
        .from('invoice_items')
        .select('product_id, quantity')
        .in('invoice_id', invoiceIds);

      if (invoiceItemsError) {
        throw new Error(
          `Failed to load invoiced quantities: ${invoiceItemsError.message}`,
        );
      }
      for (const row of invoiceItems ?? []) {
        addTo(invoicedByProduct, row.product_id, row.quantity);
      }
    }

    // ── Already returned ────────────────────────────────────────────────────
    // A declined return never brought goods back, so it must not count
    // against what the customer can still return.
    let returnsQuery = client
      .from('sales_returns')
      .select('id')
      .eq('customer_id', customerId)
      .eq('entity_id', entityId)
      .neq('status', 'declined');

    // When editing, the document's own lines are already stored. Counting
    // them would report the quantity being entered as already returned.
    if (excludeReturnId) {
      returnsQuery = returnsQuery.neq('id', excludeReturnId);
    }

    const { data: returns, error: returnError } = await returnsQuery;

    if (returnError) {
      throw new Error(`Failed to load customer returns: ${returnError.message}`);
    }

    const returnIds = (returns ?? []).map((row) => row.id as string);
    if (returnIds.length > 0) {
      const { data: returnItems, error: returnItemsError } = await client
        .from('sales_return_items')
        .select('product_id, return_qty')
        .in('sales_return_id', returnIds);

      if (returnItemsError) {
        throw new Error(
          `Failed to load returned quantities: ${returnItemsError.message}`,
        );
      }
      for (const row of returnItems ?? []) {
        addTo(returnedByProduct, row.product_id, row.return_qty);
      }
    }

    const productIds = new Set([
      ...invoicedByProduct.keys(),
      ...returnedByProduct.keys(),
    ]);

    return [...productIds].map((productId) => ({
      product_id: productId,
      invoiced_qty: invoicedByProduct.get(productId) ?? 0,
      returned_qty: returnedByProduct.get(productId) ?? 0,
    }));
  }

  // Moves a return along its workflow (draft -> approved -> received).
  async updateStatus(id: string, status: string, tenant: TenantContext) {
    const normalizedStatus = status.trim().toLowerCase();

    const updatePayload: Record<string, unknown> = {
      status: normalizedStatus,
      updated_at: new Date().toISOString(),
    };

    // Who approved it, and when — the columns exist only for this transition.
    if (normalizedStatus === 'approved') {
      updatePayload.approved_by = tenant.userId || null;
      updatePayload.approved_at = new Date().toISOString();
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from('sales_returns')
      .update(updatePayload)
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .select('*, items:sales_return_items(*)')
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to update sales return status: ${error.message}`);
    }
    if (!data) {
      throw new NotFoundException(`Sales Return ${id} not found`);
    }

    const enriched = await this.enrichSalesReturnItemsWithReceivedQty([data]);
    return enriched[0];
  }

  async remove(id: string, tenant: TenantContext) {
    // Confirm the return belongs to this tenant before deleting anything. The
    // child deletes below key off sales_return_id alone, so without this check
    // an id from another org would have its items and receives removed even
    // though the header delete would then match nothing.
    const { data: owned, error: ownerError } = await this.supabaseService
      .getClient()
      .from('sales_returns')
      .select('id')
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .maybeSingle();

    if (ownerError) {
      throw new Error(`Failed to load sales return: ${ownerError.message}`);
    }
    if (!owned) {
      throw new NotFoundException(`Sales Return ${id} not found`);
    }

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

  private async enrichSalesReturnItemsWithReceivedQty(salesReturns: any[]) {
    if (!salesReturns || salesReturns.length === 0) return salesReturns;

    const allItems = salesReturns.flatMap((sr) => sr.items ?? []);
    if (allItems.length === 0) return salesReturns;

    const allItemIds = allItems.map((item) => item.id).filter(Boolean);
    if (allItemIds.length === 0) return salesReturns;

    const { data: receiveItems, error } = await this.supabaseService
      .getClient()
      .from('sales_return_receive_items')
      .select('sales_return_item_id, receiving_qty')
      .in('sales_return_item_id', allItemIds);

    if (error) {
      // Log error but don't crash, default to 0
      console.error('Failed to fetch receive items for enrichment:', error.message);
    }

    // Map sales_return_item_id -> sum of receiving_qty
    const receivedQtyMap = new Map<string, number>();
    for (const ri of receiveItems ?? []) {
      const itemId = ri.sales_return_item_id;
      const qty = Number(ri.receiving_qty ?? 0);
      receivedQtyMap.set(itemId, (receivedQtyMap.get(itemId) ?? 0) + qty);
    }

    for (const item of allItems) {
      item.received_qty = receivedQtyMap.get(item.id) ?? 0;
    }

    return salesReturns;
  }
}
