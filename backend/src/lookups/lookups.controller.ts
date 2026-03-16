import { Controller, Get, Post, Body, Param } from "@nestjs/common";
import { SupabaseService } from "../modules/supabase/supabase.service";

@Controller("products/lookups")
export class LookupsController {
  constructor(private readonly supabaseService: SupabaseService) {}

  @Get(":type")
  async getLookups(@Param("type") type: string) {
    console.log(`🔍 Received lookup request for type: ${type}`);
    const tableMap = {
      units: "units",
      categories: "categories",
      "tax-rates": "tax_rates",
      manufacturers: "manufacturers",
      brands: "brands",
      vendors: "vendors",
      "storage-locations": "storage_locations",
      racks: "racks",
      "reorder-terms": "reorder_terms",
      accounts: "accounts",
      contents: "contents",
      strengths: "strengths",
      "buying-rules": "buying_rules",
      "drug-schedules": "drug_schedules",
      "content-units": "content_units",
      uqc: "uqc",
    };

    const tableName = tableMap[type];
    if (!tableName) return [];

    const { data, error } = await this.supabaseService
      .getClient()
      .from(tableName)
      .select("*")
      .eq("is_active", true)
      .order("created_at", { ascending: false });

    if (error) throw error;
    return data;
  }

  @Post(":type/sync")
  async syncLookups(@Param("type") type: string, @Body() items: any[]) {
    const tableMap = {
      units: "units",
      categories: "categories",
      "tax-rates": "tax_rates",
      manufacturers: "manufacturers",
      brands: "brands",
      vendors: "vendors",
      "storage-locations": "storage_locations",
      racks: "racks",
      "reorder-terms": "reorder_terms",
      accounts: "accounts",
      contents: "contents",
      strengths: "strengths",
      "buying-rules": "buying_rules",
      "drug-schedules": "drug_schedules",
      "content-units": "content_units",
      uqc: "uqc",
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
