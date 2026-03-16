import { Controller, Get, Post, Body, Param, Query } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";

@Controller("products/lookups")
export class LookupsController {
  constructor(private readonly supabaseService: SupabaseService) {}

  @Get(":type")
  async getLookups(@Param("type") type: string) {
    const tableMap = {
      units: { table: "units", field: "unit_name" },
      categories: { table: "categories", field: "name" },
      manufacturers: { table: "manufacturers", field: "name" },
      brands: { table: "brands", field: "name" },
      vendors: { table: "vendors", field: "display_name" },
      "storage-locations": {
        table: "storage_locations",
        field: "location_name",
      },
      racks: { table: "racks", field: "rack_name" },
      "reorder-terms": { table: "reorder_terms", field: "term_name" },
      accountant: { table: "accounts", field: "account_name" },
      contents: { table: "contents", field: "content_name" },
      strengths: { table: "strengths", field: "strength_name" },
      "buying-rules": { table: "buying_rules", field: "item_rule" },
      "drug-schedules": { table: "schedules", field: "shedule_name" },
      "tax-rates": { table: "associate_taxes", field: "tax_name" },
      "tds-rates": { table: "tds_rates", field: "tax_name" },
      "payment-terms": { table: "payment_terms", field: "term_name" },
      "price-lists": { table: "price_lists", field: "name" },
    };

    const config = tableMap[type];
    if (!config) return [];

    let query = this.supabaseService.getClient().from(config.table).select("*");

    // Handle different status column names or lack thereof
    if (type === "price-lists") {
      query = query.eq("status", "active");
    } else {
      query = query.eq("is_active", true);
    }

    const { data, error } = await query.order(config.field, {
      ascending: true,
    });

    if (error) {
      console.error(
        `❌ Error fetching lookups for ${type} (${config.table}):`,
        error,
      );
      throw error;
    }
    return data;
  }

  @Get(":type/search")
  async searchLookups(@Param("type") type: string, @Query("q") query: string) {
    if (!query) return [];

    const tableMap = {
      units: { table: "units", field: "unit_name" },
      categories: { table: "categories", field: "name" },
      manufacturers: { table: "manufacturers", field: "name" },
      brands: { table: "brands", field: "name" },
      vendors: { table: "vendors", field: "display_name" },
      "storage-locations": {
        table: "storage_locations",
        field: "location_name",
      },
      racks: { table: "racks", field: "rack_name" },
      "reorder-terms": { table: "reorder_terms", field: "term_name" },
      accountant: { table: "accounts", field: "account_name" },
      contents: { table: "contents", field: "content_name" },
      strengths: { table: "strengths", field: "strength_name" },
      "buying-rules": { table: "buying_rules", field: "item_rule" },
      "drug-schedules": { table: "schedules", field: "shedule_name" },
      products: { table: "products", field: "product_name" },
      "tax-rates": { table: "associate_taxes", field: "tax_name" },
      "tds-rates": { table: "tds_rates", field: "tax_name" },
      "payment-terms": { table: "payment_terms", field: "term_name" },
      "price-lists": { table: "price_lists", field: "name" },
    };
    const config = tableMap[type];
    if (!config) return [];

    // Create a flexible search pattern: replace spaces with wildcards
    // but escape literal % and _ characters from user input for accuracy
    const escapedQuery = query.replace(/[%_]/g, "\\$&");
    const pattern = escapedQuery.trim().replace(/\s+/g, "%");
    const searchPattern = `%${pattern}%`;

    // Fetch a larger sample (200) to ensure relevance sorting has enough data to work with.
    // We remove DB-side ordering here because it often cuts off relevant matches
    // (e.g., "0.x" matches filling the top slots before "2.x" matches is reached).
    let queryBuilder = this.supabaseService
      .getClient()
      .from(config.table)
      .select("*");

    if (type === "products") {
      queryBuilder = queryBuilder.or(
        `product_name.ilike.${searchPattern},item_code.ilike.${searchPattern},sku.ilike.${searchPattern},hsn_code.ilike.${searchPattern}`,
      );
    } else {
      queryBuilder = queryBuilder.ilike(config.field, searchPattern);
    }

    const { data, error } = await queryBuilder
      .eq(
        type === "price-lists" ? "status" : "is_active",
        type === "price-lists" ? "active" : true,
      )
      .limit(200);

    if (error) {
      console.error(`❌ Error searching lookups for ${type}:`, error);
      return [];
    }

    // Sort results by relevance in memory
    const sorted = (data || []).sort((a, b) => {
      const valA = (a[config.field] || "").toString().toLowerCase();
      const valB = (b[config.field] || "").toString().toLowerCase();
      const lowerQ = query.toLowerCase().trim();

      // Priority 1: Exact match
      if (valA === lowerQ && valB !== lowerQ) return -1;
      if (valB === lowerQ && valA !== lowerQ) return 1;

      // Priority 2: Starts with exact query (Prefix)
      const startsWithA = valA.startsWith(lowerQ);
      const startsWithB = valB.startsWith(lowerQ);
      if (startsWithA && !startsWithB) return -1;
      if (startsWithB && !startsWithA) return 1;

      // Priority 3: Alphabetical sort (default ascending)
      return valA.localeCompare(valB, undefined, {
        numeric: true,
        sensitivity: "base",
      });
    });

    return sorted.slice(0, 50);
  }

  @Post(":type/sync")
  async syncLookups(@Param("type") type: string, @Body() items: any[]) {
    const tableMap = {
      units: "units",
      categories: "categories",
      "tax-rates": "associate_taxes",
      "tds-rates": "tds_rates",
      "payment-terms": "payment_terms",
      "price-lists": "price_lists",
      manufacturers: "manufacturers",
      brands: "brands",
      vendors: "vendors",
      "storage-locations": "storage_locations",
      racks: "racks",
      "reorder-terms": "reorder_terms",
      accountant: "accounts",
      contents: "contents",
      strengths: "strengths",
      "buying-rules": "buying_rules",
      "drug-schedules": "schedules",
      "content-units": "units",
    };

    const tableName = tableMap[type];
    if (!tableName) throw new Error("Invalid lookup type");

    const { data, error } = await this.supabaseService
      .getClient()
      .from(tableName)
      .upsert(items)
      .select();

    if (error) throw error;
    return data;
  }

  @Post(":type/check-usage")
  async checkUsage(@Param("type") _type: string, @Body() _body: any) {
    // Basic implementation - in a real app, you'd check foreign keys in the products table
    return { inUse: false, unitsInUse: [] };
  }
}
