import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { randomUUID } from "crypto";
import { db } from "../../db/db";
import { batches, batchMaster, product, outletInventory } from "../../db/schema";
import { eq, sql } from "drizzle-orm";
import { SupabaseService } from "../supabase/supabase.service";
import { CreateProductDto } from "./dto/create-product.dto";
import { Client } from "pg";
import { UpdateProductDto } from "./dto/update-product.dto";

import { R2StorageService } from "../accountant/r2-storage.service";

@Injectable()
export class ProductsService {
  private readonly defaultOrgId = "00000000-0000-0000-0000-000000000000";
  private hasLoggedMissingOutletsLookup = false;

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly r2StorageService: R2StorageService,
  ) {}

  private readonly PRODUCT_SELECT_STRING = `
    *,
    unit:units(id, unit_name),
    category:categories(id, name),
    manufacturer:manufacturers(id, name),
    brand:brands(id, name),
    preferredVendor:vendors(id, display_name),
    salesAccount:accounts!products_sales_account_id_accounts_id_fk(id, user_account_name),
    purchaseAccount:accounts!products_purchase_account_id_accounts_id_fk(id, user_account_name),
    inventoryAccount:accounts!products_inventory_account_id_accounts_id_fk(id, user_account_name),
    rack:racks(id, rack_name),
    buyingRule:buying_rules(id, buying_rule, rule_description, system_behavior, associated_schedule_codes, requires_rx, requires_patient_info, is_saleable, log_to_special_register, requires_doctor_name, requires_prescription_date, requires_age_check, institutional_only, blocks_retail_sale, quantity_limit, allows_refill, sort_order),
    drugSchedule:drug_schedules(id, shedule_name, schedule_code, reference_description, requires_prescription, requires_h1_register, is_narcotic, requires_batch_tracking, sort_order, is_common),
    storage:storage_conditions(id, location_name, storage_type, temperature_range, display_text, description, common_examples, min_temp_c, max_temp_c, is_cold_chain, requires_fridge, sort_order),
    compositions:product_contents(
      content_id,
      strength_id,
      display_order,
      content:contents(id, content_name),
      strength:drug_strengths(id, strength_name)
    )
  `;

  private cleanUuid(value: any): string | null {
    if (!value || typeof value !== "string") return null;
    const trimmed = value.trim();
    if (trimmed.length === 0) return null;
    // Strictly return only if it looks like a UUID to prevent DB type errors
    return this.isUUID(trimmed) ? trimmed : null;
  }

  private isUUID(value: any): boolean {
    if (typeof value !== "string") return false;
    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    return uuidRegex.test(value.trim());
  }

  private resolveScope(orgId?: string | null, outletId?: string | null) {
    return {
      orgId: this.cleanUuid(orgId) ?? this.defaultOrgId,
      outletId: this.cleanUuid(outletId),
    };
  }

  private async getScopedReorderTerms(
    orgId?: string | null,
    outletId?: string | null,
  ) {
    const supabase = this.supabaseService.getClient();
    const scope = this.resolveScope(orgId, outletId);

    if (!scope.outletId) {
      const { data, error } = await supabase
        .from("reorder_terms")
        .select(
          "id, org_id, outlet_id, term_name, quantity, description, is_active",
        )
        .eq("org_id", scope.orgId)
        .is("outlet_id", null)
        .eq("is_active", true)
        .order("term_name", { ascending: true });

      if (error) throw new Error(error.message);
      return data ?? [];
    }

    const [specificResult, fallbackResult] = await Promise.all([
      supabase
        .from("reorder_terms")
        .select(
          "id, org_id, outlet_id, term_name, quantity, description, is_active",
        )
        .eq("org_id", scope.orgId)
        .eq("outlet_id", scope.outletId)
        .eq("is_active", true)
        .order("term_name", { ascending: true }),
      supabase
        .from("reorder_terms")
        .select(
          "id, org_id, outlet_id, term_name, quantity, description, is_active",
        )
        .eq("org_id", scope.orgId)
        .is("outlet_id", null)
        .eq("is_active", true)
        .order("term_name", { ascending: true }),
    ]);

    if (specificResult.error) throw new Error(specificResult.error.message);
    if (fallbackResult.error) throw new Error(fallbackResult.error.message);

    const seen = new Set<string>();
    const merged = <any>[];
    for (const row of [
      ...(specificResult.data ?? []),
      ...(fallbackResult.data ?? []),
    ]) {
      const key = (row.term_name ?? "").toString().trim().toLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);
      merged.push(row);
    }
    return merged;
  }

  private async getProductOutletInventorySetting(
    productId: string,
    orgId?: string | null,
    outletId?: string | null,
  ) {
    const supabase = this.supabaseService.getClient();
    const scope = this.resolveScope(orgId, outletId);

    if (scope.outletId) {
      const { data, error } = await supabase
        .from("product_outlet_inventory_settings")
        .select(
          "id, org_id, outlet_id, product_id, reorder_point, reorder_term_id, is_active",
        )
        .eq("product_id", productId)
        .eq("org_id", scope.orgId)
        .eq("outlet_id", scope.outletId)
        .eq("is_active", true)
        .maybeSingle();

      if (error) throw new Error(error.message);
      if (data) return data;
    }

    const { data, error } = await supabase
      .from("product_outlet_inventory_settings")
      .select(
        "id, org_id, outlet_id, product_id, reorder_point, reorder_term_id, is_active",
      )
      .eq("product_id", productId)
      .eq("org_id", scope.orgId)
      .is("outlet_id", null)
      .eq("is_active", true)
      .maybeSingle();

    if (error) throw new Error(error.message);
    return data ?? null;
  }

  private async syncProductOutletInventorySetting(
    productId: string,
    reorderPoint: number,
    reorderTermId: string | null,
    userId: string | null,
    orgId?: string | null,
    outletId?: string | null,
  ) {
    const supabase = this.supabaseService.getClient();
    const scope = this.resolveScope(orgId, outletId);
    const normalizedReorderPoint = Math.max(0, Number(reorderPoint) || 0);
    const normalizedReorderTermId = this.cleanUuid(reorderTermId);
    const hasMeaningfulSetting =
      normalizedReorderPoint > 0 || normalizedReorderTermId != null;

    let existingQuery = supabase
      .from("product_outlet_inventory_settings")
      .select("id")
      .eq("product_id", productId)
      .eq("org_id", scope.orgId);

    existingQuery = scope.outletId
      ? existingQuery.eq("outlet_id", scope.outletId)
      : existingQuery.is("outlet_id", null);

    const { data: existingSetting, error: existingError } =
      await existingQuery.maybeSingle();

    if (existingError) {
      throw new Error(existingError.message);
    }

    if (!hasMeaningfulSetting) {
      if (!existingSetting?.id) return null;

      const { error: clearError } = await supabase
        .from("product_outlet_inventory_settings")
        .update({
          reorder_point: 0,
          reorder_term_id: null,
          is_active: false,
          updated_by_id: userId,
          updated_at: new Date().toISOString(),
        })
        .eq("id", existingSetting.id);

      if (clearError) throw new Error(clearError.message);
      return null;
    }

    const payload = {
      org_id: scope.orgId,
      outlet_id: scope.outletId,
      product_id: productId,
      reorder_point: normalizedReorderPoint,
      reorder_term_id: normalizedReorderTermId,
      is_active: true,
      updated_by_id: userId,
      updated_at: new Date().toISOString(),
    };

    if (existingSetting?.id) {
      const { error: updateError } = await supabase
        .from("product_outlet_inventory_settings")
        .update(payload)
        .eq("id", existingSetting.id);

      if (updateError) throw new Error(updateError.message);
      return existingSetting.id;
    }

    const { error: insertError } = await supabase
      .from("product_outlet_inventory_settings")
      .insert({
        ...payload,
        created_by_id: userId,
      });

    if (insertError) throw new Error(insertError.message);
    return null;
  }

  private async getCompositeItemOutletInventorySetting(
    compositeItemId: string,
    orgId?: string | null,
    outletId?: string | null,
  ) {
    const supabase = this.supabaseService.getClient();
    const scope = this.resolveScope(orgId, outletId);

    if (scope.outletId) {
      const { data, error } = await supabase
        .from("composite_item_outlet_inventory_settings")
        .select(
          "id, org_id, outlet_id, composite_item_id, reorder_point, reorder_term_id, is_active",
        )
        .eq("composite_item_id", compositeItemId)
        .eq("org_id", scope.orgId)
        .eq("outlet_id", scope.outletId)
        .eq("is_active", true)
        .maybeSingle();

      if (error) throw new Error(error.message);
      if (data) return data;
    }

    const { data, error } = await supabase
      .from("composite_item_outlet_inventory_settings")
      .select(
        "id, org_id, outlet_id, composite_item_id, reorder_point, reorder_term_id, is_active",
      )
      .eq("composite_item_id", compositeItemId)
      .eq("org_id", scope.orgId)
      .is("outlet_id", null)
      .eq("is_active", true)
      .maybeSingle();

    if (error) throw new Error(error.message);
    return data ?? null;
  }

  private async syncCompositeItemOutletInventorySetting(
    compositeItemId: string,
    reorderPoint: number,
    reorderTermId: string | null,
    userId: string | null,
    orgId?: string | null,
    outletId?: string | null,
  ) {
    const supabase = this.supabaseService.getClient();
    const scope = this.resolveScope(orgId, outletId);
    const normalizedReorderPoint = Math.max(0, Number(reorderPoint) || 0);
    const normalizedReorderTermId = this.cleanUuid(reorderTermId);
    const hasMeaningfulSetting =
      normalizedReorderPoint > 0 || normalizedReorderTermId != null;

    let existingQuery = supabase
      .from("composite_item_outlet_inventory_settings")
      .select("id")
      .eq("composite_item_id", compositeItemId)
      .eq("org_id", scope.orgId);

    existingQuery = scope.outletId
      ? existingQuery.eq("outlet_id", scope.outletId)
      : existingQuery.is("outlet_id", null);

    const { data: existingSetting, error: existingError } =
      await existingQuery.maybeSingle();

    if (existingError) throw new Error(existingError.message);

    if (!hasMeaningfulSetting) {
      if (!existingSetting?.id) return null;

      const { error: clearError } = await supabase
        .from("composite_item_outlet_inventory_settings")
        .update({
          reorder_point: 0,
          reorder_term_id: null,
          is_active: false,
          updated_by_id: userId,
          updated_at: new Date().toISOString(),
        })
        .eq("id", existingSetting.id);

      if (clearError) throw new Error(clearError.message);
      return null;
    }

    const payload = {
      org_id: scope.orgId,
      outlet_id: scope.outletId,
      composite_item_id: compositeItemId,
      reorder_point: normalizedReorderPoint,
      reorder_term_id: normalizedReorderTermId,
      is_active: true,
      updated_by_id: userId,
      updated_at: new Date().toISOString(),
    };

    if (existingSetting?.id) {
      const { error: updateError } = await supabase
        .from("composite_item_outlet_inventory_settings")
        .update(payload)
        .eq("id", existingSetting.id);

      if (updateError) throw new Error(updateError.message);
      return existingSetting.id;
    }

    const { error: insertError } = await supabase
      .from("composite_item_outlet_inventory_settings")
      .insert({
        ...payload,
        created_by_id: userId,
      });

    if (insertError) throw new Error(insertError.message);
    return null;
  }

  private summarizeHistoryEntry(
    tableName: string,
    action: string,
    oldValues: Record<string, any> | null,
    newValues: Record<string, any> | null,
  ): { section: string; summary: string } {
    const actionLabel = action.toUpperCase();
    const batchRef =
      newValues?.batch ||
      oldValues?.batch ||
      newValues?.batchReference ||
      oldValues?.batchReference;
    const warehouseLabel =
      newValues?.warehouse_name || oldValues?.warehouse_name;

    switch (tableName) {
      case "products":
        return {
          section: "Products",
          summary:
            actionLabel === "INSERT"
              ? "Item created"
              : actionLabel === "DELETE"
                ? "Item deleted"
                : "Item updated",
        };
      case "product_contents":
        return {
          section: "Composition",
          summary:
            actionLabel === "INSERT"
              ? "Composition row added"
              : actionLabel === "DELETE"
                ? "Composition row removed"
                : "Composition row updated",
        };
      case "batches":
        return {
          section: "Batches",
          summary:
            actionLabel === "INSERT"
              ? `Batch added${batchRef ? ` (${batchRef})` : ""}`
              : actionLabel === "DELETE"
                ? `Batch deleted${batchRef ? ` (${batchRef})` : ""}`
                : `Batch updated${batchRef ? ` (${batchRef})` : ""}`,
        };
      case "price_list_items":
        return {
          section: "Price Lists",
          summary:
            actionLabel === "INSERT"
              ? "Price list association added"
              : actionLabel === "DELETE"
                ? "Price list association removed"
                : "Price list association updated",
        };
      case "product_warehouse_stocks":
        return {
          section: "Warehouses",
          summary:
            actionLabel === "INSERT"
              ? `Warehouse stock initialized${warehouseLabel ? ` (${warehouseLabel})` : ""}`
              : actionLabel === "DELETE"
                ? `Warehouse stock deleted${warehouseLabel ? ` (${warehouseLabel})` : ""}`
                : `Warehouse stock updated${warehouseLabel ? ` (${warehouseLabel})` : ""}`,
        };
      case "product_warehouse_stock_adjustments":
        return {
          section: "Warehouses",
          summary:
            actionLabel === "INSERT"
              ? `Physical stock adjusted${warehouseLabel ? ` (${warehouseLabel})` : ""}`
              : "Warehouse stock adjustment updated",
        };
      case "outlet_inventory":
        return {
          section: "Inventory",
          summary:
            actionLabel === "INSERT"
              ? "Outlet inventory row created"
              : actionLabel === "DELETE"
                ? "Outlet inventory row deleted"
                : "Outlet inventory updated",
        };
      case "product_outlet_inventory_settings":
        return {
          section: "Inventory",
          summary:
            actionLabel === "INSERT"
              ? "Outlet reorder settings created"
              : actionLabel === "DELETE"
                ? "Outlet reorder settings deleted"
                : "Outlet reorder settings updated",
        };
      case "composite_item_outlet_inventory_settings":
        return {
          section: "Inventory",
          summary:
            actionLabel === "INSERT"
              ? "Composite outlet reorder settings created"
              : actionLabel === "DELETE"
                ? "Composite outlet reorder settings deleted"
                : "Composite outlet reorder settings updated",
        };
      default:
        return {
          section: "History",
          summary: `${tableName} ${actionLabel.toLowerCase()}`,
        };
    }
  }

  /** Centralised UUID sanitization for product insert/update payloads. */
  private sanitizeProductPayload(
    data: Record<string, any>,
  ): Record<string, any> {
    return {
      ...data,
      unit_id: this.cleanUuid(data.unit_id),
      category_id: this.cleanUuid(data.category_id),
      intra_state_tax_id: this.cleanUuid(data.intra_state_tax_id),
      inter_state_tax_id: this.cleanUuid(data.inter_state_tax_id),
      sales_account_id: this.cleanUuid(data.sales_account_id),
      purchase_account_id: this.cleanUuid(data.purchase_account_id),
      preferred_vendor_id: this.cleanUuid(data.preferred_vendor_id),
      manufacturer_id: this.cleanUuid(data.manufacturer_id),
      brand_id: this.cleanUuid(data.brand_id),
      inventory_account_id: this.cleanUuid(data.inventory_account_id),
      storage_id: this.cleanUuid(data.storage_id),
      rack_id: this.cleanUuid(data.rack_id),
      reorder_term_id: this.cleanUuid(data.reorder_term_id),
      buying_rule_id: this.cleanUuid(data.buying_rule_id ?? data.buying_rule),
      schedule_of_drug_id:
        data.schedule_of_drug_id ?? data.schedule_of_drug ?? null,
      track_serial_number:
        data.track_serial_number ?? data.track_serial ?? null,
    };
  }

  async create(
    createProductDto: CreateProductDto,
    userId: string | null,
    scope?: { orgId?: string | null; outletId?: string | null },
  ) {
    const supabase = this.supabaseService.getClient();

    const { compositions, ...productData } = createProductDto as any;
    const reorderPoint = Number(productData.reorder_point) || 0;
    const reorderTermId = this.cleanUuid(productData.reorder_term_id);

    const insertPayload: Record<string, any> = {
      ...this.sanitizeProductPayload(productData),
      created_by_id: userId,
      updated_by_id: userId,
    };

    delete (insertPayload as any).buying_rule;
    delete (insertPayload as any).schedule_of_drug;
    delete (insertPayload as any).reorder_point;
    delete (insertPayload as any).reorder_term_id;

    // Strip null/undefined to let DB defaults work
    Object.keys(insertPayload).forEach(
      (key) =>
        (insertPayload[key] === undefined || insertPayload[key] === null) &&
        delete insertPayload[key],
    );

    const { data: product, error: productError } = await supabase
      .from("products")
      .insert(insertPayload)
      .select()
      .single();

    if (productError) {
      console.error("createProduct supabase error:", productError);
      if ((productError as any).code === "23505") {
        const detail = (productError as any).detail || "";
        if (detail.includes("item_code")) {
          throw new ConflictException(
            `Item code '${insertPayload.item_code}' already exists`,
          );
        } else if (detail.includes("sku")) {
          throw new ConflictException(
            `SKU '${insertPayload.sku}' already exists`,
          );
        }
        throw new ConflictException("Item code or SKU already exists");
      }
      // Throw with full message for frontend to parse
      throw new BadRequestException(
        `Failed to create product: ${productError.message}${productError.details ? " | " + productError.details : ""}${productError.hint ? " | " + productError.hint : ""}`,
      );
    }

    if (compositions && compositions.length > 0) {
      const compositionRows = compositions
        .map((comp: any, index: number) => {
          const contentId = this.cleanUuid(comp.content_id ?? comp.content);
          const strengthId = this.cleanUuid(comp.strength_id ?? comp.strength);

          // Skip completely empty rows
          if (!contentId && !strengthId) {
            return null;
          }

          return {
            product_id: product.id,
            content_id: contentId ?? null,
            strength_id: strengthId ?? null,
            display_order: index,
          };
        })
        .filter(Boolean);

      if (compositionRows.length > 0) {
        const { error: compError } = await supabase
          .from("product_contents")
          .insert(compositionRows);

        if (compError) {
          const msg = `Failed to save compositions: ${compError.message} | Code: ${compError.code} | Details: ${compError.details} | Hint: ${compError.hint}`;
          console.error("[compositions]", msg);
          throw new BadRequestException(msg);
        }
      }
    }

    await this.syncProductOutletInventorySetting(
      product.id,
      reorderPoint,
      reorderTermId,
      userId,
      scope?.orgId,
      scope?.outletId,
    );

    return product;
  }

  async createComposite(
    payload: any,
    userId: string = null,
    scope?: { orgId?: string | null; outletId?: string | null },
  ) {
    const supabase = this.supabaseService.getClient();

    // 1. Prepare main composite item data
    const { parts, ...mainData } = payload;
    const reorderPoint = Number(mainData.reorder_point) || 0;
    const reorderTermId = this.cleanUuid(mainData.reorder_term_id);

    // Clean and validate data before insert
    const insertPayload: Record<string, any> = {
      ...mainData,
      // Note: composite_items table uses 'sku' as primary identifier, doesn't have 'item_code'
      type: mainData.type || "assembly",
      // Map and clean UUIDs to prevent DB errors
      unit_id: this.cleanUuid(mainData.unit_id),
      category_id: this.cleanUuid(mainData.category_id),
      intra_state_tax_id: this.cleanUuid(mainData.intra_state_tax_id),
      inter_state_tax_id: this.cleanUuid(mainData.inter_state_tax_id),
      sales_account_id: this.cleanUuid(mainData.sales_account_id),
      purchase_account_id: this.cleanUuid(mainData.purchase_account_id),
      inventory_account_id: this.cleanUuid(mainData.inventory_account_id),
      preferred_vendor_id: this.cleanUuid(mainData.preferred_vendor_id),
      manufacturer_id: this.cleanUuid(mainData.manufacturer_id),
      brand_id: this.cleanUuid(mainData.brand_id),
      // Audit fields
      created_by_id: userId,
      updated_by_id: userId,
    };

    delete insertPayload.reorder_point;
    delete insertPayload.reorder_term_id;

    // Remove empty strings and undefined to let DB defaults work or avoid type errors
    Object.keys(insertPayload).forEach((key) => {
      if (insertPayload[key] === undefined || insertPayload[key] === "") {
        delete insertPayload[key];
      }
    });

    // 2. Create the main composite item
    const { data: composite, error: compositeError } = await supabase
      .from("composite_items")
      .insert(insertPayload)
      .select()
      .single();

    if (compositeError) {
      console.error("❌ Error creating composite item:", compositeError);
      if ((compositeError as any).code === "23505") {
        throw new ConflictException(
          "Composite item with this code or SKU already exists",
        );
      }
      throw new Error(
        `Failed to create composite item: ${compositeError.message}`,
      );
    }

    // 3. Save parts if present
    if (parts && parts.length > 0) {
      const partRows = parts
        .map((part: any) => {
          const componentId = this.cleanUuid(part.component_product_id);
          if (!componentId) return null;

          return {
            composite_item_id: composite.id,
            component_product_id: componentId,
            quantity: parseFloat(part.quantity) || 0,
            selling_price_override:
              parseFloat(part.selling_price_override) || 0,
            cost_price_override: parseFloat(part.cost_price_override) || 0,
          };
        })
        .filter(Boolean);

      if (partRows.length > 0) {
        const { error: partError } = await supabase
          .from("composite_item_parts")
          .insert(partRows);

        if (partError) {
          console.error("Failed to save composite item parts:", partError);
          throw new BadRequestException(
            `Failed to save composite parts: ${partError.message}`,
          );
        }
      }
    }

    await this.syncCompositeItemOutletInventorySetting(
      composite.id,
      reorderPoint,
      reorderTermId,
      userId,
      scope?.orgId,
      scope?.outletId,
    );

    return this.mapCompositeItem(composite, scope);
  }

  async findOne(
    id: string,
    scope?: { orgId?: string | null; outletId?: string | null },
  ) {
    const supabase = this.supabaseService.getClient();

    const { data, error } = await supabase
      .from("products")
      .select(this.PRODUCT_SELECT_STRING)
      .eq("id", id)
      .single();

    if (error) {
      console.error(`❌ Error fetching product ${id}:`, error);
      throw new NotFoundException(
        `Product with ID ${id} not found: ${error.message}`,
      );
    }

    return this.mapProduct(data, scope);
  }

  async countProducts() {
    const supabase = this.supabaseService.getClient();
    const { count, error } = await supabase
      .from("products")
      .select("*", { count: "exact", head: true });

    if (error) {
      console.error("❌ Error fetching products count:", error);
      throw new Error(`Failed to fetch products count: ${error.message}`);
    }

    return { count };
  }

  async findAll(limit?: number, offset?: number) {
    const supabase = this.supabaseService.getClient();

    let query = supabase
      .from("products")
      .select(this.PRODUCT_SELECT_STRING)
      .order("created_at", { ascending: false });

    if (limit !== undefined && !isNaN(limit)) {
      query = query.limit(limit);
    } else if (limit === undefined) {
      query = query.limit(1000);
    }

    if (offset !== undefined && !isNaN(offset)) {
      const currentLimit = limit && !isNaN(limit) ? limit : 1000;
      query = query.range(offset, offset + currentLimit - 1);
    }

    const { data, error } = await query;

    if (error) {
      console.error("❌ Error fetching products:", error);
      throw new Error(`Failed to fetch products: ${error.message}`);
    }

    const products = data || [];
    return Promise.all(products.map((p) => this.mapProduct(p)));
  }

  async findAllCursor(limit?: number, cursor?: string) {
    const supabase = this.supabaseService.getClient();
    const finalLimit = limit !== undefined && !isNaN(limit) ? limit : 50;

    let query = supabase
      .from("products")
      .select(this.PRODUCT_SELECT_STRING)
      .eq("is_active", true)
      .order("id", { ascending: false });

    if (cursor) {
      query = query.lt("id", cursor);
    }

    query = query.limit(finalLimit);

    const { data, error } = await query;
    if (error) {
      console.error("Cursor fetch error:", error);
      throw new Error(`Failed to fetch cursor items: ${error.message}`);
    }

    // Only provide next_cursor if we returned a full page
    let next_cursor = null;
    if (data && data.length === finalLimit) {
      next_cursor = data[data.length - 1].id;
    }

    console.log(
      `[findAllCursor] cursor=${cursor ?? "START"} fetched=${data?.length ?? 0} next=${next_cursor ? "yes" : "null"}`,
    );

    return {
      items: data ? await Promise.all(data.map((p) => this.mapProduct(p))) : [],
      next_cursor,
    };
  }

  async searchProducts(q?: string, limit: number = 30, _outletId?: string) {
    if (!q || q.length < 2) return [];

    const supabase = this.supabaseService.getClient();
    const queryTerm = q.trim();

    // Prioritize exact matches (EAN, SKU, Item Code) vs Trigram/Prefix
    const { data, error } = await supabase
      .from("products")
      .select(this.PRODUCT_SELECT_STRING)
      .eq("is_active", true)
      .or(
        `sku.eq."${queryTerm}",ean.eq."${queryTerm}",item_code.eq."${queryTerm}",product_name.ilike."${queryTerm}%",product_name.ilike."%${queryTerm}%"`,
      )
      .limit(limit);

    if (error) {
      console.error("Search error:", error);
      throw new Error(`Search failed: ${error.message}`);
    }

    // Sort exact matches higher locally to guarantee precision
    const exactMatches = data.filter(
      (d) =>
        d.sku === queryTerm || d.ean === queryTerm || d.item_code === queryTerm,
    );
    const prefixMatches = data.filter(
      (d) =>
        !exactMatches.includes(d) &&
        d.product_name?.toLowerCase().startsWith(queryTerm.toLowerCase()),
    );
    const otherMatches = data.filter(
      (d) => !exactMatches.includes(d) && !prefixMatches.includes(d),
    );

    return Promise.all(
      [...exactMatches, ...prefixMatches, ...otherMatches].map((p) =>
        this.mapProduct(p),
      ),
    );
  }

  async getBulkStock(outletId: string, productIds: string[]) {
    if (!productIds || productIds.length === 0) return { stocks: [] };

    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("outlet_inventory")
      .select("product_id, current_stock, available_stock")
      .eq("outlet_id", outletId)
      .in("product_id", productIds);

    if (error) {
      console.error("Bulk stock fetch error:", error);
      throw new Error(`Bulk stock fetch failed: ${error.message}`);
    }

    return { stocks: data || [] };
  }

  async getBatches(productId: string) {
    const supabase = this.supabaseService.getClient();

    // 1. Fetch batch_master records
    const { data: masterData, error: masterError } = await supabase
      .from("batch_master")
      .select("*")
      .eq("product_id", productId)
      .eq("is_active", true)
      .order("expiry_date", { ascending: true });

    if (masterError) {
      console.error("Error fetching batch_master:", masterError);
      throw new Error(`Failed to fetch batches (master): ${masterError.message}`);
    }

    // 2. Fetch batches records for pricing
    const { data: pricingData, error: pricingError } = await supabase
      .from("batches")
      .select("batch, mrp, ptr")
      .eq("product_id", productId)
      .eq("is_active", true);

    if (pricingError) {
      console.error("Error fetching batches (pricing):", pricingError);
      // We don't throw here, just proceed without pricing if it fails
    }

    // 3. Create a lookup map for pricing
    const priceMap = new Map();
    if (pricingData) {
      for (const p of pricingData) {
        priceMap.set(p.batch?.toString().trim(), {
          mrp: p.mrp,
          ptr: p.ptr,
        });
      }
    }

    // 4. Merge and map
    return (masterData || []).map((batch: any) => {
      const price = priceMap.get(batch.batch_no?.toString().trim());
      
      return {
        batch: batch.batch_no,
        batch_no: batch.batch_no,
        exp: batch.expiry_date,
        expiry_date: batch.expiry_date,
        unit_pack: batch.unit_pack,
        mrp: price ? price.mrp : null,
        ptr: price ? price.ptr : null,
        is_manufacture_details: batch.is_manufacture_details,
        manufacture_batch_number: batch.manufacture_batch_number,
        manufacture_exp: batch.manufacture_exp,
        is_active: batch.is_active,
      };
    });
  }

  async createBatch(productId: string, body: any) {
    const supabase = this.supabaseService.getClient();
    const payload = {
      product_id: productId,
      batch_no: body.batch || body.batch_no,
      expiry_date: body.exp || body.expiry_date,
      unit_pack: body.unit_pack != null ? String(body.unit_pack) : null,
      is_manufacture_details: body.is_manufacture_details ?? false,
      manufacture_batch_number: body.manufacture_batch_number || null,
      manufacture_exp: body.manufacture_exp || null,
      is_active: true,
    };

    const { data, error } = await supabase
      .from("batch_master")
      .insert([payload])
      .select()
      .single();

    if (error) {
      console.error("Error creating batch:", error);

      if (
        (error.message || "").includes("permission denied for table batch_master")
      ) {
        try {
          const [fallbackCreated] = await db
            .insert(batchMaster)
            .values({
              productId,
              batchNo: payload.batch_no,
              expiryDate: payload.expiry_date,
              unitPack: payload.unit_pack,
              isManufactureDetails: payload.is_manufacture_details,
              manufactureBatchNumber: payload.manufacture_batch_number,
              manufactureExp: payload.manufacture_exp,
              isActive: true,
            })
            .returning();

          if (fallbackCreated) {
            return fallbackCreated;
          }
        } catch (fallbackError: any) {
          console.error("Fallback insert into batch_master failed:", fallbackError);
        }
      }

      throw new BadRequestException(
        `Failed to create batch: ${error.message} - ${error.details || ""} - ${error.hint || ""}`,
      );
    }
    return data;
  }

  async getCompositeItems(scope?: {
    orgId?: string | null;
    outletId?: string | null;
  }) {
    const supabase = this.supabaseService.getClient();

    try {
      const { data, error } = await supabase
        .from("composite_items")
        .select(
          `
          *,
          parts:composite_item_parts(
            *,
            product:products!component_product_id(*)
          )
        `,
        )
        .order("created_at", { ascending: false });

      if (error) {
        console.error("❌ Supabase error fetching composite items:", error);
        throw new Error(`Supabase error: ${error.message}`);
      }

      console.log(
        `✅ Successfully fetched ${data?.length || 0} composite items`,
      );
      return Promise.all(
        (data || []).map((item) => this.mapCompositeItem(item, scope)),
      );
    } catch (error) {
      console.error("❌ Error in getCompositeItems:", error);
      throw error;
    }
  }

  async update(
    id: string,
    updateProductDto: UpdateProductDto,
    userId: string | null,
    scope?: { orgId?: string | null; outletId?: string | null },
  ) {
    const supabase = this.supabaseService.getClient();

    // Separate compositions from main product data
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { compositions, ...productData } = updateProductDto as any;

    const reorderPoint = Number(productData.reorder_point) || 0;
    const reorderTermId = this.cleanUuid(productData.reorder_term_id);

    const payload: Record<string, any> = {
      ...this.sanitizeProductPayload(productData),
      updated_by_id: userId,
    };

    delete (payload as any).buying_rule;
    delete (payload as any).schedule_of_drug;
    delete (payload as any).reorder_point;
    delete (payload as any).reorder_term_id;

    // Strip undefined values to avoid updating columns that weren't intended
    Object.keys(payload).forEach(
      (key) =>
        (payload[key] === undefined || payload[key] === null) &&
        delete payload[key],
    );

    const { data, error } = await supabase
      .from("products")
      .update(payload)
      .eq("id", id)
      .select()
      .single();

    if (error) {
      if ((error as any).code === "23505") {
        const detail = (error as any).detail || "";
        if (detail.includes("item_code")) {
          throw new ConflictException(
            `Item code '${payload.item_code}' already exists`,
          );
        } else if (detail.includes("sku")) {
          throw new ConflictException(`SKU '${payload.sku}' already exists`);
        }
        throw new ConflictException("Item code or SKU already exists");
      }
      throw new Error(`Failed to update product: ${error.message}`);
    }

    // Handle compositions update if provided
    if (compositions !== undefined) {
      // 1. Delete existing compositions
      const { error: deleteError } = await supabase
        .from("product_contents")
        .delete()
        .eq("product_id", id);

      if (deleteError) {
        console.error("Failed to delete old compositions:", deleteError);
      } else if (compositions && compositions.length > 0) {
        // 2. Insert new compositions
        const compositionRows = compositions
          .map((comp: any, index: number) => {
            const contentId = this.cleanUuid(comp.content_id ?? comp.content);
            const strengthId = this.cleanUuid(
              comp.strength_id ?? comp.strength,
            );

            // Skip completely empty rows
            if (!contentId && !strengthId) {
              return null;
            }

            return {
              product_id: id,
              content_id: contentId ?? null,
              strength_id: strengthId ?? null,
              display_order: index,
            };
          })
          .filter(Boolean);

        if (compositionRows.length > 0) {
          const { error: insertError } = await supabase
            .from("product_contents")
            .insert(compositionRows);

          if (insertError) {
            console.error("Failed to insert new compositions:", insertError);
            throw new BadRequestException(
              `Failed to update compositions: ${insertError.message}`,
            );
          }
        }
      }
    }

    await this.syncProductOutletInventorySetting(
      id,
      reorderPoint,
      reorderTermId,
      userId,
      scope?.orgId,
      scope?.outletId,
    );

    return this.findOne(id, scope);
  }

  async bulkUpdate(
    ids: string[],
    updateProductDto: UpdateProductDto,
    userId: string,
  ) {
    const supabase = this.supabaseService.getClient();

    if (!ids || ids.length === 0) {
      return { message: "No items to update", count: 0 };
    }

    const payload: Record<string, any> = {
      ...this.sanitizeProductPayload(updateProductDto as any),
      updated_by_id: userId,
    };

    delete (payload as any).buying_rule;
    delete (payload as any).schedule_of_drug;

    // Strip undefined values to avoid updating columns that weren't intended
    Object.keys(payload).forEach(
      (key) =>
        (payload[key] === undefined || payload[key] === null) &&
        delete payload[key],
    );

    const { data, error } = await supabase
      .from("products")
      .update(payload)
      .in("id", ids)
      .select();

    if (error) {
      console.error("bulkUpdate error:", error);
      throw new Error(`Failed to bulk update products: ${error.message}`);
    }

    return {
      message: `Successfully updated ${data?.length || 0} items`,
      count: data?.length || 0,
    };
  }

  async remove(id: string) {
    const supabase = this.supabaseService.getClient();

    const { error } = await supabase
      .from("products")
      .update({ is_active: false })
      .eq("id", id);

    if (error) {
      throw new Error(`Failed to delete product: ${error.message}`);
    }

    return { message: "Product deleted successfully" };
  }

  // LOOKUP METHODS
  async getUnits() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("units")
      .select("*")
      .eq("is_active", true);

    if (error) throw new Error(error.message);
    return data;
  }

  async getUQCs() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("uqc")
      .select("*")
      .eq("is_active", true);

    if (error) throw new Error(error.message);
    return data;
  }

  async syncUnits(units: any[]) {
    console.log(
      "🔄 [syncUnits] Received units:",
      JSON.stringify(units, null, 2),
    );
    const validUnits = units.filter((u) => {
      if (
        !u ||
        !u.unit_name ||
        typeof u.unit_name !== "string" ||
        u.unit_name.trim() === ""
      ) {
        console.warn("⚠️ [syncUnits] Skipping unit with invalid data:", u);
        return false;
      }
      return true;
    });

    // Use raw pg to preserve uqc_id FK column (Supabase upsert strips it)
    const client = new Client({ connectionString: process.env.DATABASE_URL });
    await client.connect();

    try {
      const results: any[] = [];

      for (const u of validUnits) {
        const id =
          u.id && typeof u.id === "string" && this.isUUID(u.id) ? u.id : null;
        const uqcId =
          u.uqc_id && typeof u.uqc_id === "string" && u.uqc_id.trim() !== ""
            ? u.uqc_id.trim()
            : null;
        const unitSymbol =
          typeof u.unit_symbol === "string"
            ? u.unit_symbol.trim().slice(0, 10)
            : null;
        const unitType = u.unit_type ?? null;
        const isActive = u.is_active !== undefined ? u.is_active : true;
        const unitName = u.unit_name.trim();

        let row: any;

        if (id) {
          const res = await client.query(
            `UPDATE units
               SET unit_name = $1, unit_symbol = $2, uqc_id = $3, unit_type = $4, is_active = $5
             WHERE id = $6
             RETURNING *`,
            [unitName, unitSymbol, uqcId, unitType, isActive, id],
          );
          row = res.rows[0];
          if (!row) {
            // ID provided but no match — insert as new
            const ins = await client.query(
              `INSERT INTO units (unit_name, unit_symbol, uqc_id, unit_type, is_active)
               VALUES ($1, $2, $3, $4, $5)
               ON CONFLICT (unit_name) DO UPDATE
                 SET unit_symbol = EXCLUDED.unit_symbol,
                     uqc_id = EXCLUDED.uqc_id,
                     unit_type = EXCLUDED.unit_type,
                     is_active = EXCLUDED.is_active
               RETURNING *`,
              [unitName, unitSymbol, uqcId, unitType, isActive],
            );
            row = ins.rows[0];
          }
        } else {
          const ins = await client.query(
            `INSERT INTO units (unit_name, unit_symbol, uqc_id, unit_type, is_active)
             VALUES ($1, $2, $3, $4, $5)
             ON CONFLICT (unit_name) DO UPDATE
               SET unit_symbol = EXCLUDED.unit_symbol,
                   uqc_id = EXCLUDED.uqc_id,
                   unit_type = EXCLUDED.unit_type,
                   is_active = EXCLUDED.is_active
             RETURNING *`,
            [unitName, unitSymbol, uqcId, unitType, isActive],
          );
          row = ins.rows[0];
        }

        if (row) results.push(row);
      }

      console.log(
        "✅ [syncUnits] Synced with uqc_id preserved:",
        results.map((r) => ({ id: r.id, uqc_id: r.uqc_id })),
      );
      return results;
    } finally {
      await client.end();
    }
  }

  async getContentUnits() {
    try {
      const supabase = this.supabaseService.getClient();
      const { data, error } = await supabase
        .from("content_unit")
        .select("*")
        .eq("is_active", true);

      if (error) {
        console.warn("⚠️  content_unit table not found, returning empty array");
        return [];
      }
      return data || [];
    } catch (error) {
      console.warn("⚠️  Error fetching content_unit:", error.message);
      return [];
    }
  }

  async syncContentUnits(items: any[]) {
    return this.syncTableMetadata(
      "content_unit",
      items,
      (item) => ({
        name: item.name?.trim?.() || item.name,
      }),
      "name",
    );
  }

  async checkUnitUsage(unitIds: string[]) {
    const supabase = this.supabaseService.getClient();

    console.log("🔍 Checking unit usage for IDs:", unitIds);

    const { data, error } = await supabase
      .from("products")
      .select("unit_id, product_name, is_active")
      .in("unit_id", unitIds);

    console.log("📊 Query result:", { data, error, count: data?.length });

    if (error) {
      console.error("Error checking unit usage:", error);
      return { unitsInUse: [] };
    }

    const unitsInUse = [...new Set(data.map((p) => p.unit_id))];
    console.log("✅ Units in use:", unitsInUse);
    if (data && data.length > 0) {
      console.log(
        "✅ Associated items:",
        data.map((p) => p.product_name),
      );
    }
    return { unitsInUse };
  }

  async checkLookupUsage(lookup: string, id: string) {
    const supabase = this.supabaseService.getClient();
    const key = (lookup || "").toLowerCase();

    if (!id || typeof id !== "string" || id.trim().length === 0) {
      return { inUse: false };
    }

    type UsageCheck = {
      table: string;
      column: string;
      description?: string;
      filterActive?: boolean;
    };

    const checks: UsageCheck[] = [];

    switch (key) {
      case "manufacturers":
        checks.push({
          table: "products",
          column: "manufacturer_id",
          description: "products",
          filterActive: false,
        });
        break;
      case "brands":
        checks.push({
          table: "products",
          column: "brand_id",
          description: "products",
          filterActive: false,
        });
        break;
      case "vendors":
        checks.push({
          table: "products",
          column: "preferred_vendor_id",
          description: "products",
          filterActive: true,
        });
        break;
      case "storage-conditions":
        checks.push({
          table: "products",
          column: "storage_id",
          description: "products",
          filterActive: false,
        });
        checks.push({
          table: "racks",
          column: "storage_id",
          description: "racks",
          filterActive: false,
        });
        break;
      case "racks":
        checks.push({
          table: "products",
          column: "rack_id",
          description: "products",
          filterActive: true,
        });
        break;
      case "reorder-terms":
        checks.push({
          table: "products",
          column: "reorder_term_id",
          description: "products",
          filterActive: false,
        });
        checks.push({
          table: "composite_items",
          column: "reorder_term_id",
          description: "composite items",
          filterActive: false,
        });
        checks.push({
          table: "product_outlet_inventory_settings",
          column: "reorder_term_id",
          description: "outlet inventory settings",
          filterActive: true,
        });
        checks.push({
          table: "composite_item_outlet_inventory_settings",
          column: "reorder_term_id",
          description: "composite outlet inventory settings",
          filterActive: true,
        });
        break;
      case "accounts":
        checks.push({
          table: "products",
          column: "sales_account_id",
          description: "products",
          filterActive: true,
        });
        checks.push({
          table: "products",
          column: "purchase_account_id",
          description: "products",
          filterActive: true,
        });
        checks.push({
          table: "products",
          column: "inventory_account_id",
          description: "products",
          filterActive: true,
        });
        break;
      case "contents":
        checks.push({
          table: "product_compositions",
          column: "content_id",
          description: "product compositions",
          filterActive: false,
        });
        break;
      case "strengths":
      case "drug_strengths":
        checks.push({
          table: "product_compositions",
          column: "strength_id",
          description: "product compositions",
          filterActive: false,
        });
        break;
      case "content-units":
        // Removed as column content_unit_id was removed from product_compositions
        break;
      case "buying-rules":
        checks.push({
          table: "products",
          column: "buying_rule_id",
          description: "products",
          filterActive: false,
        });
        break;
      case "drug-schedules":
      case "drug_schedules":
      case "drug-drug_schedules":
        checks.push({
          table: "products",
          column: "schedule_of_drug_id",
          description: "products",
          filterActive: false,
        });
        break;
      case "categories":
        checks.push({
          table: "products",
          column: "category_id",
          description: "products",
          filterActive: false,
        });
        checks.push({
          table: "composite_items",
          column: "category_id",
          description: "composite items",
          filterActive: false,
        });
        checks.push({
          table: "categories",
          column: "parent_id",
          description: "sub-categories",
          filterActive: false,
        });
        break;
      case "units":
        checks.push({
          table: "products",
          column: "unit_id",
          description: "products",
          filterActive: false,
        });
        break;
      case "tax-groups":
      case "tax_groups":
        checks.push({
          table: "products",
          column: "intra_state_tax_id",
          description: "products",
          filterActive: false,
        });
        break;
      case "tax-rates":
      case "associate-taxes":
      case "tax_rates":
        checks.push({
          table: "products",
          column: "inter_state_tax_id",
          description: "products",
          filterActive: false,
        });
        checks.push({
          table: "tax_group_rates",
          column: "tax_id",
          description: "tax groups",
          filterActive: false,
        });
        break;
      default:
        console.warn(
          `[UsageCheck] No usage mapping found for lookup "${lookup}"`,
        );
    }

    let inUse = false;
    const usedInSet = new Set<string>();

    for (const check of checks) {
      try {
        let query = supabase
          .from(check.table)
          .select("id")
          .eq(check.column, id)
          .limit(1);

        if (check.filterActive) {
          query = query.eq("is_active", true);
        }

        const { data, error } = await query;

        if (error) {
          console.error(
            `[UsageCheck] Error checking ${check.table}.${check.column}:`,
            error,
          );
          continue;
        }

        if (data && data.length > 0) {
          inUse = true;
          usedInSet.add(check.description ?? check.table);
        }
      } catch (err) {
        console.error(
          `[UsageCheck] Fatal error for ${check.table}.${check.column}:`,
          err,
        );
      }
    }

    if (inUse) {
      return {
        inUse: true,
        usedIn: Array.from(usedInSet),
      };
    }

    return { inUse: false };
  }

  async getCategories() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("categories")
      .select("*")
      .eq("is_active", true);

    if (error) throw new Error(error.message);
    return data;
  }

  async syncCategories(items: any[]) {
    return this.syncTableMetadata(
      "categories",
      items,
      (item) => ({
        name: item.name,
        description: item.description,
        parent_id: this.cleanUuid(item.parent_id),
      }),
      "name",
    );
  }

  async getTaxRates() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("tax_rates")
      .select("*")
      .eq("is_active", true);

    if (error) throw new Error(error.message);
    return data;
  }

  async syncTaxRates(items: any[]) {
    return this.syncTableMetadata(
      "tax_rates",
      items,
      (item) => ({
        tax_name: item.tax_name || item.taxName,
        tax_rate: item.tax_rate || item.taxRate,
        tax_type: item.tax_type || item.taxType,
      }),
      "tax_name",
    );
  }

  async getTaxGroups() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("tax_groups")
      .select("*")
      .eq("is_active", true);

    if (error) throw new Error(error.message);
    return data;
  }

  async syncTaxGroups(items: any[]) {
    return this.syncTableMetadata(
      "tax_groups",
      items,
      (item) => ({
        tax_group_name:
          item.tax_group_name || item.taxGroupName || item.tax_name,
        tax_rate: item.tax_rate || item.taxRate,
      }),
      "tax_group_name",
    );
  }

  async getManufacturers() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("manufacturers")
      .select("id, name, is_active")
      .eq("is_active", true)
      .order("name", { ascending: true });

    if (error) throw new Error(error.message);
    return data;
  }

  async syncManufacturers(items: any[]) {
    console.log(
      "🔵 [syncManufacturers] Received items:",
      JSON.stringify(items, null, 2),
    );

    // Filter out items without a valid name
    const validItems = items.filter((item) => {
      if (
        !item.name ||
        typeof item.name !== "string" ||
        item.name.trim() === ""
      ) {
        console.warn(
          "⚠️ [syncManufacturers] Skipping item with invalid name:",
          item,
        );
        return false;
      }
      return true;
    });

    console.log(
      `🔵 [syncManufacturers] Processing ${validItems.length} valid items out of ${items.length} total`,
    );

    const itemsWithIds = validItems.map((item) => {
      const hasValidId =
        item.id && typeof item.id === "string" && item.id.trim().length > 5;
      return {
        ...item,
        id: hasValidId ? item.id : randomUUID(),
      };
    });

    return this.syncTableMetadata(
      "manufacturers",
      itemsWithIds,
      (item) => {
        console.log(
          "🔵 [syncManufacturers] Mapping item:",
          JSON.stringify(item, null, 2),
        );
        const mapped = { name: item.name.trim() };
        console.log(
          "🔵 [syncManufacturers] Mapped to:",
          JSON.stringify(mapped, null, 2),
        );
        return mapped;
      },
      "name",
    );
  }

  async getBrands() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("brands")
      .select("id, name, is_active")
      .eq("is_active", true)
      .order("name", { ascending: true });

    if (error) throw new Error(error.message);
    return data;
  }

  async syncBrands(items: any[]) {
    return this.syncTableMetadata(
      "brands",
      items,
      (item) => ({
        name: item.name,
        manufacturer_id: this.cleanUuid(item.manufacturer_id),
      }),
      "name",
    );
  }

  async getVendors() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("vendors")
      .select("id, display_name, vendor_number, company_name, is_active")
      .eq("is_active", true)
      .order("display_name", { ascending: true });

    if (error) throw new Error(error.message);
    return data;
  }

  async syncVendors(items: any[]) {
    return this.syncTableMetadata(
      "vendors",
      items,
      (item) => ({ vendor_name: item.name }),
      "vendor_name",
    );
  }

  async getStorageLocations() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("storage_conditions")
      .select(
        "id, location_name, storage_type, temperature_range, display_text, description, common_examples, min_temp_c, max_temp_c, is_cold_chain, requires_fridge, sort_order, is_active",
      )
      .eq("is_active", true)
      .order("sort_order", { ascending: true })
      .order("display_text", { ascending: true });

    if (error) throw new Error(error.message);
    return data;
  }

  async getWarehouses(scope?: {
    orgId?: string | null;
    outletId?: string | null;
  }) {
    const supabase = this.supabaseService.getClient();
    const resolvedScope = this.resolveScope(scope?.orgId, scope?.outletId);

    let query = supabase
      .from("warehouses")
      .select("id, org_id, outlet_id, name, is_active")
      .eq("org_id", resolvedScope.orgId)
      .eq("is_active", true);

    if (resolvedScope.outletId != null) {
      query = query.eq("outlet_id", resolvedScope.outletId);
    }

    const { data, error } = await query.order("name", { ascending: true });

    if (error) throw new Error(error.message);
    return data;
  }

  async syncStorageLocations(items: any[]) {
    return this.syncTableMetadata(
      "storage_conditions",
      items,
      (item) => ({ location_name: item.name }),
      "location_name",
    );
  }

  async getRacks() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("racks")
      .select("id, rack_code, rack_name, storage_id, capacity, is_active")
      .eq("is_active", true)
      .order("rack_code", { ascending: true });

    if (error) throw new Error(error.message);
    return data;
  }

  async syncRacks(items: any[]) {
    return this.syncTableMetadata(
      "racks",
      items,
      (item) => ({
        rack_code: item.name,
        storage_id: this.cleanUuid(item.storage_id),
      }),
      "rack_code",
    );
  }

  async getReorderTerms(scope?: {
    orgId?: string | null;
    outletId?: string | null;
  }) {
    return this.getScopedReorderTerms(scope?.orgId, scope?.outletId);
  }

  async createReorderTerm(
    termData: {
      term_name: string;
      quantity: number;
      description?: string;
    },
    scope?: { orgId?: string | null; outletId?: string | null },
  ) {
    const supabase = this.supabaseService.getClient();
    const resolvedScope = this.resolveScope(scope?.orgId, scope?.outletId);

    // Validation
    if (!termData.term_name || termData.term_name.trim() === "") {
      throw new Error("Term name is required");
    }
    if (!termData.quantity || termData.quantity <= 0) {
      throw new Error("Quantity must be greater than 0");
    }

    const { data, error } = await supabase
      .from("reorder_terms")
      .insert({
        org_id: resolvedScope.orgId,
        outlet_id: resolvedScope.outletId,
        term_name: termData.term_name.trim(),
        quantity: termData.quantity,
        description: termData.description || null,
        is_active: true,
      })
      .select()
      .single();

    if (error) {
      if (error.code === "23505") {
        // Unique constraint violation
        throw new Error("A reorder term with this name already exists");
      }
      throw new Error(error.message);
    }

    return data;
  }

  async updateReorderTerm(
    id: string,
    termData: {
      term_name?: string;
      quantity?: number;
      description?: string;
    },
    scope?: { orgId?: string | null; outletId?: string | null },
  ) {
    const supabase = this.supabaseService.getClient();
    const resolvedScope = this.resolveScope(scope?.orgId, scope?.outletId);

    // Validation
    if (termData.term_name !== undefined && termData.term_name.trim() === "") {
      throw new Error("Term name cannot be empty");
    }
    if (termData.quantity !== undefined && termData.quantity <= 0) {
      throw new Error("Quantity must be greater than 0");
    }

    const updateData: any = {};
    if (termData.term_name !== undefined) {
      updateData.term_name = termData.term_name.trim();
    }
    if (termData.quantity !== undefined) {
      updateData.quantity = termData.quantity;
    }
    if (termData.description !== undefined) {
      updateData.description = termData.description;
    }

    let query = supabase
      .from("reorder_terms")
      .update(updateData)
      .eq("id", id)
      .eq("org_id", resolvedScope.orgId);

    query =
      resolvedScope.outletId != null
        ? query.eq("outlet_id", resolvedScope.outletId)
        : query.is("outlet_id", null);

    const { data, error } = await query.select().single();

    if (error) {
      if (error.code === "23505") {
        throw new Error("A reorder term with this name already exists");
      }
      throw new Error(error.message);
    }

    return data;
  }

  async deleteReorderTerm(
    id: string,
    scope?: { orgId?: string | null; outletId?: string | null },
  ) {
    const supabase = this.supabaseService.getClient();
    const resolvedScope = this.resolveScope(scope?.orgId, scope?.outletId);

    // Check if the reorder term is being used by any products
    const usageCheck = await this.checkLookupUsage("reorder-terms", id);
    if (usageCheck.inUse) {
      throw new Error(
        `Cannot delete this reorder term because it is being used by ${usageCheck.usedIn}`,
      );
    }

    // Soft delete
    let query = supabase
      .from("reorder_terms")
      .update({ is_active: false, updated_at: new Date().toISOString() })
      .eq("id", id)
      .eq("org_id", resolvedScope.orgId);

    query =
      resolvedScope.outletId != null
        ? query.eq("outlet_id", resolvedScope.outletId)
        : query.is("outlet_id", null);

    const { error } = await query;

    if (error) {
      throw new Error(`Failed to delete reorder term: ${error.message}`);
    }

    return { message: "Reorder term deleted successfully" };
  }

  async syncReorderTerms(
    items: any[],
    scope?: { orgId?: string | null; outletId?: string | null },
  ) {
    const supabase = this.supabaseService.getClient();
    const resolvedScope = this.resolveScope(scope?.orgId, scope?.outletId);
    let currentQuery = supabase
      .from("reorder_terms")
      .select("id, term_name, is_active")
      .eq("org_id", resolvedScope.orgId);

    currentQuery =
      resolvedScope.outletId != null
        ? currentQuery.eq("outlet_id", resolvedScope.outletId)
        : currentQuery.is("outlet_id", null);

    const { data: currentRecords, error: fetchError } = await currentQuery;

    if (fetchError) throw fetchError;

    const existingRecords = (currentRecords || []) as any[];
    const activeIds = existingRecords
      .filter((r) => r.is_active === true)
      .map((r) => r.id);

    const toUpsert = items.map((item) => {
      const normalizedName = item.term_name?.trim?.() || item.term_name;
      const byId =
        item.id && this.isUUID(item.id)
          ? existingRecords.find((r) => r.id === item.id)
          : null;
      const byName = !byId
        ? existingRecords.find(
            (r) =>
              (r.term_name ?? "").toString().trim().toLowerCase() ===
              (normalizedName ?? "").toString().trim().toLowerCase(),
          )
        : null;

      return {
        id:
          byId?.id ??
          byName?.id ??
          (this.isUUID(item.id) ? item.id : randomUUID()),
        org_id: resolvedScope.orgId,
        outlet_id: resolvedScope.outletId,
        term_name: normalizedName,
        quantity: item.quantity,
        description: item.description || null,
        is_active: item.is_active ?? true,
        updated_at: new Date().toISOString(),
      };
    });

    const incomingIds = toUpsert.map((item) => item.id);
    const idsToDisable = activeIds.filter((id) => !incomingIds.includes(id));

    if (idsToDisable.length > 0) {
      const trulyDisableableIds: string[] = [];
      const inUseItems: Array<{ id: string; usedIn: any }> = [];

      for (const id of idsToDisable) {
        const usageResult = await this.checkLookupUsage("reorder-terms", id);
        if (!usageResult.inUse) {
          trulyDisableableIds.push(id);
        } else {
          inUseItems.push({ id, usedIn: usageResult.usedIn } as any);
        }
      }

      if (inUseItems.length > 0) {
        const itemNames = inUseItems.map((i) => {
          const rec = existingRecords.find((r) => r.id === i.id);
          return rec?.term_name ?? i.id;
        });
        throw new ConflictException(
          `Cannot delete "${itemNames.join(", ")}" because it is associated with active outlet inventory settings`,
        );
      }

      if (trulyDisableableIds.length > 0) {
        const { error: disableError } = await supabase
          .from("reorder_terms")
          .update({ is_active: false, updated_at: new Date().toISOString() })
          .in("id", trulyDisableableIds);

        if (disableError) throw disableError;
      }
    }

    const { data, error } = await supabase
      .from("reorder_terms")
      .upsert(toUpsert, { onConflict: "id" })
      .select(
        "id, org_id, outlet_id, term_name, quantity, description, is_active",
      );

    if (error) throw error;
    return data ?? [];
  }

  async getAccounts() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("accounts")
      .select(
        "id, user_account_name, system_account_name, account_type, is_active",
      )
      .eq("is_active", true)
      .eq("account_type", "Stock")
      .order("system_account_name", { ascending: true });

    if (error) throw new Error(error.message);
    return data;
  }

  async syncAccounts(items: any[]) {
    return this.syncTableMetadata(
      "accounts",
      items,
      (item) => ({
        account_name: item.name,
        account_type: item.type || "expense",
      }),
      "account_name",
    );
  }

  async getContents() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("contents")
      .select("id, content_name, is_active")
      .eq("is_active", true)
      .order("content_name", { ascending: true });

    if (error) return [];
    return data;
  }

  async syncContents(items: any[]) {
    return this.syncTableMetadata(
      "contents",
      items,
      (item) => ({ content_name: item.name?.trim() || item.name }),
      "content_name",
    );
  }

  async getStrengths() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("drug_strengths")
      .select("id, strength_name, is_active")
      .eq("is_active", true)
      .order("strength_name", { ascending: true });

    if (error) return [];
    return data;
  }

  async syncStrengths(items: any[]) {
    return this.syncTableMetadata(
      "drug_strengths",
      items,
      (item) => ({ strength_name: item.name?.trim() || item.name }),
      "strength_name",
    );
  }

  async getBuyingRules() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("buying_rules")
      .select(
        "id, buying_rule, rule_description, system_behavior, associated_schedule_codes, requires_rx, requires_patient_info, is_saleable, log_to_special_register, requires_doctor_name, requires_prescription_date, requires_age_check, institutional_only, blocks_retail_sale, quantity_limit, allows_refill, sort_order, is_active",
      )
      .eq("is_active", true)
      .order("sort_order", { ascending: true })
      .order("buying_rule", { ascending: true });

    if (error) return [];
    return data;
  }

  async syncBuyingRules(items: any[]) {
    return this.syncTableMetadata(
      "buying_rules",
      items,
      (item) => ({ buying_rule: item.name?.trim() || item.name }),
      "buying_rule",
    );
  }

  async getDrugSchedules() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("drug_schedules")
      .select(
        "id, shedule_name, schedule_code, reference_description, requires_prescription, requires_h1_register, is_narcotic, requires_batch_tracking, sort_order, is_common, is_active",
      )
      .eq("is_active", true)
      .order("sort_order", { ascending: true })
      .order("shedule_name", { ascending: true });

    if (error) return [];
    return data;
  }

  async getLookupBootstrap(scope?: {
    orgId?: string | null;
    outletId?: string | null;
  }) {
    const [
      units,
      categories,
      taxRates,
      taxGroups,
      manufacturers,
      brands,
      vendors,
      storageLocations,
      warehouses,
      racks,
      reorderTerms,
      accounts,
      contents,
      strengths,
      buyingRules,
      drugSchedules,
      uqc,
    ] = await Promise.all([
      this.getUnits(),
      this.getCategories(),
      this.getTaxRates(),
      this.getTaxGroups(),
      this.getManufacturers(),
      this.getBrands(),
      this.getVendors(),
      this.getStorageLocations(),
      this.getWarehouses(scope),
      this.getRacks(),
      this.getReorderTerms(scope),
      this.getAccounts(),
      this.getContents(),
      this.getStrengths(),
      this.getBuyingRules(),
      this.getDrugSchedules(),
      this.getUQCs(),
    ]);

    return {
      units,
      categories,
      taxRates,
      taxGroups,
      manufacturers,
      brands,
      vendors,
      storageLocations,
      warehouses,
      racks,
      reorderTerms,
      accounts,
      contents,
      strengths,
      buyingRules,
      drugSchedules,
      uqc,
    };
  }

  async syncDrugSchedules(items: any[]) {
    return this.syncTableMetadata(
      "drug_schedules",
      items,
      (item) => ({ shedule_name: item.name?.trim() || item.name }),
      "shedule_name",
    );
  }

  async getProductWarehouseStocks(productId: string) {
    if (!this.isUUID(productId)) {
      throw new BadRequestException("Invalid product ID");
    }

    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("warehouses")
      .select("id, org_id, name, is_active")
      .eq("is_active", true)
      .order("name", { ascending: true });

    if (error) throw new Error(error.message);

    return (data ?? []).map((warehouse: any) => ({
      id: warehouse.id,
      warehouse_id: warehouse.id,
      name: warehouse.name,
      opening_stock: 0,
      opening_stock_value: 0,
      accounting: { onHand: 0, committed: 0 },
      physical: { onHand: 0, committed: 0 },
    }));
  }

  async getProductHistory(productId: string) {
    if (!this.isUUID(productId)) {
      throw new BadRequestException("Invalid product ID");
    }

    const client = new Client({ connectionString: process.env.DATABASE_URL });
    await client.connect();

    try {
      const result = await client.query(
        `
          SELECT
            id::text,
            table_name,
            record_id::text,
            record_pk,
            action,
            old_values,
            new_values,
            actor_name,
            source,
            request_id,
            module_name,
            changed_columns,
            created_at
          FROM audit_logs_all
          WHERE
            (table_name = 'products' AND record_id = $1::uuid)
            OR COALESCE(new_values->>'product_id', '') = $1::text
            OR COALESCE(old_values->>'product_id', '') = $1::text
            OR COALESCE(new_values->>'item_id', '') = $1::text
            OR COALESCE(old_values->>'item_id', '') = $1::text
          ORDER BY created_at DESC
        `,
        [productId],
      );

      const warehouseIds = Array.from(
        new Set(
          result.rows
            .flatMap((row: any) => [
              row?.new_values?.warehouse_id,
              row?.old_values?.warehouse_id,
            ])
            .map((value: any) => this.cleanUuid(value))
            .filter((value): value is string => Boolean(value)),
        ),
      );

      const warehouseNameMap = new Map<string, string>();
      if (warehouseIds.length > 0) {
        const { data: warehouses, error: warehousesError } =
          await this.supabaseService
            .getClient()
            .from("warehouses")
            .select("id, name")
            .in("id", warehouseIds);

        if (warehousesError) {
          throw new Error(warehousesError.message);
        }

        for (const warehouse of warehouses ?? []) {
          const id = warehouse?.id?.toString();
          const name = warehouse?.name?.toString().trim();
          if (id && name) {
            warehouseNameMap.set(id, name);
          }
        }
      }

      const items = result.rows.map((row: any) => {
        const oldValuesRaw =
          row.old_values && typeof row.old_values === "object"
            ? row.old_values
            : null;
        const newValuesRaw =
          row.new_values && typeof row.new_values === "object"
            ? row.new_values
            : null;
        const oldWarehouseId = this.cleanUuid(oldValuesRaw?.warehouse_id);
        const newWarehouseId = this.cleanUuid(newValuesRaw?.warehouse_id);
        const oldValues = oldValuesRaw
          ? {
              ...oldValuesRaw,
              warehouse_name:
                oldValuesRaw.warehouse_name ||
                (oldWarehouseId
                  ? (warehouseNameMap.get(oldWarehouseId) ?? null)
                  : null),
            }
          : null;
        const newValues = newValuesRaw
          ? {
              ...newValuesRaw,
              warehouse_name:
                newValuesRaw.warehouse_name ||
                (newWarehouseId
                  ? (warehouseNameMap.get(newWarehouseId) ?? null)
                  : null),
            }
          : null;
        const details = this.summarizeHistoryEntry(
          row.table_name,
          row.action,
          oldValues,
          newValues,
        );

        return {
          id: row.id,
          table_name: row.table_name,
          section: details.section,
          action: row.action,
          record_id: row.record_id,
          record_pk: row.record_pk,
          actor_name: row.actor_name || "system",
          source: row.source || "system",
          request_id: row.request_id,
          module_name: row.module_name,
          created_at: row.created_at,
          changed_columns: Array.isArray(row.changed_columns)
            ? row.changed_columns
            : [],
          old_values: oldValues,
          new_values: newValues,
          summary: details.summary,
        };
      });

      return {
        data: items,
        meta: {
          total: items.length,
          timestamp: new Date().toISOString(),
        },
      };
    } finally {
      await client.end();
    }
  }

  async updateProductWarehouseStocks(
    productId: string,
    _payload: { rows?: any[] } = {},
  ) {
    if (!this.isUUID(productId)) {
      throw new BadRequestException("Invalid product ID");
    }
    // Stock write logic pending new inventory implementation
    return this.getProductWarehouseStocks(productId);
  }

  async adjustProductWarehousePhysicalStock(
    productId: string,
    _payload: {
      warehouse_id?: string;
      counted_stock?: number;
      reason?: string;
      notes?: string;
    } = {},
  ) {
    if (!this.isUUID(productId)) {
      throw new BadRequestException("Invalid product ID");
    }
    // Physical stock adjustment logic pending new inventory implementation
    return this.getProductWarehouseStocks(productId);
  }

  private normalizeNonNegativeNumber(value: unknown, fallback: number) {
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) return fallback;
    return Math.max(parsed, 0);
  }

  // GENERIC SYNC HELPER
  private async syncTableMetadata(
    tableName: string,
    items: any[],
    fieldsMapper: (u: any) => any,
    nameColumn: string = "id",
  ) {
    const supabase = this.supabaseService.getClient();
    console.log(
      `🔄 [Sync] Starting sync for ${tableName} with ${items.length} items using nameColumn: ${nameColumn}`,
    );

    try {
      // 1. Fetch current records (including inactive) to match by name and handle deactivations
      const selectColumns =
        nameColumn === "id" ? "id, is_active" : `id, ${nameColumn}, is_active`;
      const { data: currentRecords, error: fetchError } = await supabase
        .from(tableName)
        .select(selectColumns);

      if (fetchError) {
        console.error(
          `❌ [Sync] Error fetching existing items for ${tableName}:`,
          fetchError,
        );
        throw fetchError;
      }

      const existingRecords = (currentRecords || []) as any[];
      const activeIds = existingRecords
        .filter((r) => r.is_active === true)
        .map((r) => r.id);

      // 2. Prepare data for Upsert
      const toUpsert = items.map((u) => {
        const mapped = fieldsMapper(u);

        // Clean entry with basic fields
        const entry: any = {
          is_active: u.is_active !== undefined ? u.is_active : true,
        };

        // Merge mapped fields
        Object.assign(entry, mapped);

        // HYBRID MATCHING LOGIC:
        let matchedId = null;

        // A. Match by ID if provided and valid
        if (u.id && typeof u.id === "string" && this.isUUID(u.id)) {
          const byId = existingRecords.find((r) => r.id === u.id);
          if (byId) matchedId = byId.id;
        }

        // B. Match by Name if no ID match (prevents unique violations)
        if (!matchedId && nameColumn !== "id" && mapped[nameColumn]) {
          const incomingName = mapped[nameColumn]
            .toString()
            .toLowerCase()
            .trim();
          const byName = existingRecords.find(
            (r) =>
              r[nameColumn]?.toString().toLowerCase().trim() === incomingName,
          );
          if (byName) {
            matchedId = byName.id;
            console.log(
              `🔗 [Sync] Matched incoming item "${mapped[nameColumn]}" to existing ID: ${matchedId}`,
            );
          }
        }

        // IMPORTANT: Always provide an ID for bulk upserts to prevent null violation errors
        // from PostgREST when mixing new and existing records.
        if (matchedId) {
          entry.id = matchedId;
        } else if (u.id && typeof u.id === "string" && this.isUUID(u.id)) {
          entry.id = u.id;
        } else {
          // Genuinely new item: Generate a client-side UUID to ensure it's provided
          entry.id = randomUUID();
        }

        return entry;
      });

      // 3. Identify items to deactivate (those that were active but NOT in the incoming list)
      const incomingIds = toUpsert.filter((u) => u.id).map((u) => u.id);
      const idsToDisable = activeIds.filter((id) => !incomingIds.includes(id));

      if (idsToDisable.length > 0) {
        const trulyDisableableIds = [];
        const inUseItems = [];
        const lookupKey = tableName.replace(/_/g, "-");

        for (const id of idsToDisable) {
          const usageResult = await this.checkLookupUsage(lookupKey, id);
          if (!usageResult.inUse) {
            trulyDisableableIds.push(id);
          } else {
            inUseItems.push({ id, usedIn: usageResult.usedIn });
            console.log(
              `⚠️ [Sync] Cannot deactivate item ${id} in ${tableName} - currently in use by ${usageResult.usedIn}`,
            );
          }
        }

        // If any items are in use, throw an error to notify the frontend
        if (inUseItems.length > 0) {
          const itemNames = inUseItems.map((i) => {
            const rec = existingRecords.find((r) => r.id === i.id);
            return rec ? rec[nameColumn] : i.id;
          });

          // Flatten and unique the labels
          const usageContexts = [
            ...new Set(
              inUseItems.flatMap((i) =>
                Array.isArray(i.usedIn) ? i.usedIn : [i.usedIn],
              ),
            ),
          ];

          throw new ConflictException(
            `Cannot delete "${itemNames.join(", ")}" because it is associated with ${usageContexts.join(", ")}`,
          );
        }

        if (trulyDisableableIds.length > 0) {
          console.log(
            `🗑️ [Sync] Deactivating ${trulyDisableableIds.length} items in ${tableName}`,
          );
          const { error: disableError } = await supabase
            .from(tableName)
            .update({ is_active: false })
            .in("id", trulyDisableableIds);

          if (disableError) {
            console.error(
              `❌ [Sync] Error deactivating items in ${tableName}:`,
              disableError,
            );
          }
        }
      }

      // 4. Final Upsert with Deduplication
      const uniqueToUpsert = [];
      const seenIds = new Set();
      for (let i = toUpsert.length - 1; i >= 0; i--) {
        const item = toUpsert[i];
        if (!seenIds.has(item.id)) {
          uniqueToUpsert.unshift(item);
          seenIds.add(item.id);
        }
      }

      console.log(
        `📤 [Sync] Upserting ${uniqueToUpsert.length} unique items to ${tableName} (deduplicated from ${toUpsert.length})`,
      );
      const { data, error: upsertError } = await supabase
        .from(tableName)
        .upsert(uniqueToUpsert, { onConflict: "id" })
        .select();

      if (upsertError) {
        console.error(`❌ [Sync] Upsert error for ${tableName}:`, {
          code: upsertError.code,
          message: upsertError.message,
          details: upsertError.hint || upsertError.details,
        });

        if (upsertError.code === "23505") {
          throw new ConflictException(
            `One or more items in ${tableName} already exist (duplicate name or ID).`,
          );
        }
        throw upsertError;
      }

      console.log(
        `✅ [Sync] Successfully synced ${data?.length || 0} items to ${tableName}`,
      );
      return data;
    } catch (error) {
      console.error(
        `💥 [Sync] Fatal error in syncTableMetadata [${tableName}]:`,
        error,
      );
      throw error;
    }
  }

  async searchManufacturers(query: string) {
    if (!query) return [];
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("manufacturers")
      .select("id, name, is_active")
      .ilike("name", `%${query}%`)
      .eq("is_active", true)
      .order("name", { ascending: true })
      .limit(20);

    if (error) {
      console.error("Error searching manufacturers:", error);
      return [];
    }
    return data;
  }

  async searchBrands(query: string) {
    if (!query) return [];
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("brands")
      .select("id, name, is_active")
      .ilike("name", `%${query}%`)
      .eq("is_active", true)
      .order("name", { ascending: true })
      .limit(20);

    if (error) {
      console.error("Error searching brands:", error);
      return [];
    }
    return data;
  }

  private async mapProduct(
    product: any,
    scope?: { orgId?: string | null; outletId?: string | null },
  ) {
    if (!product) return null;

    // Sign Primary Image if it exists
    if (product.primary_image_url || product.primaryImageUrl) {
      const key = (
        product.primary_image_url || product.primaryImageUrl
      ).toString();
      // Only sign if it looks like a key (doesn't start with http)
      if (key && !key.startsWith("http")) {
        try {
          product.primary_image_url =
            await this.r2StorageService.getPresignedUrl(key);
        } catch (e) {
          console.error(`Failed to sign primary image for ${product.id}`, e);
        }
      }
    }

    // Sign multiple images if they exist
    if (Array.isArray(product.image_urls || product.imageUrls)) {
      const urls = product.image_urls || product.imageUrls;
      product.image_urls = await Promise.all(
        urls.map(async (key: string) => {
          if (key && !key.startsWith("http")) {
            try {
              return await this.r2StorageService.getPresignedUrl(key);
            } catch (e) {
              console.error(`Failed to sign image ${key} for ${product.id}`, e);
              return key;
            }
          }
          return key;
        }),
      );
    }

    if (scope != null) {
      try {
        const outletSetting = await this.getProductOutletInventorySetting(
          product.id,
          scope.orgId,
          scope.outletId,
        );
        if (outletSetting) {
          product.reorder_point = Number(outletSetting.reorder_point ?? 0);
          product.reorder_term_id = outletSetting.reorder_term_id ?? null;
        }
      } catch (e) {
        console.error(
          `Failed to overlay outlet reorder settings for ${product.id}`,
          e,
        );
      }
    }

    return product;
  }

  private async mapCompositeItem(
    compositeItem: any,
    scope?: { orgId?: string | null; outletId?: string | null },
  ) {
    if (!compositeItem) return null;

    if (scope != null) {
      try {
        const outletSetting = await this.getCompositeItemOutletInventorySetting(
          compositeItem.id,
          scope.orgId,
          scope.outletId,
        );
        if (outletSetting) {
          compositeItem.reorder_point = Number(
            outletSetting.reorder_point ?? 0,
          );
          compositeItem.reorder_term_id = outletSetting.reorder_term_id ?? null;
        }
      } catch (e) {
        console.error(
          `Failed to overlay composite outlet reorder settings for ${compositeItem.id}`,
          e,
        );
      }
    }

    return compositeItem;
  }

  async getQuickStats(productId: string) {
    if (!this.isUUID(productId)) {
      throw new BadRequestException("Invalid product ID");
    }

    const [productData] = await db
      .select({
        last_purchase_price: product.costPrice,
      })
      .from(product)
      .where(eq(product.id, productId))
      .limit(1);

    if (!productData) {
      throw new NotFoundException("Product not found");
    }

    return {
      current_stock: 0,
      committed_stock: 0,
      to_be_shipped: null,
      to_be_received: null,
      to_be_invoiced: null,
      to_be_billed: null,
      last_purchase_price: productData.last_purchase_price || 0,
    };
  }

  async getProductsByWarehouse(warehouseId: string) {
    const supabase = this.supabaseService.getClient();

    const { data: items, error } = await supabase
      .from("sales_order_items")
      .select(`
        product_id,
        product:products (
          id,
          product_name,
          item_code
        )
      `)
      .eq("warehouse_id", warehouseId);

    if (error) {
      console.error("❌ Error fetching warehouse products:", error);
      throw new Error(`Failed to fetch warehouse products: ${error.message}`);
    }

    if (!items) return [];

    // Filter out rows where product might be null (due to data inconsistency)
    // and distinct products by ID
    const seen = new Set<string>();
    const distinctProducts: any[] = [];

    for (const item of items) {
      const p = item.product as any;
      if (p && p.id && !seen.has(p.id)) {
        seen.add(p.id);
        distinctProducts.push({
          id: p.id,
          productName: p.product_name,
          itemCode: p.item_code,
        });
      }
    }

    return distinctProducts;
  }
}
