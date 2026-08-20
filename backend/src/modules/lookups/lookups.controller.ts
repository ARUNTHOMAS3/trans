import { Controller, Get, Post, Body, Param, Query } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { listVisibleAccounts } from "../../common/account-visibility.util";
import { db, client } from "../../db/db";
import { defaultPaymentTerms } from "../../db/schema";
import { eq } from "drizzle-orm";

@Controller("products/lookups")
export class LookupsController {
  constructor(private readonly supabaseService: SupabaseService) {}

  private static readonly entityScopedTables = new Set([
    "reorder_terms",
    "price_lists",
    "vendors",
    "accounts",
    "users",
  ]);

  @Get("payment-terms/default")
  async getDefaultPaymentTerm(@Tenant() tenant: TenantContext) {
    if (!tenant.entityId) return null;

    try {
      const rows = await db
        .select({ payment_terms_id: defaultPaymentTerms.paymentTermsId })
        .from(defaultPaymentTerms)
        .where(eq(defaultPaymentTerms.entityId, tenant.entityId))
        .limit(1);

      return rows[0] ?? null;
    } catch (error) {
      console.error("❌ Error fetching default payment term:", error);
      throw error;
    }
  }

  @Post("payment-terms/default")
  async setDefaultPaymentTerm(
    @Body() body: { payment_terms_id: string },
    @Tenant() tenant: TenantContext,
  ) {
    if (!tenant.entityId) throw new Error("Entity context required");

    try {
      const [data] = await db
        .insert(defaultPaymentTerms)
        .values({
          entityId: tenant.entityId,
          paymentTermsId: body.payment_terms_id,
        })
        .onConflictDoUpdate({
          target: defaultPaymentTerms.entityId,
          set: {
            paymentTermsId: body.payment_terms_id,
          },
        })
        .returning();

      return {
        id: data.id,
        entity_id: data.entityId,
        payment_terms_id: data.paymentTermsId,
      };
    } catch (error) {
      console.error("❌ Error setting default payment term:", error);
      throw error;
    }
  }

  @Get(":type")
  async getLookups(
    @Param("type") type: string,
    @Tenant() tenant: TenantContext,
  ) {
    const tableMap: Record<string, { table: string; field: string }> = {
      units: { table: "units", field: "unit_name" },
      categories: { table: "categories", field: "name" },
      manufacturers: { table: "manufacturers", field: "name" },
      brands: { table: "brands", field: "name" },
      vendors: { table: "vendors", field: "display_name" },
      "storage-locations": {
        table: "storage_conditions",
        field: "display_text",
      },
      racks: { table: "racks", field: "rack_name" },
      "reorder-terms": { table: "reorder_terms", field: "term_name" },
      accountant: { table: "accounts", field: "account_name" },
      contents: { table: "contents", field: "content_name" },
      strengths: { table: "drug_strengths", field: "strength_name" },
      "buying-rules": { table: "buying_rules", field: "item_rule" },
      "drug-schedules": { table: "drug_schedules", field: "shedule_name" },
      "tax-rates": { table: "tax_rates", field: "tax_name" },
      "tax-group-rates": { table: "tax_group_rates", field: "id" },
      "tds-rates": { table: "tds_rates", field: "tax_name" },
      "tds-sections": { table: "tds_sections", field: "section_name" },
      "tcs-rates": { table: "tcs_rates", field: "tax_name" },
      "tcs-natures": { table: "tcs_natures", field: "nature_name" },
      "payment-terms": { table: "payment_terms", field: "term_name" },
      "shipment-preferences": { table: "shipment_preferences", field: "name" },
      "price-lists": { table: "price_lists", field: "name" },
      salespersons: { table: "users", field: "full_name" },
    };

    const config = tableMap[type];
    if (!config) return [];

    if (type === "accountant") {
      return listVisibleAccounts(client, tenant);
    }

    const sanitizedTable = config.table.replace(/[^a-zA-Z0-9_]/g, "");
    const sanitizedField = config.field.replace(/[^a-zA-Z0-9_]/g, "");

    let sqlQuery = `SELECT * FROM "${sanitizedTable}" WHERE 1=1`;
    const params: any[] = [];

    if (LookupsController.entityScopedTables.has(config.table) && tenant.entityId) {
      params.push(tenant.entityId);
      sqlQuery += ` AND entity_id = $${params.length}`;
    }

    if (type === "price-lists") {
      sqlQuery += ` AND status = 'active'`;
    } else if (type !== "tax-group-rates") {
      sqlQuery += ` AND is_active = true`;
    }

    sqlQuery += ` ORDER BY "${sanitizedField}" ASC`;

    try {
      const data = await client.unsafe(sqlQuery, params);
      return data ?? [];
    } catch (error) {
      console.error(
        `❌ Error fetching lookups for ${type} (${config.table}):`,
        error,
      );
      throw error;
    }
  }

