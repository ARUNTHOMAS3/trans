import { Injectable, HttpException, HttpStatus } from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { v4 as uuidv4 } from "uuid";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { updatePurchaseOrderStatusByOrderNumber } from "../../purchase-orders/utils/po-status";

@Injectable()
export class BillsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async createBill(entityId: string, dto: any) {
    const supabase = this.supabaseService.getClient();
    
    // 1. Create Bill
    const billId = uuidv4();
    
    const { data: billData, error: billError } = await supabase
      .from('bills')
      .insert({
        id: billId,
        entity_id: entityId,
        vendor_id: dto.vendorId,
        bill_number: dto.billNumber || `BILL-${Date.now()}`,
        order_number: dto.orderNumber,
        bill_date: dto.billDate,
        due_date: dto.dueDate,
        payment_term_id: dto.paymentTerms,
        reverse_charge_applicable: dto.isReverseCharge,
        warehouse_id: dto.warehouseId,
        price_list_id: dto.priceListId,
        subject: dto.subject,
        source_of_supply: dto.sourceOfSupply,
        destination_to_supply: dto.destinationToSupply,
        billing_address: dto.billingAddress,
        notes: dto.notes,
        subtotal: dto.subTotal?.toString(),
        discount_total: dto.discountAmount?.toString(),
        tax_total: dto.taxAmount?.toString(),
        tds_total: dto.tdsTotal?.toString(),
        tcs_total: dto.tcsTotal?.toString(),
        adjustment_amount: dto.adjustment?.toString(),
        grand_total: dto.total?.toString(),
        status: dto.status || "draft",
        is_delete: false,
      })
      .select()
      .single();

