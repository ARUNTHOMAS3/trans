import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from "@nestjs/common";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../supabase/supabase.service";

export interface ListInventoryAdjustmentsQuery {
  page?: string;
  limit?: string;
  search?: string;
  status?: string;
  adjustment_type?: string;
  date_from?: string;
  date_to?: string;
  product_id?: string;
}

export interface CreateInventoryAdjustmentBatchDto {
  bin_id?: string | null;
  bin_location_id?: string | null;
  warehouse_id?: string | null;
  product_id?: string;
  batch_id?: string | null;
  batch_stock_layer_id?: string | null;
  batch_reference?: string | null;
  quantity_in?: number;
  quantity_out?: number;
  quantity?: number;
  rate?: number;
}

export interface CreateInventoryAdjustmentItemDto {
  product_id: string;
  quantity_before?: number;
  quantity_adjusted?: number;
  quantity_after?: number;
  cost_price?: number;
  mrp?: number;
  adjustment_value?: number;
  batch_id?: string | null;
  batch_reference?: string | null;
  batch_allocations?: CreateInventoryAdjustmentBatchDto[];
  reporting_tags?: Record<string, unknown>;
  mfd_month_year?: string | null;
  expiry_month_year?: string | null;
}

export interface CreateInventoryAdjustmentValueItemDto {
  product_id: string;
  batch_id?: string | null;
  batch_stock_layer_id?: string | null;
  current_value?: number;
  changed_value?: number;
  adjusted_value?: number;
}

export interface CreateInventoryAdjustmentAccountEntryDto {
  account_id: string;
  debit?: number;
  credit?: number;
  description?: string | null;
}

export interface InventoryAdjustmentReasonDto {
  name: string;
  code?: string | null;
  is_active?: boolean;
  sort_order?: number;
}

export interface CreateInventoryAdjustmentDto {
  product_id: string;
  warehouse_id?: string | null;
  adjustment_date?: string;
  adjustment_type?: string;
  reason?: string;
  reason_id?: string | null;
  quantity_before?: number;
  quantity_adjusted: number;
  quantity_after?: number;
  cost_price?: number;
  adjustment_value?: number;
  account_id?: string | null;
  reference_number?: string;
  notes?: string;
  status?: string;
  allow_reserved_consumption?: boolean;
  items?: CreateInventoryAdjustmentItemDto[];
  value_items?: CreateInventoryAdjustmentValueItemDto[];
  account_entries?: CreateInventoryAdjustmentAccountEntryDto[];
}

export interface UpdateInventoryAdjustmentDto {
  warehouse_id?: string | null;
  adjustment_date?: string;
  adjustment_type?: string;
  reason?: string;
  reason_id?: string | null;
  quantity_before?: number;
  quantity_adjusted?: number;
  quantity_after?: number;
  cost_price?: number;
  adjustment_value?: number;
  account_id?: string | null;
  reference_number?: string;
  notes?: string;
  status?: string;
  items?: CreateInventoryAdjustmentItemDto[];
  value_items?: CreateInventoryAdjustmentValueItemDto[];
  account_entries?: CreateInventoryAdjustmentAccountEntryDto[];
}

export interface ApproveStockCountItemDto {
  product_id: string;
  name?: string;
  system_qty?: number;
  counted_qty?: number | null;
  rate?: number;
  decision?: string;
  adjustment_reason?: string | null;
  batches?: Array<Record<string, unknown>>;
}

export interface ApproveStockCountDto {
  warehouse_id?: string | null;
  description?: string | null;
  items?: ApproveStockCountItemDto[];
}

interface UserIdentity {
  name: string | null;
  email: string | null;
}

interface NormalizedBatchAllocationRow {
  adjustment_id: string;
  adjustment_item_id: string;
  entity_id: string;
  product_id: string;
  warehouse_id: string | null;
  bin_id: string | null;
  batch_id: string | null;
  batch_stock_layer_id: string | null;
  batch_reference: string | null;
  quantity_in: number;
  quantity_out: number;
  rate: number | null;
}

export interface InventoryAdjustmentReasonRow {
  id: string;
  entity_id: string | null;
  name: string;
  code: string | null;
  is_active: boolean;
  sort_order: number;
  created_at: string | null;
  updated_at: string | null;
}

@Injectable()
export class InventoryAdjustmentsService {
  private readonly logger = new Logger(InventoryAdjustmentsService.name);
  private static readonly UUID_REGEX =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

  constructor(private readonly supabaseService: SupabaseService) {}

  private get client() {
    return this.supabaseService.getClient();
  }

  private ensureEntity(tenant: TenantContext) {
    if (!tenant.entityId) {
      throw new BadRequestException("Missing tenant entity context");
    }
    return tenant.entityId;
  }

  private normalizeUuid(value: unknown): string | null {
    const raw = String(value ?? "").trim();
    if (!raw) return null;
    return InventoryAdjustmentsService.UUID_REGEX.test(raw) ? raw : null;
  }

  private isMissingTableError(error: unknown): boolean {
    const code = (error as { code?: string })?.code ?? "";
    const details = (
      (error as { details?: string })?.details ?? ""
    ).toLowerCase();
    const hint = ((error as { hint?: string })?.hint ?? "").toLowerCase();
    const message = (
      (error as { message?: string })?.message ?? ""
    ).toLowerCase();
    return (
      code === "42P01" ||
      code === "PGRST205" ||
      message.includes("does not exist") ||
      message.includes("could not find the table") ||
      details.includes("could not find the table") ||
      hint.includes("perhaps you meant the table")
    );
  }

  private isMissingColumnError(error: unknown): boolean {
    const code = (error as { code?: string })?.code ?? "";
    const message = String((error as { message?: string })?.message ?? "")
      .trim()
      .toLowerCase();
    return (
      code === "PGRST204" ||
      message.includes("schema cache") ||
      message.includes("could not find the") && message.includes("column")
    );
  }

