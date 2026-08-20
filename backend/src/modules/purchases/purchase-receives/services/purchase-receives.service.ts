import { Injectable, NotFoundException } from "@nestjs/common";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../../supabase/supabase.service";
import { CreatePurchaseReceiveDto } from "../dto/create-purchase-receive.dto";
import { UpdatePurchaseReceiveDto } from "../dto/update-purchase-receive.dto";
import { updatePurchaseOrderStatus } from "../../purchase-orders/utils/po-status";
import { client } from "../../../../db/db";

@Injectable()
export class PurchaseReceivesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private escapeRegExp(value: string) {
    return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  private async getNextReceiveNumber(
    tenant: TenantContext,
    prefix: string = "PR-",
  ) {
    const safePrefix = prefix || "PR-";
    const regexPattern = `^${this.escapeRegExp(safePrefix)}[0-9]+$`;

    const data = await client.unsafe(
      `SELECT purchase_receive_number FROM purchase_receives WHERE purchase_receive_number ~ $1 ORDER BY purchase_receive_number DESC LIMIT 1000`,
      [regexPattern],
    );

    let maxNumber = 0;
    if (data && data.length > 0) {
      for (const row of data) {
        const latest = row.purchase_receive_number;
        const match = latest.match(/(\d+)$/);
        if (match) {
          const num = Number.parseInt(match[1], 10);
          if (num > maxNumber) maxNumber = num;
        }
      }
    }

    const nextNumber = maxNumber + 1;
    return {
      prefix: safePrefix,
      nextNumber,
      formatted: `${safePrefix}${nextNumber.toString().padStart(5, "0")}`,
    };
  }

  private async resolveCreateNumber(
    createDto: CreatePurchaseReceiveDto,
    tenant: TenantContext,
  ) {
    const requested = createDto.purchase_receive_number?.toString().trim();

    if (!requested) {
      const generated = await this.getNextReceiveNumber(tenant, "PR-");
      return generated.formatted;
    }

    const countRes = await client.unsafe(
      `SELECT COUNT(*)::int as count FROM purchase_receives WHERE purchase_receive_number = $1`,
      [requested],
    );

    const count = countRes[0]?.count ?? 0;
    if (count === 0) {
      return requested;
    }

    const inferredPrefix = requested.match(/^(.*?)(\d+)$/)?.[1] || "PR-";
    const generated = await this.getNextReceiveNumber(tenant, inferredPrefix);
    return generated.formatted;
  }

