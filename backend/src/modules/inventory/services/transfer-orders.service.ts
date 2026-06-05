import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from "@nestjs/common";
import { Client } from "pg";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../supabase/supabase.service";

type TransferOrderStatus = "DRAFT" | "INITIATED" | "RECEIVED" | "CANCELLED";

export interface ListTransferOrdersQuery {
  page?: string;
  limit?: string;
  search?: string;
  status?: string;
  date_from?: string;
  date_to?: string;
}

export interface TransferOrderSourceBatchDto {
  batch_id?: string;
  layer_id?: string;
  warehouse_id: string;
  bin_id: string;
  qty: number;
}

export interface TransferOrderDestinationBatchDto {
  source_batch_id: string;
  destination_batch_id: string;
  destination_warehouse_id: string;
  destination_bin_id: string;
  qty: number;
}

export interface TransferOrderItemDto {
  product_id: string;
  qty_requested: number;
  qty_transferred?: number;
  unit?: string | null;
  source_batches?: TransferOrderSourceBatchDto[];
  destination_batches?: TransferOrderDestinationBatchDto[];
}

export interface CreateTransferOrderDto {
  transfer_no: string;
  transfer_date: string;
  source_warehouse_id: string;
  destination_warehouse_id: string;
  reason?: string | null;
  status?: string;
  items: TransferOrderItemDto[];
}

export interface UpdateTransferOrderDto {
  transfer_no?: string;
  transfer_date?: string;
  source_warehouse_id?: string;
  destination_warehouse_id?: string;
  reason?: string | null;
  status?: string;
  items?: TransferOrderItemDto[];
}

interface TransferLayerRow {
  id: string;
  qty: string | number;
  reserved_qty: string | number;
  purchase_rate: string | number;
  mrp: string | number;
  vendor_id: string | null;
}

@Injectable()
export class TransferOrdersService {
  private readonly logger = new Logger(TransferOrdersService.name);
  constructor(private readonly supabaseService: SupabaseService) {}

  private ensureEntity(tenant: TenantContext): string {
    if (!tenant.entityId) {
      throw new BadRequestException("Missing tenant entity context");
    }
    return tenant.entityId;
  }

