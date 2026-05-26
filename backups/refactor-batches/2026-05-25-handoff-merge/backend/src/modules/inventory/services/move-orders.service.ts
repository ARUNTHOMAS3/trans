import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { Client } from "pg";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../supabase/supabase.service";

type MoveOrderStatus = "draft" | "completed";

export interface ListMoveOrdersQuery {
  page?: string;
  limit?: string;
  search?: string;
  status?: string;
  date_from?: string;
  date_to?: string;
}

export interface MoveOrderSourceBatchDto {
  source_layer_id?: string;
  batch_id?: string;
  source_bin_id?: string;
  qty_out?: number;
}

export interface MoveOrderDestinationBinDto {
  source_batch_row_id?: string;
  source_layer_id?: string;
  source_bin_id?: string;
  batch_id?: string;
  destination_bin_id?: string;
  qty_in?: number;
}

export interface MoveOrderItemDto {
  product_id?: string;
  qty?: number;
  remarks?: string | null;
  source_batches?: MoveOrderSourceBatchDto[];
  destination_bins?: MoveOrderDestinationBinDto[];
}

export interface CreateMoveOrderDto {
  move_order_number?: string;
  move_date?: string;
  warehouse_id?: string;
  assignee_id?: string | null;
  notes?: string | null;
  status?: string;
  created_by?: string | null;
  items?: MoveOrderItemDto[];
}

export interface UpdateMoveOrderDto extends CreateMoveOrderDto {}

export interface CompleteMoveOrderDto {
  completed_by?: string | null;
  completed_at?: string | null;
}

interface SourceBatchRowDb {
  id: string;
  move_order_item_id: string;
  source_layer_id: string;
  batch_id: string;
  source_bin_id: string;
  qty_out: string | number;
}

interface DestinationBinRowDb {
  source_batch_row_id: string;
  destination_bin_id: string;
  qty_in: string | number;
}