  private async insertItemsAndBatches(
    receiveId: string,
    items: CreatePurchaseReceiveDto["items"] | undefined,
    tenant: TenantContext,
    headerWarehouseId?: string | null,
    transactionBinId?: string | null,
    transactionBinLabel?: string | null,
  ) {
    if (!items || items.length === 0) {
      return;
    }

    const createdItems: any[] = [];
    for (const item of items) {
      const { batches, billed, cancelled, ...itemFields } = item;
      const itemToInsert = {
        ...itemFields,
        purchase_receive_id: receiveId,
        warehouse_id: item.warehouse_id ?? headerWarehouseId ?? null,
        bin_id: item.bin_id ?? transactionBinId ?? null,
        bin_label: item.bin_label ?? transactionBinLabel ?? null,
        entity_id: tenant.entityId,
      };

      const keys = Object.keys(itemToInsert);
      const cols = keys.map((k) => `"${k}"`).join(", ");
      const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");
      const values: any[] = Object.values(itemToInsert);

      const rows = await client.unsafe(
        `INSERT INTO purchase_receive_items (${cols}) VALUES (${placeholders}) RETURNING id, item_id`,
        values,
      );
      if (rows[0]) {
        createdItems.push(rows[0]);
      }
    }

    const batchRows: Record<string, unknown>[] = [];
    for (let index = 0; index < items.length; index += 1) {
      const sourceItem = items[index];
      const createdItem = createdItems[index];
      if (
        !createdItem ||
        !sourceItem?.batches ||
        sourceItem.batches.length === 0
      ) {
        continue;
      }

      for (const batch of sourceItem.batches) {
        batchRows.push({
          purchase_receive_item_id: createdItem.id,
          product_id: sourceItem.item_id ?? createdItem.item_id ?? null,
          warehouse_id:
            batch.warehouse_id ??
            sourceItem.warehouse_id ??
            headerWarehouseId ??
            null,
          bin_id: batch.bin_id ?? sourceItem.bin_id ?? transactionBinId ?? null,
          bin_label:
            batch.bin_label ??
            sourceItem.bin_label ??
            transactionBinLabel ??
            null,
          batch_no: batch.batch_no,
          unit_pack: batch.unit_pack ?? null,
          mrp: batch.mrp ?? null,
          ptr: batch.ptr ?? null,
          quantity: batch.quantity ?? 0,
          foc_qty: batch.foc ?? 0,
          manufacture_batch_number: batch.manufacture_batch ?? null,
          manufacture_date: batch.manufacture_date ?? null,
          expiry_date: batch.expiry_date ?? null,
          is_damaged: batch.is_damaged ?? false,
          damaged_qty: batch.damaged_qty ?? 0,
          entity_id: tenant.entityId,
        });
      }
    }

    if (batchRows.length > 0) {
      for (const bRow of batchRows) {
        const bKeys = Object.keys(bRow);
        const bCols = bKeys.map((k) => `"${k}"`).join(", ");
        const bPlaceholders = bKeys.map((_, i) => `$${i + 1}`).join(", ");
        const bValues: any[] = Object.values(bRow);

        await client.unsafe(
          `INSERT INTO purchase_receive_item_batches (${bCols}) VALUES (${bPlaceholders})`,
          bValues,
        );
      }
    }
  }

  private async applyStockUpdates(
    items: any[],
    tenant: TenantContext,
    receiveId: string,
    receiveNumber: string,
    headerWarehouseId?: string | null,
  ) {
    for (const item of items) {
      if (!item.batches) continue;
      for (const batch of item.batches) {
        const existingBatches = await client.unsafe(
          `SELECT id FROM batch_master WHERE batch_no = $1 AND product_id = $2 LIMIT 1`,
          [batch.batch_no, item.item_id],
        );

        let batchId = existingBatches[0]?.id;

        if (!batchId) {
          const newBatchRows = await client.unsafe(
            `INSERT INTO batch_master (batch_no, product_id, expiry_date, unit_pack, manufacture_batch_number, manufacture_exp, created_by_entity_id, source_type)
             VALUES ($1, $2, $3, $4, $5, $6, $7, 'PURCHASE_RECEIVE') RETURNING *`,
            [
              batch.batch_no,
              item.item_id,
              batch.expiry_date,
              batch.unit_pack ?? null,
              batch.manufacture_batch ?? null,
              batch.manufacture_date ?? null,
              tenant.entityId,
            ],
          );
          batchId = newBatchRows[0]?.id;
        }

        let resolvedBinId = batch.bin_id ?? item.bin_id;
        if (!resolvedBinId) {
          const warehouseId =
            batch.warehouse_id ?? item.warehouse_id ?? headerWarehouseId;
          if (warehouseId) {
            const firstBin = await client.unsafe(
              `SELECT id FROM bin_master WHERE warehouse_id = $1 LIMIT 1`,
              [warehouseId],
            );
            resolvedBinId = firstBin[0]?.id;
          }
        }

        const targetWarehouseId =
          batch.warehouse_id ?? item.warehouse_id ?? headerWarehouseId;

        const existingLayers = await client.unsafe(
          `SELECT * FROM batch_stock_layers WHERE batch_id = $1 AND product_id = $2 AND entity_id = $3 AND warehouse_id = $4 AND bin_id = $5 LIMIT 1`,
          [batchId, item.item_id, tenant.entityId, targetWarehouseId, resolvedBinId],
        );

        const existingLayer = existingLayers[0];
        let layer: any;
        if (existingLayer) {
          const updatedLayers = await client.unsafe(
            `UPDATE batch_stock_layers SET qty = $1, foc_qty = $2, updated_at = NOW() WHERE id = $3 RETURNING *`,
            [
              Number(existingLayer.qty) + Number(batch.quantity),
              Number(existingLayer.foc_qty) + Number(batch.foc ?? 0),
              existingLayer.id,
            ],
          );
          layer = updatedLayers[0];
        } else {
          const newLayers = await client.unsafe(
            `INSERT INTO batch_stock_layers (batch_id, product_id, entity_id, warehouse_id, bin_id, qty, foc_qty, purchase_rate, mrp, ref_type, ref_id)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'PURCHASE_RECEIVE', $10) RETURNING *`,
            [
              batchId,
              item.item_id,
              tenant.entityId,
              targetWarehouseId,
              resolvedBinId,
              batch.quantity,
              batch.foc ?? 0,
              batch.ptr ?? 0,
              batch.mrp ?? 0,
              receiveId,
            ],
          );
          layer = newLayers[0];
        }

        await client.unsafe(
          `INSERT INTO batch_transactions (batch_id, layer_id, product_id, entity_id, warehouse_id, bin_id, trans_type, stock_effect_type, qty_in, rate, ref_id, ref_no)
           VALUES ($1, $2, $3, $4, $5, $6, 'PURCHASE_RECEIVE', 'PHYSICAL', $7, $8, $9, $10)`,
          [
            batchId,
            layer.id,
            item.item_id,
            tenant.entityId,
            targetWarehouseId,
            resolvedBinId,
            batch.quantity,
            batch.ptr ?? 0,
            receiveId,
            receiveNumber,
          ],
        );
      }
    }
  }

