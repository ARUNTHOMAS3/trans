import { Injectable, NotFoundException, ForbiddenException } from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { CreatePurchaseOrderDto } from "../dto/create-purchase-order.dto";
import { UpdatePurchaseOrderDto } from "../dto/update-purchase-order.dto";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { SequencesService } from "../../../../sequences/sequences.service";
import { listVisibleAccounts } from "../../../../common/account-visibility.util";
import { client } from "../../../../db/db";

@Injectable()
export class PurchaseOrdersService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly sequencesService: SequencesService,
  ) {}

  private async resolveDiscountAccountId(
    tenant: TenantContext,
    dto: { discount_level?: string; discount_account_id?: string },
  ) {
    if (dto.discount_account_id) {
      return dto.discount_account_id;
    }

    const visibleAccounts = await listVisibleAccounts(
      client,
      tenant,
    );
    const preferred = visibleAccounts.find((account: any) => {
      const name = String(account.visible_name ?? "").toLowerCase();
      return name.includes("purchase discount") || name.includes("discount");
    });

    return preferred?.id ?? visibleAccounts[0]?.id ?? null;
  }

  private async getNextPurchaseOrderNumber(tenant: TenantContext) {
    const regexPattern = "^PO-[0-9]+$";
    const data = await client.unsafe(
      `SELECT order_number FROM purchase_orders WHERE entity_id = $1 AND order_number ~ $2 LIMIT 1000`,
      [tenant.entityId, regexPattern],
    );

    let maxNumber = 0;
    for (const row of data ?? []) {
      const raw = row.order_number as string | null;
      if (raw == null) continue;
      const match = /^PO-(\d+)$/.exec(raw);
      if (match == null) continue;
      const num = Number.parseInt(match[1], 10);
      if (!Number.isNaN(num) && num > maxNumber) {
        maxNumber = num;
      }
    }

    const nextNumber = maxNumber + 1;
    const padding = 5;
    return {
      prefix: "PO-",
      nextNumber,
      padding,
      formatted: `PO-${nextNumber.toString().padStart(padding, "0")}`,
    };
  }

  private cleanUuid(val: any): string | null {
    if (val === "" || val === null || val === undefined) {
      return null;
    }
    return val;
  }

  private mapDtoToDb(dto: any): any {
    const dbData: any = {};
    if (dto.vendor_id !== undefined) dbData.vendor_id = this.cleanUuid(dto.vendor_id);
    if (dto.order_number !== undefined) dbData.order_number = dto.order_number;
    if (dto.order_date !== undefined) dbData.order_date = dto.order_date;
    if (dto.expected_delivery_date !== undefined) dbData.expected_delivery_date = dto.expected_delivery_date;
    if (dto.reference_number !== undefined) dbData.reference_number = dto.reference_number;
    if (dto.payment_terms_id !== undefined) dbData.payment_terms_id = this.cleanUuid(dto.payment_terms_id);
    if (dto.shipment_preference_id !== undefined) dbData.shipment_preference_id = this.cleanUuid(dto.shipment_preference_id);
    if (dto.delivery_type !== undefined) dbData.delivery_type = dto.delivery_type;
    if (dto.delivery_warehouse_id !== undefined) dbData.delivery_warehouse_id = this.cleanUuid(dto.delivery_warehouse_id);
    if (dto.delivery_customer_id !== undefined) dbData.delivery_customer_id = this.cleanUuid(dto.delivery_customer_id);
    if (dto.warehouse_id !== undefined) dbData.warehouse_id = this.cleanUuid(dto.warehouse_id);
    if (dto.warehouse_name !== undefined) dbData.warehouse_name = dto.warehouse_name;
    if (dto.place_of_supply !== undefined) dbData.place_of_supply = dto.place_of_supply;
    if (dto.document_type !== undefined) dbData.document_type = dto.document_type;
    if (dto.status !== undefined) dbData.status = dto.status;
    if (dto.subtotal !== undefined) dbData.subtotal = dto.subtotal;
    if (dto.tax_amount !== undefined) dbData.tax_amount = dto.tax_amount;
    if (dto.discount !== undefined) dbData.discount = dto.discount;
    if (dto.tds_tcs_type !== undefined) dbData.tds_tcs_type = dto.tds_tcs_type;
    const resolvedTdsId = dto.tds_tcs_id || dto.tds_id;
    if (resolvedTdsId !== undefined) {
      dbData.tds_tcs_id = this.cleanUuid(resolvedTdsId);
    }
    if (dto.tds_tcs_amount !== undefined) dbData.tds_tcs_amount = dto.tds_tcs_amount;
    if (dto.adjustment !== undefined) dbData.adjustment = dto.adjustment;
    if (dto.total_quantity !== undefined) dbData.total_quantity = dto.total_quantity;
    if (dto.total !== undefined) dbData.total = dto.total;
    if (dto.currency !== undefined) dbData.currency = dto.currency;
    if (dto.notes !== undefined) dbData.notes = dto.notes;
    if (dto.terms_and_conditions !== undefined) dbData.terms_and_conditions = dto.terms_and_conditions;
    if (dto.discount_level !== undefined) dbData.discount_level = dto.discount_level;
    if (dto.discount_type !== undefined) dbData.discount_type = dto.discount_type;
    if (dto.discount_account_id !== undefined) dbData.discount_account_id = this.cleanUuid(dto.discount_account_id);
    if (dto.tax_type !== undefined) dbData.tax_type = dto.tax_type;
    if (dto.is_delete !== undefined) dbData.is_delete = dto.is_delete;
    if (dto.source_of_supply !== undefined) dbData.source_of_supply = dto.source_of_supply;
    if (dto.destination_to_supply !== undefined) dbData.destination_to_supply = dto.destination_to_supply;
    if (dto.shipping_address !== undefined) dbData.shipping_address = this.cleanUuid(dto.shipping_address);
    if (dto.billing_address !== undefined) dbData.billing_address = this.cleanUuid(dto.billing_address);
    return dbData;
  }

  private mapDbToDto(db: any): any {
    if (!db) return null;
    return {
      ...db,
      order_number: db.order_number,
      order_date: db.order_date,
      reference_number: db.reference_number,
      payment_terms_id: db.payment_terms_id,
      shipment_preference_id: db.shipment_preference_id,
      subtotal: db.subtotal !== null && db.subtotal !== undefined ? parseFloat(db.subtotal) : 0,
      tax_amount: db.tax_amount !== null && db.tax_amount !== undefined ? parseFloat(db.tax_amount) : 0,
      discount: db.discount !== null && db.discount !== undefined ? parseFloat(db.discount) : 0,
      tds_id: this.cleanUuid(db.tds_tcs_id),
      tds_tcs_id: this.cleanUuid(db.tds_tcs_id),
      notes: db.notes,
      total_quantity: db.total_quantity !== null && db.total_quantity !== undefined ? parseFloat(db.total_quantity) : 0,
      total: db.total !== null && db.total !== undefined ? parseFloat(db.total) : 0,
      adjustment: db.adjustment !== null && db.adjustment !== undefined ? parseFloat(db.adjustment) : 0,
      tds_tcs_amount: db.tds_tcs_amount !== null && db.tds_tcs_amount !== undefined ? parseFloat(db.tds_tcs_amount) : 0,
      receive_status: db.receive_status ?? "none",
      bill_status: db.bill_status ?? "none",
    };
  }

  private async attachProgressStatuses<T extends Record<string, any>>(
    rows: T[],
    entityId: string,
  ): Promise<T[]> {
    if (!rows.length) return rows;

    const poIds = rows.map((row) => row.id).filter(Boolean);
    const orderNumbers = rows.map((row) => row.order_number).filter(Boolean);

    const allPoItems = await client.unsafe(
      `SELECT purchase_order_id, product_id, quantity, cancelled_quantity, is_header FROM purchase_order_items WHERE purchase_order_id = ANY($1) AND entity_id = $2`,
      [poIds, entityId],
    );

    const poExpectedItemsMap = new Map<string, Array<{ product_id: string; expected: number }>>();
    for (const item of allPoItems ?? []) {
      if (item.is_header) continue;
      const qty = parseFloat(item.quantity?.toString() ?? "0");
      const cancelled = parseFloat(item.cancelled_quantity?.toString() ?? "0");
      const expected = qty - cancelled;
      if (expected <= 0) continue;
      const list = poExpectedItemsMap.get(item.purchase_order_id) ?? [];
      list.push({ product_id: item.product_id, expected });
      poExpectedItemsMap.set(item.purchase_order_id, list);
    }

    const allReceives = await client.unsafe(
      `SELECT id, purchase_order_id FROM purchase_receives WHERE purchase_order_id = ANY($1) AND entity_id = $2 AND is_delete = false AND status = ANY($3)`,
      [poIds, entityId, ["received", "intransit"]],
    );

    const receiveIds = (allReceives ?? []).map((r: any) => r.id);
    const poToReceiveIdsMap = new Map<string, string[]>();
    for (const r of allReceives ?? []) {
      const list = poToReceiveIdsMap.get(r.purchase_order_id) ?? [];
      list.push(r.id);
      poToReceiveIdsMap.set(r.purchase_order_id, list);
    }

    let allReceiveItems: any[] = [];
    if (receiveIds.length > 0) {
      allReceiveItems = await client.unsafe(
        `SELECT id, purchase_receive_id, item_id, received FROM purchase_receive_items WHERE purchase_receive_id = ANY($1) AND entity_id = $2`,
        [receiveIds, entityId],
      );
    }

    const receiveItemIds = (allReceiveItems ?? []).map((ri: any) => ri.id);
    let allReceiveBatches: any[] = [];
    if (receiveItemIds.length > 0) {
      allReceiveBatches = await client.unsafe(
        `SELECT purchase_receive_item_id, quantity FROM purchase_receive_item_batches WHERE purchase_receive_item_id = ANY($1) AND entity_id = $2`,
        [receiveItemIds, entityId],
      );
    }

    const batchQtyMap = new Map<string, number>();
    for (const b of allReceiveBatches ?? []) {
      const current = batchQtyMap.get(b.purchase_receive_item_id) ?? 0;
      batchQtyMap.set(b.purchase_receive_item_id, current + parseFloat(b.quantity?.toString() ?? "0"));
    }

    const receiveToPoMap = new Map<string, string>();
    for (const r of allReceives ?? []) {
      receiveToPoMap.set(r.id, r.purchase_order_id);
    }

    const poReceivedItemsMap = new Map<string, Map<string, number>>();
    for (const ri of allReceiveItems ?? []) {
      const poId = receiveToPoMap.get(ri.purchase_receive_id);
      if (!poId) continue;
      const batchQty = batchQtyMap.get(ri.id);
      const qty = batchQty !== undefined ? batchQty : parseFloat(ri.received?.toString() ?? "0");
      const prodId = ri.item_id;
      if (!prodId) continue;

      const orderMap = poReceivedItemsMap.get(poId) ?? new Map<string, number>();
      const current = orderMap.get(prodId) ?? 0;
      orderMap.set(prodId, current + qty);
      poReceivedItemsMap.set(poId, orderMap);
    }

    let allBills: any[] = [];
    if (orderNumbers.length > 0) {
      allBills = await client.unsafe(
        `SELECT id, order_number FROM bills WHERE order_number = ANY($1) AND entity_id = $2 AND is_delete = false AND status != 'void'`,
        [orderNumbers, entityId],
      );
    }

    const billIds = (allBills ?? []).map((b: any) => b.id);
    const poToBillIdsMap = new Map<string, string[]>();
    for (const b of allBills ?? []) {
      const list = poToBillIdsMap.get(b.order_number) ?? [];
      list.push(b.id);
      poToBillIdsMap.set(b.order_number, list);
    }

    let allBillItems: any[] = [];
    if (billIds.length > 0) {
      allBillItems = await client.unsafe(
        `SELECT bill_id, quantity FROM bill_items WHERE bill_id = ANY($1)`,
        [billIds],
      );
    }

    const billQtyMap = new Map<string, number>();
    for (const bi of allBillItems ?? []) {
      const current = billQtyMap.get(bi.bill_id) ?? 0;
      billQtyMap.set(bi.bill_id, current + parseFloat(bi.quantity?.toString() ?? "0"));
    }

    return rows.map((row) => {
      let billed = 0;
      if (row.order_number) {
        const bIds = poToBillIdsMap.get(row.order_number) ?? [];
        for (const bid of bIds) {
          billed += billQtyMap.get(bid) ?? 0;
        }
      }

      let receive_status = "none";
      const expectedItems = poExpectedItemsMap.get(row.id) ?? [];
      const receivedMap = poReceivedItemsMap.get(row.id) ?? new Map<string, number>();
      const recIds = poToReceiveIdsMap.get(row.id) ?? [];

      if (recIds.length > 0) {
        let isAllReceived = true;
        if (expectedItems.length === 0) {
          isAllReceived = false;
        } else {
          for (const item of expectedItems) {
            const receivedQty = receivedMap.get(item.product_id) ?? 0;
            if (receivedQty < item.expected - 0.0001) {
              isAllReceived = false;
              break;
            }
          }
        }
        receive_status = isAllReceived ? "full" : "partial";
      }

      let expectedSum = 0;
      for (const item of expectedItems) {
        expectedSum += item.expected;
      }

      let bill_status = "none";
      if (billed > 0) {
        if (billed >= expectedSum - 0.0001) {
          bill_status = "full";
        } else {
          bill_status = "partial";
        }
      }

      return {
        ...row,
        receive_status,
        bill_status,
      };
    });
  }

  private async attachPurchaseOrderLookups<T extends Record<string, any>>(
    rows: T[],
  ) {
    if (!rows.length) return rows;

    const vendorIds = Array.from(
      new Set(rows.map((row) => row.vendor_id).filter(Boolean)),
    );
    const warehouseIds = Array.from(
      new Set(rows.map((row) => row.warehouse_id).filter(Boolean)),
    );
    const paymentTermIds = Array.from(
      new Set(rows.map((row) => row.payment_term_id || row.payment_terms_id).filter(Boolean)),
    );

    const vendorMap = new Map<string, { display_name?: string; company_name?: string }>();
    const warehouseMap = new Map<string, { name?: string }>();
    const paymentTermMap = new Map<string, { term_name?: string }>();

    if (vendorIds.length) {
      const vendors = await client.unsafe(
        `SELECT id, display_name, company_name FROM vendors WHERE id = ANY($1)`,
        [vendorIds],
      );
      for (const vendor of vendors ?? []) {
        vendorMap.set(vendor.id, {
          display_name: vendor.display_name,
          company_name: vendor.company_name,
        });
      }
    }

    if (warehouseIds.length) {
      const warehouses = await client.unsafe(
        `SELECT id, name FROM warehouses WHERE id = ANY($1)`,
        [warehouseIds],
      );
      for (const warehouse of warehouses ?? []) {
        warehouseMap.set(warehouse.id, { name: warehouse.name });
      }
    }

    if (paymentTermIds.length) {
      const terms = await client.unsafe(
        `SELECT id, term_name FROM payment_terms WHERE id = ANY($1)`,
        [paymentTermIds],
      );
      for (const term of terms ?? []) {
        paymentTermMap.set(term.id, { term_name: term.term_name });
      }
    }

    return rows.map((row) => ({
      ...row,
      vendor: row.vendor_id ? vendorMap.get(row.vendor_id) ?? null : null,
      warehouse: row.warehouse_id
        ? warehouseMap.get(row.warehouse_id) ?? null
        : null,
      payment_term: (row.payment_term_id || row.payment_terms_id)
        ? paymentTermMap.get(row.payment_term_id || row.payment_terms_id) ?? null
        : null,
    }));
  }

  async getNextNumber(tenant: TenantContext) {
    return this.getNextPurchaseOrderNumber(tenant);
  }

  async getSettings(tenant: TenantContext) {
    const sequence = await this.sequencesService.getSequence("purchase", tenant);
    return {
      isAuto: true,
      prefix: sequence?.prefix ?? "PO-",
      nextNumber: sequence?.next_number ?? 1,
      next_number: sequence?.next_number ?? 1,
      padding: sequence?.padding ?? 5,
      suffix: sequence?.suffix ?? "",
    };
  }

  async updateSettings(
    tenant: TenantContext,
    dto: {
      prefix?: string;
      nextNumber?: number;
      next_number?: number;
      padding?: number;
      suffix?: string;
      isAuto?: boolean;
    },
  ) {
    const updated = await this.sequencesService.updateSettings("purchase", tenant, {
      prefix: dto.prefix,
      nextNumber: dto.nextNumber ?? dto.next_number,
      padding: dto.padding,
      suffix: dto.suffix,
    });

    return {
      isAuto: dto.isAuto ?? true,
      prefix: updated?.prefix ?? "PO-",
      nextNumber: updated?.next_number ?? 1,
      next_number: updated?.next_number ?? 1,
      padding: updated?.padding ?? 5,
      suffix: updated?.suffix ?? "",
    };
  }

  async findAll(
    tenant: TenantContext,
    page: number = 1,
    limit: number = 100,
    search?: string,
    status?: string,
    vendorId?: string,
  ) {
    const offset = (page - 1) * limit;

    let sqlQuery = `SELECT * FROM purchase_orders WHERE entity_id = $1`;
    let countQuery = `SELECT COUNT(*)::int as count FROM purchase_orders WHERE entity_id = $1`;
    const params: any[] = [tenant.entityId];

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      const sIdx = params.length;
      sqlQuery += ` AND (order_number ILIKE $${sIdx} OR reference_number ILIKE $${sIdx})`;
      countQuery += ` AND (order_number ILIKE $${sIdx} OR reference_number ILIKE $${sIdx})`;
    }

    if (status && status.trim()) {
      params.push(status.trim());
      const stIdx = params.length;
      sqlQuery += ` AND status = $${stIdx}`;
      countQuery += ` AND status = $${stIdx}`;
    }

    if (vendorId && vendorId.trim()) {
      params.push(vendorId.trim());
      const vIdx = params.length;
      sqlQuery += ` AND vendor_id = $${vIdx}`;
      countQuery += ` AND vendor_id = $${vIdx}`;
    }

    sqlQuery += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    const [data, countRes] = await Promise.all([
      client.unsafe(sqlQuery, [...params, limit, offset]),
      client.unsafe(countQuery, params),
    ]);

    const totalCount = countRes[0]?.count ?? 0;

    const enriched = await this.attachPurchaseOrderLookups(data ?? []);
    const withProgress = await this.attachProgressStatuses(enriched, tenant.entityId);
    const mapped = withProgress.map((row) => this.mapDbToDto(row));

    return {
      data: mapped,
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
      `SELECT * FROM purchase_orders WHERE id = $1 LIMIT 1`,
      [id],
    );

    const data = rows[0];
    if (!data) {
      throw new NotFoundException(`Purchase Order with ID ${id} not found`);
    }

    if (data.entity_id !== tenant.entityId) {
      const branchCheck = await client.unsafe(
        `SELECT id FROM organisation_branch_master WHERE id = $1 AND parent_id = $2 LIMIT 1`,
        [data.entity_id, tenant.entityId],
      );

      if (!branchCheck[0]) {
        throw new ForbiddenException("You do not have access to this Purchase Order");
      }
    }

    const [enriched] = await this.attachPurchaseOrderLookups([data]);
    const [withProgress] = await this.attachProgressStatuses([enriched], data.entity_id);

    const items = await client.unsafe(
      `SELECT * FROM purchase_order_items WHERE purchase_order_id = $1 AND entity_id = $2`,
      [id, data.entity_id],
    );

    const productIds = Array.from(
      new Set((items ?? []).map((item: any) => item.product_id).filter(Boolean)),
    );
    let productMap = new Map<string, any>();
    if (productIds.length) {
      const products = await client.unsafe(
        `SELECT * FROM products WHERE id = ANY($1)`,
        [productIds],
      );
      productMap = new Map((products ?? []).map((p: any) => [p.id, p] as [string, any]));
    }

    const itemWithProducts = (items ?? []).map((item: any) => ({
      ...item,
      tax_rate: item.item_tax_rate !== null && item.item_tax_rate !== undefined ? parseFloat(item.item_tax_rate) : 0,
      itemTaxRate: item.item_tax_rate !== null && item.item_tax_rate !== undefined ? parseFloat(item.item_tax_rate) : 0,
      quantity: item.quantity !== null && item.quantity !== undefined ? parseFloat(item.quantity) : 0,
      rate: item.rate !== null && item.rate !== undefined ? parseFloat(item.rate) : 0,
      amount: item.amount !== null && item.amount !== undefined ? parseFloat(item.amount) : 0,
      tax_amount: item.tax_amount !== null && item.tax_amount !== undefined ? parseFloat(item.tax_amount) : 0,
      discount: item.discount !== null && item.discount !== undefined ? parseFloat(item.discount) : 0,
      cancelled_quantity: item.cancelled_quantity !== null && item.cancelled_quantity !== undefined ? parseFloat(item.cancelled_quantity) : 0,
      product: item.product_id ? productMap.get(item.product_id) ?? null : null,
    }));

    return {
      ...this.mapDbToDto(withProgress),
      items: itemWithProducts,
    };
  }

  async create(
    createPurchaseOrderDto: CreatePurchaseOrderDto,
    tenant: TenantContext,
  ) {
    const { items, org_id, branch_id, warehouse_name, ...poData } =
      createPurchaseOrderDto;
    const resolvedDiscountAccountId = await this.resolveDiscountAccountId(
      tenant,
      createPurchaseOrderDto,
    );
    let resolvedWarehouseId = this.cleanUuid(createPurchaseOrderDto.warehouse_id);
    if (!resolvedWarehouseId) {
      const deliveryWarehouseId = this.cleanUuid(createPurchaseOrderDto.delivery_warehouse_id);
      if (
        createPurchaseOrderDto.delivery_type === "warehouse" &&
        deliveryWarehouseId
      ) {
        resolvedWarehouseId = deliveryWarehouseId;
      } else {
        const wh = await client.unsafe(
          `SELECT id FROM warehouses WHERE entity_id = $1 AND is_active = true LIMIT 1`,
          [tenant.entityId],
        );
        resolvedWarehouseId = wh[0]?.id || null;
      }
    }
    const payload = this.mapDtoToDb({
      ...poData,
      warehouse_id: resolvedWarehouseId,
      discount_account_id: resolvedDiscountAccountId,
      is_delete: false,
    });
    payload.entity_id = tenant.entityId;

    const keys = Object.keys(payload);
    const cols = keys.map((k) => `"${k}"`).join(", ");
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");
    const values: any[] = Object.values(payload);

    let data: any;
    try {
      const rows = await client.unsafe(
        `INSERT INTO purchase_orders (${cols}) VALUES (${placeholders}) RETURNING *`,
        values,
      );
      data = rows[0];
    } catch (error: any) {
      throw new Error(`Failed to create purchase order: ${error.message}`);
    }

    if (items && items.length > 0) {
      for (const item of items) {
        const { warehouse_id, track_batches, track_serial_number, track_bin_location, ...restItem } = item;
        const accountId = restItem.account_id || restItem.accounts;
        let hsnNumeric: number | null = null;
        if (
          restItem.hsn_code !== undefined &&
          restItem.hsn_code !== null &&
          restItem.hsn_code !== ""
        ) {
          const parsed = Number(restItem.hsn_code);
          if (!isNaN(parsed)) {
            hsnNumeric = parsed;
          }
        }
        const itemRow = {
          ...(restItem as any),
          product_id: this.cleanUuid(restItem.product_id),
          account_id: this.cleanUuid(accountId),
          accounts: this.cleanUuid(accountId),
          tax_id: this.cleanUuid(restItem.tax_id),
          hsn_code: hsnNumeric,
          purchase_order_id: data.id,
          entity_id: tenant.entityId,
        };

        const iKeys = Object.keys(itemRow);
        const iCols = iKeys.map((k) => `"${k}"`).join(", ");
        const iPlaceholders = iKeys.map((_, i) => `$${i + 1}`).join(", ");
        const iValues: any[] = Object.values(itemRow);

        await client.unsafe(
          `INSERT INTO purchase_order_items (${iCols}) VALUES (${iPlaceholders})`,
          iValues,
        );
      }
    }

    return this.mapDbToDto(data);
  }

  async update(
    id: string,
    tenant: TenantContext,
    updatePurchaseOrderDto: UpdatePurchaseOrderDto,
  ) {
    const { items, org_id, branch_id, warehouse_name, ...poData } =
      updatePurchaseOrderDto;
    const resolvedDiscountAccountId = await this.resolveDiscountAccountId(
      tenant,
      updatePurchaseOrderDto,
    );
    let resolvedWarehouseId = this.cleanUuid(updatePurchaseOrderDto.warehouse_id);
    if (updatePurchaseOrderDto.hasOwnProperty("warehouse_id") && !resolvedWarehouseId) {
      const deliveryWarehouseId = this.cleanUuid(updatePurchaseOrderDto.delivery_warehouse_id);
      if (
        updatePurchaseOrderDto.delivery_type === "warehouse" &&
        deliveryWarehouseId
      ) {
        resolvedWarehouseId = deliveryWarehouseId;
      } else {
        const wh = await client.unsafe(
          `SELECT id FROM warehouses WHERE entity_id = $1 AND is_active = true LIMIT 1`,
          [tenant.entityId],
        );
        resolvedWarehouseId = wh[0]?.id || null;
      }
    }

    const payload = this.mapDtoToDb({
      ...poData,
      discount_account_id: resolvedDiscountAccountId,
    });
    if (resolvedWarehouseId) {
      payload.warehouse_id = resolvedWarehouseId;
    }
    payload.updated_at = new Date().toISOString();

    const keys = Object.keys(payload);
    const setClauses = keys.map((k, i) => `"${k}" = $${i + 1}`).join(", ");
    const values: any[] = Object.values(payload);

    let data: any;
    try {
      const rows = await client.unsafe(
        `UPDATE purchase_orders SET ${setClauses} WHERE id = $${keys.length + 1} AND entity_id = $${keys.length + 2} RETURNING *`,
        [...values, id, tenant.entityId],
      );
      data = rows[0];
    } catch (error: any) {
      throw new Error(`Failed to update purchase order: ${error.message}`);
    }

    if (!data) {
      throw new NotFoundException(`Purchase Order with ID ${id} not found`);
    }

    await client.unsafe(
      `DELETE FROM purchase_order_items WHERE purchase_order_id = $1 AND entity_id = $2`,
      [id, tenant.entityId],
    );

    if (items && items.length > 0) {
      for (const item of items) {
        const { warehouse_id, track_batches, track_serial_number, track_bin_location, ...restItem } = item;
        const accountId = restItem.account_id || restItem.accounts;
        let hsnNumeric: number | null = null;
        if (
          restItem.hsn_code !== undefined &&
          restItem.hsn_code !== null &&
          restItem.hsn_code !== ""
        ) {
          const parsed = Number(restItem.hsn_code);
          if (!isNaN(parsed)) {
            hsnNumeric = parsed;
          }
        }
        const itemRow = {
          ...(restItem as any),
          product_id: this.cleanUuid(restItem.product_id),
          account_id: this.cleanUuid(accountId),
          accounts: this.cleanUuid(accountId),
          tax_id: this.cleanUuid(restItem.tax_id),
          hsn_code: hsnNumeric,
          purchase_order_id: id,
          entity_id: tenant.entityId,
        };

        const iKeys = Object.keys(itemRow);
        const iCols = iKeys.map((k) => `"${k}"`).join(", ");
        const iPlaceholders = iKeys.map((_, i) => `$${i + 1}`).join(", ");
        const iValues: any[] = Object.values(itemRow);

        await client.unsafe(
          `INSERT INTO purchase_order_items (${iCols}) VALUES (${iPlaceholders})`,
          iValues,
        );
      }
    }

    return this.mapDbToDto(data);
  }

  async remove(id: string, tenant: TenantContext) {
    const existing = await this.findOne(id, tenant);
    const originalNumber = existing?.order_number;
    const newNumber = originalNumber ? (originalNumber.startsWith('SD-') ? originalNumber : `SD-${originalNumber}`) : undefined;

    try {
      if (newNumber) {
        await client.unsafe(
          `UPDATE purchase_orders SET is_delete = true, order_number = $1 WHERE id = $2 AND entity_id = $3`,
          [newNumber, id, tenant.entityId],
        );
      } else {
        await client.unsafe(
          `UPDATE purchase_orders SET is_delete = true WHERE id = $1 AND entity_id = $2`,
          [id, tenant.entityId],
        );
      }
    } catch (error: any) {
      throw new Error(`Failed to delete purchase order: ${error.message}`);
    }

    return { message: "Purchase Order deleted successfully" };
  }
}
