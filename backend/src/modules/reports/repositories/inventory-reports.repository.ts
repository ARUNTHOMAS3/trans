import { Injectable } from "@nestjs/common";
import { sql } from "drizzle-orm";
import { db } from "../../../db/db";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { InventoryReportQueryDto } from "../dto/inventory-report-query.dto";

export interface InventoryReportPage<T extends Record<string, unknown>> {
  rows: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
  totals?: Record<string, unknown>;
}

interface PaginationOptions {
  page: number;
  limit: number;
  offset: number;
}

@Injectable()
export class InventoryReportsRepository {
  private parseNumber(value: unknown, fallback = 0): number {
    if (value === null || value === undefined || value === "") return fallback;
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  private normalizePagination(
    query: InventoryReportQueryDto,
  ): PaginationOptions {
    const page = Math.max(1, Number(query.page ?? 1));
    const requestedLimit = Number(query.pageSize ?? query.limit ?? 100);
    const limit = Math.min(500, Math.max(1, requestedLimit));
    return { page, limit, offset: (page - 1) * limit };
  }

  private getEntityId(tenant: TenantContext): string {
    return tenant.entityId?.toString().trim() || "";
  }

  private rowsFrom(result: unknown): Record<string, unknown>[] {
    if (Array.isArray(result)) return result as Record<string, unknown>[];
    const maybeRows = (result as { rows?: unknown })?.rows;
    return Array.isArray(maybeRows)
      ? (maybeRows as Record<string, unknown>[])
      : [];
  }

  private pageFromRows<T extends Record<string, unknown>>(
    rows: T[],
    pagination: PaginationOptions,
  ): InventoryReportPage<T> {
    const total = rows.length > 0 ? this.parseNumber(rows[0]["__total"]) : 0;
    const cleaned = rows.map((row) => {
      const { __total, ...rest } = row;
      return rest as T;
    });
    return {
      rows: cleaned,
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: total === 0 ? 1 : Math.ceil(total / pagination.limit),
    };
  }

  async inventorySummary(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ): Promise<InventoryReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);
    const stockConditions = [sql`ps.entity_id = ${entityId}`];
    const adjustmentConditions = [sql`iai.entity_id = ${entityId}`];

    if (query.warehouseId?.trim()) {
      stockConditions.push(sql`ps.warehouse_id = ${query.warehouseId.trim()}`);
      adjustmentConditions.push(
        sql`ia.warehouse_id = ${query.warehouseId.trim()}`,
      );
    }
    if (query.search?.trim()) {
      stockConditions.push(
        sql`p.product_name ILIKE ${`%${query.search.trim()}%`}`,
      );
    }
    if (query.startDate?.trim()) {
      adjustmentConditions.push(
        sql`ia.adjustment_date >= ${query.startDate.trim()}`,
      );
    }
    if (query.endDate?.trim()) {
      const endDate = query.endDate.includes("T")
        ? query.endDate.trim()
        : `${query.endDate.trim()} 23:59:59`;
      adjustmentConditions.push(sql`ia.adjustment_date <= ${endDate}`);
    }

    const stockWhereClause = sql.join(stockConditions, sql` AND `);
    const adjustmentWhereClause = sql.join(adjustmentConditions, sql` AND `);