  async findAll(
    tenant: TenantContext,
    page: number = 1,
    limit: number = 100,
    search?: string,
    status?: string,
  ) {
    const offset = (page - 1) * limit;

    let sqlQuery = `SELECT * FROM purchase_receives WHERE entity_id = $1 AND is_delete = false`;
    let countQuery = `SELECT COUNT(*)::int as count FROM purchase_receives WHERE entity_id = $1 AND is_delete = false`;
    const params: any[] = [tenant.entityId];

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      const sIdx = params.length;
      sqlQuery += ` AND (purchase_receive_number ILIKE $${sIdx} OR purchase_order_number ILIKE $${sIdx} OR vendor_name ILIKE $${sIdx})`;
      countQuery += ` AND (purchase_receive_number ILIKE $${sIdx} OR purchase_order_number ILIKE $${sIdx} OR vendor_name ILIKE $${sIdx})`;
    }

    if (status && status.trim()) {
      params.push(status.trim());
      const stIdx = params.length;
      sqlQuery += ` AND status = $${stIdx}`;
      countQuery += ` AND status = $${stIdx}`;
    }

    sqlQuery += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    const [data, countRes] = await Promise.all([
      client.unsafe(sqlQuery, [...params, limit, offset]),
      client.unsafe(countQuery, params),
    ]);

    const totalCount = countRes[0]?.count ?? 0;

    for (const rx of data ?? []) {
      const items = await client.unsafe(
        `SELECT id, quantity_to_receive FROM purchase_receive_items WHERE purchase_receive_id = $1`,
        [rx.id],
      );
      for (const item of items ?? []) {
        const batches = await client.unsafe(
          `SELECT quantity FROM purchase_receive_item_batches WHERE purchase_receive_item_id = $1`,
          [item.id],
        );
        item.batches = batches ?? [];
      }
      rx.items = items ?? [];
    }

    const receiveIds = (data || []).map((r: any) => r.id);
    const poIds = [...new Set((data || []).map((r: any) => r.purchase_order_id).filter((id: any) => !!id))];
    const poNumbers = [...new Set((data || []).map((r: any) => r.purchase_order_number).filter((num: any) => !!num))];