    if (billError) {
      throw new HttpException(`Failed to create bill: ${billError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    // 2. Create Items
    if (dto.lineItems && dto.lineItems.length > 0) {
      const itemsToInsert = dto.lineItems.map(item => ({
        id: uuidv4(),
        bill_id: billId,
        product_id: item.item_id,
        account_id: item.account_id,
        customer_id: item.customer_id,
        description: item.description,
        hsn_code: item.hsn_code || item.hsnCode,
        quantity: item.quantity?.toString() || "0",
        rate: item.rate?.toString() || "0",
        discount_type: item.discount_type,
        discount_amount: item.discount?.toString() || "0",
        tax_id: item.tax_id,
        tax_amount: item.tax_amount?.toString() || "0",
        line_total: item.amount?.toString() || "0",
      }));

      const { data: itemsData, error: itemsError } = await supabase
        .from('bill_items')
        .insert(itemsToInsert)
        .select();

      if (itemsError) {
        throw new HttpException(`Failed to create bill items: ${itemsError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
      }

      // 3. Create Batches (If provided)
      const batchesToInsert = [];
      for (let i = 0; i < dto.lineItems.length; i++) {
        const item = dto.lineItems[i];
        const insertedItem = itemsData[i];
        
        if (item.batches && item.batches.length > 0) {
          for (const batch of item.batches) {
            const batchNo = batch.manufacture_batch_no || batch.manufactureBatchNo || batch.batch_id || batch.batchId || `BATCH-${Date.now()}`;
            const status = (dto.status || 'draft').toLowerCase();
            const shouldUpdateStock = status !== 'draft' && status !== 'void';

            const expiryDate = batch.expiry_date || batch.expiryDate || null;
            const manufactureDate = batch.manufacture_date || batch.manufactureDate || null;
            const unitPack = batch.unit_pack || batch.unitPack || null;
            const focQty = batch.foc_quantity || batch.focQuantity || 0;
            const purchaseRate = batch.purchase_rate || batch.purchaseRate || 0;
            const mrp = batch.mrp || 0;
            const quantity = batch.quantity || 0;
            const batchIdInput = batch.batch_id || batch.batchId || null;
            const binIdInput = batch.bin_id || batch.binId || null;
            const warehouseIdInput = batch.warehouse_id || batch.warehouseId || null;

            let batchId = null;
            let layerId = null;
            let resolvedBinId = binIdInput || null;

            if (shouldUpdateStock) {
              // Step 1: Check/create batch master
              const { data: existingBatch } = await supabase
                .from("batch_master")
                .select("id")
                .eq("batch_no", batchNo)
                .eq("product_id", item.item_id)
                .maybeSingle();

              batchId = existingBatch?.id;

              if (!batchId) {
                const { data: newBatch, error: batchError } = await supabase
                  .from("batch_master")
                  .insert({
                    batch_no: batchNo,
                    product_id: item.item_id,
                    expiry_date: expiryDate || new Date(Date.now() + 365*24*60*60*1000).toISOString().split('T')[0],
                    unit_pack: unitPack,
                    manufacture_batch_number: batchNo,
                    manufacture_exp: expiryDate,
                    created_by_entity_id: entityId,
                    source_type: "BILL",
                  })
                  .select()
                  .single();

                if (batchError) {
                  throw new HttpException(`Failed to create batch master: ${batchError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
                }
                batchId = newBatch.id;
              }

              // Resolve bin
              if (!resolvedBinId) {
                const warehouseId = warehouseIdInput || dto.warehouseId || dto.warehouse_id;
                if (warehouseId) {
                  const { data: firstBin } = await supabase
                    .from("bin_master")
                    .select("id")
                    .eq("warehouse_id", warehouseId)
                    .limit(1)
                    .maybeSingle();
                  resolvedBinId = firstBin?.id;
                }
              }

              // CASE 1 vs CASE 2 check
              const isFromReceive = !!(
                (dto.sourceType || dto.source_type)?.toLowerCase() === 'purchase_receive' ||
                (dto.sourceType || dto.source_type)?.toLowerCase() === 'purchase-receive' ||
                (dto.sourceId || dto.source_id) ||
                (item.purchaseReceiveItemId || item.purchase_receive_item_id)
              );

              if (isFromReceive) {
                // CASE 1: Bill from Purchase Receive
                let query = supabase
                  .from("batch_stock_layers")
                  .select("id")
                  .eq("batch_id", batchId)
                  .eq("product_id", item.item_id)
                  .eq("entity_id", entityId);

                if (dto.sourceId || dto.source_id) {
                  query = query.eq("ref_id", dto.sourceId || dto.source_id).eq("ref_type", "PURCHASE_RECEIVE");
                }
                
                const { data: existingLayer } = await query.limit(1).maybeSingle();
                layerId = existingLayer?.id || null;
              } else {
                // CASE 2: DIRECT BILL
                const targetWarehouseId = warehouseIdInput || dto.warehouseId || dto.warehouse_id;
                const { data: existingLayer, error: getLayerError } = await supabase
                  .from("batch_stock_layers")
                  .select("*")
                  .eq("batch_id", batchId)
                  .eq("product_id", item.item_id)
                  .eq("entity_id", entityId)
                  .eq("warehouse_id", targetWarehouseId)
                  .eq("bin_id", resolvedBinId)
                  .maybeSingle();

                if (getLayerError) {
                  throw new HttpException(`Failed to query existing batch stock layer: ${getLayerError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
                }

                if (existingLayer) {
                  const { data: updatedLayer, error: updateLayerError } = await supabase
                    .from("batch_stock_layers")
                    .update({
                      qty: Number(existingLayer.qty) + Number(quantity),
                      foc_qty: Number(existingLayer.foc_qty) + Number(focQty),
                      updated_at: new Date().toISOString(),
                    })
                    .eq("id", existingLayer.id)
                    .select()
                    .single();

                  if (updateLayerError) {
                    throw new HttpException(`Failed to update batch stock layer: ${updateLayerError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
                  }
                  layerId = updatedLayer.id;
                } else {
                  const { data: layer, error: layerError } = await supabase
                    .from("batch_stock_layers")
                    .insert({
                      batch_id: batchId,
                      product_id: item.item_id,
                      entity_id: entityId,
                      warehouse_id: targetWarehouseId,
                      bin_id: resolvedBinId,
                      qty: quantity,
                      foc_qty: focQty,
                      purchase_rate: purchaseRate,
                      mrp: mrp,
                      ref_type: "BILL",
                      ref_id: billId,
                    })
                    .select()
                    .single();

                  if (layerError) {
                    throw new HttpException(`Failed to create batch stock layer: ${layerError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
                  }
                  layerId = layer.id;
                }
              }

              // Step 3: Insert into batch_transactions
              const { error: transError } = await supabase
                .from("batch_transactions")
                .insert({
                  batch_id: batchId,
                  layer_id: layerId,
                  product_id: item.item_id,
                  entity_id: entityId,
                  warehouse_id: warehouseIdInput || dto.warehouseId || dto.warehouse_id,
                  bin_id: resolvedBinId,
                  trans_type: "BILL",
                  qty_in: quantity,
                  rate: purchaseRate,
                  ref_id: billId,
                  ref_no: dto.billNumber || dto.bill_number || `BILL-${Date.now()}`,
                });

              if (transError) {
                throw new HttpException(`Failed to create batch transaction: ${transError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
              }
            }

            batchesToInsert.push({
              id: uuidv4(),
              bill_item_id: insertedItem.id,
              batch_id: batchId || batchIdInput || uuidv4(),
              layer_id: layerId,
              warehouse_id: warehouseIdInput || dto.warehouseId || dto.warehouse_id || null,
              bin_id: resolvedBinId,
              quantity: quantity?.toString() ?? '0',
              foc_quantity: focQty?.toString() ?? null,
              damage_quantity: (batch.damageQuantity || batch.damage_quantity)?.toString() ?? null,
              purchase_rate: purchaseRate?.toString() ?? null,
              mrp: mrp?.toString() ?? null,
              expiry_date: expiryDate || null,
              manufacture_date: manufactureDate || null,
              manufacture_batch_no: batchNo,
              is_direct_bill: !(
                (dto.sourceType || dto.source_type)?.toLowerCase() === 'purchase_receive' ||
                (dto.sourceType || dto.source_type)?.toLowerCase() === 'purchase-receive' ||
                (dto.sourceId || dto.source_id) ||
                (item.purchaseReceiveItemId || item.purchase_receive_item_id)
              ),
            });
          }
        }
      }

      if (batchesToInsert.length > 0) {
        const { error: batchError } = await supabase
          .from('bill_item_batches')
          .insert(batchesToInsert);
          
        if (batchError) {
          throw new HttpException(`Failed to create item batches: ${batchError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
        }
      }
    }
    
    const { data: fullBill } = await supabase
      .from('bills')
      .select(
        `
        *,
        vendor:vendors(display_name, company_name),
        warehouse:warehouses(name),
        payment_terms:payment_terms(term_name)
      `
      )
      .eq('id', billId)
      .eq('entity_id', entityId)
      .single();

    if (dto.orderNumber) {
      await updatePurchaseOrderStatusByOrderNumber(supabase, dto.orderNumber, entityId);
    }

    return fullBill || billData;
  }

  async updateBill(id: string, entityId: string, dto: any) {
    const supabase = this.supabaseService.getClient();

    const { data: billData, error: billError } = await supabase
      .from('bills')
      .update({
        vendor_id: dto.vendorId,
        bill_number: dto.billNumber,
        order_number: dto.orderNumber,
        bill_date: dto.billDate,
        due_date: dto.dueDate,
        payment_term_id: dto.paymentTerms,
        reverse_charge_applicable: dto.isReverseCharge,
        warehouse_id: dto.warehouseId,
        price_list_id: dto.priceListId,
        subject: dto.subject,
        source_of_supply: dto.sourceOfSupply,
        destination_to_supply: dto.destinationToSupply,
        billing_address: dto.billingAddress,
        notes: dto.notes,
        subtotal: dto.subTotal?.toString(),
        discount_total: dto.discountAmount?.toString(),
        tax_total: dto.taxAmount?.toString(),
        tds_total: dto.tdsTotal?.toString(),
        tcs_total: dto.tcsTotal?.toString(),
        adjustment_amount: dto.adjustment?.toString(),
        grand_total: dto.total?.toString(),
        status: dto.status || "draft",
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .eq('entity_id', entityId)
      .select()
      .single();

    if (billError) {
      throw new HttpException(`Failed to update bill: ${billError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    // Clear existing batch transactions & stock layers (only if ref_type is BILL)
    await supabase
      .from('batch_transactions')
      .delete()
      .eq('ref_id', id)
      .eq('trans_type', 'BILL')
      .eq('entity_id', entityId);

    await supabase
      .from('batch_stock_layers')
      .delete()
      .eq('ref_id', id)
      .eq('ref_type', 'BILL')
      .eq('entity_id', entityId);

    // Clear existing items (cascades to batches)
    const { error: deleteItemsError } = await supabase
      .from('bill_items')
      .delete()
      .eq('bill_id', id);

    if (deleteItemsError) {
      throw new HttpException(`Failed to clear existing bill items: ${deleteItemsError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    // Create Items
    if (dto.lineItems && dto.lineItems.length > 0) {
      const itemsToInsert = dto.lineItems.map(item => ({
        id: uuidv4(),
        bill_id: id,
        product_id: item.item_id,
        account_id: item.account_id,
        customer_id: item.customer_id,
        description: item.description,
        hsn_code: item.hsn_code || item.hsnCode,
        quantity: item.quantity?.toString() || "0",
        rate: item.rate?.toString() || "0",
        discount_type: item.discount_type,
        discount_amount: item.discount?.toString() || "0",
        tax_id: item.tax_id,
        tax_amount: item.tax_amount?.toString() || "0",
        line_total: item.amount?.toString() || "0",
      }));

      const { data: itemsData, error: itemsError } = await supabase
        .from('bill_items')
        .insert(itemsToInsert)
        .select();

      if (itemsError) {
        throw new HttpException(`Failed to create bill items: ${itemsError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
      }

      // Create Batches (If provided)
      const batchesToInsert = [];
      for (let i = 0; i < dto.lineItems.length; i++) {
        const item = dto.lineItems[i];
        const insertedItem = itemsData[i];
        
        if (item.batches && item.batches.length > 0) {
          for (const batch of item.batches) {
            const batchNo = batch.manufacture_batch_no || batch.manufactureBatchNo || batch.batch_id || batch.batchId || `BATCH-${Date.now()}`;
            const status = (dto.status || 'draft').toLowerCase();
            const shouldUpdateStock = status !== 'draft' && status !== 'void';

            const expiryDate = batch.expiry_date || batch.expiryDate || null;
            const manufactureDate = batch.manufacture_date || batch.manufactureDate || null;
            const unitPack = batch.unit_pack || batch.unitPack || null;
            const focQty = batch.foc_quantity || batch.focQuantity || 0;
            const purchaseRate = batch.purchase_rate || batch.purchaseRate || 0;
            const mrp = batch.mrp || 0;
            const quantity = batch.quantity || 0;
            const batchIdInput = batch.batch_id || batch.batchId || null;
            const binIdInput = batch.bin_id || batch.binId || null;
            const warehouseIdInput = batch.warehouse_id || batch.warehouseId || null;

            let batchId = null;
            let layerId = null;
            let resolvedBinId = binIdInput || null;

            if (shouldUpdateStock) {
              // Step 1: Check/create batch master
              const { data: existingBatch } = await supabase
                .from("batch_master")
                .select("id")
                .eq("batch_no", batchNo)
                .eq("product_id", item.item_id)
                .maybeSingle();

              batchId = existingBatch?.id;

              if (!batchId) {
                const { data: newBatch, error: batchError } = await supabase
                  .from("batch_master")
                  .insert({
                    batch_no: batchNo,
                    product_id: item.item_id,
                    expiry_date: expiryDate || new Date(Date.now() + 365*24*60*60*1000).toISOString().split('T')[0],
                    unit_pack: unitPack,
                    manufacture_batch_number: batchNo,
                    manufacture_exp: expiryDate,
                    created_by_entity_id: entityId,
                    source_type: "BILL",
                  })
                  .select()
                  .single();

                if (batchError) {
                  throw new HttpException(`Failed to create batch master: ${batchError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
                }
                batchId = newBatch.id;
              }

              // Resolve bin
              if (!resolvedBinId) {
                const warehouseId = warehouseIdInput || dto.warehouseId || dto.warehouse_id;
                if (warehouseId) {
                  const { data: firstBin } = await supabase
                    .from("bin_master")
                    .select("id")
                    .eq("warehouse_id", warehouseId)
                    .limit(1)
                    .maybeSingle();
                  resolvedBinId = firstBin?.id;
                }
              }

              // CASE 1 vs CASE 2 check
              const isFromReceive = !!(
                (dto.sourceType || dto.source_type)?.toLowerCase() === 'purchase_receive' ||
                (dto.sourceType || dto.source_type)?.toLowerCase() === 'purchase-receive' ||
                (dto.sourceId || dto.source_id) ||
                (item.purchaseReceiveItemId || item.purchase_receive_item_id)
              );

              if (isFromReceive) {
                // CASE 1: Bill from Purchase Receive
                let query = supabase
                  .from("batch_stock_layers")
                  .select("id")
                  .eq("batch_id", batchId)
                  .eq("product_id", item.item_id)
                  .eq("entity_id", entityId);

                if (dto.sourceId || dto.source_id) {
                  query = query.eq("ref_id", dto.sourceId || dto.source_id).eq("ref_type", "PURCHASE_RECEIVE");
                }
                
                const { data: existingLayer } = await query.limit(1).maybeSingle();
                layerId = existingLayer?.id || null;
              } else {
                // CASE 2: DIRECT BILL
                const targetWarehouseId = warehouseIdInput || dto.warehouseId || dto.warehouse_id;
                const { data: existingLayer, error: getLayerError } = await supabase
                  .from("batch_stock_layers")
                  .select("*")
                  .eq("batch_id", batchId)
                  .eq("product_id", item.item_id)
                  .eq("entity_id", entityId)
                  .eq("warehouse_id", targetWarehouseId)
                  .eq("bin_id", resolvedBinId)
                  .maybeSingle();

                if (getLayerError) {
                  throw new HttpException(`Failed to query existing batch stock layer: ${getLayerError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
                }

                if (existingLayer) {
                  const { data: updatedLayer, error: updateLayerError } = await supabase
                    .from("batch_stock_layers")
                    .update({
                      qty: Number(existingLayer.qty) + Number(quantity),
                      foc_qty: Number(existingLayer.foc_qty) + Number(focQty),
                      updated_at: new Date().toISOString(),
                    })
                    .eq("id", existingLayer.id)
                    .select()
                    .single();

                  if (updateLayerError) {
                    throw new HttpException(`Failed to update batch stock layer: ${updateLayerError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
                  }
                  layerId = updatedLayer.id;
                } else {
                  const { data: layer, error: layerError } = await supabase
                    .from("batch_stock_layers")
                    .insert({
                      batch_id: batchId,
                      product_id: item.item_id,
                      entity_id: entityId,
                      warehouse_id: targetWarehouseId,
                      bin_id: resolvedBinId,
                      qty: quantity,
                      foc_qty: focQty,
                      purchase_rate: purchaseRate,
                      mrp: mrp,
                      ref_type: "BILL",
                      ref_id: id,
                    })
                    .select()
                    .single();

                  if (layerError) {
                    throw new HttpException(`Failed to create batch stock layer: ${layerError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
                  }
                  layerId = layer.id;
                }
              }

              // Step 3: Insert into batch_transactions
              const { error: transError } = await supabase
                .from("batch_transactions")
                .insert({
                  batch_id: batchId,
                  layer_id: layerId,
                  product_id: item.item_id,
                  entity_id: entityId,
                  warehouse_id: warehouseIdInput || dto.warehouseId || dto.warehouse_id,
                  bin_id: resolvedBinId,
                  trans_type: "BILL",
                  qty_in: quantity,
                  rate: purchaseRate,
                  ref_id: id,
                  ref_no: dto.billNumber || dto.bill_number || `BILL-${Date.now()}`,
                });

              if (transError) {
                throw new HttpException(`Failed to create batch transaction: ${transError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
              }
            }

            batchesToInsert.push({
              id: uuidv4(),
              bill_item_id: insertedItem.id,
              batch_id: batchId || batchIdInput || uuidv4(),
              layer_id: layerId,
              warehouse_id: warehouseIdInput || dto.warehouseId || dto.warehouse_id || null,
              bin_id: resolvedBinId,
              quantity: quantity?.toString() ?? '0',
              foc_quantity: focQty?.toString() ?? null,
              damage_quantity: (batch.damageQuantity || batch.damage_quantity)?.toString() ?? null,
              purchase_rate: purchaseRate?.toString() ?? null,
              mrp: mrp?.toString() ?? null,
              expiry_date: expiryDate || null,
              manufacture_date: manufactureDate || null,
              manufacture_batch_no: batchNo,
              is_direct_bill: !(
                (dto.sourceType || dto.source_type)?.toLowerCase() === 'purchase_receive' ||
                (dto.sourceType || dto.source_type)?.toLowerCase() === 'purchase-receive' ||
                (dto.sourceId || dto.source_id) ||
                (item.purchaseReceiveItemId || item.purchase_receive_item_id)
              ),
            });
          }
        }
      }

      if (batchesToInsert.length > 0) {
        const { error: batchError } = await supabase
          .from('bill_item_batches')
          .insert(batchesToInsert);
          
        if (batchError) {
          throw new HttpException(`Failed to create item batches: ${batchError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
        }
      }
    }

    const { data: fullBill } = await supabase
      .from('bills')
      .select(
        `
        *,
        vendor:vendors(display_name, company_name),
        warehouse:warehouses(name),
        payment_terms:payment_terms(term_name)
      `
      )
      .eq('id', id)
      .eq('entity_id', entityId)
      .single();

    if (dto.orderNumber) {
      await updatePurchaseOrderStatusByOrderNumber(supabase, dto.orderNumber, entityId);
    }

    return fullBill || billData;
  }

  async findAll(
    tenant: TenantContext,
    page: number = 1,
    limit: number = 100,
    search?: string,
    status?: string,
  ) {
    const offset = (page - 1) * limit;

    let query = this.supabaseService
      .getClient()
      .from("bills")
      .select(
        `
        *,
        vendor:vendors(display_name, company_name),
        warehouse:warehouses(name),
        payment_terms:payment_terms(term_name)
      `,
        { count: "exact" },
      )
      .eq("entity_id", tenant.entityId)
      .eq("is_delete", false)
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (search) {
      query = query.or(
        `bill_number.ilike.%${search}%,order_number.ilike.%${search}%`,
      );
    }

    if (status) {
      query = query.eq("status", status);
    }

    const { data, error, count } = await query;

    if (error) {
      throw new HttpException(
        `Failed to fetch bills: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
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

  async findOne(id: string, tenant: TenantContext) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("bills")
      .select(
        `
        *,
        vendor:vendors(*),
        warehouse:warehouses(name),
        payment_terms:payment_terms(term_name),
        line_items:bill_items(
          *,
          product:products(*),
          account:accounts(*),
          customer:customers(*)
        )
      `,
      )
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .eq("is_delete", false)
      .single();

    if (error) {
      throw new HttpException(
        `Bill not found: ${error.message}`,
        HttpStatus.NOT_FOUND,
      );
    }

    if (data && data.line_items) {
      for (const item of data.line_items) {
        const { data: batches } = await this.supabaseService
          .getClient()
          .from("bill_item_batches")
          .select(`*, batch:batch_master(*)`)
          .eq("bill_item_id", item.id);
        item.batches = batches || [];
      }
    }

    return data;
  }

  async updateBillStatus(id: string, entityId: string, status: string, reason: string) {
    const supabase = this.supabaseService.getClient();

    // 1. Fetch current bill to get order_number and verify it exists
    const { data: bill, error: fetchError } = await supabase
      .from('bills')
      .select('status, order_number')
      .eq('id', id)
      .eq('entity_id', entityId)
      .single();

    if (fetchError || !bill) {
      throw new HttpException(`Bill not found: ${fetchError?.message || ''}`, HttpStatus.NOT_FOUND);
    }

    const oldStatus = (bill.status || '').toLowerCase();
    const newStatus = status.toLowerCase();
    const statusChangedToActive = (oldStatus === 'draft' || oldStatus === 'void') && (newStatus !== 'draft' && newStatus !== 'void');

    // 2. Prepare update payload
    const updatePayload: any = {
      status,
      updated_at: new Date().toISOString(),
    };

    if (status === 'void') {
      updatePayload.reason_to_void = reason;
    } else if (status === 'draft') {
      updatePayload.reason_to_draft = reason;
    }

    // 3. Update status in database
    const { data: updatedBill, error: updateError } = await supabase
      .from('bills')
      .update(updatePayload)
      .eq('id', id)
      .eq('entity_id', entityId)
      .select()
      .single();

    if (updateError) {
      throw new HttpException(`Failed to update bill status: ${updateError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    // 4. Reverse or Apply stock updates based on status change
    if (newStatus === 'void' || newStatus === 'draft') {
      await this.reverseStockForBill(supabase, id, entityId);
    } else if (statusChangedToActive) {
      await this.applyStockForBill(supabase, id, entityId);
    }

    // 5. Update purchase order status if PO exists
    if (bill.order_number) {
      await updatePurchaseOrderStatusByOrderNumber(supabase, bill.order_number, entityId);
    }

    return updatedBill;
  }

  private async applyStockForBill(supabase: any, id: string, entityId: string) {
    // 1. Fetch bill details
    const { data: bill } = await supabase
      .from('bills')
      .select('*')
      .eq('id', id)
      .single();

    if (!bill) return;

    // 2. Fetch bill items
    const { data: items } = await supabase
      .from('bill_items')
      .select('*')
      .eq('bill_id', id);

    if (!items || items.length === 0) return;

    // 3. For each item, fetch its batches and apply stock
    for (const item of items) {
      const { data: batches } = await supabase
        .from('bill_item_batches')
        .select('*')
        .eq('bill_item_id', item.id);

      if (!batches || batches.length === 0) continue;

      for (const batch of batches) {
        const batchNo = batch.manufacture_batch_no || `BATCH-${Date.now()}`;
        const expiryDate = batch.expiry_date || null;
        const manufactureDate = batch.manufacture_date || null;
        const unitPack = batch.unit_pack || null;
        const focQty = Number(batch.foc_quantity || 0);
        const purchaseRate = Number(batch.purchase_rate || 0);
        const mrp = Number(batch.mrp || 0);
        const quantity = Number(batch.quantity || 0);
        const binIdInput = batch.bin_id || null;
        const warehouseIdInput = batch.warehouse_id || bill.warehouse_id || null;

        let batchId = null;
        let layerId = null;
        let resolvedBinId = binIdInput || null;

        // Step 1: Check/create batch master
        const { data: existingBatch } = await supabase
          .from("batch_master")
          .select("id")
          .eq("batch_no", batchNo)
          .eq("product_id", item.product_id)
          .maybeSingle();

        batchId = existingBatch?.id;

        if (!batchId) {
          const { data: newBatch, error: batchError } = await supabase
            .from("batch_master")
            .insert({
              batch_no: batchNo,
              product_id: item.product_id,
              expiry_date: expiryDate || new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
              unit_pack: unitPack,
              manufacture_batch_number: batchNo,
              manufacture_exp: expiryDate,
              created_by_entity_id: entityId,
              source_type: "BILL",
            })
            .select()
            .single();

          if (batchError) {
            throw new HttpException(`Failed to create batch master: ${batchError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
          }
          batchId = newBatch.id;
        }

        // Resolve bin
        if (!resolvedBinId && warehouseIdInput) {
          const { data: firstBin } = await supabase
            .from("bin_master")
            .select("id")
            .eq("warehouse_id", warehouseIdInput)
            .limit(1)
            .maybeSingle();
          resolvedBinId = firstBin?.id;
        }

        // Direct Bill (Case 2) layer update/insert
        const { data: existingLayer, error: getLayerError } = await supabase
          .from("batch_stock_layers")
          .select("*")
          .eq("batch_id", batchId)
          .eq("product_id", item.product_id)
          .eq("entity_id", entityId)
          .eq("warehouse_id", warehouseIdInput)
          .eq("bin_id", resolvedBinId)
          .maybeSingle();

        if (getLayerError) {
          throw new HttpException(`Failed to query existing batch stock layer: ${getLayerError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
        }

        if (existingLayer) {
          const { data: updatedLayer, error: updateLayerError } = await supabase
            .from("batch_stock_layers")
            .update({
              qty: Number(existingLayer.qty) + Number(quantity),
              foc_qty: Number(existingLayer.foc_qty) + Number(focQty),
              updated_at: new Date().toISOString(),
            })
            .eq("id", existingLayer.id)
            .select()
            .single();

          if (updateLayerError) {
            throw new HttpException(`Failed to update batch stock layer: ${updateLayerError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
          }
          layerId = updatedLayer.id;
        } else {
          const { data: layer, error: layerError } = await supabase
            .from("batch_stock_layers")
            .insert({
              batch_id: batchId,
              product_id: item.product_id,
              entity_id: entityId,
              warehouse_id: warehouseIdInput,
              bin_id: resolvedBinId,
              qty: quantity,
              foc_qty: focQty,
              purchase_rate: purchaseRate,
              mrp: mrp,
              ref_type: "BILL",
              ref_id: id,
            })
            .select()
            .single();

          if (layerError) {
            throw new HttpException(`Failed to create batch stock layer: ${layerError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
          }
          layerId = layer.id;
        }

        // Update bill_item_batches to associate batchId and layerId
        await supabase
          .from('bill_item_batches')
          .update({
            batch_id: batchId,
            layer_id: layerId,
          })
          .eq('id', batch.id);

        // Step 3: Insert into batch_transactions
        const { error: transError } = await supabase
          .from("batch_transactions")
          .insert({
            batch_id: batchId,
            layer_id: layerId,
            product_id: item.product_id,
            entity_id: entityId,
            warehouse_id: warehouseIdInput,
            bin_id: resolvedBinId,
            trans_type: "BILL",
            qty_in: quantity,
            rate: purchaseRate,
            ref_id: id,
            ref_no: bill.bill_number || `BILL-${Date.now()}`,
          });

        if (transError) {
          throw new HttpException(`Failed to create batch transaction: ${transError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
        }
      }
    }
  }

  private async reverseStockForBill(supabase: any, id: string, entityId: string) {
    // 1. Fetch item IDs
    const { data: billItems, error: itemsError } = await supabase
      .from('bill_items')
      .select('id')
      .eq('bill_id', id);

    if (itemsError) {
      throw new HttpException(`Failed to query bill items for stock reversal: ${itemsError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    const itemIds = (billItems || []).map((item) => item.id);
    if (itemIds.length === 0) {
      return;
    }

    // 2. Fetch item batches
    const { data: itemBatches, error: fetchError } = await supabase
      .from('bill_item_batches')
      .select('layer_id, quantity, foc_quantity')
      .in('bill_item_id', itemIds);

    if (fetchError) {
      throw new HttpException(`Failed to query item batches for stock reversal: ${fetchError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    if (itemBatches && itemBatches.length > 0) {
      for (const batch of itemBatches) {
        if (batch.layer_id) {
          const { data: layer } = await supabase
            .from('batch_stock_layers')
            .select('*')
            .eq('id', batch.layer_id)
            .maybeSingle();

          if (layer) {
            const billQty = Number(batch.quantity || 0);
            const billFocQty = Number(batch.foc_quantity || 0);

            if (layer.ref_type === 'BILL' && layer.ref_id === id) {
              await supabase
                .from('batch_stock_layers')
                .delete()
                .eq('id', layer.id);
            } else {
              const newQty = Math.max(0, Number(layer.qty || 0) - billQty);
              const newFocQty = Math.max(0, Number(layer.foc_qty || 0) - billFocQty);
              await supabase
                .from('batch_stock_layers')
                .update({
                  qty: newQty.toString(),
                  foc_qty: newFocQty.toString(),
                  updated_at: new Date().toISOString(),
                })
                .eq('id', layer.id);
            }
          }
        }
      }
    }

    // 2. Clear batch transactions
    await supabase
      .from('batch_transactions')
      .delete()
      .eq('ref_id', id)
      .eq('trans_type', 'BILL')
      .eq('entity_id', entityId);

    // 3. Delete any residual batch stock layers with ref_id = id
    await supabase
      .from('batch_stock_layers')
      .delete()
      .eq('ref_id', id)
      .eq('ref_type', 'BILL')
      .eq('entity_id', entityId);
  }

  async remove(id: string, tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();
    const { data: bill } = await supabase
      .from("bills")
      .select("order_number")
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .maybeSingle();

    const { data, error } = await supabase
      .from("bills")
      .update({ is_delete: true })
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .select()
      .single();

    if (error) {
      throw new HttpException(
        `Failed to delete bill: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }

    if (bill && bill.order_number) {
      await updatePurchaseOrderStatusByOrderNumber(supabase, bill.order_number, tenant.entityId);
    }

    return { message: "Bill deleted successfully" };
  }
}