    const result = await db.execute(sql`
      WITH stock AS (
        SELECT
          ps.product_id,
          SUM(COALESCE(ps.stock_on_hand, 0))::numeric AS stock_on_hand,
          SUM(COALESCE(ps.committed_stock, 0))::numeric AS committed_stock,
          SUM(COALESCE(ps.available_stock, 0))::numeric AS available_stock
        FROM public.v_physical_stock ps
        JOIN products p ON p.id = ps.product_id
        WHERE ${stockWhereClause}
        GROUP BY ps.product_id
      ),
      ordered AS (
        SELECT
          poi.product_id,
          SUM(
            GREATEST(
              COALESCE(poi.quantity, 0) - COALESCE(poi.cancelled_quantity, 0),
              0
            )
          )::numeric AS quantity_ordered
        FROM purchase_order_items poi
        WHERE poi.entity_id = ${entityId}
          AND poi.product_id IS NOT NULL
        GROUP BY poi.product_id
      ),
      adjusted AS (
        SELECT
          iai.product_id,
          SUM(
            CASE
              WHEN COALESCE(iai.quantity_adjusted, 0) > 0 THEN COALESCE(iai.quantity_adjusted, 0)
              ELSE 0
            END
          )::numeric AS quantity_in,
          SUM(
            CASE
              WHEN COALESCE(iai.quantity_adjusted, 0) < 0 THEN ABS(COALESCE(iai.quantity_adjusted, 0))
              ELSE 0
            END
          )::numeric AS quantity_out
        FROM inventory_adjustment_items iai
        JOIN inventory_adjustments ia ON ia.id = iai.adjustment_id
        WHERE ${adjustmentWhereClause}
        GROUP BY iai.product_id
      ),
      grouped AS (
        SELECT
          p.id::text AS "itemId",
          p.product_name AS "itemName",
          COALESCE(p.reorder_point, 0)::numeric AS "reorderLevel",
          COALESCE(o.quantity_ordered, 0)::numeric AS "quantityOrdered",
          COALESCE(a.quantity_in, 0)::numeric AS "quantityIn",
          COALESCE(a.quantity_out, 0)::numeric AS "quantityOut",
          COALESCE(s.stock_on_hand, 0)::numeric AS "stockOnHand",
          COALESCE(s.committed_stock, 0)::numeric AS "committedStock",
          COALESCE(s.available_stock, 0)::numeric AS "availableForSale"
        FROM stock s
        JOIN products p ON p.id = s.product_id
        LEFT JOIN ordered o ON o.product_id = s.product_id
        LEFT JOIN adjusted a ON a.product_id = s.product_id
      )
      SELECT *, COUNT(*) OVER()::int AS "__total"
      FROM grouped
      ORDER BY "itemName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      reorderLevel: this.parseNumber(row.reorderLevel),
      quantityOrdered: this.parseNumber(row.quantityOrdered),
      quantityIn: this.parseNumber(row.quantityIn),
      quantityOut: this.parseNumber(row.quantityOut),
      stockOnHand: this.parseNumber(row.stockOnHand),
      committedStock: this.parseNumber(row.committedStock),
      availableForSale: this.parseNumber(row.availableForSale),
    }));

    const page = this.pageFromRows(rows, pagination);
    console.log("[REPORTS BACKEND] Inventory Summary repository page", {
      runtimeType: Array.isArray(page) ? "array" : typeof page,
      json: page,
    });
    return page;
  }

  async inventoryValuationSummary(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ): Promise<InventoryReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);
    const conditions = [sql`bt.entity_id = ${entityId}`];
    const asOfDate = (query.endDate || query.startDate || "").trim();

    if (asOfDate) {
      const endDate = asOfDate.includes("T") ? asOfDate : `${asOfDate} 23:59:59`;
      conditions.push(sql`bt.trans_date <= ${endDate}`);
    }
    if (query.warehouseId?.trim()) {
      conditions.push(sql`bt.warehouse_id = ${query.warehouseId.trim()}`);
    }
    if (query.productId?.trim()) {
      conditions.push(sql`bt.product_id = ${query.productId.trim()}`);
    }
    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(
        sql`(p.product_name ILIKE ${search} OR p.sku ILIKE ${search} OR p.item_code ILIKE ${search})`,
      );
    }

    const status = query.status?.trim().toLowerCase();
    if (status === "active") {
      conditions.push(sql`COALESCE(NULLIF(to_jsonb(p)->>'is_active', '')::boolean, true) = true`);
    } else if (status === "inactive") {
      conditions.push(sql`COALESCE(NULLIF(to_jsonb(p)->>'is_active', '')::boolean, true) = false`);
    }

    const availability = query.stockAvailability?.trim().toLowerCase();
    let availabilityCondition = sql`TRUE`;
    if (availability === "greater than zero") {
      availabilityCondition = sql`stock_on_hand > 0`;
    } else if (availability === "less than or equal to zero") {
      availabilityCondition = sql`stock_on_hand <= 0`;
    } else if (availability === "less than zero") {
      availabilityCondition = sql`stock_on_hand < 0`;
    } else if (availability === "equal to zero") {
      availabilityCondition = sql`stock_on_hand = 0`;
    } else if (availability === "not equal to zero") {
      availabilityCondition = sql`stock_on_hand <> 0`;
    }

    const whereClause = sql.join(conditions, sql` AND `);
    const result = await db.execute(sql`
      WITH valued AS (
        SELECT
          p.id::text AS item_id,
          COALESCE(NULLIF(p.product_name, ''), p.id::text) AS item_name,
          COALESCE(NULLIF(u.unit_symbol, ''), NULLIF(u.unit_name, ''), '') AS unit,
          SUM(COALESCE(bt.qty_in, 0) - COALESCE(bt.qty_out, 0))::numeric AS stock_on_hand,
          SUM(
            (COALESCE(bt.qty_in, 0) - COALESCE(bt.qty_out, 0))
            * COALESCE(bt.rate, p.cost_price, 0)
          )::numeric AS asset_value
        FROM batch_transactions bt
        JOIN products p ON p.id = bt.product_id
        LEFT JOIN units u ON u.id = p.unit_id
        WHERE ${whereClause}
        GROUP BY p.id, p.product_name, u.unit_symbol, u.unit_name
      ),
      filtered AS (
        SELECT * FROM valued WHERE ${availabilityCondition}
      )
      SELECT
        item_id AS "itemId",
        item_name AS "itemName",
        unit,
        stock_on_hand AS "stockOnHand",
        asset_value AS "assetValue",
        COUNT(*) OVER()::int AS "__total",
        COALESCE(SUM(stock_on_hand) OVER(), 0)::numeric AS "__totalStockOnHand",
        COALESCE(SUM(asset_value) OVER(), 0)::numeric AS "__totalAssetValue"
      FROM filtered
      ORDER BY item_name ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rawRows = this.rowsFrom(result);
    const total = rawRows.length > 0 ? this.parseNumber(rawRows[0]["__total"]) : 0;
    const totals = {
      stockOnHand:
        rawRows.length > 0
          ? this.parseNumber(rawRows[0]["__totalStockOnHand"])
          : 0,
      assetValue:
        rawRows.length > 0
          ? this.parseNumber(rawRows[0]["__totalAssetValue"])
          : 0,
    };
    const rows = rawRows.map((row) => ({
      itemId: row.itemId,
      itemName: row.itemName,
      unit: row.unit,
      stockOnHand: this.parseNumber(row.stockOnHand),
      assetValue: this.parseNumber(row.assetValue),
    }));

    return {
      rows,
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: total === 0 ? 1 : Math.ceil(total / pagination.limit),
      totals,
    };
  }
  async batchDetails(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ): Promise<InventoryReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);

    if (!entityId) {
      return {
        rows: [],
        total: 0,
        page: pagination.page,
        limit: pagination.limit,
        totalPages: 1,
        totals: {
          quantityIn: 0,
          quantityAvailable: 0,
          currentStockValue: 0,
        },
      };
    }

    const conditions = [
      sql`(
        to_jsonb(bm)->>'entity_id' = ${entityId}
        OR (to_jsonb(bm)->>'entity_id' IS NULL AND m.batch_id IS NOT NULL)
      )`,
    ];
    const movementConditions = [sql`bt.entity_id = ${entityId}`];

    if (query.startDate?.trim()) {
      conditions.push(sql`bm.created_at >= ${query.startDate.trim()}`);
    }
    if (query.endDate?.trim()) {
      const endDate = query.endDate.includes("T")
        ? query.endDate.trim()
        : `${query.endDate.trim()} 23:59:59`;
      conditions.push(sql`bm.created_at <= ${endDate}`);
    }
    if (query.productId?.trim()) {
      conditions.push(sql`bm.product_id = ${query.productId.trim()}`);
      movementConditions.push(sql`bt.product_id = ${query.productId.trim()}`);
    }
    if (query.warehouseId?.trim()) {
      movementConditions.push(sql`bt.warehouse_id = ${query.warehouseId.trim()}`);
    }
    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        bm.batch_no ILIKE ${search}
        OR COALESCE(NULLIF(p.product_name, ''), '') ILIKE ${search}
        OR COALESCE(NULLIF(p.sku, ''), NULLIF(p.item_code, ''), '') ILIKE ${search}
        OR COALESCE(NULLIF(bm.manufacture_batch_number, ''), '') ILIKE ${search}
        OR COALESCE(NULLIF(to_jsonb(bm)->>'source_type', ''), '') ILIKE ${search}
      )`);
    }

    const status = query.status?.trim().toLowerCase();
    if (status === "active") {
      conditions.push(sql`COALESCE(bm.is_active, true) = true`);
    } else if (status === "inactive") {
      conditions.push(sql`COALESCE(bm.is_active, true) = false`);
    }

    const whereClause = sql.join(conditions, sql` AND `);
    const movementWhereClause = sql.join(movementConditions, sql` AND `);
    const hideEmptyBatches = ["true", "1", "yes"].includes(
      query.hideEmptyBatches?.trim().toLowerCase() ?? "",
    );
    const emptyBatchFilter = hideEmptyBatches
      ? sql`COALESCE("quantityIn", 0) <> 0`
      : sql`TRUE`;

    const result = await db.execute(sql`
      WITH movement AS (
        SELECT
          bt.batch_id,
          string_agg(DISTINCT COALESCE(NULLIF(w.name, ''), ''), ', ') AS warehouse_name,
          SUM(COALESCE(bt.qty_in, 0))::numeric AS quantity_in,
          SUM(COALESCE(bt.qty_out, 0))::numeric AS quantity_out,
          SUM(COALESCE(bt.qty_in, 0) - COALESCE(bt.qty_out, 0))::numeric AS quantity_available,
          COALESCE(
            SUM((COALESCE(bt.qty_in, 0) - COALESCE(bt.qty_out, 0)) * COALESCE(bt.rate, 0))
            / NULLIF(SUM(COALESCE(bt.qty_in, 0) - COALESCE(bt.qty_out, 0)), 0),
            MAX(COALESCE(bt.rate, 0)),
            0
          )::numeric AS cost_price
        FROM batch_transactions bt
        LEFT JOIN warehouses w ON w.id = bt.warehouse_id
        WHERE ${movementWhereClause}
        GROUP BY bt.batch_id
      ),
      batch_rows AS (
        SELECT
          bm.id::text AS "batchId",
          p.id::text AS "productId",
          COALESCE(NULLIF(p.product_name, ''), p.id::text) AS "itemName",
          COALESCE(NULLIF(p.sku, ''), NULLIF(p.item_code, ''), '') AS "sku",
          COALESCE(NULLIF(u.unit_symbol, ''), NULLIF(u.unit_name, ''), '') AS "unit",
          COALESCE(NULLIF(bm.batch_no, ''), bm.id::text) AS "batchNumber",
          COALESCE(NULLIF(bm.unit_pack, ''), '') AS "unitPack",
          COALESCE(NULLIF(bm.manufacture_batch_number, ''), '') AS "manufacturerBatch",
          CASE
            WHEN bm.manufacture_exp IS NULL THEN ''
            ELSE TO_CHAR(bm.manufacture_exp::date, 'DD-MM-YYYY')
          END AS "manufacturedDate",
          CASE
            WHEN bm.expiry_date IS NULL THEN ''
            ELSE TO_CHAR(bm.expiry_date::date, 'DD-MM-YYYY')
          END AS "expiryDate",
          COALESCE(NULLIF(to_jsonb(bm)->>'source_type', ''), '') AS "sourceType",
          COALESCE(NULLIF(m.warehouse_name, ''), '') AS "warehouseName",
          CASE WHEN COALESCE(bm.is_active, true) THEN 'Active' ELSE 'Inactive' END AS "batchStatus",
          COALESCE(m.quantity_in, 0)::numeric AS "quantityIn",
          COALESCE(m.quantity_out, 0)::numeric AS "quantityOut",
          COALESCE(m.quantity_available, 0)::numeric AS "quantityAvailable",
          COALESCE(m.cost_price, 0)::numeric AS "costPrice",
          (COALESCE(m.quantity_available, 0) * COALESCE(m.cost_price, 0))::numeric AS "currentStockValue"
        FROM batch_master bm
        JOIN products p ON p.id = bm.product_id
        LEFT JOIN units u ON u.id = p.unit_id
        LEFT JOIN movement m ON m.batch_id = bm.id
        WHERE ${whereClause}
      ),
      filtered AS (
        SELECT * FROM batch_rows WHERE ${emptyBatchFilter}
      )
      SELECT
        *,
        COUNT(*) OVER()::int AS "__total",
        COALESCE(SUM("quantityIn") OVER(), 0)::numeric AS "__totalQuantityIn",
        COALESCE(SUM("quantityAvailable") OVER(), 0)::numeric AS "__totalQuantityAvailable",
        COALESCE(SUM("currentStockValue") OVER(), 0)::numeric AS "__totalCurrentStockValue"
      FROM filtered
      ORDER BY "itemName" ASC, "batchNumber" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rawRows = this.rowsFrom(result);
    const firstRow = rawRows[0] ?? {};
    const totals = {
      quantityIn: this.parseNumber(firstRow.__totalQuantityIn),
      quantityAvailable: this.parseNumber(firstRow.__totalQuantityAvailable),
      currentStockValue: this.parseNumber(firstRow.__totalCurrentStockValue),
    };
    const rows = rawRows.map((row) => {
      const {
        __totalQuantityIn,
        __totalQuantityAvailable,
        __totalCurrentStockValue,
        ...rest
      } = row;
      return {
        ...rest,
        quantityIn: this.parseNumber(row.quantityIn),
        quantityOut: this.parseNumber(row.quantityOut),
        quantityAvailable: this.parseNumber(row.quantityAvailable),
        costPrice: this.parseNumber(row.costPrice),
        currentStockValue: this.parseNumber(row.currentStockValue),
      };
    });

    return {
      ...this.pageFromRows(rows, pagination),
      totals,
    };
  }
  async landedCostSummary(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ): Promise<InventoryReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);

    if (!entityId) {
      return {
        rows: [],
        total: 0,
        page: pagination.page,
        limit: pagination.limit,
        totalPages: 1,
        totals: {
          billTotal: 0,
          allocatedAmount: 0,
          unallocatedAmount: 0,
        },
      };
    }

    const conditions = [
      sql`b.entity_id = ${entityId}`,
      sql`COALESCE(b.is_delete, false) = false`,
    ];

    if (query.startDate?.trim()) {
      conditions.push(sql`b.bill_date >= ${query.startDate.trim()}`);
    }
    if (query.endDate?.trim()) {
      const endDate = query.endDate.includes("T")
        ? query.endDate.trim()
        : `${query.endDate.trim()} 23:59:59`;
      conditions.push(sql`b.bill_date <= ${endDate}`);
    }
    if (query.warehouseId?.trim()) {
      conditions.push(sql`b.warehouse_id = ${query.warehouseId.trim()}`);
    }
    if (query.productId?.trim()) {
      conditions.push(sql`EXISTS (
        SELECT 1
        FROM bill_items bi
        WHERE bi.bill_id = b.id
          AND bi.product_id = ${query.productId.trim()}
      )`);
    }
    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        b.bill_number ILIKE ${search}
        OR COALESCE(NULLIF(v.display_name, ''), NULLIF(v.company_name, '')) ILIKE ${search}
        OR blc.description ILIKE ${search}
        OR blc.allocation_method ILIKE ${search}
        OR expense_account.user_account_name ILIKE ${search}
        OR expense_account.system_account_name ILIKE ${search}
        OR expense_account.account_code ILIKE ${search}
      )`);
    }

    const whereClause = sql.join(conditions, sql` AND `);
    const result = await db.execute(sql`
      WITH landed_rows AS (
        SELECT
          blc.bill_id::text AS "billId",
          b.bill_date AS "billDateRaw",
          TO_CHAR(b.bill_date::date, 'DD-MM-YYYY') AS "billDate",
          COALESCE(NULLIF(b.bill_number, ''), b.id::text) AS "billNumber",
          COALESCE(NULLIF(v.display_name, ''), NULLIF(v.company_name, ''), '-') AS "vendorName",
          COALESCE(
            NULLIF(expense_account.user_account_name, ''),
            NULLIF(expense_account.system_account_name, ''),
            NULLIF(expense_account.account_code, ''),
            ''
          ) AS "expenseAccount",
          COALESCE(NULLIF(blc.allocation_method, ''), '') AS "allocationMethod",
          COALESCE(
            NULLIF(blc.description, ''),
            NULLIF(expense_account.user_account_name, ''),
            NULLIF(expense_account.system_account_name, ''),
            NULLIF(expense_account.account_code, ''),
            ''
          ) AS "description",
          COALESCE(blc.amount, 0)::numeric AS "billTotal",
          0::numeric AS "allocatedAmount",
          COALESCE(blc.amount, 0)::numeric AS "unallocatedAmount"
        FROM bill_landed_costs blc
        JOIN bills b ON b.id = blc.bill_id
        LEFT JOIN vendors v ON v.id = b.vendor_id
        LEFT JOIN accounts expense_account ON expense_account.id = blc.expense_account_id
        WHERE ${whereClause}
      )
      SELECT
        *,
        COUNT(*) OVER()::int AS "__total",
        COALESCE(SUM("billTotal") OVER(), 0)::numeric AS "__totalBillTotal",
        COALESCE(SUM("allocatedAmount") OVER(), 0)::numeric AS "__totalAllocatedAmount",
        COALESCE(SUM("unallocatedAmount") OVER(), 0)::numeric AS "__totalUnallocatedAmount"
      FROM landed_rows
      ORDER BY "billDateRaw" ASC NULLS LAST, "billNumber" ASC, "description" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rawRows = this.rowsFrom(result);
    const firstRow = rawRows[0] ?? {};
    const totals = {
      billTotal: this.parseNumber(firstRow.__totalBillTotal),
      allocatedAmount: this.parseNumber(firstRow.__totalAllocatedAmount),
      unallocatedAmount: this.parseNumber(firstRow.__totalUnallocatedAmount),
    };
    const rows = rawRows.map((row) => {
      const {
        __totalBillTotal,
        __totalAllocatedAmount,
        __totalUnallocatedAmount,
        ...rest
      } = row;
      return {
        ...rest,
        billTotal: this.parseNumber(row.billTotal),
        allocatedAmount: this.parseNumber(row.allocatedAmount),
        unallocatedAmount: this.parseNumber(row.unallocatedAmount),
      };
    });

    return {
      ...this.pageFromRows(rows, pagination),
      totals,
    };
  }
  async stockSummary(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ): Promise<InventoryReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);
    const stockConditions = [sql`ps.entity_id = ${entityId}`];
    const purchaseConditions = [sql`pr.entity_id = ${entityId}`];
    const salesConditions = [
      sql`s.entity_id = ${entityId}`,
      sql`s.is_delete = false`,
      sql`LOWER(COALESCE(s.document_type, '')) NOT LIKE '%credit%'`,
    ];
    const adjustmentConditions = [sql`iai.entity_id = ${entityId}`];

    if (query.warehouseId?.trim()) {
      const warehouseId = query.warehouseId.trim();
      stockConditions.push(sql`ps.warehouse_id = ${warehouseId}`);
      purchaseConditions.push(sql`COALESCE(pri.warehouse_id, pr.warehouse_id) = ${warehouseId}`);
      salesConditions.push(sql`COALESCE(soi.warehouse_id, s.warehouse_id) = ${warehouseId}`);
      adjustmentConditions.push(sql`ia.warehouse_id = ${warehouseId}`);
    }
    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      stockConditions.push(
        sql`(p.product_name ILIKE ${search} OR p.sku ILIKE ${search} OR p.item_code ILIKE ${search})`,
      );
    }
    if (query.startDate?.trim()) {
      const startDate = query.startDate.trim();
      purchaseConditions.push(sql`pr.received_date >= ${startDate}`);
      salesConditions.push(sql`s.sale_date >= ${startDate}`);
      adjustmentConditions.push(sql`ia.adjustment_date >= ${startDate}`);
    }
    if (query.endDate?.trim()) {
      const endDate = query.endDate.includes("T")
        ? query.endDate.trim()
        : `${query.endDate.trim()} 23:59:59`;
      purchaseConditions.push(sql`pr.received_date <= ${query.endDate.trim()}`);
      salesConditions.push(sql`s.sale_date <= ${endDate}`);
      adjustmentConditions.push(sql`ia.adjustment_date <= ${endDate}`);
    }

    const stockWhereClause = sql.join(stockConditions, sql` AND `);
    const purchaseWhereClause = sql.join(purchaseConditions, sql` AND `);
    const salesWhereClause = sql.join(salesConditions, sql` AND `);
    const adjustmentWhereClause = sql.join(adjustmentConditions, sql` AND `);

    const result = await db.execute(sql`
      WITH stock AS (
        SELECT
          ps.product_id,
          SUM(COALESCE(ps.stock_on_hand, 0))::numeric AS closing_stock
        FROM public.v_physical_stock ps
        JOIN products p ON p.id = ps.product_id
        WHERE ${stockWhereClause}
        GROUP BY ps.product_id
      ),
      purchase_in AS (
        SELECT
          pri.item_id AS product_id,
          SUM(COALESCE(pri.received, 0))::numeric AS quantity_in
        FROM purchase_receive_items pri
        JOIN purchase_receives pr ON pr.id = pri.purchase_receive_id
        WHERE ${purchaseWhereClause}
          AND pri.item_id IS NOT NULL
          AND COALESCE(pr.is_delete, false) = false
        GROUP BY pri.item_id
      ),
      sales_out AS (
        SELECT
          soi.product_id,
          SUM(COALESCE(soi.quantity, 0))::numeric AS quantity_out
        FROM sales_order_items soi
        JOIN sales_orders s ON s.id = soi.sales_order_id AND s.entity_id = soi.entity_id
        WHERE ${salesWhereClause}
          AND soi.product_id IS NOT NULL
        GROUP BY soi.product_id
      ),
      adjusted AS (
        SELECT
          iai.product_id,
          SUM(
            CASE
              WHEN COALESCE(iai.quantity_adjusted, 0) > 0 THEN COALESCE(iai.quantity_adjusted, 0)
              ELSE 0
            END
          )::numeric AS adjustment_in,
          SUM(
            CASE
              WHEN COALESCE(iai.quantity_adjusted, 0) < 0 THEN ABS(COALESCE(iai.quantity_adjusted, 0))
              ELSE 0
            END
          )::numeric AS adjustment_out
        FROM inventory_adjustment_items iai
        JOIN inventory_adjustments ia ON ia.id = iai.adjustment_id
        WHERE ${adjustmentWhereClause}
        GROUP BY iai.product_id
      ),
      grouped AS (
        SELECT
          p.id::text AS "itemId",
          p.product_name AS "itemName",
          COALESCE(NULLIF(p.sku, ''), NULLIF(p.item_code, ''), '') AS "sku",
          (COALESCE(s.closing_stock, 0)
            - COALESCE(pi.quantity_in, 0)
            - COALESCE(a.adjustment_in, 0)
            + COALESCE(so.quantity_out, 0)
            + COALESCE(a.adjustment_out, 0))::numeric AS "openingStock",
          (COALESCE(pi.quantity_in, 0) + COALESCE(a.adjustment_in, 0))::numeric AS "quantityIn",
          (COALESCE(so.quantity_out, 0) + COALESCE(a.adjustment_out, 0))::numeric AS "quantityOut",
          COALESCE(s.closing_stock, 0)::numeric AS "closingStock"
        FROM stock s
        JOIN products p ON p.id = s.product_id
        LEFT JOIN purchase_in pi ON pi.product_id = s.product_id
        LEFT JOIN sales_out so ON so.product_id = s.product_id
        LEFT JOIN adjusted a ON a.product_id = s.product_id
      )
      SELECT
        *,
        COUNT(*) OVER()::int AS "__total",
        SUM("openingStock") OVER()::numeric AS "__totalOpeningStock",
        SUM("quantityIn") OVER()::numeric AS "__totalQuantityIn",
        SUM("quantityOut") OVER()::numeric AS "__totalQuantityOut",
        SUM("closingStock") OVER()::numeric AS "__totalClosingStock"
      FROM grouped
      ORDER BY "itemName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rawRows = this.rowsFrom(result);
    const firstRow = rawRows[0] ?? {};
    const totals = {
      openingStock: this.parseNumber(firstRow.__totalOpeningStock),
      quantityIn: this.parseNumber(firstRow.__totalQuantityIn),
      quantityOut: this.parseNumber(firstRow.__totalQuantityOut),
      closingStock: this.parseNumber(firstRow.__totalClosingStock),
    };
    const rows = rawRows.map((row) => {
      const {
        __totalOpeningStock,
        __totalQuantityIn,
        __totalQuantityOut,
        __totalClosingStock,
        ...rest
      } = row;
      return {
        ...rest,
        openingStock: this.parseNumber(row.openingStock),
        quantityIn: this.parseNumber(row.quantityIn),
        quantityOut: this.parseNumber(row.quantityOut),
        closingStock: this.parseNumber(row.closingStock),
      };
    });

    return {
      ...this.pageFromRows(rows, pagination),
      totals,
    };
  }
  async stockMovement(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ): Promise<InventoryReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);
    const filteredConditions = [sql`bt.entity_id = ${entityId}`];
    const openingConditions = [sql`bt.entity_id = ${entityId}`];

    if (query.warehouseId?.trim()) {
      const warehouseId = query.warehouseId.trim();
      filteredConditions.push(sql`bt.warehouse_id = ${warehouseId}`);
      openingConditions.push(sql`bt.warehouse_id = ${warehouseId}`);
    }
    if (query.productId?.trim()) {
      const productId = query.productId.trim();
      filteredConditions.push(sql`bt.product_id = ${productId}`);
      openingConditions.push(sql`bt.product_id = ${productId}`);
    }
    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      filteredConditions.push(
        sql`(p.product_name ILIKE ${search} OR bt.ref_no ILIKE ${search} OR bt.trans_type ILIKE ${search})`,
      );
      openingConditions.push(sql`p.product_name ILIKE ${search}`);
    }
    if (query.startDate?.trim()) {
      const startDate = query.startDate.trim();
      filteredConditions.push(sql`bt.trans_date >= ${startDate}`);
      openingConditions.push(sql`bt.trans_date < ${startDate}`);
    } else {
      openingConditions.push(sql`1 = 0`);
    }
    if (query.endDate?.trim()) {
      const endDate = query.endDate.includes("T")
        ? query.endDate.trim()
        : `${query.endDate.trim()} 23:59:59`;
      filteredConditions.push(sql`bt.trans_date <= ${endDate}`);
      openingConditions.push(sql`bt.trans_date <= ${endDate}`);
    }

    const filteredWhereClause = sql.join(filteredConditions, sql` AND `);
    const openingWhereClause = sql.join(openingConditions, sql` AND `);

    const result = await db.execute(sql`
      WITH opening AS (
        SELECT
          bt.product_id,
          bt.warehouse_id,
          SUM(COALESCE(bt.qty_in, 0) - COALESCE(bt.qty_out, 0))::numeric AS opening_balance
        FROM batch_transactions bt
        LEFT JOIN products p ON p.id = bt.product_id
        WHERE ${openingWhereClause}
        GROUP BY bt.product_id, bt.warehouse_id
      ),
      filtered AS (
        SELECT
          bt.id::text AS "transactionId",
          bt.product_id::text AS "productId",
          bt.warehouse_id::text AS "warehouseId",
          bt.trans_date AS "transactionDateRaw",
          TO_CHAR(bt.trans_date::date, 'DD-MM-YYYY') AS "transactionDate",
          COALESCE(p.product_name, bt.product_id::text) AS "productName",
          COALESCE(w.name, bt.warehouse_id::text) AS "warehouseName",
          COALESCE(NULLIF(bt.trans_type, ''), '-') AS "transactionType",
          COALESCE(NULLIF(bt.ref_no, ''), '-') AS "referenceNo",
          COALESCE(bt.qty_in, 0)::numeric AS "quantityIn",
          COALESCE(bt.qty_out, 0)::numeric AS "quantityOut",
          COALESCE(bt.rate, 0)::numeric AS "rate",
          ((COALESCE(bt.qty_in, 0) - COALESCE(bt.qty_out, 0)) * COALESCE(bt.rate, 0))::numeric AS "value"
        FROM batch_transactions bt
        LEFT JOIN products p ON p.id = bt.product_id
        LEFT JOIN warehouses w ON w.id = bt.warehouse_id
        WHERE ${filteredWhereClause}
      ),
      sequenced AS (
        SELECT
          f.*,
          (
            COALESCE(o.opening_balance, 0) + SUM(f."quantityIn" - f."quantityOut") OVER (
              PARTITION BY f."productId", f."warehouseId"
              ORDER BY f."transactionDateRaw" ASC, f."transactionId" ASC
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )
          )::numeric AS "runningBalance"
        FROM filtered f
        LEFT JOIN opening o
          ON o.product_id::text = f."productId"
         AND o.warehouse_id::text = f."warehouseId"
      )
      SELECT
        *,
        COUNT(*) OVER()::int AS "__total",
        SUM("quantityIn") OVER()::numeric AS "__totalQuantityIn",
        SUM("quantityOut") OVER()::numeric AS "__totalQuantityOut",
        SUM("value") OVER()::numeric AS "__totalValue"
      FROM sequenced
      ORDER BY "transactionDateRaw" ASC, "transactionId" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rawRows = this.rowsFrom(result);
    const firstRow = rawRows[0] ?? {};
    const totals = {
      quantityIn: this.parseNumber(firstRow.__totalQuantityIn),
      quantityOut: this.parseNumber(firstRow.__totalQuantityOut),
      value: this.parseNumber(firstRow.__totalValue),
    };
    const rows = rawRows.map((row) => {
      const {
        __totalQuantityIn,
        __totalQuantityOut,
        __totalValue,
        transactionDateRaw,
        ...rest
      } = row;
      return {
        ...rest,
        quantityIn: this.parseNumber(row.quantityIn),
        quantityOut: this.parseNumber(row.quantityOut),
        runningBalance: this.parseNumber(row.runningBalance),
        rate: this.parseNumber(row.rate),
        value: this.parseNumber(row.value),
      };
    });

    return {
      ...this.pageFromRows(rows, pagination),
      totals,
    };
  }
  async inventoryTurnoverByQuantity(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ): Promise<InventoryReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);
    const stockConditions = [sql`ps.entity_id = ${entityId}`];
    const purchaseConditions = [sql`pr.entity_id = ${entityId}`];
    const salesConditions = [
      sql`s.entity_id = ${entityId}`,
      sql`s.is_delete = false`,
      sql`LOWER(COALESCE(s.document_type, '')) NOT LIKE '%credit%'`,
    ];
    const adjustmentConditions = [sql`iai.entity_id = ${entityId}`];

    if (query.warehouseId?.trim()) {
      const warehouseId = query.warehouseId.trim();
      stockConditions.push(sql`ps.warehouse_id = ${warehouseId}`);
      purchaseConditions.push(sql`COALESCE(pri.warehouse_id, pr.warehouse_id) = ${warehouseId}`);
      salesConditions.push(sql`COALESCE(soi.warehouse_id, s.warehouse_id) = ${warehouseId}`);
      adjustmentConditions.push(sql`ia.warehouse_id = ${warehouseId}`);
    }
    if (query.productId?.trim()) {
      const productId = query.productId.trim();
      stockConditions.push(sql`ps.product_id = ${productId}`);
      purchaseConditions.push(sql`pri.item_id = ${productId}`);
      salesConditions.push(sql`soi.product_id = ${productId}`);
      adjustmentConditions.push(sql`iai.product_id = ${productId}`);
    }
    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      stockConditions.push(
        sql`(p.product_name ILIKE ${search} OR p.sku ILIKE ${search} OR p.item_code ILIKE ${search})`,
      );
    }
    if (query.startDate?.trim()) {
      const startDate = query.startDate.trim();
      purchaseConditions.push(sql`pr.received_date >= ${startDate}`);
      salesConditions.push(sql`s.sale_date >= ${startDate}`);
      adjustmentConditions.push(sql`ia.adjustment_date >= ${startDate}`);
    }
    if (query.endDate?.trim()) {
      const endDate = query.endDate.includes("T")
        ? query.endDate.trim()
        : `${query.endDate.trim()} 23:59:59`;
      purchaseConditions.push(sql`pr.received_date <= ${query.endDate.trim()}`);
      salesConditions.push(sql`s.sale_date <= ${endDate}`);
      adjustmentConditions.push(sql`ia.adjustment_date <= ${endDate}`);
    }

    const stockWhereClause = sql.join(stockConditions, sql` AND `);
    const purchaseWhereClause = sql.join(purchaseConditions, sql` AND `);
    const salesWhereClause = sql.join(salesConditions, sql` AND `);
    const adjustmentWhereClause = sql.join(adjustmentConditions, sql` AND `);

    const result = await db.execute(sql`
      WITH report_dates AS (
        SELECT
          COALESCE(NULLIF(${query.startDate ?? ""}, '')::date, CURRENT_DATE) AS start_date,
          COALESCE(NULLIF(${query.endDate ?? ""}, '')::date, CURRENT_DATE) AS end_date
      ),
      stock AS (
        SELECT
          ps.product_id,
          SUM(COALESCE(ps.stock_on_hand, 0))::numeric AS closing_stock
        FROM public.v_physical_stock ps
        JOIN products p ON p.id = ps.product_id
        WHERE ${stockWhereClause}
        GROUP BY ps.product_id
      ),
      purchase_in AS (
        SELECT
          pri.item_id AS product_id,
          SUM(COALESCE(pri.received, 0))::numeric AS quantity_in
        FROM purchase_receive_items pri
        JOIN purchase_receives pr ON pr.id = pri.purchase_receive_id
        WHERE ${purchaseWhereClause}
          AND pri.item_id IS NOT NULL
          AND COALESCE(pr.is_delete, false) = false
        GROUP BY pri.item_id
      ),
      sales_out AS (
        SELECT
          soi.product_id,
          SUM(COALESCE(soi.quantity, 0))::numeric AS quantity_sold
        FROM sales_order_items soi
        JOIN sales_orders s ON s.id = soi.sales_order_id AND s.entity_id = soi.entity_id
        WHERE ${salesWhereClause}
          AND soi.product_id IS NOT NULL
        GROUP BY soi.product_id
      ),
      adjusted AS (
        SELECT
          iai.product_id,
          SUM(
            CASE
              WHEN COALESCE(iai.quantity_adjusted, 0) > 0 THEN COALESCE(iai.quantity_adjusted, 0)
              ELSE 0
            END
          )::numeric AS adjustment_in,
          SUM(
            CASE
              WHEN COALESCE(iai.quantity_adjusted, 0) < 0 THEN ABS(COALESCE(iai.quantity_adjusted, 0))
              ELSE 0
            END
          )::numeric AS adjustment_out
        FROM inventory_adjustment_items iai
        JOIN inventory_adjustments ia ON ia.id = iai.adjustment_id
        WHERE ${adjustmentWhereClause}
        GROUP BY iai.product_id
      ),
      calculated AS (
        SELECT
          p.id::text AS "itemId",
          p.product_name AS "itemName",
          (COALESCE(s.closing_stock, 0)
            - COALESCE(pi.quantity_in, 0)
            - COALESCE(a.adjustment_in, 0)
            + COALESCE(so.quantity_sold, 0)
            + COALESCE(a.adjustment_out, 0))::numeric AS "openingStock",
          COALESCE(s.closing_stock, 0)::numeric AS "closingStock",
          COALESCE(so.quantity_sold, 0)::numeric AS "quantitySold",
          GREATEST((rd.end_date - rd.start_date) + 1, 0)::numeric AS "periodDays"
        FROM stock s
        JOIN products p ON p.id = s.product_id
        CROSS JOIN report_dates rd
        LEFT JOIN purchase_in pi ON pi.product_id = s.product_id
        LEFT JOIN sales_out so ON so.product_id = s.product_id
        LEFT JOIN adjusted a ON a.product_id = s.product_id
      ),
      grouped AS (
        SELECT
          *,
          (("openingStock" + "closingStock") / 2)::numeric AS "averageQuantity",
          CASE
            WHEN (("openingStock" + "closingStock") / 2) = 0 THEN 0
            ELSE ("quantitySold" / (("openingStock" + "closingStock") / 2))
          END::numeric AS "turnOverRatio"
        FROM calculated
      ),
      final_rows AS (
        SELECT
          *,
          CASE
            WHEN "turnOverRatio" = 0 THEN 0
            ELSE ("periodDays" / "turnOverRatio")
          END::numeric AS "averageTurnoverDays"
        FROM grouped
      )
      SELECT
        *,
        COUNT(*) OVER()::int AS "__total",
        SUM("openingStock") OVER()::numeric AS "__totalOpeningStock",
        SUM("closingStock") OVER()::numeric AS "__totalClosingStock",
        SUM("quantitySold") OVER()::numeric AS "__totalQuantitySold",
        SUM("averageQuantity") OVER()::numeric AS "__totalAverageQuantity",
        CASE
          WHEN SUM("averageQuantity") OVER() = 0 THEN 0
          ELSE SUM("quantitySold") OVER() / SUM("averageQuantity") OVER()
        END::numeric AS "__totalTurnOverRatio"
      FROM final_rows
      ORDER BY "itemName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rawRows = this.rowsFrom(result);
    const firstRow = rawRows[0] ?? {};
    const totalRatio = this.parseNumber(firstRow.__totalTurnOverRatio);
    const periodDays = this.parseNumber(firstRow.periodDays);
    const totals = {
      openingStock: this.parseNumber(firstRow.__totalOpeningStock),
      closingStock: this.parseNumber(firstRow.__totalClosingStock),
      quantitySold: this.parseNumber(firstRow.__totalQuantitySold),
      averageQuantity: this.parseNumber(firstRow.__totalAverageQuantity),
      turnOverRatio: totalRatio,
      averageTurnoverDays: totalRatio === 0 ? 0 : periodDays / totalRatio,
    };
    const rows = rawRows.map((row) => {
      const {
        __totalOpeningStock,
        __totalClosingStock,
        __totalQuantitySold,
        __totalAverageQuantity,
        __totalTurnOverRatio,
        periodDays,
        ...rest
      } = row;
      return {
        ...rest,
        openingStock: this.parseNumber(row.openingStock),
        closingStock: this.parseNumber(row.closingStock),
        quantitySold: this.parseNumber(row.quantitySold),
        averageQuantity: this.parseNumber(row.averageQuantity),
        turnOverRatio: this.parseNumber(row.turnOverRatio),
        averageTurnoverDays: this.parseNumber(row.averageTurnoverDays),
      };
    });

    return {
      ...this.pageFromRows(rows, pagination),
      totals,
    };
  }
  async inventoryAdjustmentSummary(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ): Promise<InventoryReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);
    const conditions = [sql`ia.entity_id = ${entityId}`];

    if (query.warehouseId?.trim()) {
      conditions.push(sql`ia.warehouse_id = ${query.warehouseId.trim()}`);
    }
    if (query.productId?.trim()) {
      conditions.push(sql`ia.product_id = ${query.productId.trim()}`);
    }
    if (query.status?.trim()) {
      conditions.push(
        sql`LOWER(COALESCE(ia.status::text, '')) = LOWER(${query.status.trim()})`,
      );
    }
    if (query.startDate?.trim()) {
      conditions.push(sql`ia.adjustment_date >= ${query.startDate.trim()}`);
    }
    if (query.endDate?.trim()) {
      const endDate = query.endDate.includes("T")
        ? query.endDate.trim()
        : `${query.endDate.trim()} 23:59:59`;
      conditions.push(sql`ia.adjustment_date <= ${endDate}`);
    }
    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        ia.adjustment_number ILIKE ${search}
        OR ia.reference_number ILIKE ${search}
        OR ia.reason ILIKE ${search}
        OR ia.status::text ILIKE ${search}
        OR ia.adjustment_type::text ILIKE ${search}
        OR p.product_name ILIKE ${search}
        OR w.name ILIKE ${search}
      )`);
    }

    const whereClause = sql.join(conditions, sql` AND `);

    const result = await db.execute(sql`
      WITH grouped AS (
        SELECT
          ia.id::text AS "adjustmentId",
          COALESCE(NULLIF(ia.reference_number, ''), '') AS "referenceNumber",
          COALESCE(NULLIF(ia.adjustment_number, ''), ia.id::text) AS "adjustmentNumber",
          TO_CHAR(ia.adjustment_date::date, 'DD-MM-YYYY') AS "date",
          INITCAP(REPLACE(COALESCE(NULLIF(ia.status::text, ''), '-'), '_', ' ')) AS "status",
          COALESCE(NULLIF(ia.reason, ''), '-') AS "inventoryAdjustment",
          INITCAP(REPLACE(COALESCE(NULLIF(ia.adjustment_type::text, ''), '-'), '_', ' ')) AS "adjustmentType",
          COALESCE(p.product_name, '') AS "productName",
          COALESCE(w.name, '') AS "warehouseName",
          CASE
            WHEN COALESCE(ia.quantity_adjusted, 0) > 0 THEN COALESCE(ia.quantity_adjusted, 0)
            ELSE 0
          END::numeric AS "quantityIncreased",
          CASE
            WHEN COALESCE(ia.quantity_adjusted, 0) < 0 THEN ABS(COALESCE(ia.quantity_adjusted, 0))
            ELSE 0
          END::numeric AS "quantityDecreased",
          CASE
            WHEN COALESCE(ia.adjustment_value, 0) > 0 THEN COALESCE(ia.adjustment_value, 0)
            ELSE 0
          END::numeric AS "valueIncreased",
          CASE
            WHEN COALESCE(ia.adjustment_value, 0) < 0 THEN ABS(COALESCE(ia.adjustment_value, 0))
            ELSE 0
          END::numeric AS "valueDecreased",
          ia.adjustment_date AS "sortDate"
        FROM inventory_adjustments ia
        LEFT JOIN products p ON p.id = ia.product_id
        LEFT JOIN warehouses w ON w.id = ia.warehouse_id
        WHERE ${whereClause}
      )
      SELECT
        *,
        COUNT(*) OVER()::int AS "__total",
        SUM("quantityIncreased") OVER()::numeric AS "__totalQuantityIncreased",
        SUM("quantityDecreased") OVER()::numeric AS "__totalQuantityDecreased",
        SUM("valueIncreased") OVER()::numeric AS "__totalValueIncreased",
        SUM("valueDecreased") OVER()::numeric AS "__totalValueDecreased"
      FROM grouped
      ORDER BY "sortDate" ASC, "adjustmentNumber" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rawRows = this.rowsFrom(result);
    const firstRow = rawRows[0] ?? {};
    const totals = {
      quantityIncreased: this.parseNumber(firstRow.__totalQuantityIncreased),
      quantityDecreased: this.parseNumber(firstRow.__totalQuantityDecreased),
      valueIncreased: this.parseNumber(firstRow.__totalValueIncreased),
      valueDecreased: this.parseNumber(firstRow.__totalValueDecreased),
    };
    const rows = rawRows.map((row) => {
      const {
        __totalQuantityIncreased,
        __totalQuantityDecreased,
        __totalValueIncreased,
        __totalValueDecreased,
        sortDate,
        ...rest
      } = row;
      return {
        ...rest,
        quantityIncreased: this.parseNumber(row.quantityIncreased),
        quantityDecreased: this.parseNumber(row.quantityDecreased),
        valueIncreased: this.parseNumber(row.valueIncreased),
        valueDecreased: this.parseNumber(row.valueDecreased),
      };
    });

    return {
      ...this.pageFromRows(rows, pagination),
      totals,
    };
  }
  async inventoryAdjustmentDetails(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ): Promise<InventoryReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);
    const conditions = [
      sql`ia.entity_id = ${entityId}`,
      sql`iai.entity_id = ${entityId}`,
    ];

    if (query.warehouseId?.trim()) {
      conditions.push(sql`ia.warehouse_id = ${query.warehouseId.trim()}`);
    }
    if (query.productId?.trim()) {
      conditions.push(sql`iai.product_id = ${query.productId.trim()}`);
    }
    if (query.status?.trim()) {
      conditions.push(
        sql`LOWER(COALESCE(ia.status::text, '')) = LOWER(${query.status.trim()})`,
      );
    }
    if (query.startDate?.trim()) {
      conditions.push(sql`ia.adjustment_date >= ${query.startDate.trim()}`);
    }
    if (query.endDate?.trim()) {
      const endDate = query.endDate.includes("T")
        ? query.endDate.trim()
        : `${query.endDate.trim()} 23:59:59`;
      conditions.push(sql`ia.adjustment_date <= ${endDate}`);
    }
    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        ia.adjustment_number ILIKE ${search}
        OR ia.reference_number ILIKE ${search}
        OR ia.reason ILIKE ${search}
        OR ia.status::text ILIKE ${search}
        OR ia.adjustment_type::text ILIKE ${search}
        OR p.product_name ILIKE ${search}
        OR w.name ILIKE ${search}
      )`);
    }

    const whereClause = sql.join(conditions, sql` AND `);

    const result = await db.execute(sql`
      WITH detail_rows AS (
        SELECT
          ia.id::text AS "adjustmentId",
          iai.id::text AS "adjustmentItemId",
          COALESCE(NULLIF(ia.reference_number, ''), '') AS "referenceNumber",
          COALESCE(NULLIF(ia.adjustment_number, ''), ia.id::text) AS "adjustmentNumber",
          TO_CHAR(ia.adjustment_date::date, 'DD-MM-YYYY') AS "date",
          INITCAP(REPLACE(COALESCE(NULLIF(ia.status::text, ''), '-'), '_', ' ')) AS "status",
          COALESCE(NULLIF(ia.reason, ''), '-') AS "inventoryAdjustment",
          INITCAP(REPLACE(COALESCE(NULLIF(ia.adjustment_type::text, ''), '-'), '_', ' ')) AS "adjustmentType",
          COALESCE(p.product_name, iai.product_id::text, '') AS "productName",
          COALESCE(w.name, '') AS "warehouseName",
          COALESCE(iai.quantity_adjusted, 0)::numeric AS "quantityAdjusted",
          COALESCE(iai.adjustment_value, 0)::numeric AS "valueAdjusted",
          ia.adjustment_date AS "sortDate"
        FROM inventory_adjustment_items iai
        JOIN inventory_adjustments ia ON ia.id = iai.adjustment_id
        LEFT JOIN products p ON p.id = iai.product_id
        LEFT JOIN warehouses w ON w.id = ia.warehouse_id
        WHERE ${whereClause}
      )
      SELECT
        *,
        COUNT(*) OVER()::int AS "__total",
        SUM("quantityAdjusted") OVER()::numeric AS "__totalQuantityAdjusted",
        SUM("valueAdjusted") OVER()::numeric AS "__totalValueAdjusted"
      FROM detail_rows
      ORDER BY "sortDate" ASC, "adjustmentNumber" ASC, "productName" ASC, "adjustmentItemId" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rawRows = this.rowsFrom(result);
    const firstRow = rawRows[0] ?? {};
    const totals = {
      quantityAdjusted: this.parseNumber(firstRow.__totalQuantityAdjusted),
      valueAdjusted: this.parseNumber(firstRow.__totalValueAdjusted),
    };
    const rows = rawRows.map((row) => {
      const {
        __totalQuantityAdjusted,
        __totalValueAdjusted,
        sortDate,
        ...rest
      } = row;
      return {
        ...rest,
        quantityAdjusted: this.parseNumber(row.quantityAdjusted),
        valueAdjusted: this.parseNumber(row.valueAdjusted),
      };
    });

    return {
      ...this.pageFromRows(rows, pagination),
      totals,
    };
  }

  private quoteIdentifier(identifier: string): string {
    return `"${identifier.replace(/"/g, '""')}"`;
  }

  private columnRef(alias: string, column: string) {
    return sql.raw(`${alias}.${this.quoteIdentifier(column)}`);
  }

  private async getTableColumns(tableName: string): Promise<Set<string>> {
    const result = await db.execute(sql`
      SELECT column_name
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = ${tableName}
    `);

    return new Set(
      this.rowsFrom(result).map((row) => String(row.column_name ?? '')),
    );
  }

  private pickColumn(
    columns: Set<string>,
    candidates: string[],
  ): string | undefined {
    return candidates.find((column) => columns.has(column));
  }

  private async resolveDeliveryChallanCommittedStockSchema() {
    const headerTable = 'delivery_challans';
    const itemTable = 'delivery_challan_items';
    const headerColumns = await this.getTableColumns(headerTable);
    const itemColumns = await this.getTableColumns(itemTable);

    if (headerColumns.size === 0 || itemColumns.size === 0) return null;

    const headerIdColumn = this.pickColumn(headerColumns, ['id']);
    const headerEntityColumn = this.pickColumn(headerColumns, ['entity_id']);
    const itemEntityColumn = this.pickColumn(itemColumns, ['entity_id']);
    const itemChallanColumn = this.pickColumn(itemColumns, [
      'delivery_challan_id',
      'challan_id',
    ]);
    const itemProductColumn = this.pickColumn(itemColumns, [
      'product_id',
      'item_id',
    ]);
    const itemQuantityColumn = this.pickColumn(itemColumns, [
      'quantity',
      'delivered_quantity',
      'qty',
    ]);

    if (
      !headerIdColumn ||
      !headerEntityColumn ||
      !itemChallanColumn ||
      !itemProductColumn ||
      !itemQuantityColumn
    ) {
      return null;
    }

    return {
      headerTable,
      itemTable,
      headerIdColumn,
      headerEntityColumn,
      headerWarehouseColumn: this.pickColumn(headerColumns, ['warehouse_id']),
      headerNumberColumn: this.pickColumn(headerColumns, [
        'delivery_challan_number',
        'challan_number',
        'dc_number',
        'reference_number',
      ]),
      headerReferenceColumn: this.pickColumn(headerColumns, ['reference']),
      headerDateColumn: this.pickColumn(headerColumns, [
        'challan_date',
        'delivery_challan_date',
        'delivery_date',
        'date',
        'created_at',
      ]),
      headerDeleteColumn: this.pickColumn(headerColumns, [
        'is_delete',
        'is_deleted',
      ]),
      itemEntityColumn,
      itemChallanColumn,
      itemProductColumn,
      itemQuantityColumn,
      itemWarehouseColumn: this.pickColumn(itemColumns, ['warehouse_id']),
    };
  }

  async committedStockDetails(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ): Promise<InventoryReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);
    const salesOrderConditions = [
      sql`s.entity_id = ${entityId}`,
      sql`soi.entity_id = ${entityId}`,
      sql`s.is_delete = false`,
      sql`LOWER(TRIM(COALESCE(s.status, ''))) = 'confirmed'`,
      sql`LOWER(COALESCE(s.document_type, '')) NOT LIKE '%credit%'`,
      sql`COALESCE(soi.quantity, 0) <> 0`,
    ];

    const deliveryChallanSchema =
      await this.resolveDeliveryChallanCommittedStockSchema();
    const deliveryChallanConditions = [];

    if (query.warehouseId?.trim()) {
      const warehouseId = query.warehouseId.trim();
      salesOrderConditions.push(
        sql`COALESCE(soi.warehouse_id, s.warehouse_id) = ${warehouseId}`,
      );
      if (deliveryChallanSchema) {
        const itemWarehouse = deliveryChallanSchema.itemWarehouseColumn
          ? this.columnRef('dci', deliveryChallanSchema.itemWarehouseColumn)
          : sql`NULL`;
        const headerWarehouse = deliveryChallanSchema.headerWarehouseColumn
          ? this.columnRef('dc', deliveryChallanSchema.headerWarehouseColumn)
          : sql`NULL`;
        deliveryChallanConditions.push(
          sql`COALESCE(${itemWarehouse}, ${headerWarehouse}) = ${warehouseId}`,
        );
      }
    }
    if (query.startDate?.trim()) {
      const startDate = query.startDate.trim();
      salesOrderConditions.push(sql`s.sale_date >= ${startDate}`);
      if (deliveryChallanSchema?.headerDateColumn) {
        deliveryChallanConditions.push(
          sql`${this.columnRef('dc', deliveryChallanSchema.headerDateColumn)} >= ${startDate}`,
        );
      }
    }
    if (query.endDate?.trim()) {
      const endDate = query.endDate.includes('T')
        ? query.endDate.trim()
        : `${query.endDate.trim()} 23:59:59`;
      salesOrderConditions.push(sql`s.sale_date <= ${endDate}`);
      if (deliveryChallanSchema?.headerDateColumn) {
        deliveryChallanConditions.push(
          sql`${this.columnRef('dc', deliveryChallanSchema.headerDateColumn)} <= ${endDate}`,
        );
      }
    }
    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      salesOrderConditions.push(
        sql`(p.product_name ILIKE ${search} OR s.sale_number ILIKE ${search} OR s.reference ILIKE ${search})`,
      );
      if (deliveryChallanSchema) {
        const searchFields = [sql`p.product_name ILIKE ${search}`];
        if (deliveryChallanSchema.headerNumberColumn) {
          searchFields.push(
            sql`${this.columnRef('dc', deliveryChallanSchema.headerNumberColumn)} ILIKE ${search}`,
          );
        }
        if (deliveryChallanSchema.headerReferenceColumn) {
          searchFields.push(
            sql`${this.columnRef('dc', deliveryChallanSchema.headerReferenceColumn)} ILIKE ${search}`,
          );
        }
        deliveryChallanConditions.push(
          sql`(${sql.join(searchFields, sql` OR `)})`,
        );
      }
    }

    let deliveryChallanSelect = sql``;
    if (deliveryChallanSchema) {
      deliveryChallanConditions.unshift(
        sql`${this.columnRef('dc', deliveryChallanSchema.headerEntityColumn)} = ${entityId}`,
        sql`COALESCE(${this.columnRef('dci', deliveryChallanSchema.itemQuantityColumn)}, 0) <> 0`,
      );
      if (deliveryChallanSchema.itemEntityColumn) {
        deliveryChallanConditions.push(
          sql`${this.columnRef('dci', deliveryChallanSchema.itemEntityColumn)} = ${entityId}`,
        );
      }
      if (deliveryChallanSchema.headerDeleteColumn) {
        deliveryChallanConditions.push(
          sql`COALESCE(${this.columnRef('dc', deliveryChallanSchema.headerDeleteColumn)}, false) = false`,
        );
      }

      const deliveryWhereClause = sql.join(
        deliveryChallanConditions,
        sql` AND `,
      );
      const transactionNumber = deliveryChallanSchema.headerNumberColumn
        ? deliveryChallanSchema.headerReferenceColumn
          ? sql`COALESCE(NULLIF(${this.columnRef('dc', deliveryChallanSchema.headerNumberColumn)}, ''), NULLIF(${this.columnRef('dc', deliveryChallanSchema.headerReferenceColumn)}, ''), ${this.columnRef('dc', deliveryChallanSchema.headerIdColumn)}::text)`
          : sql`COALESCE(NULLIF(${this.columnRef('dc', deliveryChallanSchema.headerNumberColumn)}, ''), ${this.columnRef('dc', deliveryChallanSchema.headerIdColumn)}::text)`
        : sql`${this.columnRef('dc', deliveryChallanSchema.headerIdColumn)}::text`;
      const sortDate = deliveryChallanSchema.headerDateColumn
        ? sql`${this.columnRef('dc', deliveryChallanSchema.headerDateColumn)}`
        : sql`NULL::timestamp`;

      deliveryChallanSelect = sql`
        UNION ALL
        SELECT
          ${transactionNumber} AS "transactionNumber",
          p.product_name AS "itemName",
          COALESCE(${this.columnRef('dci', deliveryChallanSchema.itemQuantityColumn)}, 0)::numeric AS "committedStock",
          ${sortDate} AS "sortDate",
          NULL::text AS "salesperson",
          'Delivery Challan'::text AS "orderType",
          CASE WHEN ${sortDate} IS NOT NULL THEN to_char(${sortDate}::date, 'DD-MM-YYYY') ELSE NULL END AS "date",
          NULL::text AS "customerName"
        FROM ${sql.raw(this.quoteIdentifier(deliveryChallanSchema.headerTable))} dc
        JOIN ${sql.raw(this.quoteIdentifier(deliveryChallanSchema.itemTable))} dci
          ON ${this.columnRef('dci', deliveryChallanSchema.itemChallanColumn)} = ${this.columnRef('dc', deliveryChallanSchema.headerIdColumn)}
        JOIN products p ON p.id = ${this.columnRef('dci', deliveryChallanSchema.itemProductColumn)}
        WHERE ${deliveryWhereClause}
      `;
    }

    const salesOrderWhereClause = sql.join(salesOrderConditions, sql` AND `);

    const result = await db.execute(sql`
      WITH grouped AS (
        SELECT
          COALESCE(NULLIF(s.sale_number, ''), NULLIF(s.reference, ''), s.id::text) AS "transactionNumber",
          p.product_name AS "itemName",
          COALESCE(soi.quantity, 0)::numeric AS "committedStock",
          s.sale_date AS "sortDate",
          COALESCE(NULLIF(TRIM(u.full_name), ''), '') AS "salesperson",
          COALESCE(NULLIF(TRIM(s.document_type), ''), 'Sales Order') AS "orderType",
          to_char(s.sale_date::date, 'DD-MM-YYYY') AS "date",
          COALESCE(NULLIF(TRIM(c.display_name), ''), '') AS "customerName"
        FROM sales_orders s
        JOIN sales_order_items soi ON soi.sales_order_id = s.id AND soi.entity_id = s.entity_id
        JOIN products p ON p.id = soi.product_id
        LEFT JOIN customers c ON c.id = s.customer_id
        LEFT JOIN users u ON u.id = NULLIF(s.salesperson_id, '')::uuid
        WHERE ${salesOrderWhereClause}
        ${deliveryChallanSelect}
      )
      SELECT "transactionNumber", "itemName", "committedStock", "salesperson", "orderType", "date", "customerName", COUNT(*) OVER()::int AS "__total"
      FROM grouped
      ORDER BY "sortDate" ASC NULLS LAST, "transactionNumber" ASC, "itemName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      committedStock: this.parseNumber(row.committedStock),
    }));

    return this.pageFromRows(rows, pagination);
  }
  async assemblyDetails(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ): Promise<InventoryReportPage<Record<string, unknown>>> {
    const pagination = this.normalizePagination(query);
    const conditions = [sql`LOWER(COALESCE(ci.type::text, '')) = 'assembly'`];

    if (query.startDate?.trim()) {
      conditions.push(sql`ci.created_at >= ${query.startDate.trim()}`);
    }

    if (query.endDate?.trim()) {
      const endDate = query.endDate.includes("T")
        ? query.endDate.trim()
        : `${query.endDate.trim()} 23:59:59`;
      conditions.push(sql`ci.created_at <= ${endDate}`);
    }

    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(sql`(
        ci.product_name ILIKE ${search}
        OR ci.sku ILIKE ${search}
        OR p.product_name ILIKE ${search}
      )`);
    }

    const whereClause = sql.join(conditions, sql` AND `);

    const result = await db.execute(sql`
      WITH assembly_rows AS (
        SELECT
          COALESCE(NULLIF(ci.sku, ''), ci.id::text) AS "transactionNumber",
          ci.product_name AS "assemblyName",
          1::numeric AS "quantityAssembled",
          COALESCE(NULLIF(p.product_name, ''), '-') AS "componentName",
          COALESCE(cip.quantity, 0)::numeric AS "quantityConsumed",
          ci.created_at AS "date",
          CASE
            WHEN COALESCE(ci.is_active, true) THEN 'Active'
            ELSE 'Inactive'
          END AS "status",
          (COALESCE(cip.quantity, 0) * COALESCE(cip.cost_price_override, p.cost_price, 0))::numeric AS "totalCost",
          COALESCE(NULLIF(ci.hsn_code, ''), '-') AS "hsnSac",
          COALESCE(NULLIF(p.hsn_sac_code, ''), '-') AS "componentHsnSac"
        FROM composite_items ci
        LEFT JOIN composite_item_parts cip ON cip.composite_item_id = ci.id
        LEFT JOIN products p ON p.id = cip.component_product_id
        WHERE ${whereClause}
      )
      SELECT
        "transactionNumber",
        "assemblyName",
        "quantityAssembled",
        "componentName",
        "quantityConsumed",
        "date",
        "status",
        "totalCost",
        "hsnSac",
        "componentHsnSac",
        COUNT(*) OVER()::int AS "__total"
      FROM assembly_rows
      ORDER BY "date" ASC NULLS LAST, "assemblyName" ASC, "componentName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const rows = this.rowsFrom(result).map((row) => ({
      ...row,
      quantityAssembled: this.parseNumber(row.quantityAssembled),
      quantityConsumed: this.parseNumber(row.quantityConsumed),
      totalCost: this.parseNumber(row.totalCost),
    }));

    return this.pageFromRows(rows, pagination);
  }
  async fifoCostLotTracking(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ): Promise<InventoryReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);
    const conditions = [sql`bt.entity_id = ${entityId}`];

    if (query.warehouseId?.trim()) {
      conditions.push(sql`bt.warehouse_id = ${query.warehouseId.trim()}`);
    }
    if (query.productId?.trim()) {
      conditions.push(sql`bt.product_id = ${query.productId.trim()}`);
    }
    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      conditions.push(
        sql`(p.product_name ILIKE ${search} OR bt.ref_no ILIKE ${search} OR bt.trans_type ILIKE ${search})`,
      );
    }

    const whereClause = sql.join(conditions, sql` AND `);
    const result = await db.execute(sql`
      WITH movements AS (
        SELECT
          bt.id::text AS "transactionId",
          bt.product_id::text AS "productId",
          bt.warehouse_id::text AS "warehouseId",
          bt.trans_date AS "transactionDateRaw",
          TO_CHAR(bt.trans_date::date, 'DD-MM-YYYY') AS "transactionDate",
          LOWER(REPLACE(COALESCE(bt.trans_type, ''), ' ', '_')) AS "normalizedType",
          COALESCE(NULLIF(bt.trans_type, ''), '-') AS "transactionType",
          COALESCE(NULLIF(bt.ref_no, ''), '') AS "referenceNo",
          COALESCE(p.product_name, bt.product_id::text) AS "itemName",
          COALESCE(u.unit_symbol, u.unit_name, 'pcs') AS "unit",
          COALESCE(bt.qty_in, 0)::numeric AS "quantityIn",
          COALESCE(bt.qty_out, 0)::numeric AS "quantityOut",
          COALESCE(bt.rate, p.cost_price, 0)::numeric AS "rate",
          CASE
            WHEN LOWER(REPLACE(COALESCE(bt.trans_type, ''), ' ', '_')) IN ('bill', 'bills') THEN COALESCE(NULLIF(bv.display_name, ''), NULLIF(bv.company_name, ''), '')
            WHEN LOWER(REPLACE(COALESCE(bt.trans_type, ''), ' ', '_')) IN ('purchase_order', 'purchase_orders') THEN COALESCE(NULLIF(pov.display_name, ''), NULLIF(pov.company_name, ''), '')
            WHEN LOWER(REPLACE(COALESCE(bt.trans_type, ''), ' ', '_')) IN ('purchase_receive', 'purchase_receives') THEN COALESCE(NULLIF(prv.display_name, ''), NULLIF(prv.company_name, ''), '')
            WHEN LOWER(REPLACE(COALESCE(bt.trans_type, ''), ' ', '_')) IN ('vendor_credit', 'vendor_credits') THEN COALESCE(NULLIF(vcv.display_name, ''), NULLIF(vcv.company_name, ''), '')
            WHEN LOWER(REPLACE(COALESCE(bt.trans_type, ''), ' ', '_')) IN ('purchase_return', 'purchase_returns') THEN COALESCE(NULLIF(prv2.display_name, ''), NULLIF(prv2.company_name, ''), '')
            WHEN LOWER(REPLACE(COALESCE(bt.trans_type, ''), ' ', '_')) IN ('credit_note', 'credit_notes') THEN COALESCE(NULLIF(cnc.display_name, ''), NULLIF(cnc.company_name, ''), '')
            WHEN LOWER(REPLACE(COALESCE(bt.trans_type, ''), ' ', '_')) IN ('invoice', 'invoices') THEN COALESCE(NULLIF(imc.display_name, ''), NULLIF(imc.company_name, ''), '')
            ELSE ''
          END AS "partyName"
        FROM batch_transactions bt
        LEFT JOIN products p ON p.id = bt.product_id
        LEFT JOIN units u ON u.id = p.unit_id
        LEFT JOIN bills b ON b.id = bt.ref_id
        LEFT JOIN vendors bv ON bv.id = b.vendor_id
        LEFT JOIN purchase_orders po ON po.id = bt.ref_id
        LEFT JOIN vendors pov ON pov.id = po.vendor_id
        LEFT JOIN purchase_receives prcv ON prcv.id = bt.ref_id
        LEFT JOIN purchase_orders prpo ON prpo.id = prcv.purchase_order_id
        LEFT JOIN vendors prv ON prv.id = prpo.vendor_id
        LEFT JOIN vendor_credits vc ON vc.id = bt.ref_id
        LEFT JOIN vendors vcv ON vcv.id = vc.vendor_id
        LEFT JOIN purchase_returns pr ON pr.id = bt.ref_id
        LEFT JOIN vendors prv2 ON prv2.id = pr.vendor_id
        LEFT JOIN credit_notes cn ON cn.id = bt.ref_id
        LEFT JOIN customers cnc ON cnc.id = cn.customer_id
        LEFT JOIN invoice_master im ON im.id = bt.ref_id
        LEFT JOIN customers imc ON imc.id = im.customer_id
        WHERE ${whereClause}
          AND (
            CASE
              WHEN LOWER(REPLACE(COALESCE(bt.trans_type, ''), ' ', '_')) IN ('bill', 'bills')
                THEN COALESCE(b.is_delete, false) = false
              WHEN LOWER(REPLACE(COALESCE(bt.trans_type, ''), ' ', '_')) IN ('invoice', 'invoices')
                THEN COALESCE(im.is_delete, false) = false
              ELSE true
            END
          )
      )
      SELECT *
      FROM movements
      WHERE "quantityIn" <> 0 OR "quantityOut" <> 0
      ORDER BY
        "transactionDateRaw" ASC,
        CASE WHEN "quantityIn" > 0 THEN 0 ELSE 1 END ASC,
        "transactionId" ASC
    `);

    const displayStart = query.startDate?.trim()
      ? new Date(query.startDate.trim())
      : null;
    const displayEnd = query.endDate?.trim()
      ? new Date(query.endDate.includes("T") ? query.endDate.trim() : `${query.endDate.trim()}T23:59:59`)
      : null;
    type FifoLot = {
      source: Record<string, unknown>;
      remaining: number;
      displayInRange: boolean;
      hasDisplayAllocation: boolean;
    };

    const lotQueues = new Map<string, { head: number; lots: FifoLot[] }>();
    const allocationRows: Record<string, unknown>[] = [];
    let productInCount = 0;
    let productOutCount = 0;
    let totalReceivedQuantity = 0;
    let totalDispersedQuantity = 0;

    const inDisplayRange = (value: unknown): boolean => {
      const date = new Date(String(value));
      if (Number.isNaN(date.getTime())) return true;
      if (displayStart && date < displayStart) return false;
      if (displayEnd && date > displayEnd) return false;
      return true;
    };

    const productInFields = (
      lot: FifoLot,
      showLotDetails: boolean,
    ): Record<string, unknown> => ({
      productInDate: showLotDetails && lot.displayInRange ? lot.source.productInDate : '',
      productInTransaction: showLotDetails && lot.displayInRange
        ? lot.source.productInTransaction
        : '',
      receivedFrom: showLotDetails && lot.displayInRange ? lot.source.receivedFrom : '',
      itemName: showLotDetails ? lot.source.itemName : '',
      quantity: showLotDetails && lot.displayInRange ? lot.source.quantity : 0,
      unit: lot.source.unit,
      quantityRemaining: lot.remaining,
      costPerUnit: showLotDetails && lot.displayInRange ? lot.source.costPerUnit : 0,
      total: showLotDetails && lot.displayInRange ? lot.source.total : 0,
      hasProductInLot: true,
      showProductInLotDetails: showLotDetails,
      showProductInTransactionDetails: showLotDetails && lot.displayInRange,
    });
    for (const row of this.rowsFrom(result)) {
      const key = `${row.productId ?? ''}:${row.warehouseId ?? ''}`;
      let queue = lotQueues.get(key);
      if (!queue) {
        queue = { head: 0, lots: [] };
        lotQueues.set(key, queue);
      }

      const quantityIn = this.parseNumber(row.quantityIn);
      const quantityOut = this.parseNumber(row.quantityOut);
      const rate = this.parseNumber(row.rate);
      const shouldDisplay = inDisplayRange(row.transactionDateRaw);

      if (quantityIn > 0) {
        const lot: FifoLot = {
          source: {
            productInDate: row.transactionDate,
            productInTransaction: this.formatFifoTransactionLabel(
              row.transactionType,
              row.referenceNo,
            ),
            receivedFrom: this.partyForFifoMovement(
              row.normalizedType,
              row.partyName,
              true,
            ),
            itemName: row.itemName,
            quantity: quantityIn,
            unit: row.unit || 'pcs',
            costPerUnit: rate,
            total: quantityIn * rate,
          },
          remaining: quantityIn,
          displayInRange: shouldDisplay,
          hasDisplayAllocation: false,
        };
        queue.lots.push(lot);

        if (shouldDisplay) {
          productInCount += 1;
          totalReceivedQuantity += quantityIn;
        }
      }

      if (quantityOut > 0) {
        let remainingOut = quantityOut;

        while (remainingOut > 0 && queue.head < queue.lots.length) {
          const lot = queue.lots[queue.head];
          const consumed = Math.min(lot.remaining, remainingOut);
          lot.remaining -= consumed;
          remainingOut -= consumed;

          if (lot.displayInRange) {
            const showLotDetails = !lot.hasDisplayAllocation;
            lot.hasDisplayAllocation = true;
            allocationRows.push({
              ...productInFields(lot, showLotDetails),
              productOutDate: row.transactionDate,
              productOutTransaction: this.formatFifoTransactionLabel(
                row.transactionType,
                row.referenceNo,
              ),
              dispersedTo: this.partyForFifoMovement(
                row.normalizedType,
                row.partyName,
                false,
              ),
              quantityDispersed: consumed,
              dispersedUnit: row.unit || lot.source.unit || 'pcs',
            });
            productOutCount += 1;
            totalDispersedQuantity += consumed;
          }

          if (lot.remaining <= 0.000001) queue.head += 1;
        }

        // Visibility is driven by Product IN lots. Unmatched Product OUT rows
        // have no visible originating FIFO layer and are intentionally omitted.
      }
    }

    for (const queue of lotQueues.values()) {
      for (const lot of queue.lots) {
        if (!lot.displayInRange || lot.hasDisplayAllocation) continue;
        allocationRows.push({
          ...productInFields(lot, true),
          ...this.emptyFifoProductOutRow(),
        });
      }
    }

    const total = allocationRows.length;
    const start = pagination.offset;
    const end = Math.min(start + pagination.limit, total);
    const rows = allocationRows.slice(start, end).map((row) => ({
      ...row,
      __total: total,
    }));

    return {
      rows,
      total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: total === 0 ? 1 : Math.ceil(total / pagination.limit),
      totals: {
        productInCount,
        productOutCount,
        totalReceivedQuantity,
        totalDispersedQuantity,
      },
    };
  }
  private emptyFifoProductInRow(): Record<string, unknown> {
    return {
      productInDate: '',
      productInTransaction: '',
      receivedFrom: '',
      itemName: '',
      quantity: 0,
      unit: 'pcs',
      quantityRemaining: 0,
      costPerUnit: 0,
      total: 0,
      hasProductInLot: false,
      showProductInLotDetails: false,
      showProductInTransactionDetails: false,
    };
  }

  private emptyFifoProductOutRow(): Record<string, unknown> {
    return {
      productOutDate: '',
      productOutTransaction: '',
      dispersedTo: '',
      quantityDispersed: 0,
      dispersedUnit: 'pcs',
    };
  }

  private formatFifoTransactionLabel(type: unknown, referenceNo: unknown): string {
    const rawType = String(type ?? '').trim();
    const normalized = rawType.toLowerCase().replace(/\s+/g, '_');
    const labelMap: Record<string, string> = {
      bill: 'Bill',
      bills: 'Bill',
      purchase_order: 'Purchase Order',
      purchase_orders: 'Purchase Order',
      purchase_receive: 'Purchase Receive',
      purchase_receives: 'Purchase Receive',
      invoice: 'Invoice',
      invoices: 'Invoice',
      credit_note: 'Credit Note',
      credit_notes: 'Credit Note',
      vendor_credit: 'Vendor Credits',
      vendor_credits: 'Vendor Credits',
      purchase_return: 'Purchase Return',
      purchase_returns: 'Purchase Return',
      inventory_adjustment: 'Inventory Adjustment By Quantity',
      inventory_adjustments: 'Inventory Adjustment By Quantity',
    };
    const label = labelMap[normalized] || rawType.replace(/_/g, ' ') || 'Transaction';
    const reference = String(referenceNo ?? '').trim();
    return reference.length === 0 ? label : `${label} # ${reference}`;
  }

  private partyForFifoMovement(
    type: unknown,
    partyName: unknown,
    isProductIn: boolean,
  ): string {
    const normalized = String(type ?? '').toLowerCase().replace(/\s+/g, '_');
    if (normalized.includes('inventory_adjustment')) return '';
    if (isProductIn && normalized.includes('vendor_credit')) return '';
    return String(partyName ?? '').trim();
  }
  private getAgingInterval(query: InventoryReportQueryDto): {
    count: number;
    days: number;
  } {
    const count = Math.min(12, Math.max(1, Number(query.intervalCount ?? 6)));
    const days = Math.min(365, Math.max(1, Number(query.intervalDays ?? 3)));
    return { count, days };
  }

  private buildAgingBuckets(count: number, days: number): string[] {
    return Array.from({ length: count }, (_, index) => {
      if (index === count - 1) return `> ${index * days} Days`;
      const start = index * days + 1;
      const end = (index + 1) * days;
      return `${start} - ${end} Days`;
    });
  }

  async inventoryAgingSummary(
    tenant: TenantContext,
    query: InventoryReportQueryDto,
  ): Promise<InventoryReportPage<Record<string, unknown>>> {
    const entityId = this.getEntityId(tenant);
    const pagination = this.normalizePagination(query);
    const { count: intervalCount, days: intervalDays } =
      this.getAgingInterval(query);
    const asOfDate =
      query.endDate?.trim() || new Date().toISOString().slice(0, 10);
    const stockConditions = [sql`ps.entity_id = ${entityId}`];
    const layerConditions = [sql`bsl.entity_id = ${entityId}`];

    if (query.warehouseId?.trim()) {
      stockConditions.push(sql`ps.warehouse_id = ${query.warehouseId.trim()}`);
      layerConditions.push(sql`bsl.warehouse_id = ${query.warehouseId.trim()}`);
    }
    if (query.search?.trim()) {
      const search = `%${query.search.trim()}%`;
      stockConditions.push(sql`p.product_name ILIKE ${search}`);
      layerConditions.push(sql`p.product_name ILIKE ${search}`);
    }

    const stockWhereClause = sql.join(stockConditions, sql` AND `);
    const layerWhereClause = sql.join(layerConditions, sql` AND `);

    const result = await db.execute(sql`
      WITH stock AS (
        SELECT
          ps.product_id,
          ps.warehouse_id,
          SUM(COALESCE(ps.stock_on_hand, 0))::numeric AS stock_on_hand
        FROM public.v_physical_stock ps
        JOIN products p ON p.id = ps.product_id
        WHERE ${stockWhereClause}
        GROUP BY ps.product_id, ps.warehouse_id
        HAVING SUM(COALESCE(ps.stock_on_hand, 0)) <> 0
      ),
      layers AS (
        SELECT
          p.id::text AS item_id,
          p.product_name AS item_name,
          bsl.created_at::date AS layer_date,
          GREATEST(
            COALESCE(bsl.qty, 0) + COALESCE(bsl.foc_qty, 0),
            0
          )::numeric AS layer_qty,
          COALESCE(NULLIF(bsl.purchase_rate, 0), p.cost_price, 0)::numeric AS layer_rate,
          GREATEST(
            COALESCE(s.stock_on_hand, 0) - COALESCE(
              SUM(GREATEST(COALESCE(bsl.qty, 0) + COALESCE(bsl.foc_qty, 0), 0))
                OVER (
                  PARTITION BY bsl.product_id, bsl.warehouse_id
                  ORDER BY bsl.created_at DESC, bsl.id DESC
                  ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                ),
              0
            ),
            0
          )::numeric AS remaining_before_layer
        FROM batch_stock_layers bsl
        JOIN stock s ON s.product_id = bsl.product_id AND s.warehouse_id = bsl.warehouse_id
        JOIN products p ON p.id = bsl.product_id
        WHERE ${layerWhereClause}
          AND GREATEST(COALESCE(bsl.qty, 0) + COALESCE(bsl.foc_qty, 0), 0) > 0
      ),
      live_layers AS (
        SELECT
          item_id,
          item_name,
          GREATEST((${asOfDate}::date - layer_date), 0)::int AS age_days,
          LEAST(layer_qty, remaining_before_layer)::numeric AS quantity,
          layer_rate
        FROM layers
        WHERE remaining_before_layer > 0
      ),
      bucketed AS (
        SELECT
          item_id,
          item_name,
          CASE
            WHEN age_days > ${intervalCount * intervalDays} THEN ${intervalCount - 1}
            ELSE LEAST(${intervalCount - 1}, GREATEST(0, CEIL(age_days::numeric / ${intervalDays})::int - 1))
          END AS bucket_index,
          quantity,
          quantity * layer_rate AS asset_value
        FROM live_layers
      ),
      grouped AS (
        SELECT
          item_id AS "itemId",
          item_name AS "itemName",
          jsonb_agg(
            jsonb_build_object(
              'bucketIndex', bucket_index,
              'quantity', quantity,
              'assetValue', asset_value
            )
            ORDER BY bucket_index
          ) AS "bucketValues"
        FROM bucketed
        GROUP BY item_id, item_name
      )
      SELECT *, COUNT(*) OVER()::int AS "__total"
      FROM grouped
      ORDER BY "itemName" ASC
      LIMIT ${pagination.limit} OFFSET ${pagination.offset}
    `);

    const labels = this.buildAgingBuckets(intervalCount, intervalDays);
    const rows = this.rowsFrom(result).map((row) => {
      const buckets = labels.map((label, index) => ({
        label,
        quantity: 0,
        assetValue: 0,
        bucketIndex: index,
      }));
      const values = Array.isArray(row.bucketValues)
        ? row.bucketValues
        : row.bucketValues && typeof row.bucketValues === "object"
          ? Object.values(row.bucketValues as Record<string, unknown>)
          : [];

      for (const rawValue of values) {
        const value = rawValue as Record<string, unknown>;
        const bucketIndex = this.parseNumber(value.bucketIndex, -1);
        if (bucketIndex >= 0 && bucketIndex < buckets.length) {
          buckets[bucketIndex].quantity += this.parseNumber(value.quantity);
          buckets[bucketIndex].assetValue += this.parseNumber(value.assetValue);
        }
      }

      return {
        itemId: row.itemId,
        itemName: row.itemName,
        buckets,
        __total: row.__total,
      };
    });

    return this.pageFromRows(rows, pagination);
  }
}