    const receiveIdToBillStatusMap = new Map<string, string>();

    let directBillsData: any[] = [];
    if (receiveIds.length > 0) {
      const dbData = await client.unsafe(
        `SELECT id, source_id, status FROM bills WHERE entity_id = $1 AND is_delete = false AND status != 'void' AND source_type = ANY($2) AND source_id = ANY($3)`,
        [tenant.entityId, ["PURCHASE_RECEIVE", "purchase_receive", "purchase-receive", "PURCHASE-RECEIVE"], receiveIds],
      );

      for (const b of dbData ?? []) {
        const items = await client.unsafe(
          `SELECT quantity FROM bill_items WHERE bill_id = $1`,
          [b.id],
        );
        b.bill_items = items ?? [];
      }
      directBillsData = dbData || [];
    }

    const directBillsByRx = new Map<string, any[]>();
    for (const bill of directBillsData) {
      const rxId = bill.source_id;
      if (rxId) {
        const list = directBillsByRx.get(rxId) ?? [];
        list.push(bill);
        directBillsByRx.set(rxId, list);
      }
    }

    if (poIds.length > 0 && poNumbers.length > 0) {
      const billsData = await client.unsafe(
        `SELECT id, order_number, status FROM bills WHERE entity_id = $1 AND is_delete = false AND status != 'void' AND order_number = ANY($2)`,
        [tenant.entityId, poNumbers],
      );
      for (const b of billsData ?? []) {
        const bItems = await client.unsafe(
          `SELECT product_id, quantity FROM bill_items WHERE bill_id = $1`,
          [b.id],
        );
        b.bill_items = bItems ?? [];
      }

      const allReceivesData = await client.unsafe(
        `SELECT id, purchase_order_id, status FROM purchase_receives WHERE entity_id = $1 AND is_delete = false AND purchase_order_id = ANY($2) ORDER BY created_at ASC`,
        [tenant.entityId, poIds],
      );

      for (const rx of allReceivesData ?? []) {
        const rxItems = await client.unsafe(
          `SELECT id, item_id, quantity_to_receive FROM purchase_receive_items WHERE purchase_receive_id = $1`,
          [rx.id],
        );
        for (const item of rxItems ?? []) {
          const batches = await client.unsafe(
            `SELECT quantity FROM purchase_receive_item_batches WHERE purchase_receive_item_id = $1`,
            [item.id],
          );
          item.batches = batches ?? [];
        }
        rx.items = rxItems ?? [];
      }

      const billsByPo = new Map<string, any[]>();
      for (const bill of billsData || []) {
        const orderNum = bill.order_number;
        if (orderNum) {
          const list = billsByPo.get(orderNum) ?? [];
          list.push(bill);
          billsByPo.set(orderNum, list);
        }
      }

      const receivesByPo = new Map<string, any[]>();
      for (const rx of allReceivesData || []) {
        const poId = rx.purchase_order_id;
        if (poId) {
          const list = receivesByPo.get(poId) ?? [];
          list.push(rx);
          receivesByPo.set(poId, list);
        }
      }

      for (const poId of poIds) {
        const poReceives = receivesByPo.get(poId) ?? [];
        const poNumber = (data || []).find((r: any) => r.purchase_order_id === poId)?.purchase_order_number;
        if (!poNumber) continue;

        const poBills = billsByPo.get(poNumber) ?? [];

        const billedQuantities: Record<string, number> = {};
        for (const bill of poBills) {
          const items = bill.bill_items || [];
          for (const item of items) {
            const prodId = item.product_id;
            if (prodId) {
              billedQuantities[prodId] = (billedQuantities[prodId] ?? 0) + Number(item.quantity || 0);
            }
          }
        }

        for (const rx of poReceives) {
          let totalReceiveQty = 0;
          let totalBilledForThisReceive = 0;

          const rxItems = rx.items || [];
          for (const item of rxItems) {
            const prodId = item.item_id;
            if (!prodId) continue;

            let qtyToReceive = 0;
            if (item.batches && item.batches.length > 0) {
              for (const batch of item.batches) {
                qtyToReceive += Number(batch.quantity || 0);
              }
            } else {
              qtyToReceive = Number(item.quantity_to_receive || 0);
            }

            totalReceiveQty += qtyToReceive;

            const availableBilled = billedQuantities[prodId] ?? 0;
            const allocated = Math.min(availableBilled, qtyToReceive);
            billedQuantities[prodId] = availableBilled - allocated;
            totalBilledForThisReceive += allocated;
          }

          let rxBillStatus = "none";
          if (totalReceiveQty > 0 && totalBilledForThisReceive > 0) {
            if (totalBilledForThisReceive >= totalReceiveQty - 0.0001) {
              rxBillStatus = "full";
            } else {
              rxBillStatus = "partial";
            }
          }
          receiveIdToBillStatusMap.set(rx.id, rxBillStatus);
        }
      }
    }

