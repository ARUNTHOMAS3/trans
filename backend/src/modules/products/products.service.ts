import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { randomUUID } from "crypto";
import { db } from "../../db/db";
import { batches, product, outletInventory } from "../../db/schema";
import { eq, sql } from "drizzle-orm";
import { SupabaseService } from "../supabase/supabase.service";
import { CreateProductDto } from "./dto/create-product.dto";
import { Client } from "pg";
import { UpdateProductDto } from "./dto/update-product.dto";

import { R2StorageService } from "../accountant/r2-storage.service";

@Injectable()
export class ProductsService {
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
    buyingRule:buying_rules(id, buying_rule),
    drugSchedule:schedules(id, shedule_name),
    storage:storage_locations(id, location_name),
    compositions:product_contents(
      content_id,
      strength_id,
      display_order,
      content:contents(id, content_name),
      strength:strengths(id, strength_name)
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

  async create(createProductDto: CreateProductDto, userId: string) {
    const supabase = this.supabaseService.getClient();

    const { compositions, ...productData } = createProductDto as any;

    const insertPayload: Record<string, any> = {
      ...this.sanitizeProductPayload(productData),
      created_by_id: userId,
      updated_by_id: userId,
    };

    delete (insertPayload as any).buying_rule;
    delete (insertPayload as any).schedule_of_drug;

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

    return product;
  }

  async createComposite(payload: any, userId: string = null) {
    const supabase = this.supabaseService.getClient();

    // 1. Prepare main composite item data
    const { parts, ...mainData } = payload;

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
      reorder_term_id: this.cleanUuid(mainData.reorder_term_id),
      // Audit fields
      created_by_id: userId,
      updated_by_id: userId,
    };

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

    return composite;
  }

  async findOne(id: string) {
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

    return this.mapProduct(data);
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
    const { data, error } = await supabase
      .from("batches")
      .select("*")
      .eq("product_id", productId)
      .eq("is_active", true)
      .order("exp", { ascending: true });

    if (error) {
      console.error("Error fetching batches:", error);
      throw new Error(`Failed to fetch batches: ${error.message}`);
    }
    return data;
  }

  async createBatch(productId: string, body: any) {
    const supabase = this.supabaseService.getClient();
    const payload = {
      product_id: productId,
      batch: body.batch,
      exp: body.exp,
      mrp: body.mrp !== undefined ? Number(body.mrp) : undefined,
      ptr: body.ptr !== undefined ? Number(body.ptr) : undefined,
      unit_pack: body.unit_pack != null ? String(body.unit_pack) : null,
      is_manufacture_details: body.is_manufacture_details ?? false,
      manufacture_batch_number: body.manufacture_batch_number || null,
      manufacture_exp: body.manufacture_exp || null,
      is_active: true,
    };

    const { data, error } = await supabase
      .from("batches")
      .insert([payload])
      .select()
      .single();

    if (error) {
      console.error("Error creating batch:", error);

      if (
        (error.message || "").includes("permission denied for table batches")
      ) {
        try {
          const [fallbackCreated] = await db
            .insert(batches)
            .values({
              productId,
              batchNumber: payload.batch,
              expiryDate: payload.exp,
              mrp: payload.mrp as any,
              ptr: payload.ptr as any,
              unitPack: payload.unit_pack,
              isManufactureDetails: payload.is_manufacture_details,
              manufactureBatchNumber: payload.manufacture_batch_number,
              manufactureExpiryDate: payload.manufacture_exp,
              isActive: true,
            })
            .returning();

          if (fallbackCreated) {
            return fallbackCreated;
          }
        } catch (fallbackError: any) {
          console.error("Fallback insert into batches failed:", fallbackError);
        }
      }

      throw new BadRequestException(
        `Failed to create batch: ${error.message} - ${error.details || ""} - ${error.hint || ""}`,
      );
    }
    return data;
  }