  @Get(":type/search")
  async searchLookups(
    @Param("type") type: string,
    @Query("q") query: string,
    @Tenant() tenant: TenantContext,
  ) {
    if (!query) return [];

    const tableMap: Record<string, { table: string; field: string }> = {
      units: { table: "units", field: "unit_name" },
      categories: { table: "categories", field: "name" },
      manufacturers: { table: "manufacturers", field: "name" },
      brands: { table: "brands", field: "name" },
      vendors: { table: "vendors", field: "display_name" },
      "storage-locations": {
        table: "storage_conditions",
        field: "display_text",
      },
      racks: { table: "racks", field: "rack_name" },
      "reorder-terms": { table: "reorder_terms", field: "term_name" },
      accountant: { table: "accounts", field: "account_name" },
      contents: { table: "contents", field: "content_name" },
      strengths: { table: "drug_strengths", field: "strength_name" },
      "buying-rules": { table: "buying_rules", field: "item_rule" },
      "drug-schedules": { table: "drug_schedules", field: "shedule_name" },
      products: { table: "products", field: "product_name" },
      "tax-rates": { table: "tax_rates", field: "tax_name" },
      "tds-rates": { table: "tds_rates", field: "tax_name" },
      "tds-sections": { table: "tds_sections", field: "section_name" },
      "tcs-rates": { table: "tcs_rates", field: "tax_name" },
      "tcs-natures": { table: "tcs_natures", field: "nature_name" },
      "payment-terms": { table: "payment_terms", field: "term_name" },
      "shipment-preferences": { table: "shipment_preferences", field: "name" },
      "price-lists": { table: "price_lists", field: "name" },
      salespersons: { table: "users", field: "full_name" },
    };

    const config = tableMap[type];
    if (!config) return [];

    if (type === "accountant") {
      return listVisibleAccounts(client, tenant, {
        accountType: "Stock",
        search: query,
        limit: 50,
      });
    }

    const escapedQuery = query.replace(/[%_]/g, "\\$&");
    const pattern = escapedQuery.trim().replace(/\s+/g, "%");
    const searchPattern = `%${pattern}%`;

    const sanitizedTable = config.table.replace(/[^a-zA-Z0-9_]/g, "");
    const sanitizedField = config.field.replace(/[^a-zA-Z0-9_]/g, "");

    let sqlQuery = `SELECT * FROM "${sanitizedTable}" WHERE 1=1`;
    const params: any[] = [];

    if (LookupsController.entityScopedTables.has(config.table) && tenant.entityId) {
      params.push(tenant.entityId);
      sqlQuery += ` AND entity_id = $${params.length}`;
    }

    params.push(searchPattern);
    const searchParamIdx = params.length;

    if (type === "products") {
      sqlQuery += ` AND (product_name ILIKE $${searchParamIdx} OR item_code ILIKE $${searchParamIdx} OR sku ILIKE $${searchParamIdx} OR hsn_sac_code ILIKE $${searchParamIdx})`;
    } else if (type === "storage-locations") {
      sqlQuery += ` AND (display_text ILIKE $${searchParamIdx} OR storage_type ILIKE $${searchParamIdx} OR location_name ILIKE $${searchParamIdx})`;
    } else {
      sqlQuery += ` AND "${sanitizedField}" ILIKE $${searchParamIdx}`;
    }

    if (type === "price-lists") {
      sqlQuery += ` AND status = 'active'`;
    } else {
      sqlQuery += ` AND is_active = true`;
    }

    sqlQuery += ` LIMIT 200`;

    try {
      const data = await client.unsafe(sqlQuery, params);

      const sorted = (data || []).sort((a: any, b: any) => {
        const valA = (a[config.field] || "").toString().toLowerCase();
        const valB = (b[config.field] || "").toString().toLowerCase();
        const lowerQ = query.toLowerCase().trim();

        if (valA === lowerQ && valB !== lowerQ) return -1;
        if (valB === lowerQ && valA !== lowerQ) return 1;

        const startsWithA = valA.startsWith(lowerQ);
        const startsWithB = valB.startsWith(lowerQ);
        if (startsWithA && !startsWithB) return -1;
        if (startsWithB && !startsWithA) return 1;

        return valA.localeCompare(valB, undefined, {
          numeric: true,
          sensitivity: "base",
        });
      });

      return sorted.slice(0, 50);
    } catch (error) {
      console.error(`❌ Error searching lookups for ${type}:`, error);
      return [];
    }
  }

  @Post(":type/sync")
  async syncLookups(
    @Param("type") type: string,
    @Body() items: any[],
    @Tenant() tenant: TenantContext,
  ) {
    const tableMap: Record<string, string> = {
      units: "units",
      categories: "categories",
      "tax-rates": "tax_rates",
      "tds-rates": "tds_rates",
      "tds-sections": "tds_sections",
      "tcs-rates": "tcs_rates",
      "tcs-natures": "tcs_natures",
      "payment-terms": "payment_terms",
      "shipment-preferences": "shipment_preferences",
      "price-lists": "price_lists",
      manufacturers: "manufacturers",
      brands: "brands",
      vendors: "vendors",
      "storage-locations": "storage_conditions",
      racks: "racks",
      "reorder-terms": "reorder_terms",
      accountant: "accounts",
      contents: "contents",
      strengths: "drug_strengths",
      "buying-rules": "buying_rules",
      "drug-schedules": "drug_schedules",
      "content-units": "units",
      salespersons: "users",
    };

    const tableName = tableMap[type];
    if (!tableName) throw new Error("Invalid lookup type");

    const isEntityScoped = LookupsController.entityScopedTables.has(tableName);
    const syncedItems = items.map((item) => ({
      ...item,
      ...(isEntityScoped ? { entity_id: tenant.entityId } : {}),
    }));

    const sanitizedTable = tableName.replace(/[^a-zA-Z0-9_]/g, "");

    try {
      const data = await client.unsafe(
        `INSERT INTO "${sanitizedTable}" SELECT * FROM json_populate_recordset(null::"${sanitizedTable}", $1::json)
         ON CONFLICT (id) DO UPDATE SET is_active = EXCLUDED.is_active
         RETURNING *`,
        [JSON.stringify(syncedItems)],
      );
      return data;
    } catch {
      return syncedItems;
    }
  }

  @Post(":type/check-usage")
  async checkUsage(@Param("type") _type: string, @Body() _body: any) {
    return { inUse: false, unitsInUse: [] };
  }
}
