import { Injectable, HttpException, HttpStatus } from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { v4 as uuidv4 } from "uuid";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { updatePurchaseOrderStatusByOrderNumber } from "../../purchase-orders/utils/po-status";

@Injectable()
export class BillsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async createBill(entityIdOrTenant: string | TenantContext, dto: any) {
    const tenant = typeof entityIdOrTenant === 'string' ? null : entityIdOrTenant;
    const entityId = tenant ? tenant.entityId : entityIdOrTenant as string;
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
        discount_value: dto.discountPercent?.toString() || dto.discountValue?.toString() || null,
        discount_accounts_id: dto.discountAccountId || null,
        tax_total: dto.taxAmount?.toString(),
        tds_total: dto.tdsTotal?.toString(),
        tcs_total: dto.tcsTotal?.toString(),
        adjustment_amount: dto.adjustment?.toString(),
        grand_total: dto.total?.toString(),
        invoice_total: dto.invoiceTotal?.toString(),
        source_type: dto.sourceType || dto.source_type || null,
        source_id: dto.sourceId || dto.source_id || null,
        status: dto.status || "draft",
        is_delete: false,
        tds_tcs_type: dto.tdsTcsType || 'none',
        tds_tcs_id: dto.tdsTcsId || null,
      })
      .select()
      .single();

    if (billError) {
      throw new HttpException(`Failed to create bill: ${billError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    // 2. Create Items
    if (dto.lineItems && dto.lineItems.length > 0) {
      const itemsToInsert = dto.lineItems.map(item => {
        const qty = parseFloat(item.quantity?.toString() || '0');
        const rate = parseFloat(item.rate?.toString() || '0');
        const gross = qty * rate;
        const discVal = parseFloat(item.discount?.toString() || '0');
        const discType = item.discountType || item.discount_type || '%';
        const computedDiscountAmt = (discType === '%') ? (gross * discVal / 100) : discVal;

        return {
          id: uuidv4(),
          bill_id: billId,
          product_id: item.item_id || item.itemId,
          account_id: item.account_id || item.accountId,
          customer_id: item.customer_id || item.customerId,
          description: item.description,
          hsn_code: item.hsn_code || item.hsnCode,
          quantity: qty.toString(),
          rate: rate.toString(),
          discount_type: discType,
          discount_value: discVal.toString(),
          discount_accounts_id: item.discount_account_id || item.discountAccountId || null,
          discount_amount: computedDiscountAmt.toString(),
          tax_id: item.tax_id || item.taxId,
          tax_amount: item.tax_amount?.toString() || "0",
          line_total: item.amount?.toString() || "0",
          purchase_receive_item_id: item.purchaseReceiveItemId || item.purchase_receive_item_id || null,
        };
      });

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

    await this.postBillTransactions(
      supabase,
      billId,
      entityId,
      tenant?.orgId || dto.orgId || '00000000-0000-0000-0000-000000000000',
      dto,
    );

    return fullBill || billData;
  }

  async updateBill(id: string, entityIdOrTenant: string | TenantContext, dto: any) {
    const tenant = typeof entityIdOrTenant === 'string' ? null : entityIdOrTenant;
    const entityId = tenant ? tenant.entityId : entityIdOrTenant as string;
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
        discount_value: dto.discountPercent?.toString() || dto.discountValue?.toString() || null,
        discount_accounts_id: dto.discountAccountId || null,
        tax_total: dto.taxAmount?.toString(),
        tds_total: dto.tdsTotal?.toString(),
        tcs_total: dto.tcsTotal?.toString(),
        adjustment_amount: dto.adjustment?.toString(),
        grand_total: dto.total?.toString(),
        invoice_total: dto.invoiceTotal?.toString(),
        source_type: dto.sourceType || dto.source_type || null,
        source_id: dto.sourceId || dto.source_id || null,
        status: dto.status || "draft",
        updated_at: new Date().toISOString(),
        tds_tcs_type: dto.tdsTcsType || 'none',
        tds_tcs_id: dto.tdsTcsId || null,
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
      const itemsToInsert = dto.lineItems.map(item => {
        const qty = parseFloat(item.quantity?.toString() || '0');
        const rate = parseFloat(item.rate?.toString() || '0');
        const gross = qty * rate;
        const discVal = parseFloat(item.discount?.toString() || '0');
        const discType = item.discountType || item.discount_type || '%';
        const computedDiscountAmt = (discType === '%') ? (gross * discVal / 100) : discVal;

        return {
          id: uuidv4(),
          bill_id: id,
          product_id: item.item_id || item.itemId,
          account_id: item.account_id || item.accountId,
          customer_id: item.customer_id || item.customerId,
          description: item.description,
          hsn_code: item.hsn_code || item.hsnCode,
          quantity: qty.toString(),
          rate: rate.toString(),
          discount_type: discType,
          discount_value: discVal.toString(),
          discount_accounts_id: item.discount_account_id || item.discountAccountId || null,
          discount_amount: computedDiscountAmt.toString(),
          tax_id: item.tax_id || item.taxId,
          tax_amount: item.tax_amount?.toString() || "0",
          line_total: item.amount?.toString() || "0",
          purchase_receive_item_id: item.purchaseReceiveItemId || item.purchase_receive_item_id || null,
        };
      });

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

    await this.postBillTransactions(
      supabase,
      id,
      entityId,
      tenant?.orgId || dto.orgId || '00000000-0000-0000-0000-000000000000',
      dto,
    );

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
          account:accounts!account_id(*),
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
      .select("order_number, bill_number")
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .maybeSingle();

    const originalNumber = bill?.bill_number;
    const newNumber = originalNumber ? (originalNumber.startsWith('SD-') ? originalNumber : `SD-${originalNumber}`) : undefined;

    const { data, error } = await supabase
      .from("bills")
      .update({
        is_delete: true,
        ...(newNumber ? { bill_number: newNumber } : {}),
      })
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

    // Clear account transactions
    await supabase
      .from('account_transactions')
      .delete()
      .eq('source_id', id)
      .eq('source_type', 'BILL')
      .eq('entity_id', tenant.entityId);

    if (bill && bill.order_number) {
      await updatePurchaseOrderStatusByOrderNumber(supabase, bill.order_number, tenant.entityId);
    }

    return { message: "Bill deleted successfully" };
  }

  private async postBillTransactions(
    supabase: any,
    billId: string,
    entityId: string,
    orgId: string,
    dto: any,
  ) {
    // 1. Clear any existing transactions for this bill
    await supabase
      .from('account_transactions')
      .delete()
      .eq('source_id', billId)
      .eq('source_type', 'BILL')
      .eq('entity_id', entityId);

    // 2. If status is void, don't write new transactions
    if (dto.status?.toLowerCase() === 'void') {
      return;
    }

    // 3. Fetch all active accounts for the branch
    const { data: dbAccounts, error: accountsError } = await supabase
      .from('accounts')
      .select('id, user_account_name, system_account_name, account_type')
      .eq('entity_id', entityId)
      .eq('is_active', true);

    if (accountsError || !dbAccounts || dbAccounts.length === 0) {
      return;
    }

    // 4. Resolver helper
    const findAccount = (names: string[], types?: string[]): string | null => {
      const match = dbAccounts.find((acc: any) => {
        const uName = acc.user_account_name?.toLowerCase() || '';
        const sName = acc.system_account_name?.toLowerCase() || '';
        const aType = acc.account_type?.toLowerCase() || '';

        const nameMatch = names.some(n => {
          const ln = n.toLowerCase();
          return uName.includes(ln) || sName.includes(ln);
        });

        const typeMatch = types ? types.some(t => aType === t.toLowerCase()) : true;
        return nameMatch && typeMatch;
      });

      if (match) return match.id;

      if (types && types.length > 0) {
        const typeMatch = dbAccounts.find((acc: any) =>
          types.some(t => acc.account_type?.toLowerCase() === t.toLowerCase())
        );
        if (typeMatch) return typeMatch.id;
      }

      return dbAccounts[0]?.id || null;
    };

    // 5. Parse amounts
    const discountAmount = parseFloat(dto.discountAmount?.toString() || dto.discountTotal?.toString() || '0');
    const taxAmount = parseFloat(dto.taxAmount?.toString() || dto.taxTotal?.toString() || '0');
    const tdsAmount = parseFloat(dto.tdsTotal?.toString() || '0');
    const tcsAmount = parseFloat(dto.tcsTotal?.toString() || '0');
    const adjustmentAmount = parseFloat(dto.adjustment?.toString() || dto.adjustmentAmount?.toString() || '0');
    const grandTotal = parseFloat(dto.total?.toString() || dto.grandTotal?.toString() || '0');

    // Resolve accounts
    const accountsPayableId = findAccount(['Accounts Payable'], ['Accounts Payable']);
    const accountsPayableDiscountId = findAccount(['Accounts Payable (discount)', 'Accounts Payable discount'], ['Accounts Payable']) || accountsPayableId;
    const purchaseDiscountId = findAccount(['Purchase Discount', 'Purchase Discounts', 'Discount'], ['Income', 'Other Income', 'Expense', 'Other Expense']);
    const otherExpensesId = findAccount(['Other Expenses', 'Other Expense', 'Adjustment'], ['Expense', 'Other Expense']);
    const tdsPayableId = findAccount(['TDS Payable', 'TDS'], ['Other Current Liability', 'Other Liability']);
    const tcsPayableId = findAccount(['TCS Payable', 'TCS'], ['Other Current Liability', 'Other Liability']);
    const tdsReceivableId = findAccount(['TDS Receivable', 'TDS'], ['Other Current Asset', 'Other Asset']);
    const tcsReceivableId = findAccount(['TCS Receivable', 'TCS'], ['Other Current Asset', 'Other Asset']);
    const inputSgstId = findAccount(['Input SGST', 'SGST'], ['Other Current Asset', 'Other Asset', 'Other Current Liability', 'Other Liability']);
    const inputCgstId = findAccount(['Input CGST', 'CGST'], ['Other Current Asset', 'Other Asset', 'Other Current Liability', 'Other Liability']);
    const inputIgstId = findAccount(['Input IGST', 'IGST'], ['Other Current Asset', 'Other Asset', 'Other Current Liability', 'Other Liability']);

    // 6. Group item gross amounts (qty * rate) by account_id and compute gross subtotal
    let computedGrossSubtotal = 0;
    const itemAccountsMap = new Map<string, number>();
    const lineItemDiscountsMap = new Map<string, number>();

    for (const item of dto.lineItems || []) {
      const accId = item.account_id || item.accountId;
      const qty = parseFloat(item.quantity?.toString() || '0');
      const rate = parseFloat(item.rate?.toString() || '0');
      const itemGross = qty * rate;

      if (accId) {
        itemAccountsMap.set(accId, (itemAccountsMap.get(accId) || 0) + itemGross);
        computedGrossSubtotal += itemGross;
      }

      // Group line item discount amounts by discountAccountId
      const discAccId = item.discountAccountId || item.discount_account_id;
      const discVal = parseFloat(item.discount?.toString() || item.discountAmount?.toString() || item.discount_amount?.toString() || '0');
      if (discVal > 0.0001) {
        let discAmt = 0;
        const discType = item.discountType || item.discount_type;
        if (discType === '%') {
          discAmt = itemGross * (discVal / 100);
        } else {
          discAmt = discVal;
        }

        if (discAmt > 0.0001) {
          const finalDiscAccId = discAccId || purchaseDiscountId;
          if (finalDiscAccId) {
            lineItemDiscountsMap.set(finalDiscAccId, (lineItemDiscountsMap.get(finalDiscAccId) || 0) + discAmt);
          }
        }
      }
    }

    // 7. Determine if GST is applied
    const isGstBill = taxAmount > 0.0001;
    let isIGST = false;

    if (isGstBill && dto.lineItems?.length > 0) {
      const taxIds = dto.lineItems.map((item: any) => item.tax_id || item.taxId).filter(Boolean);
      if (taxIds.length > 0) {
        const { data: rates } = await supabase
          .from('tax_rates')
          .select('tax_type')
          .in('id', taxIds);
        if (rates && rates.some((r: any) => r.tax_type === 'IGST')) {
          isIGST = true;
        }
      }
    }

    // 8. Build transaction entries
    const entries: any[] = [];
    const addEntry = (accountId: string | null, type: string, debit: number, credit: number) => {
      if (!accountId) return;
      const dVal = Math.round(debit * 100) / 100;
      const cVal = Math.round(credit * 100) / 100;
      if (dVal > 0.0001 || cVal > 0.0001) {
        entries.push({
          entity_id: entityId,
          org_id: orgId,
          account_id: accountId,
          transaction_date: dto.billDate || new Date().toISOString(),
          transaction_type: type,
          reference_number: dto.billNumber || dto.bill_number || 'BILL',
          description: dto.notes || 'Purchase Bill transaction',
          debit: dVal,
          credit: cVal,
          source_id: billId,
          source_type: 'BILL',
        });
      }
    };

    if (!isGstBill) {
      // Scenario 1: Non GST Bill
      
      // DEBITS:
      // Accounts Payable (discount) (Dr)
      if (discountAmount > 0.0001) {
        addEntry(accountsPayableDiscountId, 'Accounts Payable (discount)', discountAmount, 0);
      }

      // Inventory Asset (selected Purchase a/c in item registration) (Dr)
      for (const [accId, amt] of itemAccountsMap.entries()) {
        addEntry(accId, 'Inventory Asset (selected Purchase a/c in item registration)', amt, 0);
      }

      // Other Expenses (Adjustment) (Dr)
      if (adjustmentAmount > 0.0001) {
        addEntry(otherExpensesId, 'Other Expenses (Adjustment) (+ve / --ve)', adjustmentAmount, 0);
      }

      // CREDITS:
      // Purchase Discount (Cr)
      if (discountAmount > 0.0001) {
        if (lineItemDiscountsMap.size > 0) {
          for (const [accId, amt] of lineItemDiscountsMap.entries()) {
            addEntry(accId, 'Purchase Discount (selected discount a/c in Transaction)', 0, amt);
          }
        } else {
          const transDiscountAccId = dto.discountAccountId || purchaseDiscountId;
          addEntry(transDiscountAccId, 'Purchase Discount (selected discount a/c in Transaction)', 0, discountAmount);
        }
      }

      // Other Expenses (Adjustment) (Cr)
      if (adjustmentAmount < -0.0001) {
        addEntry(otherExpensesId, 'Other Expenses (Adjustment) (+ve / --ve)', 0, Math.abs(adjustmentAmount));
      }

      // TDS Payable (Cr)
      if (tdsAmount > 0.0001) {
        addEntry(tdsPayableId, 'TDS Payable', 0, tdsAmount);
      }

      // TCS Payable (Cr)
      if (tcsAmount > 0.0001) {
        addEntry(tcsPayableId, 'TCS Payable', 0, tcsAmount);
      }

      // Accounts Payable (Cr) - Balancing Entry
      const totalDebits = entries.reduce((sum, e) => sum + (e.debit || 0), 0);
      const totalOtherCredits = entries.reduce((sum, e) => sum + (e.credit || 0), 0);
      const apCredit = Math.max(0, totalDebits - totalOtherCredits);

      addEntry(accountsPayableId, 'Accounts Payable', 0, apCredit);

      // Sanity warning
      const expectedAPCr = grandTotal + (discountAmount > 0 ? discountAmount : 0);
      if (Math.abs(apCredit - expectedAPCr) > 0.05) {
        console.warn(`[postBillTransactions] Non-GST AP Credit mismatch: computed=${apCredit}, expected=${expectedAPCr}`);
      }

    } else {
      // Scenario 2: GST Bill
      
      // DEBITS:
      // Inventory Asset (Dr)
      for (const [accId, amt] of itemAccountsMap.entries()) {
        addEntry(accId, 'Inventory Asset', amt, 0);
      }

      // GST Input Tax (Dr)
      if (isIGST) {
        addEntry(inputIgstId, 'Input IGST', taxAmount, 0);
      } else {
        addEntry(inputCgstId, 'Input CGST', taxAmount / 2, 0);
        addEntry(inputSgstId, 'Input SGST', taxAmount / 2, 0);
      }

      // Accounts Payable (discount) (Dr)
      if (discountAmount > 0.0001) {
        addEntry(accountsPayableDiscountId, 'Accounts Payable (discount)', discountAmount, 0);
      }

      // Other Expenses (Adjustment) (Dr)
      if (adjustmentAmount > 0.0001) {
        addEntry(otherExpensesId, 'Other Expenses (Adjustment) (+ve / --ve)', adjustmentAmount, 0);
      }

      // TCS Receivable (Dr)
      if (tcsAmount > 0.0001) {
        addEntry(tcsReceivableId, 'TCS Receivable', tcsAmount, 0);
      }

      // CREDITS:
      // TDS Payable (Cr) - Reduces Accounts Payable credit in GST scenario
      if (tdsAmount > 0.0001) {
        addEntry(tdsPayableId, 'TDS Payable', 0, tdsAmount);
      }

      // Purchase Discounts (Cr)
      if (discountAmount > 0.0001) {
        if (lineItemDiscountsMap.size > 0) {
          for (const [accId, amt] of lineItemDiscountsMap.entries()) {
            addEntry(accId, 'Purchase Discounts', 0, amt);
          }
        } else {
          const transDiscountAccId = dto.discountAccountId || purchaseDiscountId;
          addEntry(transDiscountAccId, 'Purchase Discounts', 0, discountAmount);
        }
      }

      // Other Expenses (Adjustment) (Cr)
      if (adjustmentAmount < -0.0001) {
        addEntry(otherExpensesId, 'Other Expenses (Adjustment) (+ve / --ve)', 0, Math.abs(adjustmentAmount));
      }

      // Accounts Payable (Cr) - Balancing Entry
      const totalDebits = entries.reduce((sum, e) => sum + (e.debit || 0), 0);
      const totalOtherCredits = entries.reduce((sum, e) => sum + (e.credit || 0), 0);
      const apCredit = Math.max(0, totalDebits - totalOtherCredits);

      addEntry(accountsPayableId, 'Accounts Payable', 0, apCredit);

      // Sanity warning
      const expectedAPCr = grandTotal + (discountAmount > 0 ? discountAmount : 0);
      if (Math.abs(apCredit - expectedAPCr) > 0.05) {
        console.warn(`[postBillTransactions] GST AP Credit mismatch: computed=${apCredit}, expected=${expectedAPCr}`);
      }
    }

    // 9. Bulk Insert
    if (entries.length > 0) {
      const { error: insertError } = await supabase
        .from('account_transactions')
        .insert(entries);
      if (insertError) {
        throw new HttpException(`Failed to save account transactions: ${insertError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
      }
    }
  }
}
