import { Injectable, NotFoundException } from "@nestjs/common";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../../supabase/supabase.service";
import { CreatePurchaseReceiveDto } from "../dto/create-purchase-receive.dto";
import { UpdatePurchaseReceiveDto } from "../dto/update-purchase-receive.dto";
import { updatePurchaseOrderStatus } from "../../purchase-orders/utils/po-status";

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
    // We want to match exactly prefix + digits. e.g. PR-00001
    // In SQL, we use ~ for POSIX regex. Supabase filter uses 'match' for this.
    const regexPattern = `^${this.escapeRegExp(safePrefix)}[0-9]+$`;

    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchase_receives")
      .select("purchase_receive_number")
      .eq("entity_id", tenant.entityId)
      .filter("purchase_receive_number", "match", regexPattern)
      .order("purchase_receive_number", { ascending: false })
      .limit(1000);

    if (error) {
      throw new Error(
        `Failed to generate next purchase receive number: ${error.message}`,
      );
    }

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

    const { count, error } = await this.supabaseService
      .getClient()
      .from("purchase_receives")
      .select("id", { count: "exact", head: true })
      .eq("entity_id", tenant.entityId)
      .eq("purchase_receive_number", requested);

    if (error) {
      throw new Error(
        `Failed to validate purchase receive number uniqueness: ${error.message}`,
      );
    }

    if ((count ?? 0) === 0) {
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

    const itemsToInsert = items.map(
      ({ batches, billed, cancelled, ...item }) => ({
        ...item,
        purchase_receive_id: receiveId,
        warehouse_id: item.warehouse_id ?? headerWarehouseId ?? null,
        bin_id: item.bin_id ?? transactionBinId ?? null,
        bin_label: item.bin_label ?? transactionBinLabel ?? null,
        entity_id: tenant.entityId,
      }),
    );

    const { data: createdItems, error: itemsError } = await this.supabaseService
      .getClient()
      .from("purchase_receive_items")
      .insert(itemsToInsert)
      .select("id, item_id");

    if (itemsError) {
      throw new Error(
        `Failed to create purchase receive items: ${itemsError.message}`,
      );
    }

    const batchRows: Record<string, unknown>[] = [];
    for (let index = 0; index < items.length; index += 1) {
      const sourceItem = items[index];
      const createdItem = createdItems?.[index];
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
      const { error: batchError } = await this.supabaseService
        .getClient()
        .from("purchase_receive_item_batches")
        .insert(batchRows);

      if (batchError) {
        throw new Error(
          `Failed to create purchase receive item batches: ${batchError.message}`,
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
        // 1. Check if batch exists in batch_master
        const { data: existingBatch } = await this.supabaseService
          .getClient()
          .from("batch_master")
          .select("id")
          .eq("batch_no", batch.batch_no)
          .eq("product_id", item.item_id)
          .maybeSingle();

        let batchId = existingBatch?.id;

        if (!batchId) {
          // Create batch if not exists
          const { data: newBatch, error: batchError } =
            await this.supabaseService
              .getClient()
              .from("batch_master")
              .insert({
                batch_no: batch.batch_no,
                product_id: item.item_id,
                expiry_date: batch.expiry_date, // not null
                unit_pack: batch.unit_pack ?? null,
                manufacture_batch_number: batch.manufacture_batch ?? null,
                manufacture_exp: batch.manufacture_date ?? null,
                created_by_entity_id: tenant.entityId,
                source_type: "PURCHASE_RECEIVE",
              })
              .select()
              .single();

          if (batchError) {
            throw new Error(
              `Failed to create batch master: ${batchError.message}`,
            );
          }
          batchId = newBatch.id;
        }

        // 2. Insert into batch_stock_layers
        let resolvedBinId = batch.bin_id ?? item.bin_id;
        if (!resolvedBinId) {
          const warehouseId =
            batch.warehouse_id ?? item.warehouse_id ?? headerWarehouseId;
          if (warehouseId) {
            const { data: firstBin } = await this.supabaseService
              .getClient()
              .from("bin_master")
              .select("id")
              .eq("warehouse_id", warehouseId)
              .limit(1)
              .maybeSingle();
            resolvedBinId = firstBin?.id;
          }
        }

        const targetWarehouseId =
          batch.warehouse_id ?? item.warehouse_id ?? headerWarehouseId;

        // Query if a layer already exists for the same batch, product, entity, warehouse, and bin
        const { data: existingLayer, error: getLayerError } = await this.supabaseService
          .getClient()
          .from("batch_stock_layers")
          .select("*")
          .eq("batch_id", batchId)
          .eq("product_id", item.item_id)
          .eq("entity_id", tenant.entityId)
          .eq("warehouse_id", targetWarehouseId)
          .eq("bin_id", resolvedBinId)
          .maybeSingle();

        if (getLayerError) {
          throw new Error(
            `Failed to query existing batch stock layer: ${getLayerError.message}`,
          );
        }

        let layer;
        if (existingLayer) {
          // Update existing layer quantity
          const { data: updatedLayer, error: updateLayerError } = await this.supabaseService
            .getClient()
            .from("batch_stock_layers")
            .update({
              qty: Number(existingLayer.qty) + Number(batch.quantity),
              foc_qty: Number(existingLayer.foc_qty) + Number(batch.foc ?? 0),
              updated_at: new Date().toISOString(),
            })
            .eq("id", existingLayer.id)
            .select()
            .single();

          if (updateLayerError) {
            throw new Error(
              `Failed to update batch stock layer: ${updateLayerError.message}`,
            );
          }
          layer = updatedLayer;
        } else {
          // Insert new layer
          const { data: newLayer, error: insertLayerError } = await this.supabaseService
            .getClient()
            .from("batch_stock_layers")
            .insert({
              batch_id: batchId,
              product_id: item.item_id,
              entity_id: tenant.entityId,
              warehouse_id: targetWarehouseId,
              bin_id: resolvedBinId,
              qty: batch.quantity,
              foc_qty: batch.foc ?? 0,
              purchase_rate: batch.ptr ?? 0,
              mrp: batch.mrp ?? 0,
              ref_type: "PURCHASE_RECEIVE",
              ref_id: receiveId,
            })
            .select()
            .single();

          if (insertLayerError) {
            throw new Error(
              `Failed to create batch stock layer: ${insertLayerError.message}`,
            );
          }
          layer = newLayer;
        }


        // 3. Insert into batch_transactions
        const { error: transError } = await this.supabaseService
          .getClient()
          .from("batch_transactions")
          .insert({
            batch_id: batchId,
            layer_id: layer.id,
            product_id: item.item_id,
            entity_id: tenant.entityId,
            warehouse_id:
              batch.warehouse_id ?? item.warehouse_id ?? headerWarehouseId,
            bin_id: resolvedBinId,
            trans_type: "PURCHASE_RECEIVE",
            qty_in: batch.quantity,
            rate: batch.ptr ?? 0,
            ref_id: receiveId,
            ref_no: receiveNumber,
          });

        if (transError) {
          throw new Error(
            `Failed to create batch transaction: ${transError.message}`,
          );
        }
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

    let query = this.supabaseService
      .getClient()
      .from("purchase_receives")
      .select(
        `
        *,
        items:purchase_receive_items(
          quantity_to_receive,
          batches:purchase_receive_item_batches(quantity)
        )
      `,
        { count: "exact" },
      )
      .eq("entity_id", tenant.entityId)
      .range(offset, offset + limit - 1);

    if (search) {
      query = query.or(
        `purchase_receive_number.ilike.%${search}%,purchase_order_number.ilike.%${search}%,vendor_name.ilike.%${search}%`,
      );
    }

    if (status) {
      query = query.eq("status", status);
    }

    query = query.eq("is_delete", false);

    const { data, error, count } = await query;

    if (error) {
      throw new Error(`Failed to fetch purchase receives: ${error.message}`);
    }

    const receiveIds = (data || []).map((r) => r.id);
    const poIds = [...new Set((data || []).map((r) => r.purchase_order_id).filter((id) => !!id))];
    const poNumbers = [...new Set((data || []).map((r) => r.purchase_order_number).filter((num) => !!num))];

    const receiveIdToBillStatusMap = new Map<string, string>();

    // 1. Fetch direct bills (fallback)
    let directBillsData: any[] = [];
    if (receiveIds.length > 0) {
      const { data: dbData } = await this.supabaseService
        .getClient()
        .from("bills")
        .select("id, source_id, status, bill_items(quantity)")
        .eq("entity_id", tenant.entityId)
        .eq("is_delete", false)
        .neq("status", "void")
        .in("source_type", ["PURCHASE_RECEIVE", "purchase_receive", "purchase-receive", "PURCHASE-RECEIVE"])
        .in("source_id", receiveIds);
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

    // 2. Fetch PO-based bills & receives for FIFO allocation
    if (poIds.length > 0 && poNumbers.length > 0) {
      const { data: billsData } = await this.supabaseService
        .getClient()
        .from("bills")
        .select("id, order_number, status, bill_items(product_id, quantity)")
        .eq("entity_id", tenant.entityId)
        .eq("is_delete", false)
        .neq("status", "void")
        .in("order_number", poNumbers);

      const { data: allReceivesData } = await this.supabaseService
        .getClient()
        .from("purchase_receives")
        .select(`
          id,
          purchase_order_id,
          status,
          items:purchase_receive_items(
            item_id,
            quantity_to_receive,
            batches:purchase_receive_item_batches(quantity)
          )
        `)
        .eq("entity_id", tenant.entityId)
        .eq("is_delete", false)
        .in("purchase_order_id", poIds)
        .order("created_at", { ascending: true });

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
        const poNumber = (data || []).find((r) => r.purchase_order_id === poId)?.purchase_order_number;
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

    // Flatten total quantity for list view
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
        // Fallback to direct bills
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
        items: undefined, // Remove nested items to keep payload light
      };
    });

    return {
      data: enrichedData,
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
      .from("purchase_receives")
      .select(
        `
        *,
        items:purchase_receive_items(
          *,
          batches:purchase_receive_item_batches(*)
        )
      `,
      )
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .eq("is_delete", false)
      .single();

    if (error) {
      throw new NotFoundException(`Purchase Receive with ID ${id} not found`);
    }

    if (data) {
      data.invoice_total = data.bill_invoice_total ? parseFloat(data.bill_invoice_total) : 0;

      // Calculate total receive qty
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
        // Fetch all receives for this PO
        const { data: allReceivesData } = await this.supabaseService
          .getClient()
          .from("purchase_receives")
          .select(`
            id,
            purchase_order_id,
            status,
            items:purchase_receive_items(
              item_id,
              quantity_to_receive,
              batches:purchase_receive_item_batches(quantity)
            )
          `)
          .eq("entity_id", tenant.entityId)
          .eq("is_delete", false)
          .eq("purchase_order_id", data.purchase_order_id)
          .order("created_at", { ascending: true });

        // Fetch all bills for this PO
        const { data: billsData } = await this.supabaseService
          .getClient()
          .from("bills")
          .select("id, order_number, status, bill_items(product_id, quantity)")
          .eq("entity_id", tenant.entityId)
          .eq("is_delete", false)
          .neq("status", "void")
          .eq("order_number", data.purchase_order_number);

        // Sum billed quantities by product_id
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

        // Chronologically allocate billed quantities to receives
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
        // Fallback to direct bills
        const { data: billsData } = await this.supabaseService
          .getClient()
          .from("bills")
          .select("id, status, bill_items(quantity)")
          .eq("entity_id", tenant.entityId)
          .eq("is_delete", false)
          .neq("status", "void")
          .in("source_type", ["PURCHASE_RECEIVE", "purchase_receive", "purchase-receive", "PURCHASE-RECEIVE"])
          .eq("source_id", id);

        let totalBilled = 0;
        for (const bill of billsData || []) {
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

    // Backend safety fallback: derive header warehouse from PO when client omits it.
    if (!resolvedWarehouseId && createDto.purchase_order_id) {
      const { data: poData, error: poError } = await this.supabaseService
        .getClient()
        .from("purchase_orders")
        .select("delivery_warehouse_id, warehouse_id")
        .eq("id", createDto.purchase_order_id)
        .eq("entity_id", tenant.entityId)
        .single();

      if (!poError && poData) {
        resolvedWarehouseId =
          poData.delivery_warehouse_id ?? poData.warehouse_id ?? null;
      }
    }

    const insertPayload = {
      purchase_receive_number: resolvedReceiveNumber,
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

    const { data: receive, error: receiveError } = await this.supabaseService
      .getClient()
      .from("purchase_receives")
      .insert([insertPayload])
      .select()
      .single();

    if (receiveError) {
      throw new Error(
        `Failed to create purchase receive: ${receiveError.message}`,
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

    if (Object.keys(dbUpdateData).length > 0) {
      const { error } = await this.supabaseService
        .getClient()
        .from("purchase_receives")
        .update(dbUpdateData)
        .eq("id", id)
        .eq("entity_id", tenant.entityId);

      if (error) {
        throw new Error(`Failed to update purchase receive: ${error.message}`);
      }
    }

    if (updateDto.items) {
      const { data: existingItems } = await this.supabaseService
        .getClient()
        .from("purchase_receive_items")
        .select("id")
        .eq("purchase_receive_id", id)
        .eq("entity_id", tenant.entityId);

      const itemIds = (existingItems ?? []).map((row) => row.id);
      if (itemIds.length > 0) {
        const { error: batchDeleteError } = await this.supabaseService
          .getClient()
          .from("purchase_receive_item_batches")
          .delete()
          .in("purchase_receive_item_id", itemIds)
          .eq("entity_id", tenant.entityId);

        if (batchDeleteError) {
          throw new Error(
            `Failed to delete purchase receive item batches: ${batchDeleteError.message}`,
          );
        }
      }

      const { error: itemDeleteError } = await this.supabaseService
        .getClient()
        .from("purchase_receive_items")
        .delete()
        .eq("purchase_receive_id", id)
        .eq("entity_id", tenant.entityId);

      if (itemDeleteError) {
        throw new Error(
          `Failed to delete purchase receive items: ${itemDeleteError.message}`,
        );
      }

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

    const { error } = await this.supabaseService
      .getClient()
      .from("purchase_receives")
      .update({
        is_delete: true,
        ...(newNumber ? { purchase_receive_number: newNumber } : {}),
      })
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (error) {
      throw new Error(`Failed to delete purchase receive: ${error.message}`);
    }

    if (existingReceive && existingReceive.purchase_order_id) {
      await this.updatePurchaseOrderStatus(existingReceive.purchase_order_id, tenant);
    }

    return { message: "Purchase Order deleted successfully" };
  }

  private  async updatePurchaseOrderStatus(
    purchaseOrderId: string,
    tenant: TenantContext,
  ) {
    const client = this.supabaseService.getClient();
    await updatePurchaseOrderStatus(client, purchaseOrderId, tenant.entityId);
  }
}