  async getCompositeItems() {
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
      return data;
    } catch (error) {
      console.error("❌ Error in getCompositeItems:", error);
      throw error;
    }
  }

  async update(id: string, updateProductDto: UpdateProductDto, userId: string) {
    const supabase = this.supabaseService.getClient();

    // Separate compositions from main product data
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { compositions, ...productData } = updateProductDto as any;

    const payload: Record<string, any> = {
      ...this.sanitizeProductPayload(productData),
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

    return data;
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
      case "storage-locations":
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
      case "associate_taxes":
        checks.push({
          table: "products",
          column: "inter_state_tax_id",
          description: "products",
          filterActive: false,
        });
        checks.push({
          table: "tax_group_taxes",
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
      .from("associate_taxes")
      .select("*")
      .eq("is_active", true);

    if (error) throw new Error(error.message);
    return data;
  }

  async syncTaxRates(items: any[]) {
    return this.syncTableMetadata(
      "associate_taxes",
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
      .from("storage_locations")
      .select("id, location_name, temperature_range, description, is_active")
      .eq("is_active", true)
      .order("location_name", { ascending: true });

    if (error) throw new Error(error.message);
    return data;
  }

  async syncStorageLocations(items: any[]) {
    return this.syncTableMetadata(
      "storage_locations",
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

  async getReorderTerms() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("reorder_terms")
      .select("id, term_name, quantity, description, is_active")
      .eq("is_active", true)
      .order("term_name", { ascending: true });

    if (error) throw new Error(error.message);
    return data;
  }

  async createReorderTerm(termData: {
    term_name: string;
    quantity: number;
    description?: string;
  }) {
    const supabase = this.supabaseService.getClient();

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
  ) {
    const supabase = this.supabaseService.getClient();

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

    const { data, error } = await supabase
      .from("reorder_terms")
      .update(updateData)
      .eq("id", id)
      .select()
      .single();

    if (error) {
      if (error.code === "23505") {
        throw new Error("A reorder term with this name already exists");
      }
      throw new Error(error.message);
    }

    return data;
  }

  async deleteReorderTerm(id: string) {
    const supabase = this.supabaseService.getClient();

    // Check if the reorder term is being used by any products
    const usageCheck = await this.checkLookupUsage("reorder-terms", id);
    if (usageCheck.inUse) {
      throw new Error(
        `Cannot delete this reorder term because it is being used by ${usageCheck.usedIn}`,
      );
    }

    // Soft delete
    const { error } = await supabase
      .from("reorder_terms")
      .update({ is_active: false })
      .eq("id", id);

    if (error) {
      throw new Error(`Failed to delete reorder term: ${error.message}`);
    }

    return { message: "Reorder term deleted successfully" };
  }

  async syncReorderTerms(items: any[]) {
    return this.syncTableMetadata(
      "reorder_terms",
      items,
      (item) => ({
        term_name: item.term_name?.trim?.() || item.term_name,
        quantity: item.quantity,
        description: item.description || null,
      }),
      "term_name",
    );
  }

  async getAccounts() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("accounts")
      .select("id, user_account_name, system_account_name, account_type, is_active")
      .eq("is_active", true)
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
      .from("strengths")
      .select("id, strength_name, is_active")
      .eq("is_active", true)
      .order("strength_name", { ascending: true });

    if (error) return [];
    return data;
  }

  async syncStrengths(items: any[]) {
    return this.syncTableMetadata(
      "strengths",
      items,
      (item) => ({ strength_name: item.name?.trim() || item.name }),
      "strength_name",
    );
  }

  async getBuyingRules() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("buying_rules")
      .select("id, buying_rule, is_active")
      .eq("is_active", true)
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
      .from("schedules")
      .select("id, shedule_name, is_active")
      .eq("is_active", true)
      .order("shedule_name", { ascending: true });

    if (error) return [];
    return data;
  }

  async getLookupBootstrap() {
    const [
      units,
      categories,
      taxRates,
      taxGroups,
      manufacturers,
      brands,
      vendors,
      storageLocations,
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
      this.getRacks(),
      this.getReorderTerms(),
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
      "schedules",
      items,
      (item) => ({ shedule_name: item.name?.trim() || item.name }),
      "shedule_name",
    );
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

  private async mapProduct(product: any) {
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

    return product;
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

    const inventoryData = await db
      .select({
        stock: sql<number>`sum(${outletInventory.currentStock})::int`,
        committed: sql<number>`sum(${outletInventory.reservedStock})::int`,
      })
      .from(outletInventory)
      .where(eq(outletInventory.productId, productId));

    return {
      current_stock: inventoryData[0]?.stock || 0,
      committed_stock: inventoryData[0]?.committed || 0,
      to_be_shipped: null, // Placeholder for future sales implementation
      to_be_received: null, // Placeholder for future purchases implementation
      to_be_invoiced: null, // Placeholder for future sales implementation
      to_be_billed: null, // Placeholder for future purchases implementation
      last_purchase_price: productData.last_purchase_price || 0,
    };
  }
}
