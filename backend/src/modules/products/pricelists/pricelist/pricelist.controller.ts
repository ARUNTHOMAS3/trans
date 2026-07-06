import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Patch,
  Body,
  Param,
  Query,
  BadRequestException,
  NotFoundException,
  InternalServerErrorException,
} from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { Tenant } from "../../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";

const HEADER_FIELDS = [
  "name",
  "description",
  "currency",
  "pricing_scheme",
  "round_off_preference",
  "status",
  "price_list_type",
  "percentage_type",
  "percentage_value",
  "discount_enabled",
  "transaction_type",
];

function buildPriceListResponse(header: any, items: any[]): any {
  const pickProductRow = (value: any) =>
    Array.isArray(value) ? value[0] ?? null : value ?? null;

  const itemRates = (items ?? []).map((item) => ({
    // Supabase relationship payload can be either object or array depending on query shape.
    // Normalize once so sales_rate/item_name/sku never drop to null incorrectly.
    ...(() => {
      const product = pickProductRow(item.products);
      return {
        id: item.id,
        item_id: item.product_id,
        item_name: product?.product_name ?? null,
        sku: product?.item_code ?? null,
        sales_rate: product?.selling_price ?? null,
        custom_rate: item.custom_rate,
        discount_percentage: item.discount_percentage,
        volume_ranges: (item.price_list_volume_ranges ?? []).map((r: any) => ({
          id: r.id,
          start_quantity: r.start_quantity,
          end_quantity: r.end_quantity,
          custom_rate: r.rate,
        })),
      };
    })(),
  }));
  return { ...header, item_rates: itemRates };
}

function normalizeIdList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => (item?.toString?.() ?? "").trim())
    .filter((item) => item.length > 0);
}

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  if (typeof error === "string") return error;
  try {
    return JSON.stringify(error);
  } catch {
    return String(error);
  }
}

function parseMaybeJson(value: unknown): Record<string, any> | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!trimmed.startsWith("{") || !trimmed.endsWith("}")) return null;
  try {
    const parsed = JSON.parse(trimmed);
    return parsed && typeof parsed === "object" ? parsed : null;
  } catch {
    return null;
  }
}

function normalizePriceListError(error: unknown): {
  code?: string;
  message?: string;
  details?: string;
  hint?: string;
} {
  if (error instanceof Error) {
    const parsed = parseMaybeJson(error.message);
    return {
      code: parsed?.code?.toString(),
      message: parsed?.message?.toString() ?? error.message,
      details: parsed?.details?.toString(),
      hint: parsed?.hint?.toString(),
    };
  }

  if (typeof error === "string") {
    const parsed = parseMaybeJson(error);
    if (parsed) {
      return {
        code: parsed.code?.toString(),
        message: parsed.message?.toString(),
        details: parsed.details?.toString(),
        hint: parsed.hint?.toString(),
      };
    }
    return { message: error };
  }

  if (error && typeof error === "object") {
    const record = error as Record<string, any>;
    const messageValue = record.message ?? record.error ?? record.details;
    const parsed = parseMaybeJson(messageValue);
    return {
      code: record.code?.toString() ?? parsed?.code?.toString(),
      message:
        parsed?.message?.toString() ??
        (typeof messageValue === "string" ? messageValue : undefined) ??
        record.message?.toString(),
      details:
        record.details?.toString() ??
        parsed?.details?.toString() ??
        record.detail?.toString(),
      hint: record.hint?.toString() ?? parsed?.hint?.toString(),
    };
  }

  return {};
}