    const enrichedData = (data || []).map((receive: any) => {
      let totalQty = 0;
      if (receive.items) {
        for (const item of receive.items) {
          let itemQty = 0;
          if (item.batches && item.batches.length > 0) {
            for (const batch of item.batches) {
              itemQty += Number(batch.quantity || 0);
            }
          } else {
            itemQty = Number(item.quantity_to_receive || 0);
          }
          totalQty += itemQty;
        }
      }

      let bill_status = receiveIdToBillStatusMap.get(receive.id);
      if (!bill_status) {
        let totalBilled = 0;
        const rxBills = directBillsByRx.get(receive.id) ?? [];
        for (const bill of rxBills) {
          if (bill.bill_items) {
            for (const bi of bill.bill_items) {
              totalBilled += Number(bi.quantity || 0);
            }
          }
        }
        if (totalBilled > 0) {
          if (totalBilled >= totalQty - 0.0001) {
            bill_status = "full";
          } else {
            bill_status = "partial";
          }
        } else {
          bill_status = "none";
        }
      }

      return {
        ...receive,
        quantity: totalQty,
        bill_status,
        items: undefined,
      };
    });

    return {
      data: enrichedData,
      meta: {
        total: totalCount,
        page,
        limit,
        totalPages: Math.ceil((totalCount || 0) / limit),
      },
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const rows = await client.unsafe(
      `SELECT * FROM purchase_receives WHERE id = $1 AND entity_id = $2 AND is_delete = false LIMIT 1`,
      [id, tenant.entityId],
    );

    const data = rows[0];
    if (!data) {
      throw new NotFoundException(`Purchase Receive with ID ${id} not found`);
    }

    const items = await client.unsafe(
      `SELECT * FROM purchase_receive_items WHERE purchase_receive_id = $1`,
      [id],
    );

    for (const item of items ?? []) {
      const batches = await client.unsafe(
        `SELECT * FROM purchase_receive_item_batches WHERE purchase_receive_item_id = $1`,
        [item.id],
      );
      item.batches = batches ?? [];
    }
    data.items = items ?? [];

    if (data) {
      data.invoice_total = data.bill_invoice_total ? parseFloat(data.bill_invoice_total) : 0;

      let totalQty = 0;
      if (data.items) {
        for (const item of data.items) {
          let itemQty = 0;
          if (item.batches && item.batches.length > 0) {
            for (const batch of item.batches) {
              itemQty += Number(batch.quantity || 0);
            }
          } else {
            itemQty = Number(item.quantity_to_receive || 0);
          }
          totalQty += itemQty;
        }
      }

      let bill_status = "none";
      if (data.purchase_order_id && data.purchase_order_number) {
        const allReceivesData = await client.unsafe(
          `SELECT id, purchase_order_id, status FROM purchase_receives WHERE entity_id = $1 AND is_delete = false AND purchase_order_id = $2 ORDER BY created_at ASC`,
          [tenant.entityId, data.purchase_order_id],
        );

        for (const rx of allReceivesData ?? []) {
          const rxItems = await client.unsafe(
            `SELECT id, item_id, quantity_to_receive FROM purchase_receive_items WHERE purchase_receive_id = $1`,
            [rx.id],
          );
          for (const item of rxItems ?? []) {
            const batches = await client.unsafe(
              `SELECT quantity FROM purchase_receive_item_batches WHERE purchase_receive_item_id = $1`,
              [item.id],
            );
            item.batches = batches ?? [];
          }
          rx.items = rxItems ?? [];
        }

        const billsData = await client.unsafe(
          `SELECT id, order_number, status FROM bills WHERE entity_id = $1 AND is_delete = false AND status != 'void' AND order_number = $2`,
          [tenant.entityId, data.purchase_order_number],
        );

        for (const b of billsData ?? []) {
          const bItems = await client.unsafe(
            `SELECT product_id, quantity FROM bill_items WHERE bill_id = $1`,
            [b.id],
          );
          b.bill_items = bItems ?? [];
        }

        const billedQuantities: Record<string, number> = {};
        for (const bill of billsData || []) {
          const items = bill.bill_items || [];
          for (const item of items) {
            const prodId = item.product_id;
            if (prodId) {
              billedQuantities[prodId] = (billedQuantities[prodId] ?? 0) + Number(item.quantity || 0);
            }
          }
        }

        for (const rx of allReceivesData || []) {
          let totalRxQty = 0;
          let totalBilledForRx = 0;

          const rxItems = rx.items || [];
          for (const item of rxItems) {
            const prodId = item.item_id;
            if (!prodId) continue;

            let qtyToReceive = 0;
            if (item.batches && item.batches.length > 0) {
              for (const batch of item.batches) {
                qtyToReceive += Number(batch.quantity || 0);
              }
            } else {
              qtyToReceive = Number(item.quantity_to_receive || 0);
            }

            totalRxQty += qtyToReceive;

            const availableBilled = billedQuantities[prodId] ?? 0;
            const allocated = Math.min(availableBilled, qtyToReceive);
            billedQuantities[prodId] = availableBilled - allocated;
            totalBilledForRx += allocated;
          }

          if (rx.id === data.id) {
            if (totalRxQty > 0 && totalBilledForRx > 0) {
              if (totalBilledForRx >= totalRxQty - 0.0001) {
                bill_status = "full";
              } else {
                bill_status = "partial";
              }
            }
            break;
          }
        }
      } else {
        const billsData = await client.unsafe(
          `SELECT id, status FROM bills WHERE entity_id = $1 AND is_delete = false AND status != 'void' AND source_type = ANY($2) AND source_id = $3`,
          [tenant.entityId, ["PURCHASE_RECEIVE", "purchase_receive", "purchase-receive", "PURCHASE-RECEIVE"], id],
        );

        let totalBilled = 0;
        for (const bill of billsData || []) {
          const bItems = await client.unsafe(
            `SELECT quantity FROM bill_items WHERE bill_id = $1`,
            [bill.id],
          );
          for (const bi of bItems ?? []) {
            totalBilled += Number(bi.quantity || 0);
          }
        }
        if (totalBilled > 0) {
          if (totalBilled >= totalQty - 0.0001) {
            bill_status = "full";
          } else {
            bill_status = "partial";
          }
        }
      }
      data.bill_status = bill_status;
    }

    return data;
  }

