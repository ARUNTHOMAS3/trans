import { Injectable, NotFoundException } from "@nestjs/common";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../../supabase/supabase.service";
import { CreatePurchaseReceiveDto } from "../dto/create-purchase-receive.dto";
import { UpdatePurchaseReceiveDto } from "../dto/update-purchase-receive.dto";

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

    const itemsToInsert = items.map(({ batches, billed, ...item }) => ({
      ...item,
      purchase_receive_id: receiveId,
      warehouse_id: item.warehouse_id ?? headerWarehouseId ?? null,
      bin_id: item.bin_id ?? transactionBinId ?? null,
      bin_label: item.bin_label ?? transactionBinLabel ?? null,
      entity_id: tenant.entityId,
    }));

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

        const { data: layer, error: layerError } = await this.supabaseService
          .getClient()
          .from("batch_stock_layers")
          .insert({
            batch_id: batchId,
            product_id: item.item_id,
            entity_id: tenant.entityId,
            warehouse_id:
              batch.warehouse_id ?? item.warehouse_id ?? headerWarehouseId,
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

        if (layerError) {
          throw new Error(
            `Failed to create batch stock layer: ${layerError.message}`,
          );
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

    // Flatten total quantity for list view
    const enrichedData = (data || []).map((receive: any) => {
      let totalQty = 0;
      if (receive.items) {
        for (const item of receive.items) {
          if (item.batches) {
            for (const batch of item.batches) {
              totalQty += Number(batch.quantity || 0);
            }
          }
        }
      }
      return {
        ...receive,
        quantity: totalQty,
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

    return data;
  }

  async getNextNumber(tenant: TenantContext, prefix?: string) {
    return this.getNextReceiveNumber(tenant, prefix || "PR-");
  }

  async create(createDto: CreatePurchaseReceiveDto, tenant: TenantContext) {
    const { items, billed, invoice_total, ...receiveData } = createDto;
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

    const { data: receive, error: receiveError } = await this.supabaseService
      .getClient()
      .from("purchase_receives")
      .insert([
        {
          ...receiveData,
          bill_invoice_total: invoice_total,
          purchase_receive_number: resolvedReceiveNumber,
          warehouse_id: resolvedWarehouseId,
          entity_id: tenant.entityId,
          is_delete: false,
        },
      ])
      .select()
      .single();

    if (receiveError) {
      throw new Error(
        `Failed to create purchase receive: ${receiveError.message}`,
      );
    }

    await this.insertItemsAndBatches(
      receive.id,
      items,
      tenant,
      resolvedWarehouseId,
      createDto.transaction_bin_id,
      createDto.transaction_bin_label,
    );

    if (createDto.status?.toLowerCase() === "received") {
      await this.applyStockUpdates(
        items,
        tenant,
        receive.id,
        receive.purchase_receive_number,
        resolvedWarehouseId,
      );
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
    const { items, billed, invoice_total, ...updateData } = updateDto;

    const dbUpdateData: any = { ...updateData };
    if (invoice_total !== undefined) {
      dbUpdateData.bill_invoice_total = invoice_total;
    }

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

    if (items) {
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
        items,
        tenant,
        updateDto.warehouse_id,
        updateDto.transaction_bin_id,
        updateDto.transaction_bin_label,
      );

      if (updateDto.status?.toLowerCase() === "received") {
        await this.applyStockUpdates(
          items,
          tenant,
          id,
          receiveNumber,
          updateDto.warehouse_id ?? existingReceive.warehouse_id,
        );
      }
    }

    return this.findOne(id, tenant);
  }

  async remove(id: string, tenant: TenantContext) {
    const { error } = await this.supabaseService
      .getClient()
      .from("purchase_receives")
      .update({ is_delete: true })
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (error) {
      throw new Error(`Failed to delete purchase receive: ${error.message}`);
    }

    return { message: "Purchase Receive deleted successfully" };
  }
}