@Injectable()
export class MoveOrdersService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private ensureEntity(tenant: TenantContext): string {
    if (!tenant.entityId) {
      throw new BadRequestException("Missing tenant entity context");
    }
    return tenant.entityId;
  }

  private dbConnectionString(): string {
    const value = process.env.DRIZZLE_DATABASE_URL || process.env.DATABASE_URL;
    if (!value) {
      throw new BadRequestException(
        "Missing DRIZZLE_DATABASE_URL or DATABASE_URL",
      );
    }
    return value;
  }

  private parseNumber(value: unknown, fallback = 0): number {
    const n = Number(value);
    return Number.isFinite(n) ? n : fallback;
  }

  private normalizeStatus(status?: string): MoveOrderStatus {
    const normalized = String(status ?? "draft").trim().toLowerCase();
    if (normalized === "completed") return "completed";
    return "draft";
  }

  private async withPgClient<T>(fn: (client: Client) => Promise<T>): Promise<T> {
    const client = new Client({ connectionString: this.dbConnectionString() });
    await client.connect();
    try {
      return await fn(client);
    } finally {
      await client.end();
    }
  }

  private normalizeCreatePayload(dto: CreateMoveOrderDto) {
    const moveOrderNumber = String(dto.move_order_number ?? "").trim();
    const moveDate = String(dto.move_date ?? "").trim();
    const warehouseId = String(dto.warehouse_id ?? "").trim();
    const status = this.normalizeStatus(dto.status);
    const assigneeId = dto.assignee_id?.trim() || null;
    const notes = dto.notes?.trim() || null;
    const createdBy = dto.created_by?.trim() || null;

    if (!moveOrderNumber) {
      throw new BadRequestException("move_order_number is required");
    }
    if (!moveDate) {
      throw new BadRequestException("move_date is required");
    }
    if (!warehouseId) {
      throw new BadRequestException("warehouse_id is required");
    }

    const itemRows = Array.isArray(dto.items) ? dto.items : [];
    if (itemRows.length === 0) {
      throw new BadRequestException("At least one item is required");
    }

    const items = itemRows.map((row, idx) => {
      const productId = String(row.product_id ?? "").trim();
      const qty = this.parseNumber(row.qty, 0);
      if (!productId) {
        throw new BadRequestException(`items[${idx}].product_id is required`);
      }
      if (qty <= 0) {
        throw new BadRequestException(`items[${idx}].qty must be > 0`);
      }
      const sourceBatches = Array.isArray(row.source_batches)
        ? row.source_batches
        : [];
      const destinationBins = Array.isArray(row.destination_bins)
        ? row.destination_bins
        : [];
      if (sourceBatches.length === 0) {
        throw new BadRequestException(
          `items[${idx}] must have at least one source_batches row`,
        );
      }
      return {
        product_id: productId,
        qty,
        remarks: row.remarks?.trim() || null,
        source_batches: sourceBatches.map((s, sIdx) => {
          const sourceLayerId = String(s.source_layer_id ?? "").trim();
          const batchId = String(s.batch_id ?? "").trim();
          const sourceBinId = String(s.source_bin_id ?? "").trim();
          const qtyOut = this.parseNumber(s.qty_out, 0);
          if (!sourceBinId || qtyOut <= 0) {
            throw new BadRequestException(
              `items[${idx}].source_batches[${sIdx}] is invalid`,
            );
          }
          return {
            source_layer_id: sourceLayerId,
            batch_id: batchId,
            source_bin_id: sourceBinId,
            qty_out: qtyOut,
          };
        }),
        destination_bins: destinationBins.map((d, dIdx) => {
          const destinationBinId = String(d.destination_bin_id ?? "").trim();
          const qtyIn = this.parseNumber(d.qty_in, 0);
          if (!destinationBinId || qtyIn <= 0) {
            throw new BadRequestException(
              `items[${idx}].destination_bins[${dIdx}] is invalid`,
            );
          }
          return {
            source_batch_row_id: d.source_batch_row_id?.trim() || null,
            source_layer_id: d.source_layer_id?.trim() || null,
            source_bin_id: d.source_bin_id?.trim() || null,
            batch_id: d.batch_id?.trim() || null,
            destination_bin_id: destinationBinId,
            qty_in: qtyIn,
          };
        }),
      };
    });

    return {
      moveOrderNumber,
      moveDate,
      warehouseId,
      assigneeId,
      notes,
      status,
      createdBy,
      items,
    };
  }

  private async resolveSourceLayerForDraft(
    client: Client,
    params: {
      entityId: string;
      warehouseId: string;
      productId: string;
      sourceBinId: string;
      batchId?: string;
      qty: number;
    },
  ): Promise<{ sourceLayerId: string; batchId: string; sourceBinId: string }> {
    const normalizedBatchId = (params.batchId ?? "").trim();
    const query = await client.query(
      `SELECT id, batch_id, bin_id, qty, reserved_qty
         FROM batch_stock_layers
        WHERE entity_id = $1
          AND warehouse_id = $2
          AND product_id = $3
          AND bin_id = $4
          AND ($5 = '' OR batch_id = $5::uuid)
        ORDER BY CASE WHEN (qty - reserved_qty) >= $6 THEN 0 ELSE 1 END,
                 qty DESC
        LIMIT 1`,
      [
        params.entityId,
        params.warehouseId,
        params.productId,
        params.sourceBinId,
        normalizedBatchId,
        params.qty,
      ],
    );
    let row = query.rows[0];
    // Fallback: if selected batch doesn't map to this source bin anymore,
    // resolve by product+bin and use the current live layer/batch.
    if (!row?.id && normalizedBatchId) {
      const fallback = await client.query(
        `SELECT id, batch_id, bin_id, qty, reserved_qty
           FROM batch_stock_layers
          WHERE entity_id = $1
            AND warehouse_id = $2
            AND product_id = $3
            AND bin_id = $4
          ORDER BY CASE WHEN (qty - reserved_qty) >= $5 THEN 0 ELSE 1 END,
                   qty DESC
          LIMIT 1`,
        [
          params.entityId,
          params.warehouseId,
          params.productId,
          params.sourceBinId,
          params.qty,
        ],
      );
      row = fallback.rows[0];
    }
    if (!row?.id && normalizedBatchId) {
      const batchScoped = await client.query(
        `SELECT id, batch_id, bin_id, qty, reserved_qty
           FROM batch_stock_layers
          WHERE entity_id = $1
            AND warehouse_id = $2
            AND product_id = $3
            AND batch_id = $4::uuid
          ORDER BY CASE WHEN (qty - reserved_qty) >= $5 THEN 0 ELSE 1 END,
                   qty DESC
          LIMIT 2`,
        [
          params.entityId,
          params.warehouseId,
          params.productId,
          normalizedBatchId,
          params.qty,
        ],
      );
      if (batchScoped.rows.length === 1) {
        row = batchScoped.rows[0];
      } else if (batchScoped.rows.length > 1) {
        throw new BadRequestException(
          `Multiple source stock layers found for product ${params.productId}; select the exact source bin`,
        );
      }
    }
    if (!row?.id || !row?.batch_id || !row?.bin_id) {
      throw new BadRequestException(
        `Unable to resolve source stock layer for product ${params.productId} in source bin`,
      );
    }
    return {
      sourceLayerId: String(row.id),
      batchId: String(row.batch_id),
      sourceBinId: String(row.bin_id),
    };
  }

  private async writeGraph(
    client: Client,
    entityId: string,
    warehouseId: string,
    moveOrderId: string,
    items: ReturnType<MoveOrdersService["normalizeCreatePayload"]>["items"],
  ) {
    await client.query(
      "DELETE FROM inventory_move_order_destination_bins WHERE source_batch_row_id IN (SELECT id FROM inventory_move_order_source_batches WHERE move_order_item_id IN (SELECT id FROM inventory_move_order_items WHERE move_order_id = $1))",
      [moveOrderId],
    );
    await client.query(
      "DELETE FROM inventory_move_order_source_batches WHERE move_order_item_id IN (SELECT id FROM inventory_move_order_items WHERE move_order_id = $1)",
      [moveOrderId],
    );
    await client.query(
      "DELETE FROM inventory_move_order_items WHERE move_order_id = $1",
      [moveOrderId],
    );

    for (const item of items) {
      const itemInsert = await client.query(
        `INSERT INTO inventory_move_order_items
          (move_order_id, product_id, qty, remarks, created_at)
         VALUES ($1, $2, $3, $4, now())
         RETURNING id`,
        [moveOrderId, item.product_id, item.qty, item.remarks],
      );
      const moveOrderItemId = String(itemInsert.rows[0]?.id ?? "");
      if (!moveOrderItemId) {
        throw new BadRequestException("Failed to insert move order item");
      }

      const sourceRowsByIndex = new Map<number, string>();
      for (let i = 0; i < item.source_batches.length; i += 1) {
        const source = item.source_batches[i];
        let sourceLayerId = source.source_layer_id;
        let batchId = source.batch_id;
        let sourceBinId = source.source_bin_id;
        if (!sourceLayerId || !batchId) {
          const resolved = await this.resolveSourceLayerForDraft(client, {
            entityId,
            warehouseId,
            productId: item.product_id,
            sourceBinId: source.source_bin_id,
            batchId: source.batch_id,
            qty: source.qty_out,
          });
          sourceLayerId = resolved.sourceLayerId;
          batchId = resolved.batchId;
          sourceBinId = resolved.sourceBinId;
        }
        const sourceInsert = await client.query(
          `INSERT INTO inventory_move_order_source_batches
            (move_order_item_id, source_layer_id, batch_id, source_bin_id, qty_out, created_at)
           VALUES ($1, $2, $3, $4, $5, now())
           RETURNING id`,
          [
            moveOrderItemId,
            sourceLayerId,
            batchId,
            sourceBinId,
            source.qty_out,
          ],
        );
        sourceRowsByIndex.set(i, String(sourceInsert.rows[0]?.id ?? ""));
      }

      for (const destination of item.destination_bins) {
        let sourceBatchRowId = destination.source_batch_row_id ?? "";
        if (!sourceBatchRowId) {
          const matchedIndex = item.source_batches.findIndex(
            (source) =>
              (destination.source_layer_id &&
                source.source_layer_id === destination.source_layer_id) ||
              (destination.source_bin_id &&
                source.source_bin_id === destination.source_bin_id) ||
              (destination.batch_id && source.batch_id === destination.batch_id),
          );
          if (matchedIndex >= 0) {
            sourceBatchRowId = sourceRowsByIndex.get(matchedIndex) ?? "";
          }
        }
        if (!sourceBatchRowId && sourceRowsByIndex.size === 1) {
          sourceBatchRowId = Array.from(sourceRowsByIndex.values())[0];
        }
        if (!sourceBatchRowId) {
          throw new BadRequestException(
            "destination bin row could not be mapped to source batch row",
          );
        }

        await client.query(
          `INSERT INTO inventory_move_order_destination_bins
            (source_batch_row_id, destination_bin_id, qty_in, created_at)
           VALUES ($1, $2, $3, now())`,
          [sourceBatchRowId, destination.destination_bin_id, destination.qty_in],
        );
      }
    }
  }

  async findAll(tenant: TenantContext, query: ListMoveOrdersQuery) {
    const entityId = this.ensureEntity(tenant);
    const page = Math.max(Number(query.page ?? 1) || 1, 1);
    const limit = Math.min(Math.max(Number(query.limit ?? 20) || 20, 1), 200);
    const offset = (page - 1) * limit;
    const search = query.search?.trim();
    const status = query.status?.trim().toLowerCase();

    let builder = this.supabaseService
      .getClient()
      .from("inventory_move_orders")
      .select("*", { count: "exact" })
      .eq("entity_id", entityId)
      .order("move_date", { ascending: false })
      .order("created_at", { ascending: false });

    if (status) builder = builder.eq("status", status);
    if (query.date_from) builder = builder.gte("move_date", query.date_from);
    if (query.date_to) builder = builder.lte("move_date", query.date_to);
    if (search) {
      builder = builder.ilike("move_order_number", `%${search}%`);
    }

    const { data, count, error } = await builder.range(offset, offset + limit - 1);
    if (error) throw new BadRequestException(error.message);

    return {
      data: data ?? [],
      page,
      limit,
      total: count ?? 0,
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    const { data: order, error } = await this.supabaseService
      .getClient()
      .from("inventory_move_orders")
      .select("*")
      .eq("id", id)
      .eq("entity_id", entityId)
      .maybeSingle();
    if (error) throw new BadRequestException(error.message);
    if (!order) throw new NotFoundException("Move order not found");

    const { data: items, error: itemsError } = await this.supabaseService
      .getClient()
      .from("inventory_move_order_items")
      .select("*")
      .eq("move_order_id", id);
    if (itemsError) throw new BadRequestException(itemsError.message);

    const itemIds = (items ?? []).map((row: any) => row.id);
    const { data: sourceRows, error: sourceError } = itemIds.length
      ? await this.supabaseService
          .getClient()
          .from("inventory_move_order_source_batches")
          .select("*")
          .in("move_order_item_id", itemIds)
      : { data: [], error: null as any };
    if (sourceError) throw new BadRequestException(sourceError.message);

    const sourceIds = (sourceRows ?? []).map((row: any) => row.id);
    const { data: destRows, error: destError } = sourceIds.length
      ? await this.supabaseService
          .getClient()
          .from("inventory_move_order_destination_bins")
          .select("*")
          .in("source_batch_row_id", sourceIds)
      : { data: [], error: null as any };
    if (destError) throw new BadRequestException(destError.message);

    const sourceByItem = new Map<string, any[]>();
    for (const row of sourceRows ?? []) {
      const key = String((row as any).move_order_item_id);
      const list = sourceByItem.get(key) ?? [];
      list.push(row);
      sourceByItem.set(key, list);
    }
    const destBySource = new Map<string, any[]>();
    for (const row of destRows ?? []) {
      const key = String((row as any).source_batch_row_id);
      const list = destBySource.get(key) ?? [];
      list.push(row);
      destBySource.set(key, list);
    }

    return {
      ...order,
      items: (items ?? []).map((item: any) => {
        const sources = sourceByItem.get(String(item.id)) ?? [];
        return {
          ...item,
          source_batches: sources,
          destination_bins: sources.flatMap(
            (source: any) => destBySource.get(String(source.id)) ?? [],
          ),
        };
      }),
    };
  }

  async create(dto: CreateMoveOrderDto, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    const payload = this.normalizeCreatePayload(dto);

    return this.withPgClient(async (client) => {
      await client.query("BEGIN");
      try {
        const headerInsert = await client.query(
          `INSERT INTO inventory_move_orders
            (entity_id, warehouse_id, move_order_number, move_date, assignee_id, notes, status, created_by, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, now(), now())
           RETURNING id`,
          [
            entityId,
            payload.warehouseId,
            payload.moveOrderNumber,
            payload.moveDate,
            payload.assigneeId,
            payload.notes,
            payload.status,
            payload.createdBy ?? tenant.userId ?? null,
          ],
        );
        const moveOrderId = String(headerInsert.rows[0]?.id ?? "");
        if (!moveOrderId) {
          throw new BadRequestException("Failed to create move order");
        }

        await this.writeGraph(
          client,
          entityId,
          payload.warehouseId,
          moveOrderId,
          payload.items,
        );
        await client.query("COMMIT");
        return this.findOne(moveOrderId, tenant);
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    });
  }

  async update(id: string, dto: UpdateMoveOrderDto, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    const existing = await this.findOne(id, tenant);
    if (String(existing.status).toLowerCase() === "completed") {
      throw new BadRequestException("Completed move orders cannot be updated");
    }

    const payload = this.normalizeCreatePayload({
      move_order_number: dto.move_order_number ?? existing.move_order_number,
      move_date: dto.move_date ?? existing.move_date,
      warehouse_id: dto.warehouse_id ?? existing.warehouse_id,
      assignee_id: dto.assignee_id ?? existing.assignee_id,
      notes: dto.notes ?? existing.notes,
      status: dto.status ?? existing.status,
      created_by: dto.created_by ?? existing.created_by,
      items: dto.items ?? existing.items,
    });

    return this.withPgClient(async (client) => {
      await client.query("BEGIN");
      try {
        await client.query(
          `UPDATE inventory_move_orders
           SET warehouse_id = $1,
               move_order_number = $2,
               move_date = $3,
               assignee_id = $4,
               notes = $5,
               status = $6,
               updated_at = now()
           WHERE id = $7
             AND entity_id = $8`,
          [
            payload.warehouseId,
            payload.moveOrderNumber,
            payload.moveDate,
            payload.assigneeId,
            payload.notes,
            payload.status,
            id,
            entityId,
          ],
        );

        await this.writeGraph(
          client,
          entityId,
          payload.warehouseId,
          id,
          payload.items,
        );
        await client.query("COMMIT");
        return this.findOne(id, tenant);
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    });
  }

  async complete(id: string, dto: CompleteMoveOrderDto, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    const completedBy = dto.completed_by?.trim() || tenant.userId || null;
    const completedAt = dto.completed_at?.trim() || new Date().toISOString();

    return this.withPgClient(async (client) => {
      await client.query("BEGIN");
      try {
        const orderResult = await client.query(
          `SELECT id, status, entity_id, warehouse_id, move_order_number
           FROM inventory_move_orders
           WHERE id = $1
             AND entity_id = $2
           FOR UPDATE`,
          [id, entityId],
        );
        if (!orderResult.rows.length) {
          throw new NotFoundException("Move order not found");
        }
        const order = orderResult.rows[0];
        if (String(order.status).toLowerCase() === "completed") {
          throw new BadRequestException("Move order already completed");
        }

        const sourceRowsResult = await client.query(
          `SELECT sb.id,
                  sb.move_order_item_id,
                  sb.source_layer_id,
                  sb.batch_id,
                  sb.source_bin_id,
                  sb.qty_out
           FROM inventory_move_order_source_batches sb
           INNER JOIN inventory_move_order_items i ON i.id = sb.move_order_item_id
           WHERE i.move_order_id = $1`,
          [id],
        );
        const sourceRows = sourceRowsResult.rows as SourceBatchRowDb[];
        if (!sourceRows.length) {
          throw new BadRequestException("Move order has no source allocations");
        }

        const destRowsResult = await client.query(
          `SELECT source_batch_row_id, destination_bin_id, qty_in
           FROM inventory_move_order_destination_bins
           WHERE source_batch_row_id = ANY($1::uuid[])`,
          [sourceRows.map((row) => row.id)],
        );
        const destinationRows = destRowsResult.rows as DestinationBinRowDb[];
        const destBySource = new Map<string, DestinationBinRowDb[]>();
        for (const row of destinationRows) {
          const list = destBySource.get(row.source_batch_row_id) ?? [];
          list.push(row);
          destBySource.set(row.source_batch_row_id, list);
        }

        for (const source of sourceRows) {
          const qtyOut = this.parseNumber(source.qty_out, 0);
          if (qtyOut <= 0) {
            throw new BadRequestException("Invalid source qty_out");
          }
          const sourceLayerResult = await client.query(
            `SELECT id,
                    batch_id,
                    product_id,
                    entity_id,
                    warehouse_id,
                    bin_id,
                    vendor_id,
                    purchase_rate,
                    mrp,
                    qty
             FROM batch_stock_layers
             WHERE id = $1
             FOR UPDATE`,
            [source.source_layer_id],
          );
          if (!sourceLayerResult.rows.length) {
            throw new BadRequestException(
              `Source layer not found: ${source.source_layer_id}`,
            );
          }
          const sourceLayer = sourceLayerResult.rows[0] as any;
          const currentQty = this.parseNumber(sourceLayer.qty, 0);
          if (currentQty < qtyOut) {
            throw new BadRequestException(
              `Insufficient source qty for layer ${source.source_layer_id}`,
            );
          }

          await client.query(
            `UPDATE batch_stock_layers
             SET qty = qty - $1,
                 updated_at = now()
             WHERE id = $2`,
            [qtyOut, source.source_layer_id],
          );

          await client.query(
            `INSERT INTO batch_transactions
              (batch_id, layer_id, product_id, entity_id, warehouse_id, bin_id, trans_type, ref_id, ref_no, qty_in, qty_out, rate, trans_date, created_at)
             VALUES ($1, $2, $3, $4, $5, $6, 'MOVE_OUT', $7, $8, 0, $9, $10, now(), now())`,
            [
              sourceLayer.batch_id,
              sourceLayer.id,
              sourceLayer.product_id,
              sourceLayer.entity_id,
              sourceLayer.warehouse_id,
              sourceLayer.bin_id,
              id,
              order.move_order_number ?? null,
              qtyOut,
              sourceLayer.purchase_rate ?? 0,
            ],
          );

          const destinations = destBySource.get(source.id) ?? [];
          if (!destinations.length) {
            throw new BadRequestException(
              `Missing destination bins for source allocation ${source.id}`,
            );
          }

          for (const dest of destinations) {
            const qtyIn = this.parseNumber(dest.qty_in, 0);
            if (qtyIn <= 0) {
              throw new BadRequestException("Invalid destination qty_in");
            }
            const destinationLayerResult = await client.query(
              `SELECT id, qty
               FROM batch_stock_layers
               WHERE batch_id = $1
                 AND product_id = $2
                 AND entity_id = $3
                 AND warehouse_id = $4
                 AND bin_id = $5
                 AND COALESCE(vendor_id, '00000000-0000-0000-0000-000000000000'::uuid) = COALESCE($6::uuid, '00000000-0000-0000-0000-000000000000'::uuid)
                 AND purchase_rate = $7
                 AND mrp = $8
               FOR UPDATE`,
              [
                sourceLayer.batch_id,
                sourceLayer.product_id,
                sourceLayer.entity_id,
                sourceLayer.warehouse_id,
                dest.destination_bin_id,
                sourceLayer.vendor_id,
                sourceLayer.purchase_rate,
                sourceLayer.mrp,
              ],
            );

            let destinationLayerId = "";
            if (destinationLayerResult.rows.length) {
              destinationLayerId = String(destinationLayerResult.rows[0].id);
              await client.query(
                `UPDATE batch_stock_layers
                 SET qty = qty + $1,
                     updated_at = now()
                 WHERE id = $2`,
                [qtyIn, destinationLayerId],
              );
            } else {
              const insertLayer = await client.query(
                `INSERT INTO batch_stock_layers
                  (batch_id, product_id, entity_id, warehouse_id, bin_id, vendor_id, purchase_rate, mrp, qty, foc_qty, ref_id, ref_type, created_at, updated_at, reserved_qty)
                 VALUES
                  ($1, $2, $3, $4, $5, $6, $7, $8, $9, 0, $10, 'MOVE_ORDER', now(), now(), 0)
                 RETURNING id`,
                [
                  sourceLayer.batch_id,
                  sourceLayer.product_id,
                  sourceLayer.entity_id,
                  sourceLayer.warehouse_id,
                  dest.destination_bin_id,
                  sourceLayer.vendor_id,
                  sourceLayer.purchase_rate,
                  sourceLayer.mrp,
                  qtyIn,
                  id,
                ],
              );
              destinationLayerId = String(insertLayer.rows[0].id);
            }

            await client.query(
              `INSERT INTO batch_transactions
                (batch_id, layer_id, product_id, entity_id, warehouse_id, bin_id, trans_type, ref_id, ref_no, qty_in, qty_out, rate, trans_date, created_at)
               VALUES ($1, $2, $3, $4, $5, $6, 'MOVE_IN', $7, $8, $9, 0, $10, now(), now())`,
              [
                sourceLayer.batch_id,
                destinationLayerId,
                sourceLayer.product_id,
                sourceLayer.entity_id,
                sourceLayer.warehouse_id,
                dest.destination_bin_id,
                id,
                order.move_order_number ?? null,
                qtyIn,
                sourceLayer.purchase_rate ?? 0,
              ],
            );
          }
        }

        await client.query(
          `UPDATE inventory_move_orders
           SET status = 'completed',
               completed_by = $1,
               completed_at = $2::timestamp,
               updated_at = now()
           WHERE id = $3
             AND entity_id = $4`,
          [completedBy, completedAt, id, entityId],
        );

        await client.query("COMMIT");
        return this.findOne(id, tenant);
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    });
  }
}
