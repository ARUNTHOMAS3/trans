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

  private handleStorageError(error: unknown): never {
    if (this.isMissingTableError(error)) {
      throw new ServiceUnavailableException(
        "Inventory adjustments table is not ready yet. Complete DB setup, then retry.",
      );
    }
    throw error;
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

    let fallbackQuery = this.client
      .from("batch_stock_layers")
      .select("qty, reserved_qty, warehouse_id")
      .eq("entity_id", entityId)
      .eq("product_id", productId);

    if (normalizedWarehouseId) {
      fallbackQuery = fallbackQuery.eq("warehouse_id", normalizedWarehouseId);
    }

    const { data: layerRows, error: layerError } = await fallbackQuery;
    if (layerError) {
      this.handleStorageError(layerError);
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
  ) {
    const entityId = this.ensureEntity(tenant);
    const now = new Date().toISOString();
    const transDate =
      adjustment.adjustment_date?.toString() ?? new Date().toISOString();

    for (const row of batchRows) {
      const productId = String(row?.product_id ?? "").trim();
      const batchId = this.normalizeUuid(row?.batch_id);
      const warehouseId = this.normalizeUuid(row?.warehouse_id);
      const binId = this.normalizeUuid(row?.bin_id);
      const qIn = this.parseNumber(row?.quantity_in, 0);
      const qOut = this.parseNumber(row?.quantity_out, 0);
      const delta = qIn - qOut;

      if (!productId || !batchId || !warehouseId || !binId || delta === 0) {
        continue;
      }

      let layerId = this.normalizeUuid(row?.batch_stock_layer_id);

      if (delta < 0) {
        const qtyToConsume = Math.abs(delta);
        let layerQuery = this.client
          .from("batch_stock_layers")
          .select("id, qty, reserved_qty")
          .eq("entity_id", entityId)
          .eq("product_id", productId)
          .eq("warehouse_id", warehouseId)
          .eq("bin_id", binId)
          .eq("batch_id", batchId)
          .order("updated_at", { ascending: false })
          .limit(1);

        if (layerId) {
          layerQuery = layerQuery.eq("id", layerId);
        }

        const { data: layerRows, error: layerReadError } = await layerQuery;
        if (layerReadError) this.handleStorageError(layerReadError);

        const layer = layerRows?.[0] as
          | { id: string; qty?: number | string; reserved_qty?: number | string }
          | undefined;
        if (!layer?.id) {
          throw new BadRequestException(
            `Missing source stock layer for adjustment batch row (product ${productId})`,
          );
        }

        const currentQty = this.parseNumber(layer.qty, 0);
        const reservedQty = this.parseNumber(layer.reserved_qty, 0);
        const availableQty = currentQty - reservedQty;
        if (availableQty < qtyToConsume) {
          throw new BadRequestException(
            `Insufficient available stock for product ${productId} in selected bin`,
          );
        }

        const { error: updateErr } = await this.client
          .from("batch_stock_layers")
          .update({
            qty: currentQty - qtyToConsume,
            updated_at: now,
          })
          .eq("id", layer.id)
          .eq("entity_id", entityId);
        if (updateErr) this.handleStorageError(updateErr);
        layerId = layer.id;
      } else {
        const upsertPayload = {
          batch_id: batchId,
          product_id: productId,
          entity_id: entityId,
          warehouse_id: warehouseId,
          bin_id: binId,
          purchase_rate: this.parseNumber(row?.rate, 0),
          mrp: 0,
          qty: delta,
          foc_qty: 0,
          ref_id: adjustmentId,
          ref_type: "ADJUSTMENT",
          reserved_qty: 0,
          updated_at: now,
        };

        const { data: upserted, error: upsertError } = await this.client
          .from("batch_stock_layers")
          .upsert(upsertPayload, {
            onConflict: "batch_id,product_id,entity_id,warehouse_id,bin_id",
            ignoreDuplicates: false,
          })
          .select("id")
          .limit(1);
        if (upsertError) this.handleStorageError(upsertError);
        layerId =
          this.normalizeUuid((upserted?.[0] as any)?.id) ??
          this.normalizeUuid(row?.batch_stock_layer_id);
      }

      const { error: transError } = await this.client
        .from("batch_transactions")
        .insert({
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
      if (transError) this.handleStorageError(transError);
    }
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

    if (valueItemsError) {
      this.handleStorageError(valueItemsError);
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

    if (accountEntriesError) {
      this.handleStorageError(accountEntriesError);
    }

    const { data: itemBatches, error: itemBatchesError } = await this.client
      .from("inventory_adjustment_item_batches")
      .select("*")
      .eq("adjustment_id", id)
      .eq("entity_id", entityId)
      .order("created_at", { ascending: true });

    if (itemBatchesError) {
      this.handleStorageError(itemBatchesError);
    }
    const rawItemBatches = itemBatches ?? [];
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
      value_items: valueItems ?? [],
      account_entries: (accountEntries ?? []).map((entry: any) => ({
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
      status,
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
      await this.approve(data.id, tenant);
    }

    return this.findOne(data.id, tenant);
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

  async approve(id: string, tenant: TenantContext) {
    const entityId = this.ensureEntity(tenant);
    const existing = await this.findOne(id, tenant);
    if (existing.status === "approved") {
      return existing;
    }

    const normalizedType = this.normalizeType(existing.adjustment_type);
    if (normalizedType === "quantity") {
      await this.postQuantityAdjustment(id, existing, tenant);
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