function getFriendlyPriceListError(error: unknown): {
  statusCode: number;
  message: string;
} {
  const normalized = normalizePriceListError(error);
  const haystack = [
    normalized.code,
    normalized.message,
    normalized.details,
    normalized.hint,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  if (
    haystack.includes("23503") ||
    haystack.includes("foreign key") ||
    haystack.includes("branch_price_list_assignments_branch_entity_id_fkey") ||
    haystack.includes("organisation_branch_master")
  ) {
    return {
      statusCode: 400,
      message:
        "One or more selected branches are no longer available. Refresh the branch list and try again.",
    };
  }

  if (haystack.includes("23505")) {
    return {
      statusCode: 400,
      message: "A price list with these settings already exists.",
    };
  }

  return {
    statusCode: 500,
    message:
      normalized.message?.trim() ||
      normalized.details?.trim() ||
      getErrorMessage(error),
  };
}

@Controller("price-lists")
export class PriceListController {
  constructor(private readonly supabaseService: SupabaseService) {}

  private getTenantEntityId(tenant: TenantContext): string {
    const entityId = tenant?.entityId?.toString().trim();
    if (!entityId) {
      throw new BadRequestException("entity_id is required");
    }
    return entityId;
  }

  private isBranchViewOnlyTenant(tenant: TenantContext): boolean {
    return Boolean(tenant?.branchId);
  }

  private async assertWriteAllowed(tenant: TenantContext, body?: any, priceListId?: string) {
    if (this.isBranchViewOnlyTenant(tenant)) {
      let scope = body?.price_scope ?? body?.priceScope;
      
      if (!scope && priceListId) {
        const { data } = await this.supabaseService
          .getClient()
          .from("price_lists")
          .select("price_scope")
          .eq("id", priceListId)
          .maybeSingle();
        scope = data?.price_scope;
      }

      if (scope === "BRANCH") {
        return;
      }

      throw new BadRequestException(
        "Branch users can only view assigned branch price lists.",
      );
    }
  }

  private buildHeaderPayload(
    body: any,
    entityId: string,
    existing?: Record<string, any>,
  ): Record<string, any> {
    const payload: Record<string, any> = {
      entity_id: entityId,
      created_by_entity_id: existing?.created_by_entity_id ?? entityId,
      price_scope: existing?.price_scope ?? body.price_scope ?? "SELF",
      is_seasonal: body.is_seasonal ?? false,
      valid_from: body.valid_from ?? null,
      valid_to: body.valid_to ?? null,
    };

    for (const f of HEADER_FIELDS) {
      if (body[f] !== undefined) payload[f] = body[f];
    }

    return payload;
  }

  private async loadVisiblePriceLists(
    sb: ReturnType<SupabaseService["getClient"]>,
    tenant: TenantContext,
  ) {
    const entityId = this.getTenantEntityId(tenant);

    if (this.isBranchViewOnlyTenant(tenant)) {
      const { data, error } = await sb
        .from("branch_price_list_assignments")
        .select("price_list_id, price_lists(*, price_list_items(*, products(product_name, item_code, selling_price), price_list_volume_ranges(*)))")
        .eq("branch_entity_id", entityId);
      if (error) throw error;

      const uniquePriceLists = new Map<string, any>();
      for (const row of data ?? []) {
        const rawPriceList = row?.price_lists;
        const priceList = Array.isArray(rawPriceList)
          ? rawPriceList[0]
          : rawPriceList;
        const id = priceList?.id?.toString?.() ?? "";
        if (!id) continue;
        if ((priceList?.price_scope ?? "").toString() !== "BRANCH") continue;
        if (!uniquePriceLists.has(id)) {
          uniquePriceLists.set(id, priceList);
        }
      }
      const priceLists = Array.from(uniquePriceLists.values());

      const ids = priceLists
        .map((row: any) => row?.id?.toString?.() ?? "")
        .filter((id: string) => id.length > 0);
      const assignments = await this.loadBranchAssignments(sb, ids);

      return priceLists.map((row: any) => {
        const items = row.price_list_items ?? [];
        const { price_list_items, ...header } = row;
        return {
          ...buildPriceListResponse(header, items),
          branch_entity_ids: assignments.get(row.id?.toString?.() ?? "") ?? [],
        };
      });
    }

    const visibleEntityIds = new Set<string>([entityId]);
    if (tenant?.accessibleBranchIds?.length) {
      const { data: branchEntities, error: branchEntitiesError } = await sb
        .from("organisation_branch_master")
        .select("id, ref_id")
        .eq("type", "BRANCH")
        .in("ref_id", tenant.accessibleBranchIds);
      if (branchEntitiesError) throw branchEntitiesError;
      for (const row of branchEntities ?? []) {
        const id = row?.id?.toString?.().trim();
        if (id) visibleEntityIds.add(id);
      }
    }

    const { data, error } = await sb
      .from("price_lists")
      .select("*, price_list_items(*, products(product_name, item_code, selling_price), price_list_volume_ranges(*))")
      .in("entity_id", Array.from(visibleEntityIds))
      .order("created_at", { ascending: false });

    if (error) throw error;
    const ids = (data ?? [])
      .map((row: any) => row?.id?.toString?.() ?? "")
      .filter((id: string) => id.length > 0);
    const assignments = await this.loadBranchAssignments(sb, ids);
    return (data ?? []).map((row: any) => {
      const items = row.price_list_items ?? [];
      const { price_list_items, ...header } = row;
      return {
        ...buildPriceListResponse(header, items),
        branch_entity_ids: assignments.get(row.id?.toString?.() ?? "") ?? [],
      };
    });
  }

  private async ensureBranchCanView(
    sb: ReturnType<SupabaseService["getClient"]>,
    tenant: TenantContext,
    priceListId: string,
  ): Promise<boolean> {
    if (!this.isBranchViewOnlyTenant(tenant)) {
      return true;
    }

    const entityId = this.getTenantEntityId(tenant);
    const { data, error } = await sb
      .from("branch_price_list_assignments")
      .select("id, price_lists(*)")
      .eq("price_list_id", priceListId)
      .eq("branch_entity_id", entityId)
      .maybeSingle();

    if (error) throw error;
    return Boolean(data?.price_lists);
  }

  private async saveItemRates(
    sb: ReturnType<SupabaseService["getClient"]>,
    priceListId: string,
    itemRates: any[] = [],
  ) {
    const { error: clearErr } = await sb
      .from("price_list_items")
      .delete()
      .eq("price_list_id", priceListId);
    if (clearErr) throw clearErr;

    for (const rate of itemRates) {
      if (!rate?.item_id) continue;
      const { data: inserted, error: insertErr } = await sb
        .from("price_list_items")
        .insert({
          price_list_id: priceListId,
          product_id: rate.item_id,
          custom_rate: rate.custom_rate ?? rate.customRate ?? null,
          discount_percentage: rate.discount_percentage ?? rate.discountPercentage ?? null,
          is_active: rate.is_active ?? true,
        })
        .select("id")
        .single();
      if (insertErr) throw insertErr;
      const priceListItemId = inserted.id as string;

      await sb
        .from("price_list_volume_ranges")
        .delete()
        .eq("price_list_item_id", priceListItemId);

      const volRanges: any[] = rate.volume_ranges ?? rate.volumeRanges ?? [];
      if (volRanges.length > 0) {
        const rangeRows = volRanges.map((r: any) => ({
          price_list_item_id: priceListItemId,
          start_quantity: r.start_quantity ?? r.startQuantity ?? 1,
          end_quantity: r.end_quantity ?? r.endQuantity ?? null,
          rate: r.custom_rate ?? r.rate ?? r.customRate ?? 0,
        }));
        const { error: rangeErr } = await sb
          .from("price_list_volume_ranges")
          .insert(rangeRows);
        if (rangeErr) throw rangeErr;
      }
    }
  }

  private async saveBranchAssignments(
    sb: ReturnType<SupabaseService["getClient"]>,
    priceListId: string,
    branchNamesOrIds: string[] = [],
  ) {
    const fs = require("fs");
    const path = require("path");
    const logDir = path.join(process.cwd(), "logs");
    const logPath = path.join(logDir, "branch_assignments_debug.log");

    try {
      if (!fs.existsSync(logDir)) {
        fs.mkdirSync(logDir, { recursive: true });
      }
    } catch (e) {
      console.error("Failed to create log dir", e);
    }

    const log = (msg: string) => {
      try {
        fs.appendFileSync(logPath, `[${new Date().toISOString()}] ${msg}\n`);
      } catch (e) {
        console.error("Failed to write to log", e);
      }
    };

    log(`saveBranchAssignments called with priceListId: ${priceListId}, branchNamesOrIds: ${JSON.stringify(branchNamesOrIds)}`);

    const { error: deleteErr } = await sb
      .from("branch_price_list_assignments")
      .delete()
      .eq("price_list_id", priceListId);
    if (deleteErr) {
      log(`Delete existing assignments error: ${deleteErr.message}`);
      throw deleteErr;
    }

    if (branchNamesOrIds.length === 0) {
      log("No branchNamesOrIds provided, returning.");
      return;
    }

    const uniqueList = Array.from(new Set(branchNamesOrIds.map(x => x.trim()))).filter(x => x.length > 0);
    if (uniqueList.length === 0) {
      log("uniqueList is empty after trim, returning.");
      return;
    }

    // Fetch all branch entities from organisation_branch_master robustly
    const { data: masterBranches, error: fetchMasterErr } = await sb
      .from("organisation_branch_master")
      .select("id, name, type, ref_id");

    if (fetchMasterErr) {
      log(`Fetch organisation_branch_master error: ${fetchMasterErr.message}`);
      throw fetchMasterErr;
    }

    // Fetch all branch details from branches table to resolve local names
    const { data: realBranches, error: fetchRealErr } = await sb
      .from("branches")
      .select("id, name");

    if (fetchRealErr) {
      log(`Fetch branches error: ${fetchRealErr.message}`);
      throw fetchRealErr;
    }

    log(`Fetched master branches: ${JSON.stringify(masterBranches)}`);
    log(`Fetched real branches: ${JSON.stringify(realBranches)}`);

    const rows = [];
    for (const nameOrId of uniqueList) {
      // 1. Try to find a match in the branches table (by name or by id)
      const branchMatch = (realBranches ?? []).find(
        (b) =>
          b.id === nameOrId ||
          (b.name && b.name.trim().toLowerCase() === nameOrId.toLowerCase()) ||
          (b.name && b.name.trim().toLowerCase().includes(nameOrId.toLowerCase())) ||
          (b.name && nameOrId.toLowerCase().includes(b.name.trim().toLowerCase()))
      );

      if (branchMatch) {
        // Find corresponding master branch entity
        const masterMatch = (masterBranches ?? []).find(
          (m) => m.ref_id === branchMatch.id
        );

        log(`Matched "${nameOrId}" to branch: name="${branchMatch.name}", branches.id="${branchMatch.id}", master.id="${masterMatch?.id ?? 'none'}"`);

        rows.push({
          price_list_id: priceListId,
          branch_entity_id: masterMatch ? masterMatch.id : branchMatch.id,
          branch_id: branchMatch.id,
        });
      } else {
        // 2. Try to find match in organisation_branch_master as fallback
        const masterMatch = (masterBranches ?? []).find(
          (b) =>
            b.id === nameOrId ||
            b.ref_id === nameOrId ||
            (b.name && b.name.trim().toLowerCase() === nameOrId.toLowerCase())
        );

        if (masterMatch) {
          log(`Matched "${nameOrId}" via master fallback: id="${masterMatch.id}", ref_id="${masterMatch.ref_id}"`);
          rows.push({
            price_list_id: priceListId,
            branch_entity_id: masterMatch.id,
            branch_id: masterMatch.ref_id || masterMatch.id,
          });
        } else {
          // 3. Fallback for UUID
          const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(nameOrId);
          if (isUuid) {
            log(`"${nameOrId}" is valid UUID, using fallback.`);
            rows.push({
              price_list_id: priceListId,
              branch_entity_id: nameOrId,
              branch_id: nameOrId,
            });
          } else {
            log(`"${nameOrId}" not resolved, skipped.`);
          }
        }
      }
    }

    if (rows.length === 0) {
      log("No resolved rows to insert, returning.");
      return;
    }

    log(`Inserting rows into branch_price_list_assignments: ${JSON.stringify(rows)}`);

    const { error: insertErr } = await sb
      .from("branch_price_list_assignments")
      .insert(rows);
    if (insertErr) {
      log(`Insert assignments error: ${insertErr.message}`);
      throw insertErr;
    }

    log("Successfully saved branch assignments.");
  }

  private async loadBranchAssignments(
    sb: ReturnType<SupabaseService["getClient"]>,
    priceListIds: string[],
  ) {
    if (priceListIds.length === 0) return new Map<string, string[]>();

    const { data, error } = await sb
      .from("branch_price_list_assignments")
      .select("price_list_id, branch_entity_id")
      .in("price_list_id", priceListIds);
    if (error) throw error;

    const grouped = new Map<string, string[]>();
    for (const row of data ?? []) {
      const priceListId = row?.price_list_id?.toString?.() ?? "";
      const branchEntityId = row?.branch_entity_id?.toString?.() ?? "";
      if (!priceListId || !branchEntityId) continue;
      const bucket = grouped.get(priceListId) ?? [];
      bucket.push(branchEntityId);
      grouped.set(priceListId, bucket);
    }

    return grouped;
  }

  private async loadPriceListById(
    sb: ReturnType<SupabaseService["getClient"]>,
    priceListId: string,
    tenant: TenantContext,
  ) {
    const entityId = this.getTenantEntityId(tenant);
    const canView = await this.ensureBranchCanView(sb, tenant, priceListId);
    if (!canView) {
      throw new NotFoundException("Price list not found");
    }

    let headerQuery = sb.from("price_lists").select("*").eq("id", priceListId);
    if (!this.isBranchViewOnlyTenant(tenant)) {
      headerQuery = headerQuery.eq("entity_id", entityId);
    }
    const { data: header, error: hErr } = await headerQuery.single();
    if (hErr) throw hErr;

    const { data: items, error: iErr } = await sb
      .from("price_list_items")
      .select(
        `*, products(product_name, item_code, selling_price), price_list_volume_ranges(*)`,
      )
      .eq("price_list_id", priceListId)
      .eq("is_active", true);
    if (iErr) throw iErr;

    const assignments = await this.loadBranchAssignments(sb, [priceListId]);
    return {
      ...buildPriceListResponse(header, items ?? []),
      branch_entity_ids: assignments.get(priceListId) ?? [],
    };
  }

  @Get()
  async findAll(
    @Tenant() tenant: TenantContext,
    @Query("scope") scope?: string,
  ) {
    try {
      const sb = this.supabaseService.getClient();
      const data = await this.loadVisiblePriceLists(sb, tenant);
      const normalizedScope = (scope ?? "").toString().trim().toUpperCase();
      if (normalizedScope == "SELF" || normalizedScope == "BRANCH") {
        const filtered = data.filter(
          (row: any) =>
            (row?.price_scope ?? "").toString().trim().toUpperCase() ==
            normalizedScope,
        );
        return { data: filtered };
      }
      return { data };
    } catch (e) {
      const friendly = getFriendlyPriceListError(e);
      if (friendly.statusCode < 500) {
        throw new BadRequestException(friendly.message);
      }
      throw new InternalServerErrorException(friendly.message);
    }
  }

  @Get(":id")
  async findOne(@Param("id") id: string, @Tenant() tenant: TenantContext) {
    try {
      const sb = this.supabaseService.getClient();
      const data = await this.loadPriceListById(sb, id, tenant);
      return { data };
    } catch (e) {
      if ((e as any)?.code === "PGRST116") {
        throw new NotFoundException("Price list not found");
      }
      const friendly = getFriendlyPriceListError(e);
      if (friendly.statusCode < 500) {
        throw new BadRequestException(friendly.message);
      }
      throw new InternalServerErrorException(friendly.message);
    }
  }

  @Post()
  async create(@Body() body: any, @Tenant() tenant: TenantContext) {
    try {
      await this.assertWriteAllowed(tenant, body);
      const entityId = this.getTenantEntityId(tenant);
      const headerPayload = this.buildHeaderPayload(body, entityId);
      const sb = this.supabaseService.getClient();

      const { data: createdHeader, error: createErr } = await sb
        .from("price_lists")
        .insert(headerPayload)
        .select()
        .single();

      if (createErr) throw createErr;

      await this.saveItemRates(sb, createdHeader.id, body.item_rates ?? []);
      await this.saveBranchAssignments(
        sb,
        createdHeader.id,
        normalizeIdList(body.branch_entity_ids),
      );
      const data = await this.loadPriceListById(sb, createdHeader.id, tenant);
      return { data };
    } catch (e) {
      const friendly = getFriendlyPriceListError(e);
      if (friendly.statusCode < 500) {
        throw new BadRequestException(friendly.message);
      }
      throw new InternalServerErrorException(friendly.message);
    }
  }

  @Put(":id")
  async update(
    @Param("id") id: string,
    @Body() body: any,
    @Tenant() tenant: TenantContext,
  ) {
    try {
      await this.assertWriteAllowed(tenant, body, id);
      const entityId = this.getTenantEntityId(tenant);
      const sb = this.supabaseService.getClient();
      const { data: existing, error: existingErr } = await sb
        .from("price_lists")
        .select("created_by_entity_id, price_scope")
        .eq("id", id)
        .eq("entity_id", entityId)
        .single();
      if (existingErr) throw existingErr;
      const headerPayload = {
        ...this.buildHeaderPayload(body, entityId, existing as any),
        updated_at: new Date().toISOString(),
      };
      const { data: header, error: hErr } = await sb
        .from("price_lists")
        .update(headerPayload)
        .eq("id", id)
        .eq("entity_id", entityId)
        .select()
        .single();
      if (hErr) throw hErr;

      await this.saveItemRates(sb, id, body.item_rates ?? []);
      if ("branch_entity_ids" in body) {
        await this.saveBranchAssignments(
          sb,
          id,
          normalizeIdList(body.branch_entity_ids),
        );
      }
      const data = await this.loadPriceListById(sb, id, tenant);
      return { data };
    } catch (e) {
      const friendly = getFriendlyPriceListError(e);
      if (friendly.statusCode < 500) {
        throw new BadRequestException(friendly.message);
      }
      throw new InternalServerErrorException(friendly.message);
    }
  }

  @Delete(":id")
  async remove(@Param("id") id: string, @Tenant() tenant: TenantContext) {
    await this.assertWriteAllowed(tenant, null, id);
    const entityId = this.getTenantEntityId(tenant);
    const { error } = await this.supabaseService
      .getClient()
      .from("price_lists")
      .delete()
      .eq("id", id)
      .eq("entity_id", entityId);

    if (error) throw error;
    return { success: true };
  }

  @Patch(":id/deactivate")
  async deactivate(@Param("id") id: string, @Tenant() tenant: TenantContext) {
    await this.assertWriteAllowed(tenant, null, id);
    const entityId = this.getTenantEntityId(tenant);
    const { data, error } = await this.supabaseService
      .getClient()
      .from("price_lists")
      .update({
        status: "inactive",
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .eq("entity_id", entityId)
      .select()
      .single();

    if (error) throw error;
    return { data };
  }

  @Get("product/:productId")
  async findByProduct(
    @Param("productId") productId: string,
    @Tenant() tenant: TenantContext,
  ) {
    try {
      const entityId = this.getTenantEntityId(tenant);
      const sb = this.supabaseService.getClient();
      const { data, error } = await sb
        .from("price_list_items")
        .select(
          `
          id,
          custom_rate,
          discount_percentage,
          price_lists (
            id,
            name,
            currency,
            transaction_type,
            pricing_scheme,
            entity_id,
            price_scope,
            status
          )
        `,
        )
        .eq("product_id", productId);

      if (error) {
        console.error("Supabase Error (findByProduct):", error);
        throw error;
      }
      const filtered = (data ?? []).filter((row: any) => {
        const priceList = row?.price_lists ?? {};
        const priceListEntityId = priceList?.entity_id?.toString?.() ?? "";
        const priceScope = priceList?.price_scope?.toString?.() ?? "";
        if (this.isBranchViewOnlyTenant(tenant)) {
          return priceScope === "BRANCH";
        }
        return priceListEntityId === entityId && priceScope === "BRANCH";
      });
      return { data: filtered };
    } catch (e) {
      console.error("Exception in findByProduct:", e);
      const friendly = getFriendlyPriceListError(e);
      if (friendly.statusCode < 500) {
        throw new BadRequestException(friendly.message);
      }
      throw new InternalServerErrorException(friendly.message);
    }
  }

  @Post("associate")
  async associate(
    @Body()
    body: {
      product_id: string;
      price_list_id: string;
      custom_rate?: number;
      discount_percentage?: number;
    },
  ) {
    try {
      throw new BadRequestException(
        "Branch price list assignments are managed through the price list form.",
      );
      const { data, error } = await this.supabaseService
        .getClient()
        .from("price_list_items")
        .insert(body)
        .select()
        .single();

      if (error) throw error;
      return { data };
    } catch (e) {
      const friendly = getFriendlyPriceListError(e);
      if (friendly.statusCode < 500) {
        throw new BadRequestException(friendly.message);
      }
      throw new InternalServerErrorException(friendly.message);
    }
  }
}