  private getMissingColumnName(error: unknown): string | null {
    const message = String((error as { message?: string })?.message ?? "").trim();
    const match = message.match(/'([^']+)' column/i);
    if (match?.[1]) {
      return match[1].trim();
    }
    const alternate = message.match(/could not find the '([^']+)'/i);
    return alternate?.[1]?.trim() ?? null;
  }

  private errorMentionsRelation(error: unknown, relation: string): boolean {
    const haystack = [
      (error as { message?: string })?.message ?? "",
      (error as { details?: string })?.details ?? "",
      (error as { hint?: string })?.hint ?? "",
    ]
      .join(" ")
      .toLowerCase();
    return haystack.includes(relation.toLowerCase());
  }

  private isOptionalBatchTransactionStorageError(error: unknown): boolean {
    return (
      this.errorMentionsRelation(error, "batch_transactions") &&
      (this.isMissingTableError(error) || this.isMissingColumnError(error))
    );
  }

  private handleStorageError(error: unknown): never {
    if (this.isMissingTableError(error)) {
      throw new ServiceUnavailableException(
        "Inventory adjustments table is not ready yet. Complete DB setup, then retry.",
      );
    }
    throw error;
  }

  private async insertWithSchemaFallback(
    table: string,
    payload: Record<string, unknown>,
    selectClause?: string,
  ) {
    let currentPayload = { ...payload };
    const strippedColumns = new Set<string>();

    while (true) {
      let query: any = this.client.from(table).insert(currentPayload);
      if (selectClause) {
        query = query.select(selectClause).single();
      }

      const { data, error } = await query;
      if (!error) {
        return { data, payload: currentPayload };
      }

      const missingColumn = this.getMissingColumnName(error);
      if (
        !this.isMissingColumnError(error) ||
        !missingColumn ||
        strippedColumns.has(missingColumn) ||
        !(missingColumn in currentPayload)
      ) {
        this.handleStorageError(error);
      }

      strippedColumns.add(missingColumn);
      delete currentPayload[missingColumn];
      this.logger.warn(
        `insertWithSchemaFallback table=${table} dropped unsupported column=${missingColumn}`,
      );
    }
  }

  private async updateWithSchemaFallback(
    table: string,
    payload: Record<string, unknown>,
    applyFilters: (query: any) => any,
  ) {
    let currentPayload = { ...payload };
    const strippedColumns = new Set<string>();

    while (true) {
      const query = applyFilters(this.client.from(table).update(currentPayload));
      const { data, error } = await query;
      if (!error) {
        return { data, payload: currentPayload };
      }

      const missingColumn = this.getMissingColumnName(error);
      if (
        !this.isMissingColumnError(error) ||
        !missingColumn ||
        strippedColumns.has(missingColumn) ||
        !(missingColumn in currentPayload)
      ) {
        this.handleStorageError(error);
      }

      strippedColumns.add(missingColumn);
      delete currentPayload[missingColumn];
      this.logger.warn(
        `updateWithSchemaFallback table=${table} dropped unsupported column=${missingColumn}`,
      );
    }
  }

  private buildFallbackAdjustmentResponse(
    header: Record<string, unknown>,
    items: CreateInventoryAdjustmentItemDto[] = [],
  ) {
    return {
      ...header,
      items: items.map((item) => ({
        ...item,
        batch_allocations: Array.isArray(item.batch_allocations)
          ? item.batch_allocations
          : [],
      })),
      value_items: [],
      account_entries: [],
    };
  }

  private async isStockCountBackedAdjustment(
    tenant: TenantContext,
    adjustment: Record<string, unknown>,
  ): Promise<boolean> {
    const entityId = this.ensureEntity(tenant);
    const referenceNumber = String(
      adjustment.reference_number ?? adjustment.referenceNumber ?? "",
    ).trim();
    if (!referenceNumber) {
      return false;
    }

    const { data, error } = await this.client
      .from("inventory_stock_count")
      .select("id")
      .eq("entity_id", entityId)
      .eq("stock_count_number", referenceNumber)
      .limit(1)
      .maybeSingle();

    if (error) {
      this.handleStorageError(error);
    }

    return !!data;
  }

  private parseNumber(value: unknown, fallback = 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  private normalizeStatus(status?: string) {
    const normalized = (status ?? "draft").trim().toLowerCase();
    if (
      normalized === "draft" ||
      normalized === "submitted" ||
      normalized === "approved" ||
      normalized === "rejected" ||
      normalized === "cancelled"
    ) {
      return normalized;
    }
    return "draft";
  }

  private normalizeType(type?: string) {
    const normalized = (type ?? "quantity").trim().toLowerCase();
    if (normalized === "quantity" || normalized === "value") {
      return normalized;
    }
    return "quantity";
  }

  private safeArray<T>(value: unknown): T[] {
    return Array.isArray(value) ? (value as T[]) : [];
  }

  private async resolveInventoryAccountIdForProduct(
    productId: string | null | undefined,
  ): Promise<string | null> {
    const normalizedProductId = this.normalizeUuid(productId);
    if (!normalizedProductId) return null;

    const { data, error } = await this.client
      .from("products")
      .select("inventory_account_id")
      .eq("id", normalizedProductId)
      .maybeSingle();

    if (error) this.handleStorageError(error);
    return this.normalizeUuid((data as any)?.inventory_account_id);
  }

  private async buildUserIdentityMap(
    tenant: TenantContext,
    rawUserIds: Array<string | null | undefined>,
  ): Promise<Map<string, UserIdentity>> {
    const entityId = this.ensureEntity(tenant);
    const userIds = Array.from(
      new Set(
        rawUserIds
          .map((id) => (id ?? "").toString().trim())
          .filter((id) => id.length > 0),
      ),
    );

    if (userIds.length === 0) {
      return new Map<string, UserIdentity>();
    }

    const { data, error } = await this.client
      .from("users")
      .select("id, full_name, email")
      .eq("entity_id", entityId)
      .in("id", userIds);

    if (error) {
      this.handleStorageError(error);
    }

    const map = new Map<string, UserIdentity>();
    const attachRows = (rows: any[] | null | undefined) => {
      for (const row of rows ?? []) {
        const id = String((row as any).id ?? "").trim();
        if (!id || map.has(id)) continue;
        const fullName = String((row as any).full_name ?? "").trim();
        const email = String((row as any).email ?? "").trim();
        if (fullName || email) {
          map.set(id, {
            name: fullName || null,
            email: email || null,
          });
        }
      }
    };

    attachRows(data as any[]);

    const unresolved = userIds.filter((id) => !map.has(id));
    if (unresolved.length > 0) {
      const { data: fallbackData, error: fallbackError } = await this.client
        .from("users")
        .select("id, full_name, email")
        .in("id", unresolved);

      if (fallbackError) {
        this.handleStorageError(fallbackError);
      }

      attachRows(fallbackData as any[]);
    }

    for (const id of userIds) {
      if (!map.has(id)) {
        map.set(id, {
          name: `User ${id.slice(0, 8)}`,
          email: null,
        });
      }
    }

    return map;
  }

  private async getCurrentStock(
    productId: string,
    tenant: TenantContext,
    warehouseId?: string | null,
  ) {
    const entityId = this.ensureEntity(tenant);

    const normalizedWarehouseId = this.normalizeUuid(warehouseId);

    const { data, error } = await this.client
      .from("v_product_stock_summary")
      .select("warehouse_id, stock_on_hand")
      .eq("entity_id", entityId)
      .eq("product_id", productId)
      .eq("warehouse_id", normalizedWarehouseId ?? null);

    if (!error) {
      const row = data?.[0] as { stock_on_hand?: number | string } | undefined;
      return {
        currentStock: this.parseNumber(row?.stock_on_hand, 0),
      };
    }

    if (!this.isMissingTableError(error)) {
      this.handleStorageError(error);
    }

    this.logger.warn(
      "v_product_stock_summary unavailable; falling back to batch_stock_layers for stock baseline",
    );

    let layerRows: any[] | null = null;
    {
      let fallbackQuery = this.client
        .from("batch_stock_layers")
        .select("qty, reserved_qty, warehouse_id")
        .eq("entity_id", entityId)
        .eq("product_id", productId);
    if (normalizedWarehouseId) {
        fallbackQuery = fallbackQuery.eq("warehouse_id", normalizedWarehouseId);
      }

    const firstAttempt = await fallbackQuery;
      if (!firstAttempt.error) {
        layerRows = firstAttempt.data ?? [];
      } else if (this.isMissingColumnError(firstAttempt.error)) {
        let minimalQuery = this.client
          .from("batch_stock_layers")
          .select("qty, warehouse_id")
          .eq("entity_id", entityId)
          .eq("product_id", productId);

        if (normalizedWarehouseId) {
          minimalQuery = minimalQuery.eq("warehouse_id", normalizedWarehouseId);
        }

        const secondAttempt = await minimalQuery;
        if (secondAttempt.error) {
          this.handleStorageError(secondAttempt.error);
        }
        layerRows = secondAttempt.data ?? [];
      } else {
        this.handleStorageError(firstAttempt.error);
      }

    const currentStock = (layerRows ?? []).reduce((sum, row: any) => {
      const qty = this.parseNumber(row?.qty, 0);
      const reserved = this.parseNumber(row?.reserved_qty, 0);
      return sum + Math.max(0, qty - reserved);
    }, 0);

    return {
      currentStock,
    };
  }

  private async applyBatchLayerQuantityAdjustments(
    adjustmentId: string,
    adjustment: Record<string, unknown>,
    tenant: TenantContext,
    batchRows: any[],
    options?: { allowReservedConsumption?: boolean },
  ) {
    const entityId = this.ensureEntity(tenant);
    const now = new Date().toISOString();
    const transDate =
      adjustment.adjustment_date?.toString() ?? new Date().toISOString();
    const allowReservedConsumption =
      options?.allowReservedConsumption === true;

    for (const row of batchRows) {
      const productId = String(row?.product_id ?? "").trim();
      const batchId = this.normalizeUuid(row?.batch_id);
      const warehouseId = this.normalizeUuid(row?.warehouse_id);
      const binId = this.normalizeUuid(row?.bin_id);
      const qIn = this.parseNumber(row?.quantity_in, 0);
      const qOut = this.parseNumber(row?.quantity_out, 0);
      const delta = qIn - qOut;

      if (!productId || !batchId || !warehouseId || delta === 0) {
        continue;
      }

      let layerId = this.normalizeUuid(row?.batch_stock_layer_id);

      if (delta < 0) {
        const qtyToConsume = Math.abs(delta);
        let layerRows: any[] | null = null;
        {
          let layerQuery = this.client
            .from("batch_stock_layers")
            .select("id, qty, reserved_qty")
            .eq("entity_id", entityId)
            .eq("product_id", productId)
            .eq("warehouse_id", warehouseId)
            .eq("batch_id", batchId)
            .order("updated_at", { ascending: false });

          if (layerId) {
            layerQuery = layerQuery.eq("id", layerId);
          }
          if (binId) {
            layerQuery = layerQuery.eq("bin_id", binId);
          }

          const firstAttempt = await layerQuery;
          if (!firstAttempt.error) {
            layerRows = firstAttempt.data ?? [];
          } else if (this.isMissingColumnError(firstAttempt.error)) {
            let minimalLayerQuery = this.client
              .from("batch_stock_layers")
              .select("id, qty")
              .eq("entity_id", entityId)
              .eq("product_id", productId)
              .eq("warehouse_id", warehouseId)
              .eq("batch_id", batchId);

            if (layerId) {
              minimalLayerQuery = minimalLayerQuery.eq("id", layerId);
            }
            if (binId) {
              minimalLayerQuery = minimalLayerQuery.eq("bin_id", binId);
            }

            const secondAttempt = await minimalLayerQuery;
            if (secondAttempt.error) this.handleStorageError(secondAttempt.error);
            layerRows = secondAttempt.data ?? [];
          } else {
            this.handleStorageError(firstAttempt.error);
          }
        }

        const layers = (layerRows ?? []) as Array<{
          id?: string;
          qty?: number | string;
          reserved_qty?: number | string;
        }>;
        if (layers.length === 0) {
          throw new BadRequestException(
            `Missing source stock layer for adjustment batch row (product ${productId})`,
          );
        }

        const totalAvailableQty = layers.reduce((sum, layer) => {
          const currentQty = this.parseNumber(layer.qty, 0);
          const reservedQty = allowReservedConsumption
            ? 0
            : this.parseNumber(layer.reserved_qty, 0);
          return sum + Math.max(0, currentQty - reservedQty);
        }, 0);
        if (totalAvailableQty < qtyToConsume) {
          throw new BadRequestException(
            binId != null
              ? `Insufficient available stock for product ${productId} in selected bin`
              : `Insufficient available stock for product ${productId} in selected warehouse batch layers`,
          );
        }

        let remainingQtyToConsume = qtyToConsume;
        for (const layer of layers) {
          if (remainingQtyToConsume <= 0) {
            break;
          }
          const currentQty = this.parseNumber(layer.qty, 0);
          const reservedQty = allowReservedConsumption
            ? 0
            : this.parseNumber(layer.reserved_qty, 0);
          const availableQty = Math.max(0, currentQty - reservedQty);
          if (availableQty <= 0 || !layer.id) {
            continue;
          }

          const consumeQty = Math.min(availableQty, remainingQtyToConsume);
          await this.updateWithSchemaFallback(
            "batch_stock_layers",
            {
              qty: currentQty - consumeQty,
              updated_at: now,
            },
            (query) => query.eq("id", layer.id).eq("entity_id", entityId),
          );

          remainingQtyToConsume -= consumeQty;
          layerId = layer.id;
        }
        if (remainingQtyToConsume > 0.00001) {
          throw new BadRequestException(
            `Insufficient available stock for product ${productId} in selected warehouse batch layers`,
          );
        }
      } else {
        // Query to check if the layer already exists for the combination
        let layerCheckQuery = this.client
          .from("batch_stock_layers")
          .select("id, qty")
          .eq("entity_id", entityId)
          .eq("product_id", productId)
          .eq("warehouse_id", warehouseId)
          .eq("batch_id", batchId)
          .limit(1);

        if (binId) {
          layerCheckQuery = layerCheckQuery.eq("bin_id", binId);
        }

        const { data: existingLayers, error: layerCheckError } =
          await layerCheckQuery;

        if (layerCheckError) this.handleStorageError(layerCheckError);

        const matchingLayers = (existingLayers ?? []) as Array<{
          id?: string;
          qty?: number | string;
        }>;
        const existingLayer = matchingLayers[0];

        if (existingLayer?.id) {
          const currentQty = this.parseNumber(existingLayer.qty, 0);
          await this.updateWithSchemaFallback(
            "batch_stock_layers",
            {
              qty: currentQty + delta,
              updated_at: now,
            },
            (query) =>
              query.eq("id", existingLayer.id).eq("entity_id", entityId),
          );
          layerId = existingLayer.id;
        } else {
          // If layer doesn't exist, insert it
          const insertPayload = {
            batch_id: batchId,
            product_id: productId,
            entity_id: entityId,
            warehouse_id: warehouseId,
            bin_id: binId,
            vendor_id: null,
            purchase_rate: this.parseNumber(row?.rate, 0),
            mrp: 0,
            qty: delta,
            reserved_qty: 0,
            ref_id: adjustmentId,
            ref_type: "INVENTORY_ADJUSTMENT",
            created_at: now,
            updated_at: now,
          };

          const { data: inserted } = await this.insertWithSchemaFallback(
            "batch_stock_layers",
            insertPayload,
            "id",
          );
          layerId = this.normalizeUuid((inserted as any)?.id);
        }

        let transactionQuery = this.client
        .from("batch_transactions")
        .select("id, qty_in, qty_out")
        .eq("entity_id", entityId)
        .eq("product_id", productId)
        .eq("warehouse_id", warehouseId)
        .eq("batch_id", batchId)
        .eq("trans_type", "ADJUSTMENT")
        .eq("ref_id", adjustmentId)
        .limit(1);

      if (binId) {
        transactionQuery = transactionQuery.eq("bin_id", binId);
      }

      const {
        data: existingTransactions,
        error: transactionReadError,
      } = await transactionQuery;
      if (transactionReadError) {
        if (this.isOptionalBatchTransactionStorageError(transactionReadError)) {
          this.logger.warn(
            `applyBatchLayerQuantityAdjustments adjustment=${adjustmentId} skipped batch_transactions read ∵ optional ledger schema unavailable`,
          );
          continue;
        }
        this.handleStorageError(transactionReadError);
      }

        const existingTransaction = (existingTransactions?.[0] ?? null) as
        | { id?: string; qty_in?: number | string; qty_out?: number | string }
        | null;

      if (existingTransaction?.id) {
        try {
          await this.updateWithSchemaFallback(
            "batch_transactions",
            {
              layer_id: layerId,
              qty_in:
                this.parseNumber(existingTransaction.qty_in, 0) +
                Math.max(0, qIn),
              qty_out:
                this.parseNumber(existingTransaction.qty_out, 0) +
                Math.max(0, qOut),
              rate: this.parseNumber(row?.rate, 0) || null,
              trans_date: transDate,
            },
            (query) =>
              query.eq("id", existingTransaction.id).eq("entity_id", entityId),
          );
        } catch (error) {
          if (this.isOptionalBatchTransactionStorageError(error)) {
            this.logger.warn(
              `applyBatchLayerQuantityAdjustments adjustment=${adjustmentId} skipped batch_transactions update ∵ optional ledger schema unavailable`,
            );
            continue;
          }
          throw error;
        }
      } else {
        try {
          await this.insertWithSchemaFallback("batch_transactions", {
            batch_id: batchId,
            layer_id: layerId,
            product_id: productId,
            entity_id: entityId,
            warehouse_id: warehouseId,
            bin_id: binId,
            trans_type: "ADJUSTMENT",
            ref_id: adjustmentId,
            ref_no: adjustment.reference_number ?? null,
            qty_in: Math.max(0, qIn),
            qty_out: Math.max(0, qOut),
            rate: this.parseNumber(row?.rate, 0) || null,
            trans_date: transDate,
          });
        } catch (error) {
          if (this.isOptionalBatchTransactionStorageError(error)) {
            this.logger.warn(
              `applyBatchLayerQuantityAdjustments adjustment=${adjustmentId} skipped batch_transactions insert ∵ optional ledger schema unavailable`,
            );
            continue;
          }
          throw error;
        }
      }
    }
  }

        private composeBatchStockKey(batchId: string, binId?: string | null) {
    return `${batchId}::${binId ?? ""}`;
  }

  private async resolveBinIdForStockCountBatch(
    entityId: string,
    warehouseId: string,
    rawBinId: unknown,
    rawBinCode: string,
  ) {
    const normalizedBinId = this.normalizeUuid(rawBinId);
    if (normalizedBinId) {
      return normalizedBinId;
    }

    const normalizedBinCode = rawBinCode.trim();
    if (!normalizedBinCode) {
      return null;
    }

    const { data, error } = await this.client
      .from("bin_master")
      .select("id")
      .eq("entity_id", entityId)
      .eq("warehouse_id", warehouseId)
      .ilike("bin_code", normalizedBinCode)
      .limit(1)
      .maybeSingle();

    if (error) {
      this.handleStorageError(error);
    }

    return this.normalizeUuid((data as any)?.id);
  }

  private async resolveOrCreateStockCountBatchMaster(
    entityId: string,
    productId: string,
    rawBatchId: unknown,
    rawBatchNo: string,
  ) {
    const normalizedBatchId = this.normalizeUuid(rawBatchId);
    if (normalizedBatchId) {
      return {
        batchId: normalizedBatchId,
        batchNo: rawBatchNo.trim(),
      };
    }

    const normalizedBatchNo = rawBatchNo.trim();
    if (!normalizedBatchNo) {
      return {
        batchId: null,
        batchNo: normalizedBatchNo,
      };
    }

    const { data: existingBatch, error: existingBatchError } = await this.client
      .from("batch_master")
      .select("id, batch_no")
      .eq("product_id", productId)
      .ilike("batch_no", normalizedBatchNo)
      .limit(1)
      .maybeSingle();

    if (existingBatchError) {
      this.handleStorageError(existingBatchError);
    }

    const existingBatchId = this.normalizeUuid((existingBatch as any)?.id);
    if (existingBatchId) {
      return {
        batchId: existingBatchId,
        batchNo: String((existingBatch as any)?.batch_no ?? normalizedBatchNo)
          .trim(),
      };
    }

    const fallbackDate = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
      .toISOString()
      .split("T")[0];

    const { data: insertedBatch } = await this.insertWithSchemaFallback(
      "batch_master",
      {
        batch_no: normalizedBatchNo,
        product_id: productId,
        expiry_date: fallbackDate,
        unit_pack: null,
        manufacture_batch_number: normalizedBatchNo,
        manufacture_exp: fallbackDate,
        created_by_entity_id: entityId,
        source_type: "INVENTORY_ADJUSTMENT",
      },
      "id, batch_no",
    );

    return {
      batchId: this.normalizeUuid((insertedBatch as any)?.id),
      batchNo: String((insertedBatch as any)?.batch_no ?? normalizedBatchNo)
        .trim(),
    };
  }

  private async loadBatchBinSnapshot(
    entityId: string,
    warehouseId: string,
    productId: string,
  ) {
    const { data: layerRows, error: layerError } = await this.client
      .from("batch_stock_layers")
      .select(
        "batch_id, bin_id, qty, batch_master(batch_no), bin_master(bin_code)",
      )
      .eq("entity_id", entityId)
      .eq("warehouse_id", warehouseId)
      .eq("product_id", productId);

    if (layerError) {
      this.handleStorageError(layerError);
    }

    const { data: binRows, error: binError } = await this.client
      .from("v_bin_wise_stock")
      .select("bin_id, stock_on_hand")
      .eq("entity_id", entityId)
      .eq("warehouse_id", warehouseId)
      .eq("product_id", productId);

    if (binError) {
      this.handleStorageError(binError);
    }

    const activeBinIds = new Set<string>();
    for (const row of binRows ?? []) {
      const binId = this.normalizeUuid((row as any)?.bin_id);
      const stockOnHand = this.parseNumber((row as any)?.stock_on_hand, 0);
      if (binId && Math.abs(stockOnHand) > 0.00001) {
        activeBinIds.add(binId);
      }
    }
      return {
      activeBinIds,
      layers: (layerRows ?? []).map((row: any) => ({
        batchId: this.normalizeUuid(row?.batch_id),
        binId: this.normalizeUuid(row?.bin_id),
        qty: this.parseNumber(row?.qty, 0),
        batchNo: String(row?.batch_master?.batch_no ?? "").trim(),
        binCode: String(row?.bin_master?.bin_code ?? "").trim(),
      })),
    };
  }

  private async normalizeStockCountBatchRows(
    entityId: string,
    warehouseId: string | null,
    productId: string,
    rawBatches: Array<Record<string, unknown>>,
  ) {
    if (!warehouseId) {
      const batchRows = [] as Array<{
        batchId: string | null;
        binId: string | null;
        batchNo: string;
        binCode: string;
        qty: number;
      }>;

      for (const batch of rawBatches) {
        const rawBatchNo = String(
          batch?.batch_no ?? batch?.batchNo ?? "",
        ).trim();
        const resolvedBatch = await this.resolveOrCreateStockCountBatchMaster(
          entityId,
          productId,
          batch?.batch_id ?? batch?.batchId,
          rawBatchNo,
        );

        batchRows.push({
          batchId: resolvedBatch.batchId,
          binId: this.normalizeUuid(batch?.bin_id ?? batch?.binId),
          batchNo: resolvedBatch.batchNo,
          binCode: String(batch?.bin_code ?? batch?.binCode ?? "").trim(),
          qty: this.parseNumber(batch?.qty, 0),
        });
      }

      return {
        hasTrackedBinRows: false,
        batchRows,
        snapshotLayers: [] as Array<{
          batchId: string | null;
          binId: string | null;
          qty: number;
          batchNo: string;
          binCode: string;
        }>,
      };
    }
    const snapshot = await this.loadBatchBinSnapshot(
      entityId,
      warehouseId,
      productId,
    );

    const batchRows = [] as Array<{
      batchId: string | null;
      binId: string | null;
      batchNo: string;
      binCode: string;
      qty: number;
    }>;

    for (const batch of rawBatches) {
      let batchId = this.normalizeUuid(batch?.batch_id ?? batch?.batchId);
      let binId = this.normalizeUuid(batch?.bin_id ?? batch?.binId);
      let batchNo = String(batch?.batch_no ?? batch?.batchNo ?? "").trim();
      let binCode = String(batch?.bin_code ?? batch?.binCode ?? "").trim();

      const candidates = snapshot.layers.filter((layer) => {
        if (!layer.batchId) {
          return false;
        }
        const batchMatches = batchId
          ? layer.batchId === batchId
          : batchNo.length > 0 &&
            layer.batchNo.toLowerCase() === batchNo.toLowerCase();
        if (!batchMatches) {
          return false;
        }
        if (binId) {
          return layer.binId === binId;
        }
        if (binCode.length > 0) {
          return layer.binCode.toLowerCase() === binCode.toLowerCase();
        }
        return true;
      });

      if (candidates.length === 1) {
        const match = candidates[0];
        batchId = batchId ?? match.batchId;
        binId = binId ?? match.binId;
        batchNo = batchNo || match.batchNo;
        binCode = binCode || match.binCode;
      } else if (batchId && !binId) {
        const batchBins = Array.from(
          new Set(
            snapshot.layers
              .filter((layer) => layer.batchId === batchId && layer.binId)
              .map((layer) => layer.binId as string),
          ),
        );
        if (
          batchBins.length === 1 &&
          snapshot.activeBinIds.has(batchBins[0])
        ) {
          binId = batchBins[0];
          const match = snapshot.layers.find(
            (layer) => layer.batchId === batchId && layer.binId === binId,
          );
          if (match) {
            batchNo = batchNo || match.batchNo;
            binCode = binCode || match.binCode;
          }
        }
      }

      if (!binId && warehouseId) {
        binId = await this.resolveBinIdForStockCountBatch(
          entityId,
          warehouseId,
          batch?.bin_id ?? batch?.binId,
          binCode,
        );
      }

      if (!batchId && batchNo.length > 0) {
        const resolvedBatch = await this.resolveOrCreateStockCountBatchMaster(
          entityId,
          productId,
          batch?.batch_id ?? batch?.batchId,
          batchNo,
        );
        batchId = resolvedBatch.batchId;
        batchNo = resolvedBatch.batchNo || batchNo;
      }

      batchRows.push({
        batchId,
        binId,
        batchNo,
        binCode,
        qty: this.parseNumber(batch?.qty, 0),
      });
    }

    return {
      hasTrackedBinRows: batchRows.some((row) => row.binId != null),
      batchRows,
      snapshotLayers: snapshot.layers,
    };
  }

  private normalizeItemRow(
    item: CreateInventoryAdjustmentItemDto,
    adjustmentId: string,
    tenant: TenantContext,
  ) {
    const entityId = this.ensureEntity(tenant);

    return {
      adjustment_id: adjustmentId,
      entity_id: entityId,
      product_id: item.product_id,
      quantity_before: this.parseNumber(item.quantity_before, 0),
      quantity_adjusted: this.parseNumber(item.quantity_adjusted, 0),
      quantity_after: this.parseNumber(item.quantity_after, 0),
      cost_price: this.parseNumber(item.cost_price, 0) || null,
      mrp: this.parseNumber(item.mrp, 0) || null,
      adjustment_value: this.parseNumber(item.adjustment_value, 0),
      batch_id: this.normalizeUuid(item.batch_id),
      batch_reference: item.batch_reference?.trim() || null,
      batch_allocations: Array.isArray(item.batch_allocations)
        ? item.batch_allocations
        : [],
      reporting_tags:
        item.reporting_tags && typeof item.reporting_tags === "object"
          ? item.reporting_tags
          : {},
      mfd_month_year: item.mfd_month_year?.trim() || null,
      expiry_month_year: item.expiry_month_year?.trim() || null,
    };
  }

  private normalizeValueItemRow(
    item: CreateInventoryAdjustmentValueItemDto,
    adjustmentId: string,
    tenant: TenantContext,
  ) {
    const entityId = this.ensureEntity(tenant);

    return {
      adjustment_id: adjustmentId,
      entity_id: entityId,
      product_id: item.product_id,
      batch_id: item.batch_id ?? null,
      batch_stock_layer_id: item.batch_stock_layer_id ?? null,
      current_value: this.parseNumber(item.current_value, 0),
      changed_value: this.parseNumber(item.changed_value, 0),
      adjusted_value: this.parseNumber(item.adjusted_value, 0),
    };
  }

  private normalizeAccountEntryRow(
    entry: CreateInventoryAdjustmentAccountEntryDto,
    adjustmentId: string,
    tenant: TenantContext,
  ) {
    const entityId = this.ensureEntity(tenant);

    return {
      adjustment_id: adjustmentId,
      entity_id: entityId,
      account_id: entry.account_id,
      debit: this.parseNumber(entry.debit, 0),
      credit: this.parseNumber(entry.credit, 0),
      description: entry.description?.trim() || null,
    };
  }

  private normalizeBatchAllocationRows(
    adjustmentId: string,
    adjustmentItemId: string,
    itemProductId: string,
    batchAllocations: unknown,
    fallbackWarehouseId: string | null,
    quantityAdjusted: number,
    tenant: TenantContext,
  ): NormalizedBatchAllocationRow[] {
    const entityId = this.ensureEntity(tenant);
    const rows =
      this.safeArray<CreateInventoryAdjustmentBatchDto>(batchAllocations);

    if (rows.length === 0) {
      return [];
    }

    return rows.map((batch) => {
      const quantityRaw = this.parseNumber(batch.quantity, 0);
      const qIn = this.parseNumber(
        batch.quantity_in,
        quantityRaw > 0 && quantityAdjusted >= 0 ? quantityRaw : 0,
      );
      const qOut = this.parseNumber(
        batch.quantity_out,
        quantityRaw > 0 && quantityAdjusted < 0 ? quantityRaw : 0,
      );

      return {
        adjustment_id: adjustmentId,
        adjustment_item_id: adjustmentItemId,
        entity_id: entityId,
        product_id: (batch.product_id ?? itemProductId)?.toString().trim(),
        warehouse_id: batch.warehouse_id ?? fallbackWarehouseId,
        bin_id: this.normalizeUuid(batch.bin_id ?? batch.bin_location_id),
        batch_id: this.normalizeUuid(batch.batch_id),
        batch_stock_layer_id: this.normalizeUuid(batch.batch_stock_layer_id),
        batch_reference: batch.batch_reference?.trim() || null,
        quantity_in: Math.max(0, qIn),
        quantity_out: Math.max(0, qOut),
        rate: this.parseNumber(batch.rate, 0) || null,
      };
    });
  }

  private async persistAdjustmentDetails(
    adjustmentId: string,
    adjustmentType: string,
    items: CreateInventoryAdjustmentItemDto[],
    valueItems: CreateInventoryAdjustmentValueItemDto[],
    accountEntries: CreateInventoryAdjustmentAccountEntryDto[],
    fallbackProductId: string,
    fallbackWarehouseId: string | null,
    headerNumbers: {
      quantityBefore: number;
      quantityAdjusted: number;
      quantityAfter: number;
      costPrice: number;
      adjustmentValue: number;
    },
    tenant: TenantContext,
  ) {
    const entityId = this.ensureEntity(tenant);

    const preparedItems: CreateInventoryAdjustmentItemDto[] =
      items.length > 0
        ? items.filter((row) => row?.product_id?.trim())
        : [
            {
              product_id: fallbackProductId,
              quantity_before: headerNumbers.quantityBefore,
              quantity_adjusted: headerNumbers.quantityAdjusted,
              quantity_after: headerNumbers.quantityAfter,
              cost_price: headerNumbers.costPrice,
              adjustment_value: headerNumbers.adjustmentValue,
              batch_allocations: [],
            },
          ];

    const normalizedItems = preparedItems.map((row) =>
      this.normalizeItemRow(row, adjustmentId, tenant),
    );

    let insertedItems: Array<Record<string, unknown>> = [];

    if (normalizedItems.length > 0) {
      const { data: inserted, error: itemsInsertError } = await this.client
        .from("inventory_adjustment_items")
        .insert(normalizedItems)
        .select("id, product_id, quantity_adjusted, batch_allocations");

      if (itemsInsertError) {
        this.handleStorageError(itemsInsertError);
      }
      insertedItems = inserted ?? [];
    }

    const batchRows = insertedItems.flatMap((itemRow, idx) => {
      const originalItem = preparedItems[idx];
      return this.normalizeBatchAllocationRows(
        adjustmentId,
        String(itemRow.id),
        String(itemRow.product_id),
        itemRow.batch_allocations ?? originalItem.batch_allocations,
        fallbackWarehouseId,
        this.parseNumber(itemRow.quantity_adjusted, 0),
        tenant,
      );
    });
    this.logger.log(
      `persistAdjustmentDetails adjustment=${adjustmentId} normalizedBatchRows=${batchRows.length}`,
    );

    if (batchRows.length > 0) {
      const { error: batchInsertError } = await this.client
        .from("inventory_adjustment_item_batches")
        .insert(batchRows);

      if (batchInsertError) {
        this.handleStorageError(batchInsertError);
      }
      this.logger.log(
        `persistAdjustmentDetails adjustment=${adjustmentId} inserted batch rows successfully`,
      );
    }

    const preparedValueItems =
      valueItems.length > 0
        ? valueItems.filter((row) => row?.product_id?.trim())
        : adjustmentType === "value"
          ? preparedItems
              .filter((row) => row?.product_id?.trim())
              .map((row) => ({
                product_id: row.product_id,
                changed_value: this.parseNumber(row.cost_price, 0),
                adjusted_value: this.parseNumber(row.adjustment_value, 0),
                current_value: 0,
                batch_id: row.batch_id ?? null,
              }))
          : [];

    if (preparedValueItems.length > 0) {
      const normalizedValueRows = preparedValueItems.map((row) =>
        this.normalizeValueItemRow(row, adjustmentId, tenant),
      );

      const { error: valueInsertError } = await this.client
        .from("inventory_adjustment_value_items")
        .insert(normalizedValueRows);

      if (valueInsertError) {
        this.handleStorageError(valueInsertError);
      }
    }

    const preparedEntries = accountEntries.filter((row) =>
      row?.account_id?.trim(),
    );
    if (preparedEntries.length > 0) {
      const normalizedAccountEntries = preparedEntries.map((entry) =>
        this.normalizeAccountEntryRow(entry, adjustmentId, tenant),
      );

      const { error: accountInsertError } = await this.client
        .from("inventory_adjustment_account_entries")
        .insert(normalizedAccountEntries);

      if (accountInsertError) {
        this.handleStorageError(accountInsertError);
      }
    }

    if (adjustmentType === "value" && preparedValueItems.length === 0) {
      const { error: fallbackValueError } = await this.client
        .from("inventory_adjustment_value_items")
        .insert({
          adjustment_id: adjustmentId,
          entity_id: entityId,
          product_id: fallbackProductId,
          current_value: 0,
          changed_value: headerNumbers.costPrice,
          adjusted_value: headerNumbers.adjustmentValue,
        });

      if (fallbackValueError) {
        this.handleStorageError(fallbackValueError);
      }
    }
  }

  async findAll(tenant: TenantContext, query: ListInventoryAdjustmentsQuery) {
    const entityId = this.ensureEntity(tenant);
    const page = Math.max(1, parseInt(query.page ?? "1", 10) || 1);
    const limit = Math.max(
      1,
      Math.min(200, parseInt(query.limit ?? "100", 10) || 100),
    );
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    let req = this.client
      .from("inventory_adjustments")
      .select(
        "*, products:products(id, product_name, item_code), warehouses:warehouses(id, name), reasons:inventory_adjustment_reasons(id, name)",
        { count: "exact" },
      )
      .eq("entity_id", entityId)
      .order("adjustment_date", { ascending: false })
      .order("created_at", { ascending: false });

    if (query.status?.trim()) {
      req = req.eq("status", query.status.trim().toLowerCase());
    }
    if (query.adjustment_type?.trim()) {
      req = req.eq(
        "adjustment_type",
        query.adjustment_type.trim().toLowerCase(),
      );
    }
    if (query.search?.trim()) {
      const search = query.search.trim();
      req = req.or(
        `reason.ilike.%${search}%,reference_number.ilike.%${search}%,notes.ilike.%${search}%`,
      );
    }
    if (query.date_from?.trim()) {
      req = req.gte("adjustment_date", query.date_from.trim());
    }
    if (query.date_to?.trim()) {
      req = req.lte("adjustment_date", query.date_to.trim());
    }
    if (query.product_id?.trim()) {
      const productId = query.product_id.trim();
      const matchingAdjustmentIds = new Set<string>();

      const { data: headerRows, error: headerRowsError } = await this.client
        .from("inventory_adjustments")
        .select("id")
        .eq("entity_id", entityId)
        .eq("product_id", productId);
      if (headerRowsError) {
        this.handleStorageError(headerRowsError);
      }
      for (const row of headerRows ?? []) {
        const id = String((row as any)?.id ?? "").trim();
        if (id) matchingAdjustmentIds.add(id);
      }

      const { data: itemRows, error: itemRowsError } = await this.client
        .from("inventory_adjustment_items")
        .select("adjustment_id")
        .eq("entity_id", entityId)
        .eq("product_id", productId);
      if (itemRowsError) {
        this.handleStorageError(itemRowsError);
      }
      for (const row of itemRows ?? []) {
        const id = String((row as any)?.adjustment_id ?? "").trim();
        if (id) matchingAdjustmentIds.add(id);
      }

      const idFilter = Array.from(matchingAdjustmentIds);
      if (idFilter.length === 0) {
        return {
          data: [],
          total: 0,
          page,
          limit,
        };
      }
      req = req.in("id", idFilter);
    }

    const { data, count, error } = await req.range(from, to);
    if (error) {
      this.handleStorageError(error);
    }

    const items = (data ?? []).map((row: any) => ({
      ...row,
      reason: row.reason ?? row.reasons?.name ?? null,
      reason_name: row.reasons?.name ?? row.reason ?? null,
      product_name: row.products?.product_name ?? null,
      product_code: row.products?.item_code ?? null,
      warehouse_name: row.warehouses?.name ?? null,
    }));
    const userIdentityMap = await this.buildUserIdentityMap(
      tenant,
      items.flatMap((row: any) => [row?.adjusted_by, row?.approved_by]),
    );
    const hydratedItems = items.map((row: any) => ({
      ...row,
      adjusted_by_name:
        userIdentityMap.get(String(row.adjusted_by ?? "").trim())?.name ?? null,
      adjusted_by_email:
        userIdentityMap.get(String(row.adjusted_by ?? "").trim())?.email ??
        null,
      approved_by_name:
        userIdentityMap.get(String(row.approved_by ?? "").trim())?.name ??
        (String(row.status ?? "").toLowerCase() === "approved"
          ? (userIdentityMap.get(String(row.adjusted_by ?? "").trim())?.name ??
            null)
          : null),
      approved_by_email:
        userIdentityMap.get(String(row.approved_by ?? "").trim())?.email ??
        (String(row.status ?? "").toLowerCase() === "approved"
          ? (userIdentityMap.get(String(row.adjusted_by ?? "").trim())?.email ??
            null)
          : null),
    }));

    return {
      data: hydratedItems,
      total: count ?? hydratedItems.length,
      page,
      limit,
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);

    const { data, error } = await this.client
      .from("inventory_adjustments")
      .select(
        "*, products:products(id, product_name, item_code), warehouses:warehouses(id, name), reasons:inventory_adjustment_reasons(id, name), accounts:accounts(id, user_account_name, system_account_name)",
      )
      .eq("id", id)
      .eq("entity_id", entityId)
      .maybeSingle();

    if (error) {
      this.handleStorageError(error);
    }
    if (!data) {
      throw new NotFoundException("Inventory adjustment not found");
    }

    const { data: items, error: itemsError } = await this.client
      .from("inventory_adjustment_items")
      .select("*")
      .eq("adjustment_id", id)
      .eq("entity_id", entityId)
      .order("created_at", { ascending: true });

    if (itemsError) {
      this.handleStorageError(itemsError);
    }

    const { data: valueItems, error: valueItemsError } = await this.client
      .from("inventory_adjustment_value_items")
      .select("*")
      .eq("adjustment_id", id)
      .eq("entity_id", entityId)
      .order("created_at", { ascending: true });

    const safeValueItemsError = valueItemsError;
    const safeValueItems =
      safeValueItemsError && this.isMissingTableError(safeValueItemsError)
        ? []
        : valueItems;
    if (safeValueItemsError) {
      if (this.isMissingTableError(safeValueItemsError)) {
        this.logger.warn(
          `findOne adjustment=${id} skipped inventory_adjustment_value_items ∵ table missing`,
        );
      } else {
        this.handleStorageError(safeValueItemsError);
      }
    }

    const { data: accountEntries, error: accountEntriesError } =
      await this.client
        .from("inventory_adjustment_account_entries")
        .select(
          "*, accounts:accounts(id, user_account_name, system_account_name)",
        )
        .eq("adjustment_id", id)
        .eq("entity_id", entityId)
        .order("created_at", { ascending: true });

    const safeAccountEntriesError = accountEntriesError;
    const safeAccountEntries =
      safeAccountEntriesError && this.isMissingTableError(safeAccountEntriesError)
        ? []
        : accountEntries;
    if (safeAccountEntriesError) {
      if (this.isMissingTableError(safeAccountEntriesError)) {
        this.logger.warn(
          `findOne adjustment=${id} skipped inventory_adjustment_account_entries ∵ table missing`,
        );
      } else {
        this.handleStorageError(safeAccountEntriesError);
      }
    }

    const { data: itemBatches, error: itemBatchesError } = await this.client
      .from("inventory_adjustment_item_batches")
      .select("*")
      .eq("adjustment_id", id)
      .eq("entity_id", entityId)
      .order("created_at", { ascending: true });

    const safeItemBatchesError = itemBatchesError;
    const safeItemBatches =
      safeItemBatchesError && this.isMissingTableError(safeItemBatchesError)
        ? []
        : itemBatches;
    if (safeItemBatchesError) {
      if (this.isMissingTableError(safeItemBatchesError)) {
        this.logger.warn(
          `findOne adjustment=${id} skipped inventory_adjustment_item_batches ∵ table missing`,
        );
      } else {
        this.handleStorageError(safeItemBatchesError);
      }
    }
     const rawItemBatches = safeItemBatches ?? [];
    const batchIdsForHydration = rawItemBatches
      .map((row: any) => String(row?.batch_id ?? "").trim())
      .filter((id: string) => id.length > 0);
    const binIdsForHydration = rawItemBatches
      .map((row: any) => String(row?.bin_id ?? "").trim())
      .filter((id: string) => id.length > 0);

    const batchMasterById = new Map<string, any>();
    if (batchIdsForHydration.length > 0) {
      const { data: batchMasterRows, error: batchMasterError } =
        await this.client
          .from("batch_master")
          .select(
            "id, batch_no, unit_pack, expiry_date, manufacture_exp, manufacture_batch_number",
          )
          .in("id", batchIdsForHydration);
      if (batchMasterError) {
        this.handleStorageError(batchMasterError);
      }
      for (const row of batchMasterRows ?? []) {
        const id = String((row as any).id ?? "").trim();
        if (id) batchMasterById.set(id, row);
      }
    }

    const layerAggByBatchId = new Map<string, { mrp: number | null }>();
    if (batchIdsForHydration.length > 0) {
      const { data: layerRows, error: layerError } = await this.client
        .from("batch_stock_layers")
        .select("batch_id, mrp, purchase_rate")
        .eq("entity_id", entityId)
        .in("batch_id", batchIdsForHydration);
      if (layerError) {
        this.handleStorageError(layerError);
      }
      for (const layer of layerRows ?? []) {
        const batchId = String((layer as any).batch_id ?? "").trim();
        if (!batchId) continue;
        const mrp = this.parseNumber((layer as any).mrp, 0);
        const existing = layerAggByBatchId.get(batchId) ?? { mrp: null };
        if (existing.mrp == null && mrp > 0) existing.mrp = mrp;
        layerAggByBatchId.set(batchId, existing);
      }
    }

    const binCodeById = new Map<string, string>();
    if (binIdsForHydration.length > 0) {
      const { data: binRows, error: binRowsError } = await this.client
        .from("bin_master")
        .select("id, bin_code")
        .in("id", binIdsForHydration);
      if (binRowsError) {
        this.handleStorageError(binRowsError);
      }
      for (const row of binRows ?? []) {
        const id = String((row as any).id ?? "").trim();
        const code = String((row as any).bin_code ?? "").trim();
        if (id && code) {
          binCodeById.set(id, code);
        }
      }
    }

    const enrichedItemBatches = rawItemBatches.map((row: any) => {
      const batchId = String(row?.batch_id ?? "").trim();
      const binId = String(row?.bin_id ?? "").trim();
      const master = batchId ? batchMasterById.get(batchId) : null;
      const layerAgg = batchId ? layerAggByBatchId.get(batchId) : null;
      return {
        ...row,
        batch_no: master?.batch_no ?? null,
        manufacture_batch_number: master?.manufacture_batch_number ?? null,
        unit_pack: master?.unit_pack ?? null,
        expiry_date: master?.expiry_date ?? null,
        manufacture_exp: master?.manufacture_exp ?? null,
        mfd_date: master?.manufacture_exp ?? null,
        mrp: layerAgg?.mrp ?? null,
        bin_code: binId ? (binCodeById.get(binId) ?? null) : null,
      };
    });

    const userIdentityMap = await this.buildUserIdentityMap(tenant, [
      data.adjusted_by,
      data.approved_by,
    ]);
    const adjustedIdentity =
      userIdentityMap.get(String(data.adjusted_by ?? "").trim()) ?? null;
    const approvedIdentity =
      userIdentityMap.get(String(data.approved_by ?? "").trim()) ?? null;
    const status = String(data.status ?? "").toLowerCase();

    const batchesByItemId = new Map<string, any[]>();
    const batchesByProductId = new Map<string, any[]>();
    for (const batch of enrichedItemBatches) {
      const row = batch as any;
      const itemId = String(
        row.adjustment_item_id ??
          row.item_id ??
          row.inventory_adjustment_item_id ??
          "",
      ).trim();
      const productId = String(row.product_id ?? "").trim();

      if (itemId) {
        const existing = batchesByItemId.get(itemId) ?? [];
        existing.push(batch);
        batchesByItemId.set(itemId, existing);
      }

      if (productId) {
        const existingByProduct = batchesByProductId.get(productId) ?? [];
        existingByProduct.push(batch);
        batchesByProductId.set(productId, existingByProduct);
      }
    }

    const itemRows = items ?? [];
    const itemProductIds = Array.from(
      new Set(
        itemRows
          .map((row: any) => String(row?.product_id ?? "").trim())
          .filter((productId) => productId.length > 0),
      ),
    );
    const productNameById = new Map<string, string>();
    if (itemProductIds.length > 0) {
      const { data: itemProducts, error: itemProductsError } = await this.client
        .from("products")
        .select("id, product_name")
        .in("id", itemProductIds);
      if (itemProductsError) {
        this.handleStorageError(itemProductsError);
      }
      for (const product of itemProducts ?? []) {
        const productId = String((product as any).id ?? "").trim();
        const productName = String((product as any).product_name ?? "").trim();
        if (productId && productName) {
          productNameById.set(productId, productName);
        }
      }
    }
    const productCounts = new Map<string, number>();
    for (const item of itemRows) {
      const productId = String((item as any).product_id ?? "").trim();
      if (!productId) continue;
      productCounts.set(productId, (productCounts.get(productId) ?? 0) + 1);
    }

    const hydratedItems = itemRows.map((item: any) => {
      const itemId = String(item.id ?? "").trim();
      const productId = String(item.product_id ?? "").trim();
      const direct = batchesByItemId.get(itemId) ?? [];
      if (direct.length > 0) {
        return {
          ...item,
          product_name: productNameById.get(productId) ?? null,
          batch_allocations: direct,
        };
      }

      // Backward-compatible fallback for legacy rows that missed item linkage:
      // only attach product-level batches when a product appears once in this adjustment.
      if (productId.length > 0 && (productCounts.get(productId) ?? 0) === 1) {
        return {
          ...item,
          product_name: productNameById.get(productId) ?? null,
          batch_allocations: batchesByProductId.get(productId) ?? [],
        };
      }

      return {
        ...item,
        product_name: productNameById.get(productId) ?? null,
        batch_allocations: [],
      };
    });
    const hydratedBatchCount = hydratedItems.reduce(
      (sum, item: any) =>
        sum +
        (Array.isArray(item.batch_allocations)
          ? item.batch_allocations.length
          : 0),
      0,
    );
    this.logger.log(
      `findOne adjustment=${id} items=${itemRows.length} rawBatchRows=${(itemBatches ?? []).length} hydratedBatchRows=${hydratedBatchCount}`,
    );

    return {
      ...data,
      reason: data.reason ?? data.reasons?.name ?? null,
      reason_name: data.reasons?.name ?? data.reason ?? null,
      product_name: data.products?.product_name ?? null,
      product_code: data.products?.item_code ?? null,
      warehouse_name: data.warehouses?.name ?? null,
      adjusted_by_name: adjustedIdentity?.name ?? null,
      adjusted_by_email: adjustedIdentity?.email ?? null,
      account_name:
        (data as any).accounts?.user_account_name ??
        (data as any).accounts?.system_account_name ??
        null,
      approved_by_name:
        approvedIdentity?.name ??
        (status === "approved" ? (adjustedIdentity?.name ?? null) : null),
      approved_by_email:
        approvedIdentity?.email ??
        (status === "approved" ? (adjustedIdentity?.email ?? null) : null),
      items: hydratedItems,
      value_items: safeValueItems ?? [],
      account_entries: (safeAccountEntries ?? []).map((entry: any) => ({
        ...entry,
        account_name:
          entry?.accounts?.user_account_name ??
          entry?.accounts?.system_account_name ??
          null,
      })),
    };
  }

  async getBatchSuggestions(
    productId: string,
    query: string,
    entityId: string,
  ) {
    const { data: batches, error } = await this.client
      .from("batch_master")
      .select("id, batch_no, expiry_date, manufacture_exp, unit_pack")
      .eq("product_id", productId)
      .eq("is_active", true)
      .ilike("batch_no", `%${query}%`)
      .limit(20);
    if (error) this.handleStorageError(error);
    const batchRows = batches ?? [];
    const batchIds = batchRows
      .map((row: any) => row?.id?.toString().trim())
      .filter((id: string) => id.length > 0);

    const aggregatesByBatchId = new Map<
      string,
      { quantity_available: number; mrp: number | null }
    >();
    if (batchIds.length > 0) {
      const { data: layerRows, error: layerError } = await this.client
        .from("batch_stock_layers")
        .select("batch_id, qty, reserved_qty, mrp, purchase_rate")
        .eq("entity_id", entityId)
        .in("batch_id", batchIds);
      if (layerError) this.handleStorageError(layerError);

      for (const layer of layerRows ?? []) {
        const batchId = String((layer as any).batch_id ?? "").trim();
        if (!batchId) continue;
        const qty = this.parseNumber((layer as any).qty, 0);
        const reservedQty = this.parseNumber((layer as any).reserved_qty, 0);
        const available = qty - reservedQty;
        const mrp = this.parseNumber((layer as any).mrp, 0);
        const current = aggregatesByBatchId.get(batchId) ?? {
          quantity_available: 0,
          mrp: null,
        };
        current.quantity_available += available;
        if (current.mrp == null && mrp > 0) current.mrp = mrp;
        aggregatesByBatchId.set(batchId, current);
      }
    }

    return batchRows.map((row: any) => {
      const id = String(row?.id ?? "").trim();
      const agg = aggregatesByBatchId.get(id);
      return {
        id,
        batch_no: row?.batch_no ?? null,
        batch_reference: row?.batch_no ?? null,
        expiry_date: row?.expiry_date ?? null,
        manufacture_exp: row?.manufacture_exp ?? null,
        mfd_date: row?.manufacture_exp ?? null,
        unit_pack: row?.unit_pack ?? null,
        quantity_available: agg?.quantity_available ?? 0,
        mrp: agg?.mrp,
      };
    });
  }

  async getBinMaster(warehouseId: string, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    const { data, error } = await this.client
      .from("bin_master")
      .select("id, bin_code")
      .eq("entity_id", entityId)
      .eq("warehouse_id", warehouseId)
      .eq("is_active", true)
      .order("bin_code", { ascending: true });
    if (error) this.handleStorageError(error);
    return (data ?? []).map((r: any) => ({
      id: r.id,
      bin_code: r.bin_code,
    }));
  }

  private mapReasonRow(row: any): InventoryAdjustmentReasonRow {
    return {
      id: String(row?.id ?? "").trim(),
      entity_id: row?.entity_id ?? null,
      name: String(row?.name ?? "").trim(),
      code: row?.code ?? null,
      is_active: row?.is_active === true,
      sort_order: Number(row?.sort_order ?? 0) || 0,
      created_at: row?.created_at ?? null,
      updated_at: row?.updated_at ?? null,
    };
  }

  private toReasonCodeBase(value: string) {
    return value
      .trim()
      .toUpperCase()
      .replace(/[^A-Z0-9]+/g, "_")
      .replace(/^_+|_+$/g, "")
      .slice(0, 60);
  }

  private async resolveUniqueReasonCode(
    entityId: string,
    preferredCode: string | null,
    reasonName: string,
  ) {
    const preferred = String(preferredCode ?? "").trim();
    const seed = preferred.length > 0 ? preferred : this.toReasonCodeBase(reasonName);
    const baseCode = seed.length > 0 ? seed : "REASON";

    const { data, error } = await this.client
      .from("inventory_adjustment_reasons")
      .select("code")
      .eq("entity_id", entityId);

    if (error) {
      this.handleStorageError(error);
    }

    const used = new Set(
      (data ?? [])
        .map((row: any) => String(row?.code ?? "").trim().toUpperCase())
        .filter((code) => code.length > 0),
    );

    if (!used.has(baseCode)) {
      return baseCode;
    }

    let suffix = 2;
    while (suffix <= 9999) {
      const candidate = `${baseCode}_${suffix}`.slice(0, 60);
      if (!used.has(candidate)) {
        return candidate;
      }
      suffix += 1;
    }

    return `${baseCode}_${Date.now()}`.slice(0, 60);
  }

  async getReasons(tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    const { data, error } = await this.client
      .from("inventory_adjustment_reasons")
      .select("*")
      .or(`entity_id.eq.${entityId},entity_id.is.null`)
      .order("sort_order", { ascending: true })
      .order("name", { ascending: true });

    if (error) {
      this.handleStorageError(error);
    }

    const mapped = (data ?? []).map((row: any) => this.mapReasonRow(row));
    // De-duplicate by reason name, preferring tenant-specific over global.
    const byName = new Map<string, InventoryAdjustmentReasonRow>();
    for (const row of mapped) {
      const key = row.name.trim().toLowerCase();
      const existing = byName.get(key);
      if (!existing) {
        byName.set(key, row);
        continue;
      }
      if (existing.entity_id == null && row.entity_id != null) {
        byName.set(key, row);
      }
    }
    return Array.from(byName.values())
      .sort((a, b) => a.sort_order - b.sort_order || a.name.localeCompare(b.name));
  }

  async createReason(
    tenant: TenantContext,
    dto: InventoryAdjustmentReasonDto,
  ) {
    const entityId = this.ensureEntity(tenant);
    const name = String(dto.name ?? "").trim();
    if (!name) {
      throw new BadRequestException("name is required");
    }

    const normalizedName = name.toLowerCase();
    const { data: existingRows, error: existingRowsError } = await this.client
      .from("inventory_adjustment_reasons")
      .select("id, entity_id, name")
      .or(`entity_id.eq.${entityId},entity_id.is.null`);

    if (existingRowsError) {
      this.handleStorageError(existingRowsError);
    }

    const hasNameConflict = (existingRows ?? []).some((row: any) => {
      const existingName = String(row?.name ?? "").trim().toLowerCase();
      return existingName.length > 0 && existingName === normalizedName;
    });
    if (hasNameConflict) {
      throw new BadRequestException(
        "Reason already exists in global defaults or this entity",
      );
    }

    const { data: maxRows, error: maxError } = await this.client
      .from("inventory_adjustment_reasons")
      .select("sort_order")
      .eq("entity_id", entityId)
      .order("sort_order", { ascending: false })
      .limit(1);
    if (maxError) {
      this.handleStorageError(maxError);
    }

    const nextSortOrder = Number(maxRows?.[0]?.sort_order ?? 0) + 1;
    const generatedCode = await this.resolveUniqueReasonCode(
      entityId,
      String(dto.code ?? "").trim() || null,
      name,
    );

    const payload = {
      entity_id: entityId,
      name,
      code: generatedCode,
      is_active: dto.is_active ?? true,
      sort_order: Number.isFinite(Number(dto.sort_order))
        ? Number(dto.sort_order)
        : nextSortOrder,
    };

    const { data, error } = await this.client
      .from("inventory_adjustment_reasons")
      .insert(payload)
      .select("*")
      .single();

    if (error) {
      this.handleStorageError(error);
    }

    return this.mapReasonRow(data);
  }

  async updateReason(
    id: string,
    tenant: TenantContext,
    dto: Partial<InventoryAdjustmentReasonDto>,
  ) {
    const entityId = this.ensureEntity(tenant);
    const { data: existingReason, error: existingReasonError } = await this.client
      .from("inventory_adjustment_reasons")
      .select("id, entity_id")
      .eq("id", id)
      .maybeSingle();

    if (existingReasonError) {
      this.handleStorageError(existingReasonError);
    }
    if (!existingReason) {
      throw new NotFoundException("Inventory adjustment reason not found");
    }
    if (existingReason.entity_id == null) {
      throw new BadRequestException("Global default reasons cannot be modified");
    }
    if (String(existingReason.entity_id) !== entityId) {
      throw new NotFoundException("Inventory adjustment reason not found");
    }

    const updates: Record<string, unknown> = {};

    if (dto.name !== undefined) {
      const name = String(dto.name ?? "").trim();
      if (!name) {
        throw new BadRequestException("name is required");
      }
      updates.name = name;
    }
    if (dto.code !== undefined) {
      updates.code = String(dto.code ?? "").trim() || null;
    }
    if (dto.is_active !== undefined) {
      updates.is_active = dto.is_active === true;
    }
    if (dto.sort_order !== undefined) {
      updates.sort_order = Number(dto.sort_order) || 0;
    }

    if (Object.keys(updates).length === 0) {
      throw new BadRequestException("No reason fields were provided");
    }

    const { data, error } = await this.client
      .from("inventory_adjustment_reasons")
      .update(updates)
      .eq("id", id)
      .select("*")
      .maybeSingle();

    if (error) {
      this.handleStorageError(error);
    }
    if (!data) {
      throw new NotFoundException("Inventory adjustment reason not found");
    }

    return this.mapReasonRow(data);
  }

  async deleteReason(id: string, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    const { data: existingReason, error: existingReasonError } = await this.client
      .from("inventory_adjustment_reasons")
      .select("id, entity_id")
      .eq("id", id)
      .maybeSingle();

    if (existingReasonError) {
      this.handleStorageError(existingReasonError);
    }
    if (!existingReason) {
      throw new NotFoundException("Inventory adjustment reason not found");
    }
    if (existingReason.entity_id == null) {
      throw new BadRequestException("Global default reasons cannot be deleted");
    }
    if (String(existingReason.entity_id) !== entityId) {
      throw new NotFoundException("Inventory adjustment reason not found");
    }

    const { error } = await this.client
      .from("inventory_adjustment_reasons")
      .delete()
      .eq("id", id)
      .eq("entity_id", entityId);

    if (error) {
      this.handleStorageError(error);
    }

    return { ok: true };
  }

  async create(createDto: CreateInventoryAdjustmentDto, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);

    if (!createDto.product_id?.trim()) {
      throw new BadRequestException("product_id is required");
    }

    const existing = await this.getCurrentStock(
      createDto.product_id,
      tenant,
      createDto.warehouse_id ?? null,
    );
    const quantityBefore = this.parseNumber(
      createDto.quantity_before,
      existing.currentStock,
    );
    const quantityAdjusted = this.parseNumber(createDto.quantity_adjusted, 0);
    const quantityAfter = this.parseNumber(
      createDto.quantity_after,
      quantityBefore + quantityAdjusted,
    );
    const status = this.normalizeStatus(createDto.status);
    const persistedStatus = status === "approved" ? "submitted" : status;
    const adjustmentType = this.normalizeType(createDto.adjustment_type);
    const resolvedAccountId =
      this.normalizeUuid(createDto.account_id) ??
      (await this.resolveInventoryAccountIdForProduct(createDto.product_id));

    const payload = {
      entity_id: entityId,
      product_id: createDto.product_id,
      warehouse_id: createDto.warehouse_id ?? null,
      adjustment_date: createDto.adjustment_date ?? new Date().toISOString(),
      adjustment_type: adjustmentType,
      reason_id: createDto.reason_id ?? null,
      reason: (createDto.reason ?? "Stock correction").trim(),
      quantity_before: quantityBefore,
      quantity_adjusted: quantityAdjusted,
      quantity_after: quantityAfter,
      cost_price: this.parseNumber(createDto.cost_price, 0) || null,
      adjustment_value: this.parseNumber(createDto.adjustment_value, 0),
      account_id: resolvedAccountId,
      reference_number: createDto.reference_number?.trim() || null,
      notes: createDto.notes?.trim() || null,
      status: persistedStatus,
      adjusted_by: tenant.userId ?? null,
    };

    const { data, error } = await this.client
      .from("inventory_adjustments")
      .insert(payload)
      .select("*")
      .single();

    if (error) {
      this.handleStorageError(error);
    }

    await this.persistAdjustmentDetails(
      data.id,
      adjustmentType,
      this.safeArray<CreateInventoryAdjustmentItemDto>(createDto.items),
      this.safeArray<CreateInventoryAdjustmentValueItemDto>(
        createDto.value_items,
      ),
      this.safeArray<CreateInventoryAdjustmentAccountEntryDto>(
        createDto.account_entries,
      ),
      createDto.product_id,
      createDto.warehouse_id ?? null,
      {
        quantityBefore,
        quantityAdjusted,
        quantityAfter,
        costPrice: this.parseNumber(createDto.cost_price, 0),
        adjustmentValue: this.parseNumber(createDto.adjustment_value, 0),
      },
      tenant,
    );

    if (status === "approved") {
      await this.approve(data.id, tenant, {
        allowReservedConsumption: createDto.allow_reserved_consumption === true,
      });
    }

    try {
      return await this.findOne(data.id, tenant);
    } catch (error) {
      if (!this.isMissingTableError(error)) {
        throw error;
      }
      this.logger.warn(
        `Adjustment ${data.id} created but detail hydration skipped ∵ optional table missing`,
      );
      return this.buildFallbackAdjustmentResponse(data as Record<string, unknown>, [
        ...this.safeArray<CreateInventoryAdjustmentItemDto>(createDto.items),
      ]);
    }
  }

  async approveStockCount(
    stockCountId: string,
    approvalDto: ApproveStockCountDto,
    tenant: TenantContext,
  ) {
    const entityId = this.ensureEntity(tenant);
    const normalizedStockCountId = this.normalizeUuid(stockCountId);
    if (!normalizedStockCountId) {
      throw new BadRequestException("Invalid stock count id");
    }

    const { data: stockCount, error: stockCountError } = await this.client
      .from("inventory_stock_count")
      .select(
        "id, entity_id, stock_count_number, description, warehouse_id, status",
      )
      .eq("id", normalizedStockCountId)
      .eq("entity_id", entityId)
      .maybeSingle();

    if (stockCountError) {
      this.handleStorageError(stockCountError);
    }
    if (!stockCount) {
      throw new NotFoundException("Stock count not found");
    }

    const currentStatus = String((stockCount as any).status ?? "")
      .trim()
      .toLowerCase();
    if (currentStatus === "cancelled" || currentStatus === "expired") {
      throw new BadRequestException(
        `Stock count cannot be approved from status: ${(
          stockCount as any
        ).status}`,
      );
    }

    const normalizedWarehouseId =
      this.normalizeUuid(approvalDto.warehouse_id) ??
      this.normalizeUuid((stockCount as any).warehouse_id);
    const stockCountNumber = String(
      (stockCount as any).stock_count_number ?? normalizedStockCountId,
    ).trim();

    const adjustmentItems: Array<
      CreateInventoryAdjustmentItemDto & {
        adjustment_reason: string;
        product_name: string | null;
      }
    > = [];
    for (const item of this.safeArray<ApproveStockCountItemDto>(
      approvalDto.items,
    )) {
      const productId = String(item?.product_id ?? "").trim();
      if (!productId) continue;

      const decision = String(item?.decision ?? "Approve")
        .trim()
        .toLowerCase();
      if (decision === "reject") continue;

      const systemQty = this.parseNumber(item?.system_qty, 0);
      const countedQty = this.parseNumber(item?.counted_qty, systemQty);
      const quantityAdjusted = countedQty - systemQty;
      if (Math.abs(quantityAdjusted) <= 0.00001) {
        continue;
      }

      const normalizedBatchRows = await this.normalizeStockCountBatchRows(
        entityId,
        normalizedWarehouseId,
        productId,
        this.safeArray<Record<string, unknown>>(item.batches),
      );

      const countedQtyByBatchKey = new Map<string, number>();
      const batchReferenceByKey = new Map<string, string | null>();
      const batchIdByKey = new Map<string, string>();
      const binIdByKey = new Map<string, string | null>();
      for (const batch of normalizedBatchRows.batchRows) {
        const batchId = batch.batchId;
        if (!batchId) continue;
        const binId = batch.binId;
        const batchKey = this.composeBatchStockKey(batchId, binId);
        const qty = this.parseNumber(batch.qty, 0);
        const batchNo = batch.batchNo.trim();
        countedQtyByBatchKey.set(
          batchKey,
          this.parseNumber(countedQtyByBatchKey.get(batchKey), 0) + qty,
        );
        batchReferenceByKey.set(batchKey, batchNo || null);
        batchIdByKey.set(batchKey, batchId);
        binIdByKey.set(batchKey, binId);
      }

      const currentQtyByBatchKey = new Map<string, number>();
      if (normalizedWarehouseId) {
        for (const row of normalizedBatchRows.snapshotLayers) {
          const batchId = row.batchId;
          if (!batchId) continue;
          const binId = normalizedBatchRows.hasTrackedBinRows ? row.binId : null;
          const batchKey = this.composeBatchStockKey(batchId, binId);
          const physicalQty = this.parseNumber(row.qty, 0);
          currentQtyByBatchKey.set(
            batchKey,
            this.parseNumber(currentQtyByBatchKey.get(batchKey), 0) +
              physicalQty,
          );
          batchIdByKey.set(batchKey, batchId);
          binIdByKey.set(batchKey, binId);
        }
      }

      const batchAllocations: CreateInventoryAdjustmentBatchDto[] = [];
      const allBatchKeys = new Set<string>([
        ...currentQtyByBatchKey.keys(),
        ...countedQtyByBatchKey.keys(),
      ]);

      for (const batchKey of allBatchKeys) {
        const batchId = batchIdByKey.get(batchKey);
        if (batchId == null) {
          continue;
        }
        const binId = binIdByKey.get(batchKey) ?? null;
        const currentBatchQty = this.parseNumber(
          currentQtyByBatchKey.get(batchKey),
          0,
        );
        const countedBatchQty = this.parseNumber(
          countedQtyByBatchKey.get(batchKey),
          0,
        );
        const batchDelta = countedBatchQty - currentBatchQty;
        if (Math.abs(batchDelta) <= 0.00001) {
          continue;
        }

        batchAllocations.push({
          batch_id: batchId,
          bin_id: binId,
          batch_reference: batchReferenceByKey.get(batchKey) ?? null,
          warehouse_id: normalizedWarehouseId,
          product_id: productId,
          quantity_in: batchDelta > 0 ? batchDelta : 0,
          quantity_out: batchDelta < 0 ? Math.abs(batchDelta) : 0,
          rate: this.parseNumber(item.rate, 0),
        });
      }

      const batchDeltaTotal = batchAllocations.reduce(
        (sum, batch) =>
          sum +
          this.parseNumber(batch.quantity_in, 0) -
          this.parseNumber(batch.quantity_out, 0),
        0,
      );
      const unresolvedDelta = quantityAdjusted - batchDeltaTotal;
      if (
        Math.abs(unresolvedDelta) > 0.00001 &&
        batchAllocations.length > 0
      ) {
        const firstBatch = batchAllocations[0];
        batchAllocations[0] = {
          ...firstBatch,
          quantity_in:
            this.parseNumber(firstBatch.quantity_in, 0) +
            (unresolvedDelta > 0 ? unresolvedDelta : 0),
          quantity_out:
            this.parseNumber(firstBatch.quantity_out, 0) +
            (unresolvedDelta < 0 ? Math.abs(unresolvedDelta) : 0),
        };
      }

      adjustmentItems.push({
        product_id: productId,
        quantity_adjusted: quantityAdjusted,
        cost_price: this.parseNumber(item.rate, 0),
        batch_allocations: batchAllocations,
        adjustment_reason:
          String(item.adjustment_reason ?? "Stocktaking results").trim() ||
          "Stocktaking results",
        product_name: String(item.name ?? "").trim() || null,
      });
    }

    let approvedAdjustment: any = null;
    if (adjustmentItems.length > 0) {
      const { data: existingAdjustment, error: existingAdjustmentError } =
        await this.client
          .from("inventory_adjustments")
          .select("id, status")
          .eq("entity_id", entityId)
          .eq("reference_number", stockCountNumber)
          .eq("warehouse_id", normalizedWarehouseId ?? null)
          .eq("status", "approved")
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle();

      if (existingAdjustmentError) {
        this.handleStorageError(existingAdjustmentError);
      }

      if (existingAdjustment?.id) {
        try {
          approvedAdjustment = await this.findOne(existingAdjustment.id, tenant);
        } catch (error) {
          if (!this.isMissingTableError(error)) {
            throw error;
          }
          this.logger.warn(
            `Adjustment ${existingAdjustment.id} found but detail hydration skipped ∵ optional table missing`,
          );
          approvedAdjustment = this.buildFallbackAdjustmentResponse(
            existingAdjustment as Record<string, unknown>,
            adjustmentItems,
          );
        }
      } else {
        const totalQtyAdjusted = adjustmentItems.reduce(
          (sum, item) => sum + this.parseNumber(item.quantity_adjusted, 0),
          0,
        );
        const combinedReasons = Array.from(
          new Set(
            adjustmentItems
              .map((item) => item.adjustment_reason)
              .filter((reason) => reason && reason.trim().length > 0),
          ),
        ).join(", ");

        approvedAdjustment = await this.create(
          {
            product_id: adjustmentItems[0].product_id,
            warehouse_id: normalizedWarehouseId,
            adjustment_date: new Date().toISOString(),
            adjustment_type: "quantity",
            reason: combinedReasons || "Stocktaking results",
            quantity_before: 0,
            quantity_adjusted: totalQtyAdjusted,
            quantity_after: 0,
            cost_price: this.parseNumber(adjustmentItems[0].cost_price, 0),
            reference_number: stockCountNumber,
            notes:
              approvalDto.description?.trim() ||
              String((stockCount as any).description ?? "").trim() ||
              "Stock count approval",
            status: "approved",
            allow_reserved_consumption: true,
            items: adjustmentItems.map((item) => ({
              product_id: item.product_id,
              quantity_adjusted: item.quantity_adjusted,
              cost_price: item.cost_price,
              batch_allocations: item.batch_allocations,
            })),
          },
          tenant,
        );
      }
    }

    const { data: updatedStockCount, error: updateError } = await this.client
      .from("inventory_stock_count")
      .update({
        status: "Completed",
      })
      .eq("id", normalizedStockCountId)
      .eq("entity_id", entityId)
      .select(
        "id, entity_id, stock_count_number, description, warehouse_id, status",
      )
      .single();

    if (updateError) {
      this.handleStorageError(updateError);
    }

    return {
      stock_count: updatedStockCount,
      inventory_adjustment: approvedAdjustment,
    };
  }

  async update(
    id: string,
    updateDto: UpdateInventoryAdjustmentDto,
    tenant: TenantContext,
  ) {
    const entityId = this.ensureEntity(tenant);
    const existing = await this.findOne(id, tenant);

    if (existing.status === "approved") {
      throw new BadRequestException(
        "Approved adjustments cannot be edited. Create a new adjustment instead.",
      );
    }

    const quantityBefore = this.parseNumber(
      updateDto.quantity_before,
      this.parseNumber(existing.quantity_before, 0),
    );
    const quantityAdjusted = this.parseNumber(
      updateDto.quantity_adjusted,
      this.parseNumber(existing.quantity_adjusted, 0),
    );
    const quantityAfter = this.parseNumber(
      updateDto.quantity_after,
      quantityBefore + quantityAdjusted,
    );

    const adjustmentType = this.normalizeType(
      updateDto.adjustment_type ?? existing.adjustment_type,
    );
    const fallbackInventoryAccountId =
      (updateDto.account_id !== undefined
        ? this.normalizeUuid(updateDto.account_id)
        : this.normalizeUuid(existing.account_id)) ??
      (await this.resolveInventoryAccountIdForProduct(
        String(existing.product_id ?? "").trim(),
      ));

    const payload: Record<string, unknown> = {
      warehouse_id: updateDto.warehouse_id ?? existing.warehouse_id ?? null,
      adjustment_date: updateDto.adjustment_date ?? existing.adjustment_date,
      adjustment_type: adjustmentType,
      reason_id:
        updateDto.reason_id !== undefined
          ? (updateDto.reason_id ?? null)
          : (existing.reason_id ?? null),
      reason: (
        updateDto.reason ??
        existing.reason ??
        existing.reason_name ??
        "Stock correction"
      ).trim(),
      quantity_before: quantityBefore,
      quantity_adjusted: quantityAdjusted,
      quantity_after: quantityAfter,
      cost_price:
        this.parseNumber(updateDto.cost_price ?? existing.cost_price, 0) ||
        null,
      adjustment_value: this.parseNumber(
        updateDto.adjustment_value ?? existing.adjustment_value,
        0,
      ),
      account_id: fallbackInventoryAccountId,
      reference_number:
        updateDto.reference_number?.trim() ?? existing.reference_number ?? null,
      notes: updateDto.notes?.trim() ?? existing.notes ?? null,
      status: this.normalizeStatus(updateDto.status ?? existing.status),
      updated_at: new Date().toISOString(),
    };

    const { error } = await this.client
      .from("inventory_adjustments")
      .update(payload)
      .eq("id", id)
      .eq("entity_id", entityId);

    if (error) {
      this.handleStorageError(error);
    }

    const shouldRewriteDetails =
      Array.isArray(updateDto.items) ||
      Array.isArray(updateDto.value_items) ||
      Array.isArray(updateDto.account_entries);

    if (shouldRewriteDetails) {
      const { error: deleteItemsError } = await this.client
        .from("inventory_adjustment_items")
        .delete()
        .eq("adjustment_id", id)
        .eq("entity_id", entityId);
      if (deleteItemsError) this.handleStorageError(deleteItemsError);

      const { error: deleteBatchesError } = await this.client
        .from("inventory_adjustment_item_batches")
        .delete()
        .eq("adjustment_id", id)
        .eq("entity_id", entityId);
      if (deleteBatchesError) this.handleStorageError(deleteBatchesError);

      const { error: deleteValueError } = await this.client
        .from("inventory_adjustment_value_items")
        .delete()
        .eq("adjustment_id", id)
        .eq("entity_id", entityId);
      if (deleteValueError) this.handleStorageError(deleteValueError);

      const { error: deleteEntriesError } = await this.client
        .from("inventory_adjustment_account_entries")
        .delete()
        .eq("adjustment_id", id)
        .eq("entity_id", entityId);
      if (deleteEntriesError) this.handleStorageError(deleteEntriesError);

      await this.persistAdjustmentDetails(
        id,
        adjustmentType,
        this.safeArray<CreateInventoryAdjustmentItemDto>(updateDto.items),
        this.safeArray<CreateInventoryAdjustmentValueItemDto>(
          updateDto.value_items,
        ),
        this.safeArray<CreateInventoryAdjustmentAccountEntryDto>(
          updateDto.account_entries,
        ),
        String(existing.product_id ?? "").trim(),
        (updateDto.warehouse_id ?? existing.warehouse_id ?? null) as
          | string
          | null,
        {
          quantityBefore,
          quantityAdjusted,
          quantityAfter,
          costPrice: this.parseNumber(
            updateDto.cost_price ?? existing.cost_price,
            0,
          ),
          adjustmentValue: this.parseNumber(
            updateDto.adjustment_value ?? existing.adjustment_value,
            0,
          ),
        },
        tenant,
      );
    }

    return this.findOne(id, tenant);
  }

  async remove(id: string, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    const existing = await this.findOne(id, tenant);
    if (existing.status === "approved") {
      throw new BadRequestException(
        "Approved adjustments cannot be deleted. Use a reverse adjustment instead.",
      );
    }

    const { error } = await this.client
      .from("inventory_adjustments")
      .delete()
      .eq("id", id)
      .eq("entity_id", entityId);

    if (error) {
      this.handleStorageError(error);
    }

    return { success: true };
  }

  private async postQuantityAdjustment(
    adjustmentId: string,
    adjustment: Record<string, unknown>,
    tenant: TenantContext,
    options?: { allowReservedConsumption?: boolean },
  ) {
    const entityId = this.ensureEntity(tenant);
    const { data: items, error: itemsError } = await this.client
      .from("inventory_adjustment_items")
      .select("*")
      .eq("adjustment_id", adjustmentId)
      .eq("entity_id", entityId);
    if (itemsError) this.handleStorageError(itemsError);
    const safeItems = items ?? [];

    const { data: itemBatches, error: itemBatchesError } = await this.client
      .from("inventory_adjustment_item_batches")
      .select("*")
      .eq("adjustment_id", adjustmentId)
      .eq("entity_id", entityId);
    if (itemBatchesError) this.handleStorageError(itemBatchesError);
    const batchRows = itemBatches ?? [];

    if (batchRows.length > 0) {
      await this.applyBatchLayerQuantityAdjustments(
        adjustmentId,
        adjustment,
        tenant,
        batchRows,
        options,
      );
    } else {
      this.logger.warn(
        `postQuantityAdjustment adjustment=${adjustmentId} has no batch allocations; stock layer update skipped`,
      );
    }

    const { data: entries, error: entriesError } = await this.client
      .from("inventory_adjustment_account_entries")
      .select("*")
      .eq("adjustment_id", adjustmentId)
      .eq("entity_id", entityId);
    if (entriesError) this.handleStorageError(entriesError);
    let toPostEntries = entries ?? [];
    const adjustmentAccountId =
      this.normalizeUuid((adjustment as any).account_id) ??
      (await this.resolveInventoryAccountIdForProduct(
        String((adjustment as any).product_id ?? "").trim(),
      ));

    if (toPostEntries.length === 0 && adjustmentAccountId) {
      const headerAdjustmentValue = this.parseNumber(
        (adjustment as any).adjustment_value,
        0,
      );
      const itemAdjustmentValue = safeItems.reduce(
        (sum, row: any) => sum + this.parseNumber(row.adjustment_value, 0),
        0,
      );
      const computedMagnitude = safeItems.reduce((sum, row: any) => {
        const qty = Math.abs(this.parseNumber(row.quantity_adjusted, 0));
        const rate = Math.abs(this.parseNumber(row.cost_price, 0));
        return sum + qty * rate;
      }, 0);
      const quantityDirection = safeItems.reduce(
        (sum, row: any) => sum + this.parseNumber(row.quantity_adjusted, 0),
        0,
      );

      // Prefer explicit signed value if present; else derive magnitude from qty*cost
      // and use quantity direction to assign Dr/Cr for selected account.
      let signedForSelectedAccount = 0;
      if (Math.abs(headerAdjustmentValue) > 0.00001) {
        signedForSelectedAccount = headerAdjustmentValue;
      } else if (Math.abs(itemAdjustmentValue) > 0.00001) {
        signedForSelectedAccount = itemAdjustmentValue;
      } else if (computedMagnitude > 0.00001) {
        if (quantityDirection >= 0) {
          // Stock increase: selected expense-side account gets credit
          signedForSelectedAccount = -computedMagnitude;
        } else {
          // Stock decrease: selected expense-side account gets debit
          signedForSelectedAccount = computedMagnitude;
        }
      }

      if (Math.abs(signedForSelectedAccount) > 0.00001) {
        toPostEntries = [
          {
            account_id: adjustmentAccountId,
            debit:
              signedForSelectedAccount > 0
                ? Math.abs(signedForSelectedAccount)
                : 0,
            credit:
              signedForSelectedAccount < 0
                ? Math.abs(signedForSelectedAccount)
                : 0,
            description: "Auto quantity-adjustment entry",
          },
        ] as any[];
      }
    }

    if (toPostEntries.length > 0) {
      const accountTransactionsPayload = toPostEntries
        .filter((entry: any) => entry?.account_id)
        .map((entry: any) => ({
          entity_id: entityId,
          account_id: entry.account_id,
          transaction_date:
            adjustment.adjustment_date?.toString() ?? new Date().toISOString(),
          transaction_type: "Inventory Adjustment By Quantity",
          reference_number: adjustment.reference_number ?? null,
          description:
            entry.description ??
            adjustment.notes ??
            "Inventory quantity adjustment",
          debit: this.parseNumber(entry.debit, 0),
          credit: this.parseNumber(entry.credit, 0),
          source_id: adjustmentId,
          source_type: "inventory_adjustment",
          contact_id: null,
          contact_type: null,
          org_id: tenant.orgId,
        }))
        .filter((row) => {
          const debit = this.parseNumber(row.debit, 0);
          const credit = this.parseNumber(row.credit, 0);
          return Math.abs(debit) > 0.00001 || Math.abs(credit) > 0.00001;
        });

      if (accountTransactionsPayload.length > 0) {
        const { error: accountTxnError } = await this.client
          .from("account_transactions")
          .insert(accountTransactionsPayload);
        if (accountTxnError) this.handleStorageError(accountTxnError);
      } else {
        this.logger.warn(
          `postQuantityAdjustment adjustment=${adjustmentId} skipped account_transactions insert because all computed rows were zero/zero`,
        );
      }
    }
  }

  private async postValueAdjustment(
    adjustmentId: string,
    adjustment: Record<string, unknown>,
    tenant: TenantContext,
  ) {
    const entityId = this.ensureEntity(tenant);

    const { data: valueItems, error: valueItemsError } = await this.client
      .from("inventory_adjustment_value_items")
      .select("*")
      .eq("adjustment_id", adjustmentId)
      .eq("entity_id", entityId);
    if (valueItemsError) this.handleStorageError(valueItemsError);
    const safeValueItems = valueItems ?? [];

    for (const row of safeValueItems) {
      const newRate = this.parseNumber(row.changed_value, 0);

      let updateReq = this.client
        .from("batch_stock_layers")
        .update({
          purchase_rate: newRate,
          updated_at: new Date().toISOString(),
        })
        .eq("entity_id", entityId)
        .eq("product_id", row.product_id);

      if (row.batch_stock_layer_id) {
        updateReq = updateReq.eq("id", row.batch_stock_layer_id);
      } else if (row.batch_id) {
        updateReq = updateReq.eq("batch_id", row.batch_id);
      }

      const { error: layerUpdateError } = await updateReq;
      if (layerUpdateError) this.handleStorageError(layerUpdateError);
    }

    const { data: entries, error: entriesError } = await this.client
      .from("inventory_adjustment_account_entries")
      .select("*")
      .eq("adjustment_id", adjustmentId)
      .eq("entity_id", entityId);
    if (entriesError) this.handleStorageError(entriesError);
    let toPostEntries = entries ?? [];
    const adjustmentAccountId =
      this.normalizeUuid((adjustment as any).account_id) ??
      (await this.resolveInventoryAccountIdForProduct(
        String((adjustment as any).product_id ?? "").trim(),
      ));

    if (toPostEntries.length === 0 && adjustmentAccountId) {
      const netValue = safeValueItems.reduce(
        (sum, row) => sum + this.parseNumber(row.adjusted_value, 0),
        0,
      );
      if (Math.abs(netValue) > 0.00001) {
        toPostEntries = [
          {
            account_id: adjustmentAccountId,
            debit: netValue > 0 ? Math.abs(netValue) : 0,
            credit: netValue < 0 ? Math.abs(netValue) : 0,
            description: "Auto value-adjustment entry",
          },
        ] as any[];
      }
    }

    if (toPostEntries.length > 0) {
      const accountTransactionsPayload = toPostEntries
        .filter((entry: any) => entry?.account_id)
        .map((entry: any) => ({
          entity_id: entityId,
          account_id: entry.account_id,
          transaction_date:
            adjustment.adjustment_date?.toString() ?? new Date().toISOString(),
          transaction_type: "Inventory Adjustment By Value",
          reference_number: adjustment.reference_number ?? null,
          description:
            entry.description ??
            adjustment.notes ??
            "Inventory value adjustment",
          debit: this.parseNumber(entry.debit, 0),
          credit: this.parseNumber(entry.credit, 0),
          source_id: adjustmentId,
          source_type: "inventory_adjustment",
          contact_id: null,
          contact_type: null,
          org_id: tenant.orgId,
        }))
        .filter((row) => {
          const debit = this.parseNumber(row.debit, 0);
          const credit = this.parseNumber(row.credit, 0);
          return Math.abs(debit) > 0.00001 || Math.abs(credit) > 0.00001;
        });

      if (accountTransactionsPayload.length > 0) {
        const { error: accountTxnError } = await this.client
          .from("account_transactions")
          .insert(accountTransactionsPayload);
        if (accountTxnError) this.handleStorageError(accountTxnError);
      } else {
        this.logger.warn(
          `postValueAdjustment adjustment=${adjustmentId} skipped account_transactions insert because all computed rows were zero/zero`,
        );
      }
    }
  }

  async approve(
    id: string,
    tenant: TenantContext,
    options?: { allowReservedConsumption?: boolean },
  ) {
    const entityId = this.ensureEntity(tenant);
    const existing = await this.findOne(id, tenant);
    if (existing.status === "approved") {
      return existing;
    }

    const normalizedType = this.normalizeType(existing.adjustment_type);
    const allowReservedConsumption =
      options?.allowReservedConsumption === true ||
      (await this.isStockCountBackedAdjustment(tenant, existing));
    if (normalizedType === "quantity") {
      await this.postQuantityAdjustment(id, existing, tenant, {
        allowReservedConsumption,
      });
    } else {
      await this.postValueAdjustment(id, existing, tenant);
    }

    const { error } = await this.client
      .from("inventory_adjustments")
      .update({
        status: "approved",
        approved_by: tenant.userId ?? null,
        approved_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .eq("entity_id", entityId);

    if (error) {
      this.handleStorageError(error);
    }

    return this.findOne(id, tenant);
  }

  async reject(id: string, tenant: TenantContext, reason?: string) {
    const entityId = this.ensureEntity(tenant);
    const existing = await this.findOne(id, tenant);

    if (existing.status === "approved") {
      throw new BadRequestException(
        "Approved adjustments cannot be rejected. Use a reverse adjustment instead.",
      );
    }

    const note = reason?.trim();
    const existingNotes = (existing.notes ?? "").toString().trim();
    const mergedNotes = note
      ? [existingNotes, `Rejection Reason: ${note}`]
          .filter((part) => part.trim().length > 0)
          .join("\n\n")
      : existingNotes || null;

    const { error } = await this.client
      .from("inventory_adjustments")
      .update({
        status: "rejected",
        notes: mergedNotes,
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .eq("entity_id", entityId);

    if (error) {
      this.handleStorageError(error);
    }

    if (!note) {
      this.logger.log(`Adjustment ${id} rejected without explicit reason`);
    }

    return this.findOne(id, tenant);
  }
}
