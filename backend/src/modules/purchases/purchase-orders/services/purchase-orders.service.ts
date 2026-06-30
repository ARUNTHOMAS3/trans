import { Injectable, NotFoundException } from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { CreatePurchaseOrderDto } from "../dto/create-purchase-order.dto";
import { UpdatePurchaseOrderDto } from "../dto/update-purchase-order.dto";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { SequencesService } from "../../../../sequences/sequences.service";

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

    const { data } = await this.supabaseService
      .getClient()
      .from("accounts")
      .select("id,user_account_name,system_account_name")
      .eq("entity_id", tenant.entityId)
      .or(
        "user_account_name.ilike.%Purchase Discount%,system_account_name.ilike.%Purchase Discount%,user_account_name.ilike.%Discount%",
      )
      .limit(1)
      .maybeSingle();

    if (!data) {
      const fallback = await this.supabaseService
        .getClient()
        .from("accounts")
        .select("id")
        .eq("entity_id", tenant.entityId)
        .limit(1)
        .maybeSingle();
      return fallback.data?.id ?? null;
    }
    return data?.id ?? null;
  }

  private async getNextPurchaseOrderNumber(tenant: TenantContext) {
    const regexPattern = "^PO-[0-9]+$";
    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchase_orders")
      .select("order_number")
      .eq("entity_id", tenant.entityId)
      .filter("order_number", "match", regexPattern)
      .limit(1000);

    if (error) {
      throw new Error(
        `Failed to generate next purchase order number: ${error.message}`,
      );
    }

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
    if (dto.document_type !== undefined) dbData.document_type = dto.document_type;
    if (dto.status !== undefined) dbData.status = dto.status;
    if (dto.subtotal !== undefined) dbData.subtotal = dto.subtotal;
    if (dto.tax_amount !== undefined) dbData.tax_amount = dto.tax_amount;
    if (dto.discount !== undefined) dbData.discount = dto.discount;
    if (dto.tds_tcs_type !== undefined) dbData.tds_tcs_type = dto.tds_tcs_type;
    if (dto.tds_tcs_id !== undefined) dbData.tds_tcs_id = this.cleanUuid(dto.tds_tcs_id);
    else if (dto.tds_id !== undefined) dbData.tds_tcs_id = this.cleanUuid(dto.tds_id);
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
      tds_id: db.tds_tcs_id ?? db.tds_id,
      tds_tcs_id: db.tds_tcs_id ?? db.tds_id,
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

    const client = this.supabaseService.getClient();
    const poIds = rows.map((row) => row.id).filter(Boolean);
    const orderNumbers = rows.map((row) => row.order_number).filter(Boolean);

    // 1. Get PO items to calculate expected quantities
    const { data: allPoItems } = await client
      .from("purchase_order_items")
      .select("purchase_order_id, quantity, cancelled_quantity, is_header")
      .in("purchase_order_id", poIds)
      .eq("entity_id", entityId);

    const poExpectedQtyMap = new Map<string, number>();
    for (const item of allPoItems ?? []) {
      if (item.is_header) continue;
      const qty = parseFloat(item.quantity?.toString() ?? "0");
      const cancelled = parseFloat(item.cancelled_quantity?.toString() ?? "0");
      const current = poExpectedQtyMap.get(item.purchase_order_id) ?? 0;
      poExpectedQtyMap.set(item.purchase_order_id, current + (qty - cancelled));
    }

    // 2. Get receives and receive items (including intransit receives)
    const { data: allReceives } = await client
      .from("purchase_receives")
      .select("id, purchase_order_id")
      .in("purchase_order_id", poIds)
      .eq("entity_id", entityId)
      .eq("is_delete", false)
      .in("status", ["received", "intransit"]);

    const receiveIds = (allReceives ?? []).map((r) => r.id);
    const poToReceiveIdsMap = new Map<string, string[]>();
    for (const r of allReceives ?? []) {
      const list = poToReceiveIdsMap.get(r.purchase_order_id) ?? [];
      list.push(r.id);
      poToReceiveIdsMap.set(r.purchase_order_id, list);
    }

    // Fetch all receive items for these receives
    let allReceiveItems: any[] = [];
    if (receiveIds.length > 0) {
      const { data } = await client
        .from("purchase_receive_items")
        .select("id, purchase_receive_id, received")
        .in("purchase_receive_id", receiveIds)
        .eq("entity_id", entityId);
      allReceiveItems = data ?? [];
    }

    const receiveItemIds = allReceiveItems.map((ri) => ri.id);
    // Fetch all batch items for these receive items
    let allReceiveBatches: any[] = [];
    if (receiveItemIds.length > 0) {
      const { data } = await client
        .from("purchase_receive_item_batches")
        .select("purchase_receive_item_id, quantity")
        .in("purchase_receive_item_id", receiveItemIds)
        .eq("entity_id", entityId);
      allReceiveBatches = data ?? [];
    }

    const batchQtyMap = new Map<string, number>();
    for (const b of allReceiveBatches) {
      const current = batchQtyMap.get(b.purchase_receive_item_id) ?? 0;
      batchQtyMap.set(b.purchase_receive_item_id, current + parseFloat(b.quantity?.toString() ?? "0"));
    }

    const receiveQtyMap = new Map<string, number>();
    for (const ri of allReceiveItems) {
      const current = receiveQtyMap.get(ri.purchase_receive_id) ?? 0;
      const batchQty = batchQtyMap.get(ri.id);
      const qty = batchQty !== undefined ? batchQty : parseFloat(ri.received?.toString() ?? "0");
      receiveQtyMap.set(ri.purchase_receive_id, current + qty);
    }

    // 3. Get bills and bill items
    let allBills: any[] = [];
    if (orderNumbers.length > 0) {
      let query = client
        .from("bills")
        .select("id, order_number")
        .eq("entity_id", entityId)
        .eq("is_delete", false)
        .neq("status", "void");

      const orConditions = orderNumbers.map((poNum) => `order_number.ilike.%${poNum}%`).join(',');
      if (orConditions) {
        query = query.or(orConditions);
      }
      const { data } = await query;

      const lowerOrderNumbers = orderNumbers.map((num) => num.trim().toLowerCase());
      allBills = (data || []).filter((bill) => {
        if (!bill.order_number) return false;
        const parts = bill.order_number.split(',').map((p: string) => p.trim().toLowerCase());
        return parts.some((part) => lowerOrderNumbers.includes(part));
      });
    }

    const billIds = allBills.map((b) => b.id);
    const poToBillIdsMap = new Map<string, string[]>();
    for (const b of allBills) {
      if (b.order_number) {
        const parts = b.order_number.split(',').map((p: string) => p.trim()).filter(Boolean);
        for (const part of parts) {
          const list = poToBillIdsMap.get(part) ?? [];
          list.push(b.id);
          poToBillIdsMap.set(part, list);
        }
      }
    }

    const riIdToPoIdMap = new Map<string, string>();
    for (const r of allReceives ?? []) {
      const rItems = allReceiveItems.filter((ri) => ri.purchase_receive_id === r.id);
      for (const ri of rItems) {
        riIdToPoIdMap.set(ri.id, r.purchase_order_id);
      }
    }

    let allBillItems: any[] = [];
    if (billIds.length > 0) {
      const { data } = await client
        .from("bill_items")
        .select("bill_id, quantity, purchase_receive_item_id")
        .in("bill_id", billIds);
      allBillItems = data ?? [];
    }

    return rows.map((row) => {
      const expected = poExpectedQtyMap.get(row.id) ?? 0;

      // Calculate received total
      let received = 0;
      const recIds = poToReceiveIdsMap.get(row.id) ?? [];
      for (const rid of recIds) {
        received += receiveQtyMap.get(rid) ?? 0;
      }

      // Calculate billed total
      let billed = 0;
      if (row.order_number) {
        const bIds = poToBillIdsMap.get(row.order_number) ?? [];
        for (const bid of bIds) {
          const bill = allBills.find((b) => b.id === bid);
          const orderNumStr = (bill?.order_number ?? "").toString();
          const isMultiPo = orderNumStr.includes(",");
          
          const bItems = allBillItems.filter((bi) => bi.bill_id === bid);
          for (const bi of bItems) {
            const prItemId = bi.purchase_receive_item_id;
            if (prItemId) {
              if (riIdToPoIdMap.get(prItemId) === row.id) {
                billed += parseFloat(bi.quantity?.toString() ?? "0");
              }
            } else if (!isMultiPo) {
              billed += parseFloat(bi.quantity?.toString() ?? "0");
            }
          }
        }
      }

      // Determine statuses
      let receive_status = "none";
      if (received > 0) {
        if (received >= expected - 0.0001) {
          receive_status = "full";
        } else {
          receive_status = "partial";
        }
      }

      let bill_status = "none";
      if (billed > 0) {
        if (billed >= expected - 0.0001) {
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

    const client = this.supabaseService.getClient();
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
      const { data: vendors } = await client
        .from("vendors")
        .select("id,display_name,company_name")
        .in("id", vendorIds);
      for (const vendor of vendors ?? []) {
        vendorMap.set(vendor.id, {
          display_name: vendor.display_name,
          company_name: vendor.company_name,
        });
      }
    }

    if (warehouseIds.length) {
      const { data: warehouses } = await client
        .from("warehouses")
        .select("id,name")
        .in("id", warehouseIds);
      for (const warehouse of warehouses ?? []) {
        warehouseMap.set(warehouse.id, { name: warehouse.name });
      }
    }

    if (paymentTermIds.length) {
      const { data: terms } = await client
        .from("payment_terms")
        .select("id,term_name")
        .in("id", paymentTermIds);
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

    let query = this.supabaseService
      .getClient()
      .from("purchase_orders")
      .select("*", { count: "exact" })
      .eq("entity_id", tenant.entityId)
      .range(offset, offset + limit - 1);

    if (search) {
      query = query.or(
        `order_number.ilike.%${search}%,reference_number.ilike.%${search}%`,
      );
    }

    if (status) {
      query = query.eq("status", status);
    }

    if (vendorId) {
      query = query.eq("vendor_id", vendorId);
    }

    const { data, error, count } = await query;

    if (error) {
      throw new Error(`Failed to fetch purchase orders: ${error.message}`);
    }

    const enriched = await this.attachPurchaseOrderLookups(data ?? []);
    const withProgress = await this.attachProgressStatuses(enriched, tenant.entityId);
    const mapped = withProgress.map((row) => this.mapDbToDto(row));

    return {
      data: mapped,
      meta: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const { data: rows, error } = await client
      .from("purchase_orders")
      .select("*")
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .limit(1);

    if (error) {
      console.error("Error in findOne PO:", error);
      throw new NotFoundException(
        `Purchase Order not found: ${error.message} (code: ${error.code})`,
      );
    }
    const data = (rows ?? [])[0];
    if (!data) {
      throw new NotFoundException(`Purchase Order with ID ${id} not found`);
    }

    const [enriched] = await this.attachPurchaseOrderLookups([data]);
    const [withProgress] = await this.attachProgressStatuses([enriched], tenant.entityId);

    const { data: items } = await client
      .from("purchase_order_items")
      .select("*")
      .eq("purchase_order_id", id)
      .eq("entity_id", tenant.entityId);

    const productIds = Array.from(
      new Set((items ?? []).map((item) => item.product_id).filter(Boolean)),
    );
    let productMap = new Map<string, any>();
    if (productIds.length) {
      const { data: products } = await client
        .from("products")
        .select("*")
        .in("id", productIds);
      productMap = new Map((products ?? []).map((p) => [p.id, p]));
    }

    const itemWithProducts = (items ?? []).map((item) => ({
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
        const { data: wh } = await this.supabaseService
          .getClient()
          .from("warehouses")
          .select("id")
          .eq("entity_id", tenant.entityId)
          .eq("is_active", true)
          .limit(1)
          .maybeSingle();
        resolvedWarehouseId = wh?.id || null;
      }
    }
    const payload = this.mapDtoToDb({
      ...poData,
      warehouse_id: resolvedWarehouseId,
      discount_account_id: resolvedDiscountAccountId,
      is_delete: false,
    });
    payload.entity_id = tenant.entityId;

    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchase_orders")
      .insert([payload])
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create purchase order: ${error.message}`);
    }

    if (items && items.length > 0) {
      const itemsPayload = items.map((item) => {
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
        return {
          ...(restItem as any),
          product_id: this.cleanUuid(restItem.product_id),
          account_id: this.cleanUuid(accountId),
          accounts: this.cleanUuid(accountId),
          tax_id: this.cleanUuid(restItem.tax_id),
          hsn_code: hsnNumeric,
          purchase_order_id: data.id,
          entity_id: tenant.entityId,
        };
      });

      const { error: itemsError } = await this.supabaseService
        .getClient()
        .from("purchase_order_items")
        .insert(itemsPayload);

      if (itemsError) {
        throw new Error(
          `Failed to create purchase order items: ${itemsError.message}`,
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
        const { data: wh } = await this.supabaseService
          .getClient()
          .from("warehouses")
          .select("id")
          .eq("entity_id", tenant.entityId)
          .eq("is_active", true)
          .limit(1)
          .maybeSingle();
        resolvedWarehouseId = wh?.id || null;
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

    const { data, error } = await this.supabaseService
      .getClient()
      .from("purchase_orders")
      .update(payload)
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update purchase order: ${error.message}`);
    }

    if (!data) {
      throw new NotFoundException(`Purchase Order with ID ${id} not found`);
    }

    // 1. Delete all existing items for this Purchase Order
    const { error: deleteError } = await this.supabaseService
      .getClient()
      .from("purchase_order_items")
      .delete()
      .eq("purchase_order_id", id)
      .eq("entity_id", tenant.entityId);

    if (deleteError) {
      throw new Error(
        `Failed to clean old purchase order items: ${deleteError.message}`,
      );
    }

    // 2. Insert new / updated items
    if (items && items.length > 0) {
      const itemsPayload = items.map((item) => {
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
        return {
          ...(restItem as any),
          product_id: this.cleanUuid(restItem.product_id),
          account_id: this.cleanUuid(accountId),
          accounts: this.cleanUuid(accountId),
          tax_id: this.cleanUuid(restItem.tax_id),
          hsn_code: hsnNumeric,
          purchase_order_id: id,
          entity_id: tenant.entityId,
        };
      });

      const { error: itemsError } = await this.supabaseService
        .getClient()
        .from("purchase_order_items")
        .insert(itemsPayload);

      if (itemsError) {
        throw new Error(
          `Failed to update purchase order items: ${itemsError.message}`,
        );
      }
    }

    return this.mapDbToDto(data);
  }

  async remove(id: string, tenant: TenantContext) {
    const existing = await this.findOne(id, tenant);
    const originalNumber = existing?.order_number;
    const newNumber = originalNumber ? (originalNumber.startsWith('SD-') ? originalNumber : `SD-${originalNumber}`) : undefined;

    const { error } = await this.supabaseService
      .getClient()
      .from("purchase_orders")
      .update({
        is_delete: true,
        ...(newNumber ? { order_number: newNumber } : {}),
      })
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (error) {
      throw new Error(`Failed to delete purchase order: ${error.message}`);
    }

    return { message: "Purchase Order deleted successfully" };
  }
}