  async getNextNumber(tenant: TenantContext, prefix?: string) {
    return this.getNextReceiveNumber(tenant, prefix || "PR-");
  }

  async create(createDto: CreatePurchaseReceiveDto, tenant: TenantContext) {
    let resolvedWarehouseId = createDto.warehouse_id ?? null;
    const resolvedReceiveNumber = await this.resolveCreateNumber(
      createDto,
      tenant,
    );

    if (!resolvedWarehouseId && createDto.purchase_order_id) {
      const poData = await client.unsafe(
        `SELECT delivery_warehouse_id, warehouse_id FROM purchase_orders WHERE id = $1 AND entity_id = $2 LIMIT 1`,
        [createDto.purchase_order_id, tenant.entityId],
      );

      if (poData[0]) {
        resolvedWarehouseId =
          poData[0].delivery_warehouse_id ?? poData[0].warehouse_id ?? null;
      }
    }

    let receive: any = null;
    let receiveError: any = null;
    let currentReceiveNumber = resolvedReceiveNumber;
    let attempts = 0;

    while (attempts < 5) {
      attempts++;
      const insertPayload = {
        purchase_receive_number: currentReceiveNumber,
        received_date: createDto.received_date,
        vendor_name: createDto.vendor_name ?? null,
        purchase_order_id: createDto.purchase_order_id ?? null,
        purchase_order_number: createDto.purchase_order_number ?? null,
        warehouse_id: resolvedWarehouseId,
        status: createDto.status ?? "draft",
        notes: createDto.notes ?? null,
        bill_no: createDto.bill_no ?? null,
        bill_date: createDto.bill_date ?? null,
        bill_invoice_total: createDto.invoice_total ?? null,
        entity_id: tenant.entityId,
        is_delete: false,
      };

      const keys = Object.keys(insertPayload);
      const cols = keys.map((k) => `"${k}"`).join(", ");
      const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");
      const values: any[] = Object.values(insertPayload);

      try {
        const rows = await client.unsafe(
          `INSERT INTO purchase_receives (${cols}) VALUES (${placeholders}) RETURNING *`,
          values,
        );
        receive = rows[0];
        receiveError = null;
        break;
      } catch (err: any) {
        receiveError = err;
        if (
          err.code === "23505" ||
          err.message?.includes("purchase_receives_purchase_receive_number_key")
        ) {
          const prefix = currentReceiveNumber.match(/^(.*?)(\d+)$/)?.[1] || "PR-";
          const nextGen = await this.getNextReceiveNumber(tenant, prefix);
          currentReceiveNumber = nextGen.formatted;
        } else {
          break;
        }
      }
    }

    if (receiveError || !receive) {
      throw new Error(
        `Failed to create purchase receive: ${receiveError?.message || 'Unknown error'}`,
      );
    }

    await this.insertItemsAndBatches(
      receive.id,
      createDto.items,
      tenant,
      resolvedWarehouseId,
      createDto.transaction_bin_id,
      createDto.transaction_bin_label,
    );

    if (createDto.status?.toLowerCase() === "received") {
      await this.applyStockUpdates(
        createDto.items,
        tenant,
        receive.id,
        receive.purchase_receive_number,
        resolvedWarehouseId,
      );
    }

    if (createDto.purchase_order_id) {
      await this.updatePurchaseOrderStatus(createDto.purchase_order_id, tenant);
    }

    return this.findOne(receive.id, tenant);
  }