  private getRuntimePgConnectionString(): string {
    const connectionString =
      process.env.DRIZZLE_DATABASE_URL || process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error(
        "Missing DRIZZLE_DATABASE_URL or DATABASE_URL for database connection.",
      );
    }
    return connectionString;
  }

  private parseNumber(value: unknown, fallback = 0): number {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  private normalizeStatus(status?: string): TransferOrderStatus {
    const normalized = String(status ?? "DRAFT")
      .trim()
      .toUpperCase();
    if (
      normalized === "DRAFT" ||
      normalized === "INITIATED" ||
      normalized === "RECEIVED" ||
      normalized === "CANCELLED"
    ) {
      return normalized;
    }
    return "DRAFT";
  }

  private assertWarehousePair(
    sourceWarehouseId?: string,
    destinationWarehouseId?: string,
  ) {
    if (!sourceWarehouseId || !destinationWarehouseId) {
      throw new BadRequestException(
        "Source warehouse and destination warehouse are required",
      );
    }
    if (sourceWarehouseId === destinationWarehouseId) {
      throw new BadRequestException(
        "Source warehouse and destination warehouse cannot be the same",
      );
    }
  }

  private sanitizeItems(items: TransferOrderItemDto[]): TransferOrderItemDto[] {
    if (!Array.isArray(items) || items.length === 0) {
      throw new BadRequestException("At least one transfer item is required");
    }
    return items.map((item) => {
      const qtyRequested = this.parseNumber(item.qty_requested, 0);
      if (!item.product_id || qtyRequested <= 0) {
        throw new BadRequestException(
          "Each item must include product_id and qty_requested > 0",
        );
      }
      return {
        product_id: item.product_id,
        qty_requested: qtyRequested,
        qty_transferred: this.parseNumber(item.qty_transferred, 0),
        unit: item.unit ?? null,
        source_batches: Array.isArray(item.source_batches)
          ? item.source_batches.map((row) => ({
              ...row,
              batch_id: row.batch_id?.trim() || "",
              layer_id: row.layer_id?.trim() || "",
              warehouse_id: row.warehouse_id?.trim() || "",
              bin_id: row.bin_id?.trim() || "",
              qty: this.parseNumber(row.qty, 0),
            }))
          : [],
        destination_batches: Array.isArray(item.destination_batches)
          ? item.destination_batches.map((row) => ({
              ...row,
              qty: this.parseNumber(row.qty, 0),
            }))
          : [],
      };
    });
  }

  private async withPgClient<T>(fn: (client: Client) => Promise<T>): Promise<T> {
    const client = new Client({
      connectionString: this.getRuntimePgConnectionString(),
    });
    await client.connect();
    try {
      return await fn(client);
    } finally {
      await client.end();
    }
  }

  private async resolveSourceLayerForDraft(
    client: Client,
    params: {
      entityId: string;
      productId: string;
      warehouseId: string;
      binId: string;
      batchId?: string;
      qty: number;
    },
  ): Promise<{ layerId: string; batchId: string }> {
    const normalizedBatchId = (params.batchId ?? "").trim();
    const query = await client.query(
      `SELECT id, batch_id, qty, reserved_qty
         FROM batch_stock_layers
        WHERE entity_id = $1
          AND product_id = $2
          AND warehouse_id = $3
          AND bin_id = $4
          AND ($5 = '' OR batch_id = $5::uuid)
        ORDER BY CASE WHEN (qty - reserved_qty) >= $6 THEN 0 ELSE 1 END,
                 qty DESC
        LIMIT 1`,
      [
        params.entityId,
        params.productId,
        params.warehouseId,
        params.binId,
        normalizedBatchId,
        params.qty,
      ],
    );
    let row = query.rows[0];
    // Fallback: if the selected batch no longer maps to this source bin,
    // resolve using product+bin only and persist the actual live layer/batch.
    if (!row?.id && normalizedBatchId) {
      const fallback = await client.query(
        `SELECT id, batch_id, qty, reserved_qty
           FROM batch_stock_layers
          WHERE entity_id = $1
            AND product_id = $2
            AND warehouse_id = $3
            AND bin_id = $4
          ORDER BY CASE WHEN (qty - reserved_qty) >= $5 THEN 0 ELSE 1 END,
                   qty DESC
          LIMIT 1`,
        [
          params.entityId,
          params.productId,
          params.warehouseId,
          params.binId,
          params.qty,
        ],
      );
      row = fallback.rows[0];
    }
    if (!row?.id || !row?.batch_id) {
      throw new BadRequestException(
        `Unable to resolve source stock layer for product ${params.productId} in selected source bin`,
      );
    }
    return {
      layerId: String(row.id),
      batchId: String(row.batch_id),
    };
  }

  private async writeDraftGraph(
    client: Client,
    entityId: string,
    orderId: string,
    items: TransferOrderItemDto[],
  ) {
    await client.query(
      "DELETE FROM transfer_order_source_batches WHERE transfer_item_id IN (SELECT id FROM transfer_order_items WHERE transfer_order_id = $1)",
      [orderId],
    );
    await client.query(
      "DELETE FROM transfer_order_destination_batches WHERE transfer_item_id IN (SELECT id FROM transfer_order_items WHERE transfer_order_id = $1)",
      [orderId],
    );
    await client.query("DELETE FROM transfer_order_items WHERE transfer_order_id = $1", [
      orderId,
    ]);

    for (const item of items) {
      const itemInsert = await client.query(
        `INSERT INTO transfer_order_items
          (transfer_order_id, product_id, qty_requested, qty_transferred, unit, created_at)
         VALUES ($1, $2, $3, $4, $5, now())
         RETURNING id`,
        [
          orderId,
          item.product_id,
          item.qty_requested,
          item.qty_transferred ?? 0,
          item.unit ?? null,
        ],
      );
      const transferItemId = itemInsert.rows[0]?.id as string;
      if (!transferItemId) {
        throw new BadRequestException("Unable to persist transfer order item");
      }

      const resolvedSourceBatches: Array<{ batchId: string }> = [];
      for (const sourceRow of item.source_batches ?? []) {
        const sourceWarehouseId = String(sourceRow.warehouse_id ?? "").trim();
        const sourceBinId = String(sourceRow.bin_id ?? "").trim();
        if (!sourceWarehouseId || !sourceBinId || sourceRow.qty <= 0) {
          throw new BadRequestException(
            "Each source batch row must include warehouse_id, bin_id and qty > 0",
          );
        }
        let resolvedLayerId = String(sourceRow.layer_id ?? "").trim();
        let resolvedBatchId = String(sourceRow.batch_id ?? "").trim();
        if (!resolvedLayerId || !resolvedBatchId) {
          const resolved = await this.resolveSourceLayerForDraft(client, {
            entityId,
            productId: item.product_id,
            warehouseId: sourceWarehouseId,
            binId: sourceBinId,
            batchId: resolvedBatchId,
            qty: sourceRow.qty,
          });
          resolvedLayerId = resolved.layerId;
          resolvedBatchId = resolved.batchId;
        }
        await client.query(
          `INSERT INTO transfer_order_source_batches
            (transfer_item_id, batch_id, layer_id, warehouse_id, bin_id, qty)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [
            transferItemId,
            resolvedBatchId,
            resolvedLayerId,
            sourceWarehouseId,
            sourceBinId,
            sourceRow.qty,
          ],
        );
        resolvedSourceBatches.push({ batchId: resolvedBatchId });
      }

      for (const destinationRow of item.destination_batches ?? []) {
        const sourceBatchId = String(destinationRow.source_batch_id ?? "").trim();
        const destinationBatchId = String(
          destinationRow.destination_batch_id ?? "",
        ).trim();
        const resolvedSourceBatchId =
          sourceBatchId ||
          destinationBatchId ||
          resolvedSourceBatches[0]?.batchId ||
          "";
        const resolvedDestinationBatchId =
          destinationBatchId || resolvedSourceBatchId;
        if (!resolvedSourceBatchId || !resolvedDestinationBatchId) {
          throw new BadRequestException(
            "Destination batch rows must map to a valid source batch",
          );
        }
        await client.query(
          `INSERT INTO transfer_order_destination_batches
            (transfer_item_id, source_batch_id, destination_batch_id, destination_warehouse_id, destination_bin_id, qty)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [
            transferItemId,
            resolvedSourceBatchId,
            resolvedDestinationBatchId,
            destinationRow.destination_warehouse_id,
            destinationRow.destination_bin_id,
            destinationRow.qty,
          ],
        );
      }
    }
  }

  private async appendLog(
    client: Client,
    transferOrderId: string,
    action: "CREATED" | "UPDATED" | "INITIATED" | "RECEIVED",
    userId?: string | null,
  ) {
    await client.query(
      `INSERT INTO transfer_order_logs
        (transfer_order_id, action, action_by, action_at)
       VALUES ($1, $2, $3, now())`,
      [transferOrderId, action, userId ?? null],
    );
  }

  async findAll(tenant: TenantContext, query: ListTransferOrdersQuery) {
    const entityId = this.ensureEntity(tenant);
    const page = Math.max(Number(query.page ?? 1) || 1, 1);
    const limit = Math.min(Math.max(Number(query.limit ?? 20) || 20, 1), 200);
    const offset = (page - 1) * limit;
    const status = query.status?.trim().toUpperCase();
    const search = query.search?.trim();

    // Use raw query for complex joins and aggregations
    let sql = `
      SELECT 
        m.*,
        sw.name as source_warehouse_name,
        dw.name as destination_warehouse_name,
        COALESCE(SUM(i.qty_transferred), 0) as total_qty
      FROM transfer_order_master m
      LEFT JOIN organisation_branch_master sw ON m.source_warehouse_id = sw.id
      LEFT JOIN organisation_branch_master dw ON m.destination_warehouse_id = dw.id
      LEFT JOIN transfer_order_items i ON m.id = i.transfer_order_id
      WHERE m.entity_id = $1
    `;
    
    const params: any[] = [entityId];
    let paramCount = 1;

    if (status) {
      paramCount++;
      sql += ` AND m.status = $${paramCount}`;
      params.push(status);
    }

    if (search) {
      paramCount++;
      sql += ` AND m.transfer_no ILIKE $${paramCount}`;
      params.push(`%${search}%`);
    }

    sql += `
      GROUP BY m.id, sw.name, dw.name
      ORDER BY m.transfer_date DESC, m.created_at DESC
      LIMIT $${++paramCount} OFFSET $${++paramCount}
    `;
    params.push(limit, offset);

    const countSql = `SELECT COUNT(*) FROM transfer_order_master WHERE entity_id = $1 ${status ? 'AND status = $2' : ''}`;
    const countParams = status ? [entityId, status] : [entityId];

    let dataRes: { data?: unknown } | null = null;
    let countRes: { data?: unknown } | null = null;
    try {
      [dataRes, countRes] = await Promise.all([
        this.supabaseService.getClient().rpc('request', {
          p_method: 'GET',
          p_path: '/raw-query',
          p_body: { sql, params },
        }),
        this.supabaseService.getClient().rpc('request', {
          p_method: 'GET',
          p_path: '/raw-query',
          p_body: { sql: countSql, params: countParams },
        }),
      ]);
    } catch (_) {
      // Fallback if rpc('request') is not configured for raw-query.
      // We'll fall back to the builder path below.
      dataRes = null;
      countRes = null;
    }

    // If raw query fails or not available, fallback to builder with joins
    if (!dataRes || !dataRes.data) {
      let builder = this.supabaseService
        .getClient()
        .from("transfer_order_master")
        .select(`
          *,
          source_warehouse:source_warehouse_id(name),
          destination_warehouse:destination_warehouse_id(name)
        `, { count: "exact" })
        .eq("entity_id", entityId)
        .order("transfer_date", { ascending: false })
        .order("created_at", { ascending: false });

      if (status) builder = builder.eq("status", status);
      if (search) builder = builder.ilike("transfer_no", `%${search}%`);

      const { data, error, count } = await builder.range(offset, offset + limit - 1);
      if (error) throw new BadRequestException(error.message);

      const mappedData = (data ?? []).map(row => ({
        ...row,
        source_warehouse_name: row.source_warehouse?.name,
        destination_warehouse_name: row.destination_warehouse?.name,
      }));

      return {
        data: mappedData,
        page,
        limit,
        total: count ?? 0,
      };
    }

      const rawCountRows = Array.isArray(countRes?.data) ? countRes?.data : [];
      const rawCountRow = rawCountRows.length > 0 ? rawCountRows[0] as Record<string, unknown> : null;

      return {
        data: dataRes.data ?? [],
        page,
        limit,
        total: Number(rawCountRow?.count ?? rawCountRow?.total ?? 0),
      };
  }

  async findOne(id: string, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    const client = this.supabaseService.getClient();

    const [orderRes, rawItemsRes] = await Promise.all([
      client
        .from("transfer_order_master")
        .select("*")
        .eq("id", id)
        .eq("entity_id", entityId)
        .maybeSingle(),
      this.supabaseService.getClient().rpc('request', {
        p_method: 'GET',
        p_path: '/raw-query',
        p_body: {
          sql: `
            SELECT i.*, p.product_name, p.hsn_code, p.item_code
            FROM transfer_order_items i
            LEFT JOIN products p ON i.product_id = p.id
            WHERE i.transfer_order_id = $1
          `,
          params: [id]
        }
      }),
    ]);

    if (orderRes.error) {
      this.logger.error(`Order Fetch Error: ${JSON.stringify(orderRes.error)}`);
      throw new BadRequestException(orderRes.error.message);
    }
    if (!orderRes.data) throw new NotFoundException("Transfer order not found");

    let itemsRes = rawItemsRes;
    if (itemsRes.error) {
      // Graceful fallback when rpc('request') is unavailable in target DB.
      const fallbackItemsRes = await client
        .from("transfer_order_items")
        .select(`
          *,
          product:product_id (
            product_name,
            hsn_code,
            item_code
          )
        `)
        .eq("transfer_order_id", id);

      if (fallbackItemsRes.error) {
        throw new BadRequestException(fallbackItemsRes.error.message);
      }

      const mappedFallbackItems = (fallbackItemsRes.data ?? []).map((row: any) => ({
        ...row,
        product_name: row.product?.product_name ?? null,
        hsn_code: row.product?.hsn_code ?? null,
        item_code: row.product?.item_code ?? null,
      }));

      itemsRes = { data: mappedFallbackItems, error: null } as any;
    }

    const order = orderRes.data;
    const rawItems = itemsRes.data ?? [];
    const itemIds = rawItems.map((row: any) => row.id);

    const [sourceRes, destinationRes] = await Promise.all([
      itemIds.length > 0
        ? client
            .from("transfer_order_source_batches")
            .select("*")
            .in("transfer_item_id", itemIds)
        : Promise.resolve({ data: [], error: null as any }),
      itemIds.length > 0
        ? client
            .from("transfer_order_destination_batches")
            .select("*")
            .in("transfer_item_id", itemIds)
        : Promise.resolve({ data: [], error: null as any }),
    ]);

    if (sourceRes.error) throw new BadRequestException(sourceRes.error.message);
    if (destinationRes.error) {
      throw new BadRequestException(destinationRes.error.message);
    }

    const sourceByItem = new Map<string, any[]>();
    for (const row of sourceRes.data ?? []) {
      const list = sourceByItem.get(String((row as any).transfer_item_id)) ?? [];
      list.push(row);
      sourceByItem.set(String((row as any).transfer_item_id), list);
    }

    const destinationByItem = new Map<string, any[]>();
    for (const row of destinationRes.data ?? []) {
      const list =
        destinationByItem.get(String((row as any).transfer_item_id)) ?? [];
      list.push(row);
      destinationByItem.set(String((row as any).transfer_item_id), list);
    }

    return {
      ...order,
      items: rawItems.map((item: any) => {
        return {
          ...item,
          product_name: item.product_name || "Unknown Product",
          product_code: item.item_code || "",
          hsn_sac: item.hsn_code || "",
          source_batches: sourceByItem.get(String(item.id)) ?? [],
          destination_batches: destinationByItem.get(String(item.id)) ?? [],
        };
      }),
    };
  }

  async create(dto: CreateTransferOrderDto, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    const status = this.normalizeStatus(dto.status);
    if (status !== "DRAFT") {
      throw new BadRequestException(
        "Create supports DRAFT only. Use initiate/approve endpoints for state progression.",
      );
    }
    this.assertWarehousePair(
      dto.source_warehouse_id,
      dto.destination_warehouse_id,
    );
    const items = this.sanitizeItems(dto.items);
    if (!dto.transfer_no?.trim()) {
      throw new BadRequestException("transfer_no is required");
    }
    if (!dto.transfer_date?.trim()) {
      throw new BadRequestException("transfer_date is required");
    }

    return this.withPgClient(async (client) => {
      await client.query("BEGIN");
      try {
        const masterInsert = await client.query(
          `INSERT INTO transfer_order_master
            (transfer_no, transfer_date, entity_id, source_warehouse_id, destination_warehouse_id, status, reason, created_by, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, 'DRAFT', $6, $7, now(), now())
           RETURNING id`,
          [
            dto.transfer_no.trim(),
            dto.transfer_date,
            entityId,
            dto.source_warehouse_id,
            dto.destination_warehouse_id,
            dto.reason ?? null,
            tenant.userId ?? null,
          ],
        );
        const orderId = masterInsert.rows[0]?.id as string;
        if (!orderId) {
          throw new BadRequestException("Unable to create transfer order");
        }

        await this.writeDraftGraph(client, entityId, orderId, items);
        await this.appendLog(client, orderId, "CREATED", tenant.userId ?? null);

        await client.query("COMMIT");
        return this.findOne(orderId, tenant);
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    });
  }

  async update(id: string, dto: UpdateTransferOrderDto, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    const existing = await this.findOne(id, tenant);
    if (String(existing.status ?? "").toUpperCase() !== "DRAFT") {
      throw new BadRequestException("Only DRAFT transfer orders can be updated");
    }

    const sourceWarehouseId =
      dto.source_warehouse_id ?? existing.source_warehouse_id;
    const destinationWarehouseId =
      dto.destination_warehouse_id ?? existing.destination_warehouse_id;
    this.assertWarehousePair(sourceWarehouseId, destinationWarehouseId);

    const items = dto.items ? this.sanitizeItems(dto.items) : existing.items;

    return this.withPgClient(async (client) => {
      await client.query("BEGIN");
      try {
        await client.query(
          `UPDATE transfer_order_master
           SET transfer_no = $1,
               transfer_date = $2,
               source_warehouse_id = $3,
               destination_warehouse_id = $4,
               reason = $5,
               updated_at = now()
           WHERE id = $6 AND entity_id = $7`,
          [
            (dto.transfer_no ?? existing.transfer_no)?.trim(),
            dto.transfer_date ?? existing.transfer_date,
            sourceWarehouseId,
            destinationWarehouseId,
            dto.reason ?? existing.reason ?? null,
            id,
            entityId,
          ],
        );

        await this.writeDraftGraph(client, entityId, id, items);
        await this.appendLog(client, id, "UPDATED", tenant.userId ?? null);

        await client.query("COMMIT");
        return this.findOne(id, tenant);
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    });
  }

  async initiateTransfer(id: string, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    return this.withPgClient(async (client) => {
      await client.query("BEGIN");
      try {
        const orderRes = await client.query(
          `SELECT id, status
           FROM transfer_order_master
           WHERE id = $1 AND entity_id = $2
           FOR UPDATE`,
          [id, entityId],
        );
        const order = orderRes.rows[0];
        if (!order) {
          throw new NotFoundException("Transfer order not found");
        }
        const status = String(order.status ?? "").toUpperCase();
        if (status === "INITIATED") {
          await client.query("COMMIT");
          return this.findOne(id, tenant);
        }
        if (status !== "DRAFT") {
          throw new BadRequestException(
            `Only DRAFT transfer orders can be initiated. Current status: ${status}`,
          );
        }

        const sourceRowsRes = await client.query(
          `SELECT sb.layer_id, SUM(sb.qty) AS qty
           FROM transfer_order_source_batches sb
           JOIN transfer_order_items ti ON ti.id = sb.transfer_item_id
           WHERE ti.transfer_order_id = $1
           GROUP BY sb.layer_id`,
          [id],
        );
        if (sourceRowsRes.rows.length === 0) {
          throw new BadRequestException(
            "No source batch allocations found to initiate transfer",
          );
        }

        for (const row of sourceRowsRes.rows) {
          const layerId = String(row.layer_id);
          const requiredQty = this.parseNumber(row.qty, 0);
          if (requiredQty <= 0) continue;

          const layerRes = await client.query(
            `SELECT id, qty, reserved_qty
             FROM batch_stock_layers
             WHERE id = $1 AND entity_id = $2
             FOR UPDATE`,
            [layerId, entityId],
          );
          const layer = layerRes.rows[0] as TransferLayerRow | undefined;
          if (!layer) {
            throw new BadRequestException(
              `Source stock layer not found: ${layerId}`,
            );
          }

          const qty = this.parseNumber(layer.qty, 0);
          const reservedQty = this.parseNumber(layer.reserved_qty, 0);
          const available = qty - reservedQty;
          if (available < requiredQty) {
            throw new BadRequestException(
              `Insufficient available quantity in source layer ${layerId}. Required: ${requiredQty}, available: ${available}`,
            );
          }

          await client.query(
            `UPDATE batch_stock_layers
             SET reserved_qty = reserved_qty + $1,
                 updated_at = now()
             WHERE id = $2`,
            [requiredQty, layerId],
          );
        }

        await client.query(
          `UPDATE transfer_order_master
           SET status = 'INITIATED',
               updated_at = now()
           WHERE id = $1`,
          [id],
        );

        await this.appendLog(client, id, "INITIATED", tenant.userId ?? null);
        await client.query("COMMIT");
        return this.findOne(id, tenant);
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    });
  }

  async approveTransfer(id: string, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    return this.withPgClient(async (client) => {
      await client.query("BEGIN");
      try {
        const orderRes = await client.query(
          `SELECT id, status, transfer_no, transfer_date
           FROM transfer_order_master
           WHERE id = $1 AND entity_id = $2
           FOR UPDATE`,
          [id, entityId],
        );
        const order = orderRes.rows[0];
        if (!order) {
          throw new NotFoundException("Transfer order not found");
        }
        const status = String(order.status ?? "").toUpperCase();
        if (status === "RECEIVED") {
          await client.query("COMMIT");
          return this.findOne(id, tenant);
        }
        if (status !== "INITIATED") {
          throw new BadRequestException(
            `Only INITIATED transfer orders can be approved. Current status: ${status}`,
          );
        }

        const sourceRowsRes = await client.query(
          `SELECT
              sb.id,
              sb.transfer_item_id,
              sb.layer_id,
              sb.batch_id,
              sb.warehouse_id,
              sb.bin_id,
              sb.qty,
              ti.product_id
           FROM transfer_order_source_batches sb
           JOIN transfer_order_items ti ON ti.id = sb.transfer_item_id
           WHERE ti.transfer_order_id = $1`,
          [id],
        );
        const destinationRowsRes = await client.query(
          `SELECT
              db.id,
              db.transfer_item_id,
              db.source_batch_id,
              db.destination_batch_id,
              db.destination_warehouse_id,
              db.destination_bin_id,
              db.qty,
              ti.product_id
           FROM transfer_order_destination_batches db
           JOIN transfer_order_items ti ON ti.id = db.transfer_item_id
           WHERE ti.transfer_order_id = $1`,
          [id],
        );

        if (sourceRowsRes.rows.length === 0) {
          throw new BadRequestException("No source batches found for transfer");
        }
        if (destinationRowsRes.rows.length === 0) {
          throw new BadRequestException(
            "No destination batches found for transfer",
          );
        }

        const sourceBatchMetaByBatchId = new Map<
          string,
          { purchaseRate: number; mrp: number; vendorId: string | null }
        >();

        for (const sourceRow of sourceRowsRes.rows) {
          const qty = this.parseNumber(sourceRow.qty, 0);
          if (qty <= 0) continue;

          const layerRes = await client.query(
            `SELECT id, qty, reserved_qty, purchase_rate, mrp, vendor_id
             FROM batch_stock_layers
             WHERE id = $1 AND entity_id = $2
             FOR UPDATE`,
            [sourceRow.layer_id, entityId],
          );
          const layer = layerRes.rows[0] as TransferLayerRow | undefined;
          if (!layer) {
            throw new BadRequestException(
              `Source stock layer not found: ${sourceRow.layer_id}`,
            );
          }

          const currentQty = this.parseNumber(layer.qty, 0);
          const currentReserved = this.parseNumber(layer.reserved_qty, 0);
          if (currentQty < qty || currentReserved < qty) {
            throw new BadRequestException(
              `Cannot approve transfer; layer ${sourceRow.layer_id} has insufficient qty/reserved`,
            );
          }

          await client.query(
            `UPDATE batch_stock_layers
             SET qty = qty - $1,
                 reserved_qty = reserved_qty - $1,
                 updated_at = now()
             WHERE id = $2`,
            [qty, sourceRow.layer_id],
          );

          await client.query(
            `INSERT INTO batch_transactions
              (batch_id, layer_id, product_id, entity_id, warehouse_id, bin_id, trans_type, ref_id, ref_no, qty_in, qty_out, rate, trans_date, created_at)
             VALUES
              ($1, $2, $3, $4, $5, $6, 'TRANSFER_OUT', $7, $8, 0, $9, $10, now(), now())`,
            [
              sourceRow.batch_id,
              sourceRow.layer_id,
              sourceRow.product_id,
              entityId,
              sourceRow.warehouse_id,
              sourceRow.bin_id,
              id,
              order.transfer_no,
              qty,
              this.parseNumber(layer.purchase_rate, 0),
            ],
          );

          if (!sourceBatchMetaByBatchId.has(String(sourceRow.batch_id))) {
            sourceBatchMetaByBatchId.set(String(sourceRow.batch_id), {
              purchaseRate: this.parseNumber(layer.purchase_rate, 0),
              mrp: this.parseNumber(layer.mrp, 0),
              vendorId: layer.vendor_id ?? null,
            });
          }
        }

        for (const destinationRow of destinationRowsRes.rows) {
          const qty = this.parseNumber(destinationRow.qty, 0);
          if (qty <= 0) continue;

          const sourceMeta = sourceBatchMetaByBatchId.get(
            String(destinationRow.source_batch_id),
          ) ?? {
            purchaseRate: 0,
            mrp: 0,
            vendorId: null,
          };

          const layerUpsertRes = await client.query(
            `INSERT INTO batch_stock_layers
              (batch_id, product_id, entity_id, warehouse_id, bin_id, vendor_id, purchase_rate, mrp, qty, ref_id, ref_type, created_at, updated_at, reserved_qty)
             VALUES
              ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'TRANSFER_IN', now(), now(), 0)
             ON CONFLICT (batch_id, product_id, entity_id, warehouse_id, bin_id)
             DO UPDATE SET
               qty = batch_stock_layers.qty + EXCLUDED.qty,
               updated_at = now()
             RETURNING id`,
            [
              destinationRow.destination_batch_id,
              destinationRow.product_id,
              entityId,
              destinationRow.destination_warehouse_id,
              destinationRow.destination_bin_id,
              sourceMeta.vendorId,
              sourceMeta.purchaseRate,
              sourceMeta.mrp,
              qty,
              id,
            ],
          );
          const destinationLayerId = layerUpsertRes.rows[0]?.id as string;

          await client.query(
            `INSERT INTO batch_transactions
              (batch_id, layer_id, product_id, entity_id, warehouse_id, bin_id, trans_type, ref_id, ref_no, qty_in, qty_out, rate, trans_date, created_at)
             VALUES
              ($1, $2, $3, $4, $5, $6, 'TRANSFER_IN', $7, $8, $9, 0, $10, now(), now())`,
            [
              destinationRow.destination_batch_id,
              destinationLayerId,
              destinationRow.product_id,
              entityId,
              destinationRow.destination_warehouse_id,
              destinationRow.destination_bin_id,
              id,
              order.transfer_no,
              qty,
              sourceMeta.purchaseRate,
            ],
          );
        }

        await client.query(
          `UPDATE transfer_order_items
           SET qty_transferred = qty_requested
           WHERE transfer_order_id = $1`,
          [id],
        );

        await client.query(
          `UPDATE transfer_order_master
           SET status = 'RECEIVED',
               updated_at = now()
           WHERE id = $1`,
          [id],
        );

        await this.appendLog(client, id, "RECEIVED", tenant.userId ?? null);

        await client.query("COMMIT");
        return this.findOne(id, tenant);
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    });
  }

  async deleteTransfer(id: string, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    return this.withPgClient(async (client) => {
      await client.query("BEGIN");
      try {
        const orderRes = await client.query(
          `SELECT id, status
           FROM transfer_order_master
           WHERE id = $1 AND entity_id = $2
           FOR UPDATE`,
          [id, entityId],
        );
        const order = orderRes.rows[0];
        if (!order) {
          throw new NotFoundException("Transfer order not found");
        }
        const status = String(order.status ?? "").toUpperCase();
        if (status !== "DRAFT") {
          throw new BadRequestException(
            `Only DRAFT transfer orders can be deleted. Current status: ${status}`,
          );
        }

        await client.query(
          "DELETE FROM transfer_order_source_batches WHERE transfer_item_id IN (SELECT id FROM transfer_order_items WHERE transfer_order_id = $1)",
          [id],
        );
        await client.query(
          "DELETE FROM transfer_order_destination_batches WHERE transfer_item_id IN (SELECT id FROM transfer_order_items WHERE transfer_order_id = $1)",
          [id],
        );
        await client.query("DELETE FROM transfer_order_items WHERE transfer_order_id = $1", [
          id,
        ]);
        await client.query(
          "DELETE FROM transfer_order_logs WHERE transfer_order_id = $1",
          [id],
        );
        await client.query(
          "DELETE FROM transfer_order_master WHERE id = $1 AND entity_id = $2",
          [id, entityId],
        );

        await client.query("COMMIT");
        return { success: true };
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    });
  }
}
