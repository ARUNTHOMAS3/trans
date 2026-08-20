import { Injectable, HttpException, HttpStatus } from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { v4 as uuidv4 } from "uuid";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { updatePurchaseOrderStatusByOrderNumber } from "../../purchase-orders/utils/po-status";
import { client } from "../../../../db/db";

@Injectable()
export class BillsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async createBill(entityIdOrTenant: string | TenantContext, dto: any) {
    const tenant = typeof entityIdOrTenant === 'string' ? null : entityIdOrTenant;
    const entityId = tenant ? tenant.entityId : entityIdOrTenant as string;

    const vendorRows = await client.unsafe(
      `SELECT gst_treatment FROM vendors WHERE id = $1 LIMIT 1`,
      [dto.vendorId],
    );
    const vendorData = vendorRows[0];

    const isUnregistered =
      vendorData?.gst_treatment?.toLowerCase() === 'unregistered_business' ||
      vendorData?.gst_treatment?.toLowerCase() === 'unregistered business';

    const billId = uuidv4();
    const billNumber = dto.billNumber || `BILL-${Date.now()}`;
    const status = dto.status || "draft";

    const payload = {
      id: billId,
      entity_id: entityId,
      vendor_id: dto.vendorId,
      bill_number: billNumber,
      order_number: dto.orderNumber || null,
      bill_date: dto.billDate,
      due_date: dto.dueDate || null,
      payment_term_id: dto.paymentTerms || null,
      reverse_charge_applicable: dto.isReverseCharge || false,
      warehouse_id: dto.warehouseId || null,
      price_list_id: dto.priceListId || null,
      subject: dto.subject || null,
      source_of_supply: dto.sourceOfSupply || null,
      destination_to_supply: dto.destinationToSupply || null,
      billing_address: dto.billingAddress || null,
      notes: dto.notes || null,
      subtotal: dto.subTotal?.toString() || "0",
      discount_total: dto.discountAmount?.toString() || "0",
      discount_value: dto.discountPercent?.toString() || dto.discountValue?.toString() || null,
      discount_accounts_id: dto.discountAccountId || null,
      tax_total: isUnregistered ? "0" : (dto.taxAmount?.toString() || "0"),
      tds_total: dto.tdsTotal?.toString() || "0",
      tcs_total: dto.tcsTotal?.toString() || "0",
      adjustment_amount: dto.adjustment?.toString() || "0",
      grand_total: isUnregistered
        ? ((parseFloat(dto.subTotal?.toString() || "0") - parseFloat(dto.discountAmount?.toString() || "0") + parseFloat(dto.adjustment?.toString() || "0")).toString())
        : (dto.total?.toString() || "0"),
      invoice_total: dto.invoiceTotal?.toString() || null,
      source_type: dto.sourceType || dto.source_type || null,
      source_id: dto.sourceId || dto.source_id || null,
      status: status,
      is_delete: false,
      tds_tcs_type: dto.tdsTcsType || 'none',
      tds_tcs_id: dto.tdsTcsId || null,
    };

    const keys = Object.keys(payload);
    const cols = keys.map((k) => `"${k}"`).join(", ");
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");
    const values: any[] = Object.values(payload);