  async update(
    id: string,
    updateDto: UpdatePurchaseReceiveDto,
    tenant: TenantContext,
  ) {
    const existingReceive = await this.findOne(id, tenant);
    const receiveNumber =
      updateDto.purchase_receive_number ??
      existingReceive.purchase_receive_number;

    const dbUpdateData: any = {};
    if (updateDto.purchase_receive_number !== undefined) dbUpdateData.purchase_receive_number = updateDto.purchase_receive_number;
    if (updateDto.received_date !== undefined) dbUpdateData.received_date = updateDto.received_date;
    if (updateDto.vendor_name !== undefined) dbUpdateData.vendor_name = updateDto.vendor_name;
    if (updateDto.purchase_order_id !== undefined) dbUpdateData.purchase_order_id = updateDto.purchase_order_id;
    if (updateDto.purchase_order_number !== undefined) dbUpdateData.purchase_order_number = updateDto.purchase_order_number;
    if (updateDto.warehouse_id !== undefined) dbUpdateData.warehouse_id = updateDto.warehouse_id;
    if (updateDto.status !== undefined) dbUpdateData.status = updateDto.status;
    if (updateDto.notes !== undefined) dbUpdateData.notes = updateDto.notes;
    if (updateDto.bill_no !== undefined) dbUpdateData.bill_no = updateDto.bill_no;
    if (updateDto.bill_date !== undefined) dbUpdateData.bill_date = updateDto.bill_date;
    if (updateDto.invoice_total !== undefined) dbUpdateData.bill_invoice_total = updateDto.invoice_total;

    const keys = Object.keys(dbUpdateData);
    if (keys.length > 0) {
      const setClauses = keys.map((k, i) => `"${k}" = $${i + 1}`).join(", ");
      const values: any[] = Object.values(dbUpdateData);

      try {
        await client.unsafe(
          `UPDATE purchase_receives SET ${setClauses} WHERE id = $${keys.length + 1} AND entity_id = $${keys.length + 2}`,
          [...values, id, tenant.entityId],
        );
      } catch (error: any) {
        throw new Error(`Failed to update purchase receive: ${error.message}`);
      }
    }

    if (updateDto.items) {
      const existingItems = await client.unsafe(
        `SELECT id FROM purchase_receive_items WHERE purchase_receive_id = $1 AND entity_id = $2`,
        [id, tenant.entityId],
      );

      const itemIds = (existingItems ?? []).map((row: any) => row.id);
      if (itemIds.length > 0) {
        await client.unsafe(
          `DELETE FROM purchase_receive_item_batches WHERE purchase_receive_item_id = ANY($1) AND entity_id = $2`,
          [itemIds, tenant.entityId],
        );
      }

      await client.unsafe(
        `DELETE FROM purchase_receive_items WHERE purchase_receive_id = $1 AND entity_id = $2`,
        [id, tenant.entityId],
      );

      await this.insertItemsAndBatches(
        id,
        updateDto.items,
        tenant,
        updateDto.warehouse_id,
        updateDto.transaction_bin_id,
        updateDto.transaction_bin_label,
      );

      if (updateDto.status?.toLowerCase() === "received") {
        await this.applyStockUpdates(
          updateDto.items,
          tenant,
          id,
          receiveNumber,
          updateDto.warehouse_id ?? existingReceive.warehouse_id,
        );
      }
    }

    if (existingReceive.purchase_order_id) {
      await this.updatePurchaseOrderStatus(existingReceive.purchase_order_id, tenant);
    }

    return this.findOne(id, tenant);
  }

  async remove(id: string, tenant: TenantContext) {
    const existingReceive = await this.findOne(id, tenant);
    const originalNumber = existingReceive?.purchase_receive_number;
    const newNumber = originalNumber ? (originalNumber.startsWith('SD-') ? originalNumber : `SD-${originalNumber}`) : undefined;

    try {
      if (newNumber) {
        await client.unsafe(
          `UPDATE purchase_receives SET is_delete = true, purchase_receive_number = $1 WHERE id = $2 AND entity_id = $3`,
          [newNumber, id, tenant.entityId],
        );
      } else {
        await client.unsafe(
          `UPDATE purchase_receives SET is_delete = true WHERE id = $1 AND entity_id = $2`,
          [id, tenant.entityId],
        );
      }
    } catch (error: any) {
      throw new Error(`Failed to delete purchase receive: ${error.message}`);
    }

    if (existingReceive && existingReceive.purchase_order_id) {
      await this.updatePurchaseOrderStatus(existingReceive.purchase_order_id, tenant);
    }

    return { message: "Purchase Order deleted successfully" };
  }

  private async updatePurchaseOrderStatus(
    purchaseOrderId: string,
    tenant: TenantContext,
  ) {
    await updatePurchaseOrderStatus(client, purchaseOrderId, tenant.entityId);
  }
}