    let billData: any;
    try {
      const rows = await client.unsafe(
        `INSERT INTO bills (${cols}) VALUES (${placeholders}) RETURNING *`,
        values,
      );
      billData = rows[0];
    } catch (billError: any) {
      throw new HttpException(`Failed to create bill: ${billError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    const itemsData: any[] = [];
    if (dto.lineItems && dto.lineItems.length > 0) {
      const itemsToInsert = dto.lineItems.map((item: any) => {
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
          account_id: item.account_id || item.accountId || null,
          customer_id: item.customer_id || item.customerId || null,
          description: item.description || null,
          hsn_code: item.hsn_code || item.hsnCode || null,
          quantity: qty.toString(),
          rate: rate.toString(),
          discount_type: discType,
          discount_value: discVal.toString(),
          discount_accounts_id: item.discount_account_id || item.discountAccountId || null,
          discount_amount: computedDiscountAmt.toString(),
          tax_id: isUnregistered ? null : (item.tax_id || item.taxId || null),
          tax_amount: isUnregistered ? "0" : (item.tax_amount?.toString() || "0"),
          line_total: item.amount?.toString() || "0",
          purchase_receive_item_id: item.purchaseReceiveItemId || item.purchase_receive_item_id || null,
        };
      });

      for (const itemRow of itemsToInsert) {
        const iKeys = Object.keys(itemRow);
        const iCols = iKeys.map((k) => `"${k}"`).join(", ");
        const iPlaceholders = iKeys.map((_, i) => `$${i + 1}`).join(", ");
        const iValues: any[] = Object.values(itemRow);

        const rows = await client.unsafe(
          `INSERT INTO bill_items (${iCols}) VALUES (${iPlaceholders}) RETURNING *`,
          iValues,
        );
        if (rows[0]) itemsData.push(rows[0]);
      }

      const batchesToInsert: any[] = [];
      for (let i = 0; i < dto.lineItems.length; i++) {
        const item = dto.lineItems[i];
        const insertedItem = itemsData[i];

        if (item.batches && item.batches.length > 0 && insertedItem) {
          for (const batch of item.batches) {
            const batchNo = batch.manufacture_batch_no || batch.manufactureBatchNo || batch.batch_id || batch.batchId || `BATCH-${Date.now()}`;
            const shouldUpdateStock = status.toLowerCase() !== 'draft' && status.toLowerCase() !== 'void';

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

            let batchId: string | null = null;
            let layerId: string | null = null;
            let resolvedBinId = binIdInput || null;

            if (shouldUpdateStock) {
              const existingBatches = await client.unsafe(
                `SELECT id FROM batch_master WHERE batch_no = $1 AND product_id = $2 LIMIT 1`,
                [batchNo, item.item_id],
              );
              batchId = existingBatches[0]?.id;

              if (!batchId) {
                const newBatchRows = await client.unsafe(
                  `INSERT INTO batch_master (batch_no, product_id, expiry_date, unit_pack, manufacture_batch_number, manufacture_exp, created_by_entity_id, source_type)
                   VALUES ($1, $2, $3, $4, $5, $6, $7, 'BILL') RETURNING *`,
                  [
                    batchNo,
                    item.item_id,
                    expiryDate || new Date(Date.now() + 365*24*60*60*1000).toISOString().split('T')[0],
                    unitPack,
                    batchNo,
                    expiryDate,
                    entityId,
                  ],
                );
                batchId = newBatchRows[0]?.id;
              }

              if (!resolvedBinId) {
                const warehouseId = warehouseIdInput || dto.warehouseId || dto.warehouse_id;
                if (warehouseId) {
                  const firstBin = await client.unsafe(
                    `SELECT id FROM bin_master WHERE warehouse_id = $1 LIMIT 1`,
                    [warehouseId],
                  );
                  resolvedBinId = firstBin[0]?.id;
                }
              }

              const isFromReceive = !!(
                (dto.sourceType || dto.source_type)?.toLowerCase() === 'purchase_receive' ||
                (dto.sourceType || dto.source_type)?.toLowerCase() === 'purchase-receive' ||
                (dto.sourceId || dto.source_id) ||
                (item.purchaseReceiveItemId || item.purchase_receive_item_id)
              );

              if (isFromReceive) {
                let layerSql = `SELECT id FROM batch_stock_layers WHERE batch_id = $1 AND product_id = $2 AND entity_id = $3`;
                const layerParams: any[] = [batchId, item.item_id, entityId];

                if (dto.sourceId || dto.source_id) {
                  layerParams.push(dto.sourceId || dto.source_id);
                  layerSql += ` AND ref_id = $${layerParams.length} AND ref_type = 'PURCHASE_RECEIVE'`;
                }
                layerSql += ` LIMIT 1`;

                const existingLayers = await client.unsafe(layerSql, layerParams);
                layerId = existingLayers[0]?.id || null;
              } else {
                const targetWarehouseId = warehouseIdInput || dto.warehouseId || dto.warehouse_id;
                const existingLayers = await client.unsafe(
                  `SELECT * FROM batch_stock_layers WHERE batch_id = $1 AND product_id = $2 AND entity_id = $3 AND warehouse_id = $4 AND bin_id = $5 LIMIT 1`,
                  [batchId, item.item_id, entityId, targetWarehouseId, resolvedBinId],
                );
                const existingLayer = existingLayers[0];

                if (existingLayer) {
                  const updatedLayers = await client.unsafe(
                    `UPDATE batch_stock_layers SET qty = $1, foc_qty = $2, updated_at = NOW() WHERE id = $3 RETURNING *`,
                    [
                      Number(existingLayer.qty) + Number(quantity),
                      Number(existingLayer.foc_qty) + Number(focQty),
                      existingLayer.id,
                    ],
                  );
                  layerId = updatedLayers[0]?.id;
                } else {
                  const newLayers = await client.unsafe(
                    `INSERT INTO batch_stock_layers (batch_id, product_id, entity_id, warehouse_id, bin_id, qty, foc_qty, purchase_rate, mrp, ref_type, ref_id)
                     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'BILL', $10) RETURNING *`,
                    [
                      batchId,
                      item.item_id,
                      entityId,
                      targetWarehouseId,
                      resolvedBinId,
                      quantity,
                      focQty,
                      purchaseRate,
                      mrp,
                      billId,
                    ],
                  );
                  layerId = newLayers[0]?.id;
                }
              }

              await client.unsafe(
                `INSERT INTO batch_transactions (batch_id, layer_id, product_id, entity_id, warehouse_id, bin_id, trans_type, stock_effect_type, qty_in, rate, ref_id, ref_no)
                 VALUES ($1, $2, $3, $4, $5, $6, 'BILL', 'ACCOUNTING', $7, $8, $9, $10)`,
                [
                  batchId,
                  layerId,
                  item.item_id,
                  entityId,
                  warehouseIdInput || dto.warehouseId || dto.warehouse_id,
                  resolvedBinId,
                  quantity,
                  purchaseRate,
                  billId,
                  billNumber,
                ],
              );
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
        for (const bRow of batchesToInsert) {
          const bKeys = Object.keys(bRow);
          const bCols = bKeys.map((k) => `"${k}"`).join(", ");
          const bPlaceholders = bKeys.map((_, i) => `$${i + 1}`).join(", ");
          const bValues: any[] = Object.values(bRow);

          await client.unsafe(
            `INSERT INTO bill_item_batches (${bCols}) VALUES (${bPlaceholders})`,
            bValues,
          );
        }
      }
    }

    if (dto.orderNumber) {
      await updatePurchaseOrderStatusByOrderNumber(client, dto.orderNumber, entityId);
    }

    await this.postBillTransactions(
      billId,
      entityId,
      tenant?.orgId || dto.orgId || '00000000-0000-0000-0000-000000000000',
      dto,
    );

    return this.findOne(billId, tenant ?? ({ entityId } as any));
  }

  async updateBill(id: string, entityIdOrTenant: string | TenantContext, dto: any) {
    const tenant = typeof entityIdOrTenant === 'string' ? null : entityIdOrTenant;
    const entityId = tenant ? tenant.entityId : entityIdOrTenant as string;

    const updatePayload = {
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
    };

    const keys = Object.keys(updatePayload);
    const setClauses = keys.map((k, i) => `"${k}" = $${i + 1}`).join(", ");
    const values: any[] = Object.values(updatePayload);

    let billData: any;
    try {
      const rows = await client.unsafe(
        `UPDATE bills SET ${setClauses} WHERE id = $${keys.length + 1} AND entity_id = $${keys.length + 2} RETURNING *`,
        [...values, id, entityId],
      );
      billData = rows[0];
    } catch (billError: any) {
      throw new HttpException(`Failed to update bill: ${billError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    await client.unsafe(
      `DELETE FROM batch_transactions WHERE ref_id = $1 AND trans_type = 'BILL' AND entity_id = $2`,
      [id, entityId],
    );

    await client.unsafe(
      `DELETE FROM batch_stock_layers WHERE ref_id = $1 AND ref_type = 'BILL' AND entity_id = $2`,
      [id, entityId],
    );

    await client.unsafe(`DELETE FROM bill_items WHERE bill_id = $1`, [id]);

    const itemsData: any[] = [];
    if (dto.lineItems && dto.lineItems.length > 0) {
      const itemsToInsert = dto.lineItems.map((item: any) => {
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
          account_id: item.account_id || item.accountId || null,
          customer_id: item.customer_id || item.customerId || null,
          description: item.description || null,
          hsn_code: item.hsn_code || item.hsnCode || null,
          quantity: qty.toString(),
          rate: rate.toString(),
          discount_type: discType,
          discount_value: discVal.toString(),
          discount_accounts_id: item.discount_account_id || item.discountAccountId || null,
          discount_amount: computedDiscountAmt.toString(),
          tax_id: item.tax_id || item.taxId || null,
          tax_amount: item.tax_amount?.toString() || "0",
          line_total: item.amount?.toString() || "0",
          purchase_receive_item_id: item.purchaseReceiveItemId || item.purchase_receive_item_id || null,
        };
      });

      for (const itemRow of itemsToInsert) {
        const iKeys = Object.keys(itemRow);
        const iCols = iKeys.map((k) => `"${k}"`).join(", ");
        const iPlaceholders = iKeys.map((_, i) => `$${i + 1}`).join(", ");
        const iValues: any[] = Object.values(itemRow);

        const rows = await client.unsafe(
          `INSERT INTO bill_items (${iCols}) VALUES (${iPlaceholders}) RETURNING *`,
          iValues,
        );
        if (rows[0]) itemsData.push(rows[0]);
      }

      const batchesToInsert: any[] = [];
      for (let i = 0; i < dto.lineItems.length; i++) {
        const item = dto.lineItems[i];
        const insertedItem = itemsData[i];

        if (item.batches && item.batches.length > 0 && insertedItem) {
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

            let batchId: string | null = null;
            let layerId: string | null = null;
            let resolvedBinId = binIdInput || null;

            if (shouldUpdateStock) {
              const existingBatches = await client.unsafe(
                `SELECT id FROM batch_master WHERE batch_no = $1 AND product_id = $2 LIMIT 1`,
                [batchNo, item.item_id],
              );
              batchId = existingBatches[0]?.id;

              if (!batchId) {
                const newBatchRows = await client.unsafe(
                  `INSERT INTO batch_master (batch_no, product_id, expiry_date, unit_pack, manufacture_batch_number, manufacture_exp, created_by_entity_id, source_type)
                   VALUES ($1, $2, $3, $4, $5, $6, $7, 'BILL') RETURNING *`,
                  [
                    batchNo,
                    item.item_id,
                    expiryDate || new Date(Date.now() + 365*24*60*60*1000).toISOString().split('T')[0],
                    unitPack,
                    batchNo,
                    expiryDate,
                    entityId,
                  ],
                );
                batchId = newBatchRows[0]?.id;
              }

              if (!resolvedBinId) {
                const warehouseId = warehouseIdInput || dto.warehouseId || dto.warehouse_id;
                if (warehouseId) {
                  const firstBin = await client.unsafe(
                    `SELECT id FROM bin_master WHERE warehouse_id = $1 LIMIT 1`,
                    [warehouseId],
                  );
                  resolvedBinId = firstBin[0]?.id;
                }
              }

              const isFromReceive = !!(
                (dto.sourceType || dto.source_type)?.toLowerCase() === 'purchase_receive' ||
                (dto.sourceType || dto.source_type)?.toLowerCase() === 'purchase-receive' ||
                (dto.sourceId || dto.source_id) ||
                (item.purchaseReceiveItemId || item.purchase_receive_item_id)
              );

              if (isFromReceive) {
                let layerSql = `SELECT id FROM batch_stock_layers WHERE batch_id = $1 AND product_id = $2 AND entity_id = $3`;
                const layerParams: any[] = [batchId, item.item_id, entityId];

                if (dto.sourceId || dto.source_id) {
                  layerParams.push(dto.sourceId || dto.source_id);
                  layerSql += ` AND ref_id = $${layerParams.length} AND ref_type = 'PURCHASE_RECEIVE'`;
                }
                layerSql += ` LIMIT 1`;

                const existingLayers = await client.unsafe(layerSql, layerParams);
                layerId = existingLayers[0]?.id || null;
              } else {
                const targetWarehouseId = warehouseIdInput || dto.warehouseId || dto.warehouse_id;
                const existingLayers = await client.unsafe(
                  `SELECT * FROM batch_stock_layers WHERE batch_id = $1 AND product_id = $2 AND entity_id = $3 AND warehouse_id = $4 AND bin_id = $5 LIMIT 1`,
                  [batchId, item.item_id, entityId, targetWarehouseId, resolvedBinId],
                );
                const existingLayer = existingLayers[0];

                if (existingLayer) {
                  const updatedLayers = await client.unsafe(
                    `UPDATE batch_stock_layers SET qty = $1, foc_qty = $2, updated_at = NOW() WHERE id = $3 RETURNING *`,
                    [
                      Number(existingLayer.qty) + Number(quantity),
                      Number(existingLayer.foc_qty) + Number(focQty),
                      existingLayer.id,
                    ],
                  );
                  layerId = updatedLayers[0]?.id;
                } else {
                  const newLayers = await client.unsafe(
                    `INSERT INTO batch_stock_layers (batch_id, product_id, entity_id, warehouse_id, bin_id, qty, foc_qty, purchase_rate, mrp, ref_type, ref_id)
                     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'BILL', $10) RETURNING *`,
                    [
                      batchId,
                      item.item_id,
                      entityId,
                      targetWarehouseId,
                      resolvedBinId,
                      quantity,
                      focQty,
                      purchaseRate,
                      mrp,
                      id,
                    ],
                  );
                  layerId = newLayers[0]?.id;
                }
              }

              await client.unsafe(
                `INSERT INTO batch_transactions (batch_id, layer_id, product_id, entity_id, warehouse_id, bin_id, trans_type, stock_effect_type, qty_in, rate, ref_id, ref_no)
                 VALUES ($1, $2, $3, $4, $5, $6, 'BILL', 'ACCOUNTING', $7, $8, $9, $10)`,
                [
                  batchId,
                  layerId,
                  item.item_id,
                  entityId,
                  warehouseIdInput || dto.warehouseId || dto.warehouse_id,
                  resolvedBinId,
                  quantity,
                  purchaseRate,
                  id,
                  dto.billNumber || dto.bill_number || `BILL-${Date.now()}`,
                ],
              );
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
        for (const bRow of batchesToInsert) {
          const bKeys = Object.keys(bRow);
          const bCols = bKeys.map((k) => `"${k}"`).join(", ");
          const bPlaceholders = bKeys.map((_, i) => `$${i + 1}`).join(", ");
          const bValues: any[] = Object.values(bRow);

          await client.unsafe(
            `INSERT INTO bill_item_batches (${bCols}) VALUES (${bPlaceholders})`,
            bValues,
          );
        }
      }
    }

    if (dto.orderNumber) {
      await updatePurchaseOrderStatusByOrderNumber(client, dto.orderNumber, entityId);
    }

    await this.postBillTransactions(
      id,
      entityId,
      tenant?.orgId || dto.orgId || '00000000-0000-0000-0000-000000000000',
      dto,
    );

    return this.findOne(id, tenant ?? ({ entityId } as any));
  }

  async findAll(
    tenant: TenantContext,
    page: number = 1,
    limit: number = 100,
    search?: string,
    status?: string,
  ) {
    const offset = (page - 1) * limit;

    let sqlQuery = `SELECT b.*, v.display_name as vendor_display_name, v.company_name as vendor_company_name, w.name as warehouse_name, pt.term_name as payment_term_name
                    FROM bills b
                    LEFT JOIN vendors v ON v.id = b.vendor_id
                    LEFT JOIN warehouses w ON w.id = b.warehouse_id
                    LEFT JOIN payment_terms pt ON pt.id = b.payment_term_id
                    WHERE b.entity_id = $1 AND b.is_delete = false`;
    let countQuery = `SELECT COUNT(*)::int as count FROM bills WHERE entity_id = $1 AND is_delete = false`;
    const params: any[] = [tenant.entityId];

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      const sIdx = params.length;
      sqlQuery += ` AND (b.bill_number ILIKE $${sIdx} OR b.order_number ILIKE $${sIdx})`;
      countQuery += ` AND (bill_number ILIKE $${sIdx} OR order_number ILIKE $${sIdx})`;
    }

    if (status && status.trim()) {
      params.push(status.trim());
      const stIdx = params.length;
      sqlQuery += ` AND b.status = $${stIdx}`;
      countQuery += ` AND status = $${stIdx}`;
    }

    sqlQuery += ` ORDER BY b.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    const [rows, countRes] = await Promise.all([
      client.unsafe(sqlQuery, [...params, limit, offset]),
      client.unsafe(countQuery, params),
    ]);

    const totalCount = countRes[0]?.count ?? 0;

    const formattedData = (rows ?? []).map((row: any) => ({
      ...row,
      vendor: row.vendor_id ? { display_name: row.vendor_display_name, company_name: row.vendor_company_name } : null,
      warehouse: row.warehouse_id ? { name: row.warehouse_name } : null,
      payment_terms: row.payment_term_id ? { term_name: row.payment_term_name } : null,
    }));

    return {
      data: formattedData,
      meta: {
        total: totalCount,
        page,
        limit,
        totalPages: Math.ceil(totalCount / limit),
      },
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const rows = await client.unsafe(
      `SELECT * FROM bills WHERE id = $1 AND entity_id = $2 AND is_delete = false LIMIT 1`,
      [id, tenant.entityId],
    );

    const data = rows[0];
    if (!data) {
      throw new HttpException(`Bill not found`, HttpStatus.NOT_FOUND);
    }

    if (data.vendor_id) {
      const v = await client.unsafe(`SELECT * FROM vendors WHERE id = $1 LIMIT 1`, [data.vendor_id]);
      data.vendor = v[0] ?? null;
    }
    if (data.warehouse_id) {
      const w = await client.unsafe(`SELECT name FROM warehouses WHERE id = $1 LIMIT 1`, [data.warehouse_id]);
      data.warehouse = w[0] ?? null;
    }
    if (data.payment_term_id) {
      const pt = await client.unsafe(`SELECT term_name FROM payment_terms WHERE id = $1 LIMIT 1`, [data.payment_term_id]);
      data.payment_terms = pt[0] ?? null;
    }

    const items = await client.unsafe(
      `SELECT * FROM bill_items WHERE bill_id = $1`,
      [id],
    );

    for (const item of items ?? []) {
      if (item.product_id) {
        const p = await client.unsafe(`SELECT * FROM products WHERE id = $1 LIMIT 1`, [item.product_id]);
        item.product = p[0] ?? null;
      }
      if (item.account_id) {
        const acc = await client.unsafe(`SELECT * FROM accounts WHERE id = $1 LIMIT 1`, [item.account_id]);
        item.account = acc[0] ?? null;
      }
      if (item.customer_id) {
        const c = await client.unsafe(`SELECT * FROM customers WHERE id = $1 LIMIT 1`, [item.customer_id]);
        item.customer = c[0] ?? null;
      }

      const batches = await client.unsafe(
        `SELECT bib.*, bm.batch_no, bm.expiry_date as bm_expiry FROM bill_item_batches bib
         LEFT JOIN batch_master bm ON bm.id = bib.batch_id
         WHERE bib.bill_item_id = $1`,
        [item.id],
      );
      item.batches = (batches ?? []).map((b: any) => ({
        ...b,
        batch: b.batch_id ? { batch_no: b.batch_no, expiry_date: b.bm_expiry } : null,
      }));
    }

    data.line_items = items ?? [];

    return data;
  }

  async updateBillStatus(id: string, entityId: string, status: string, reason: string) {
    const rows = await client.unsafe(
      `SELECT status, order_number FROM bills WHERE id = $1 AND entity_id = $2 LIMIT 1`,
      [id, entityId],
    );

    const bill = rows[0];
    if (!bill) {
      throw new HttpException(`Bill not found`, HttpStatus.NOT_FOUND);
    }

    const oldStatus = (bill.status || '').toLowerCase();
    const newStatus = status.toLowerCase();
    const statusChangedToActive = (oldStatus === 'draft' || oldStatus === 'void') && (newStatus !== 'draft' && newStatus !== 'void');

    const updatePayload: any = {
      status,
      updated_at: new Date().toISOString(),
    };

    if (status === 'void') {
      updatePayload.reason_to_void = reason;
    } else if (status === 'draft') {
      updatePayload.reason_to_draft = reason;
    }

    const updatedRows = await client.unsafe(
      `UPDATE bills SET status = $1, updated_at = NOW() WHERE id = $2 AND entity_id = $3 RETURNING *`,
      [status, id, entityId],
    );

    const updatedBill = updatedRows[0];

    if (newStatus === 'void' || newStatus === 'draft') {
      await this.reverseStockForBill(id, entityId);
    } else if (statusChangedToActive) {
      await this.applyStockForBill(id, entityId);
    }

    if (bill.order_number) {
      await updatePurchaseOrderStatusByOrderNumber(client, bill.order_number, entityId);
    }

    return updatedBill;
  }

  private async applyStockForBill(id: string, entityId: string) {
    const bills = await client.unsafe(`SELECT * FROM bills WHERE id = $1 LIMIT 1`, [id]);
    const bill = bills[0];
    if (!bill) return;

    const items = await client.unsafe(`SELECT * FROM bill_items WHERE bill_id = $1`, [id]);
    if (!items || items.length === 0) return;

    for (const item of items) {
      const batches = await client.unsafe(
        `SELECT * FROM bill_item_batches WHERE bill_item_id = $1`,
        [item.id],
      );

      if (!batches || batches.length === 0) continue;

      for (const batch of batches) {
        const batchNo = batch.manufacture_batch_no || `BATCH-${Date.now()}`;
        const expiryDate = batch.expiry_date || null;
        const unitPack = batch.unit_pack || null;
        const focQty = Number(batch.foc_quantity || 0);
        const purchaseRate = Number(batch.purchase_rate || 0);
        const mrp = Number(batch.mrp || 0);
        const quantity = Number(batch.quantity || 0);
        const binIdInput = batch.bin_id || null;
        const warehouseIdInput = batch.warehouse_id || bill.warehouse_id || null;

        let batchId: string | null = null;
        let layerId: string | null = null;
        let resolvedBinId = binIdInput || null;

        const existingBatches = await client.unsafe(
          `SELECT id FROM batch_master WHERE batch_no = $1 AND product_id = $2 LIMIT 1`,
          [batchNo, item.product_id],
        );
        batchId = existingBatches[0]?.id;

        if (!batchId) {
          const newBatches = await client.unsafe(
            `INSERT INTO batch_master (batch_no, product_id, expiry_date, unit_pack, manufacture_batch_number, manufacture_exp, created_by_entity_id, source_type)
             VALUES ($1, $2, $3, $4, $5, $6, $7, 'BILL') RETURNING *`,
            [
              batchNo,
              item.product_id,
              expiryDate || new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
              unitPack,
              batchNo,
              expiryDate,
              entityId,
            ],
          );
          batchId = newBatches[0]?.id;
        }

        if (!resolvedBinId && warehouseIdInput) {
          const firstBin = await client.unsafe(
            `SELECT id FROM bin_master WHERE warehouse_id = $1 LIMIT 1`,
            [warehouseIdInput],
          );
          resolvedBinId = firstBin[0]?.id;
        }

        const existingLayers = await client.unsafe(
          `SELECT * FROM batch_stock_layers WHERE batch_id = $1 AND product_id = $2 AND entity_id = $3 AND warehouse_id = $4 AND bin_id = $5 LIMIT 1`,
          [batchId, item.product_id, entityId, warehouseIdInput, resolvedBinId],
        );
        const existingLayer = existingLayers[0];

        if (existingLayer) {
          const updatedLayers = await client.unsafe(
            `UPDATE batch_stock_layers SET qty = $1, foc_qty = $2, updated_at = NOW() WHERE id = $3 RETURNING *`,
            [
              Number(existingLayer.qty) + Number(quantity),
              Number(existingLayer.foc_qty) + Number(focQty),
              existingLayer.id,
            ],
          );
          layerId = updatedLayers[0]?.id;
        } else {
          const newLayers = await client.unsafe(
            `INSERT INTO batch_stock_layers (batch_id, product_id, entity_id, warehouse_id, bin_id, qty, foc_qty, purchase_rate, mrp, ref_type, ref_id)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'BILL', $10) RETURNING *`,
            [
              batchId,
              item.product_id,
              entityId,
              warehouseIdInput,
              resolvedBinId,
              quantity,
              focQty,
              purchaseRate,
              mrp,
              id,
            ],
          );
          layerId = newLayers[0]?.id;
        }

        await client.unsafe(
          `UPDATE bill_item_batches SET batch_id = $1, layer_id = $2 WHERE id = $3`,
          [batchId, layerId, batch.id],
        );

        await client.unsafe(
          `INSERT INTO batch_transactions (batch_id, layer_id, product_id, entity_id, warehouse_id, bin_id, trans_type, stock_effect_type, qty_in, rate, ref_id, ref_no)
           VALUES ($1, $2, $3, $4, $5, $6, 'BILL', 'ACCOUNTING', $7, $8, $9, $10)`,
          [
            batchId,
            layerId,
            item.product_id,
            entityId,
            warehouseIdInput,
            resolvedBinId,
            quantity,
            purchaseRate,
            id,
            bill.bill_number || `BILL-${Date.now()}`,
          ],
        );
      }
    }
  }

  private async reverseStockForBill(id: string, entityId: string) {
    const billItems = await client.unsafe(
      `SELECT id FROM bill_items WHERE bill_id = $1`,
      [id],
    );

    const itemIds = (billItems || []).map((item: any) => item.id);
    if (itemIds.length === 0) return;

    const itemBatches = await client.unsafe(
      `SELECT layer_id, quantity, foc_quantity FROM bill_item_batches WHERE bill_item_id = ANY($1)`,
      [itemIds],
    );

    if (itemBatches && itemBatches.length > 0) {
      for (const batch of itemBatches) {
        if (batch.layer_id) {
          const layers = await client.unsafe(
            `SELECT * FROM batch_stock_layers WHERE id = $1 LIMIT 1`,
            [batch.layer_id],
          );
          const layer = layers[0];

          if (layer) {
            const billQty = Number(batch.quantity || 0);
            const billFocQty = Number(batch.foc_quantity || 0);

            if (layer.ref_type === 'BILL' && layer.ref_id === id) {
              await client.unsafe(`DELETE FROM batch_stock_layers WHERE id = $1`, [layer.id]);
            } else {
              const newQty = Math.max(0, Number(layer.qty || 0) - billQty);
              const newFocQty = Math.max(0, Number(layer.foc_qty || 0) - billFocQty);
              await client.unsafe(
                `UPDATE batch_stock_layers SET qty = $1, foc_qty = $2, updated_at = NOW() WHERE id = $3`,
                [newQty, newFocQty, layer.id],
              );
            }
          }
        }
      }
    }

    await client.unsafe(
      `DELETE FROM batch_transactions WHERE ref_id = $1 AND trans_type = 'BILL' AND entity_id = $2`,
      [id, entityId],
    );

    await client.unsafe(
      `DELETE FROM batch_stock_layers WHERE ref_id = $1 AND ref_type = 'BILL' AND entity_id = $2`,
      [id, entityId],
    );
  }

  async remove(id: string, tenant: TenantContext) {
    const bills = await client.unsafe(
      `SELECT order_number, bill_number FROM bills WHERE id = $1 AND entity_id = $2 LIMIT 1`,
      [id, tenant.entityId],
    );
    const bill = bills[0];

    const originalNumber = bill?.bill_number;
    const newNumber = originalNumber ? (originalNumber.startsWith('SD-') ? originalNumber : `SD-${originalNumber}`) : undefined;

    try {
      if (newNumber) {
        await client.unsafe(
          `UPDATE bills SET is_delete = true, bill_number = $1 WHERE id = $2 AND entity_id = $3`,
          [newNumber, id, tenant.entityId],
        );
      } else {
        await client.unsafe(
          `UPDATE bills SET is_delete = true WHERE id = $1 AND entity_id = $2`,
          [id, tenant.entityId],
        );
      }
    } catch (error: any) {
      throw new HttpException(
        `Failed to delete bill: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }

    await client.unsafe(
      `DELETE FROM journal_entry_lines WHERE source_id = $1 AND source_type = 'BILL' AND entity_id = $2`,
      [id, tenant.entityId],
    );

    if (bill && bill.order_number) {
      await updatePurchaseOrderStatusByOrderNumber(client, bill.order_number, tenant.entityId);
    }

    return { message: "Bill deleted successfully" };
  }

  private async postBillTransactions(
    billId: string,
    entityId: string,
    orgId: string,
    dto: any,
  ) {
    await client.unsafe(
      `DELETE FROM journal_entry_lines WHERE source_id = $1 AND source_type = 'BILL' AND entity_id = $2`,
      [billId, entityId],
    );

    if (dto.status?.toLowerCase() === 'void') {
      return;
    }

    const dbAccounts = await client.unsafe(
      `SELECT id, user_account_name, system_account_name, account_type FROM accounts WHERE entity_id = $1 AND is_active = true`,
      [entityId],
    );

    if (!dbAccounts || dbAccounts.length === 0) return;

    const existingJE = await client.unsafe(
      `SELECT id, created_by FROM journal_entries WHERE entity_id = $1 AND source_document_type = 'BILL' AND source_document_id = $2 LIMIT 1`,
      [entityId, billId],
    );

    const journalEntryId = existingJE[0]?.id || uuidv4();

    if (existingJE[0]?.id) {
      await client.unsafe(`DELETE FROM journal_entry_lines WHERE journal_entry_id = $1`, [existingJE[0].id]);
    }

    const billNumber = dto.billNumber || dto.bill_number || 'BILL';
    const billDate = dto.billDate || dto.bill_date || new Date().toISOString().split('T')[0];
    const defaultOrgId = '00000000-0000-0000-0000-000000000000';
    const currentUserId = dto.userId || dto.created_by || dto.updated_by || null;

    if (existingJE[0]?.id) {
      await client.unsafe(
        `UPDATE journal_entries SET
           org_id = $1, entity_id = $2, journal_number = $3, journal_type = 'BILL',
           journal_date = $4, posting_date = $4, reference_number = $5, narration = $6,
           source_module = 'PURCHASES', source_document_type = 'BILL', source_document_id = $7,
           currency_code = 'INR', exchange_rate = 1.0, status = 'POSTED', updated_by = $8, updated_at = NOW()
         WHERE id = $9`,
        [
          orgId || defaultOrgId,
          entityId,
          `JE-${billNumber}`,
          billDate,
          billNumber,
          dto.notes || `Purchase Bill ${billNumber}`,
          billId,
          currentUserId,
          journalEntryId,
        ],
      );
    } else {
      await client.unsafe(
        `INSERT INTO journal_entries (id, org_id, entity_id, fiscal_year_id, journal_number, journal_type, journal_date, posting_date, reference_number, narration, source_module, source_document_type, source_document_id, currency_code, exchange_rate, status, created_by, updated_by)
         VALUES ($1, $2, $3, null, $4, 'BILL', $5, $5, $6, $7, 'PURCHASES', 'BILL', $8, 'INR', 1.0, 'POSTED', $9, $9)`,
        [
          journalEntryId,
          orgId || defaultOrgId,
          entityId,
          `JE-${billNumber}`,
          billDate,
          billNumber,
          dto.notes || `Purchase Bill ${billNumber}`,
          billId,
          existingJE[0]?.created_by || currentUserId,
        ],
      );
    }

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

    const discountAmount = parseFloat(dto.discountAmount?.toString() || dto.discountTotal?.toString() || '0');
    const taxAmount = parseFloat(dto.taxAmount?.toString() || dto.taxTotal?.toString() || '0');
    const tdsAmount = parseFloat(dto.tdsTotal?.toString() || '0');
    const tcsAmount = parseFloat(dto.tcsTotal?.toString() || '0');
    const adjustmentAmount = parseFloat(dto.adjustment?.toString() || dto.adjustmentAmount?.toString() || '0');

    const accountsPayableId = findAccount(['Accounts Payable'], ['Accounts Payable']);
    const purchaseDiscountId = findAccount(['Purchase Discount', 'Purchase Discounts', 'Discount'], ['Income', 'Other Income', 'Expense', 'Other Expense']);
    const otherExpensesId = findAccount(['Other Expenses', 'Other Expense', 'Adjustment'], ['Expense', 'Other Expense']);
    const tdsPayableId = findAccount(['TDS Payable', 'TDS'], ['Other Current Liability', 'Other Liability']);
    const tcsPayableId = findAccount(['TCS Payable', 'TCS'], ['Other Current Liability', 'Other Liability']);
    const tcsReceivableId = findAccount(['TCS Receivable', 'TCS'], ['Other Current Asset', 'Other Asset']);
    const inputSgstId = findAccount(['Input SGST', 'SGST'], ['Other Current Asset', 'Other Asset', 'Other Current Liability', 'Other Liability']);
    const inputCgstId = findAccount(['Input CGST', 'CGST'], ['Other Current Asset', 'Other Asset', 'Other Current Liability', 'Other Liability']);
    const inputIgstId = findAccount(['Input IGST', 'IGST'], ['Other Current Asset', 'Other Asset', 'Other Current Liability', 'Other Liability']);

    const itemAccountsMap = new Map<string, number>();
    const lineItemDiscountsMap = new Map<string, number>();

    for (const item of dto.lineItems || []) {
      const accId = item.account_id || item.accountId;
      const qty = parseFloat(item.quantity?.toString() || '0');
      const rate = parseFloat(item.rate?.toString() || '0');
      const itemGross = qty * rate;

      if (accId) {
        itemAccountsMap.set(accId, (itemAccountsMap.get(accId) || 0) + itemGross);
      }

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

    const isGstBill = taxAmount > 0.0001;
    let isIGST = false;

    if (isGstBill) {
      const headerTaxName = (dto.taxName || dto.tax_name || dto.tax_rate_name || dto.taxRateName || '').toUpperCase();
      const headerTaxType = (dto.taxType || dto.tax_type || dto.tax_rate_type || dto.taxRateType || '').toUpperCase();

      if (headerTaxName.includes('IGST') || headerTaxType.includes('IGST')) {
        isIGST = true;
      }

      const headerTaxId = dto.tax_id || dto.taxId;
      if (!isIGST && headerTaxId) {
        const headerRate = await client.unsafe(
          `SELECT tax_type, tax_name FROM tax_rates WHERE id = $1 LIMIT 1`,
          [headerTaxId],
        );
        if (headerRate[0]) {
          const rateType = (headerRate[0].tax_type || '').toUpperCase();
          const rateName = (headerRate[0].tax_name || '').toUpperCase();
          if (rateType === 'IGST' || rateName.includes('IGST')) {
            isIGST = true;
          }
        }
      }

      if (!isIGST && dto.lineItems?.length > 0) {
        for (const item of dto.lineItems) {
          const itemTaxName = (item.taxName || item.tax_name || item.tax_rate_name || '').toUpperCase();
          const itemTaxType = (item.taxType || item.tax_type || '').toUpperCase();
          if (itemTaxName.includes('IGST') || itemTaxType.includes('IGST')) {
            isIGST = true;
            break;
          }
        }

        if (!isIGST) {
          const taxIds = dto.lineItems.map((item: any) => item.tax_id || item.taxId).filter(Boolean);
          if (taxIds.length > 0) {
            const rates = await client.unsafe(
              `SELECT tax_type, tax_name FROM tax_rates WHERE id = ANY($1)`,
              [taxIds],
            );
            if (rates && rates.some((r: any) =>
              (r.tax_type || '').toUpperCase() === 'IGST' ||
              (r.tax_name || '').toUpperCase().includes('IGST')
            )) {
              isIGST = true;
            }
          }
        }
      }
    }

    const entries: any[] = [];
    const addEntry = (accountId: string | null, type: string, debit: number, credit: number) => {
      if (!accountId) return;
      const dVal = Math.round(debit * 100) / 100;
      const cVal = Math.round(credit * 100) / 100;
      if (dVal > 0.0001 || cVal > 0.0001) {
        entries.push({
          id: uuidv4(),
          journal_entry_id: journalEntryId,
          entity_id: entityId,
          org_id: orgId || defaultOrgId,
          account_id: accountId,
          transaction_date: dto.billDate || dto.bill_date || new Date().toISOString(),
          reference_number: billNumber,
          description: dto.notes || 'Purchase Bill transaction',
          debit: dVal,
          credit: cVal,
          source_id: billId,
          source_type: 'BILL',
          contact_id: dto.vendorId || null,
          contact_type: dto.vendorId ? 'vendor' : null,
        });
      }
    };

    if (!isGstBill) {
      for (const [accId, amt] of itemAccountsMap.entries()) {
        addEntry(accId, 'Inventory Asset', amt, 0);
      }
      if (adjustmentAmount > 0.0001) {
        addEntry(otherExpensesId, 'Other Expenses (Adjustment)', adjustmentAmount, 0);
      }
      if (discountAmount > 0.0001) {
        if (lineItemDiscountsMap.size > 0) {
          for (const [accId, amt] of lineItemDiscountsMap.entries()) {
            addEntry(accId, 'Purchase Discount', 0, amt);
          }
        } else {
          const transDiscountAccId = dto.discountAccountId || dto.discount_account_id || purchaseDiscountId;
          addEntry(transDiscountAccId, 'Purchase Discount', 0, discountAmount);
        }
      }
      if (adjustmentAmount < -0.0001) {
        addEntry(otherExpensesId, 'Other Expenses (Adjustment)', 0, Math.abs(adjustmentAmount));
      }
      if (tdsAmount > 0.0001) {
        addEntry(tdsPayableId, 'TDS Payable', 0, tdsAmount);
      }
      if (tcsAmount > 0.0001) {
        addEntry(tcsPayableId, 'TCS Payable', 0, tcsAmount);
      }

      const totalDebits = entries.reduce((sum, e) => sum + (e.debit || 0), 0);
      const totalOtherCredits = entries.reduce((sum, e) => sum + (e.credit || 0), 0);
      const apCredit = Math.max(0, totalDebits - totalOtherCredits);

      addEntry(accountsPayableId, 'Accounts Payable', 0, apCredit);
    } else {
      for (const [accId, amt] of itemAccountsMap.entries()) {
        addEntry(accId, 'Inventory Asset', amt, 0);
      }

      if (isIGST) {
        addEntry(inputIgstId, 'Input IGST', taxAmount, 0);
      } else {
        addEntry(inputCgstId, 'Input CGST', taxAmount / 2, 0);
        addEntry(inputSgstId, 'Input SGST', taxAmount / 2, 0);
      }

      if (adjustmentAmount > 0.0001) {
        addEntry(otherExpensesId, 'Other Expenses (Adjustment)', adjustmentAmount, 0);
      }
      if (tcsAmount > 0.0001) {
        addEntry(tcsReceivableId, 'TCS Receivable', tcsAmount, 0);
      }
      if (tdsAmount > 0.0001) {
        addEntry(tdsPayableId, 'TDS Payable', 0, tdsAmount);
      }
      if (discountAmount > 0.0001) {
        if (lineItemDiscountsMap.size > 0) {
          for (const [accId, amt] of lineItemDiscountsMap.entries()) {
            addEntry(accId, 'Purchase Discounts', 0, amt);
          }
        } else {
          const transDiscountAccId = dto.discountAccountId || dto.discount_account_id || purchaseDiscountId;
          addEntry(transDiscountAccId, 'Purchase Discounts', 0, discountAmount);
        }
      }
      if (adjustmentAmount < -0.0001) {
        addEntry(otherExpensesId, 'Other Expenses (Adjustment)', 0, Math.abs(adjustmentAmount));
      }

      const totalDebits = entries.reduce((sum, e) => sum + (e.debit || 0), 0);
      const totalOtherCredits = entries.reduce((sum, e) => sum + (e.credit || 0), 0);
      const apCredit = Math.max(0, totalDebits - totalOtherCredits);

      addEntry(accountsPayableId, 'Accounts Payable', 0, apCredit);
    }

    if (entries.length > 0) {
      for (const entry of entries) {
        await client.unsafe(
          `INSERT INTO journal_entry_lines (id, journal_entry_id, entity_id, org_id, account_id, transaction_date, reference_number, description, debit, credit, source_id, source_type, contact_id, contact_type)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`,
          [
            entry.id,
            entry.journal_entry_id,
            entry.entity_id,
            entry.org_id,
            entry.account_id,
            entry.transaction_date,
            entry.reference_number,
            entry.description,
            entry.debit,
            entry.credit,
            entry.source_id,
            entry.source_type,
            entry.contact_id,
            entry.contact_type,
          ],
        );
      }
    }

    try {
      await client.unsafe(
        `UPDATE bills SET journal_id = $1 WHERE id = $2`,
        [journalEntryId, billId],
      );
    } catch (jeBacklinkErr) {
      console.error('Error updating bills journal_id:', jeBacklinkErr);
    }
  }
}
