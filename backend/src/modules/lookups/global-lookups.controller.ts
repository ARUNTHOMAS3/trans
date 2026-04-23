import {
  Controller,
  Get,
  Post,
  Delete,
  HttpCode,
  HttpStatus,
  Query,
  Param,
  Body,
  BadRequestException,
  ForbiddenException,
} from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { R2StorageService } from "../accountant/r2-storage.service";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Controller("lookups")
export class GlobalLookupsController {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly r2StorageService: R2StorageService,
  ) {}

  private async syncOrganisationMaster(orgId: string) {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("organization")
      .select("id,name,is_active")
      .eq("id", orgId)
      .maybeSingle();

    if (error) throw error;
    if (!data?.id || !data?.name) return;

    const { error: upsertError } = await client
      .from("organisation_branch_master")
      .upsert(
        {
          name: data.name,
          type: "ORG",
          ref_id: data.id,
          parent_id: null,
          is_active: data.is_active ?? true,
        },
        { onConflict: "type,ref_id" },
      );

    if (upsertError) throw upsertError;
  }

  private async resolveLogoUrl(
    keyOrUrl?: string | null,
  ): Promise<string | null> {
    if (!keyOrUrl?.trim()) return null;
    const value = keyOrUrl.trim();
    if (value.startsWith("data:")) return value;

    if (value.startsWith("http://") || value.startsWith("https://")) {
      const bucket = process.env.CLOUDFLARE_BUCKET_NAME?.trim();
      if (bucket) {
        const marker = `/${bucket}/`;
        const idx = value.indexOf(marker);
        if (idx !== -1) {
          const key = value.substring(idx + marker.length);
          try {
            return await this.r2StorageService.getPresignedUrl(key);
          } catch {
            return null;
          }
        }
      }
      return value;
    }

    try {
      return await this.r2StorageService.getPresignedUrl(value);
    } catch (error) {
      console.error("[GlobalLookupsController] Failed to sign logo:", error);
      return null;
    }
  }

  private async resolveTimezoneRow(
    rawTimezone: string,
  ): Promise<{ display: string; tzdb_name: string } | null> {
    const client = this.supabaseService.getClient();

    const matchBy = async (column: "tzdb_name" | "display" | "name") => {
      const { data, error } = await client
        .from("timezones")
        .select("display, tzdb_name")
        .eq("is_active", true)
        .eq(column, rawTimezone)
        .maybeSingle();

      if (error) {
        throw error;
      }

      return data ?? null;
    };

    return (
      (await matchBy("tzdb_name")) ??
      (await matchBy("display")) ??
      (await matchBy("name"))
    );
  }

  private async resolveCompanyIdLabel(
    rawLabel: string,
  ): Promise<string | null> {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("company_id_labels")
      .select("label")
      .eq("is_active", true)
      .eq("label", rawLabel)
      .maybeSingle();

    if (error) {
      throw error;
    }

    return data?.label ?? null;
  }

  private async fetchActiveOptions(
    table: string,
    select: string,
    orderBy: string[] = ["sort_order", "label"],
  ) {
    const client = this.supabaseService.getClient();
    let query = client.from(table).select(select).eq("is_active", true);

    for (const column of orderBy) {
      query = query.order(column, { ascending: true });
    }

    const { data, error } = await query;
    if (error) throw error;
    return data ?? [];
  }

  private parseJsonObject(rawValue?: string | null) {
    if (!rawValue?.trim()) {
      return null as Record<string, any> | null;
    }

    try {
      const parsed = JSON.parse(rawValue);
      return parsed && typeof parsed === "object" && !Array.isArray(parsed)
        ? (parsed as Record<string, any>)
        : null;
    } catch {
      return null;
    }
  }

  private getR2BaseUrl(): string {
    const endpoint =
      process.env.CLOUDFLARE_R2_ENDPOINT?.trim().replace(/\/$/, "") ?? "";
    const bucket = process.env.CLOUDFLARE_BUCKET_NAME?.trim() ?? "";

    if (!endpoint || !bucket) {
      throw new BadRequestException("R2 storage is not configured.");
    }

    return `${endpoint}/${bucket}`;
  }

  private toPublicFileUrl(key: string): string {
    return `${this.getR2BaseUrl()}/${key}`;
  }

  private parseFileKeyFromUrl(fileUrl: string): string | null {
    const baseUrl = this.getR2BaseUrl();
    if (!fileUrl.startsWith(baseUrl)) {
      return null;
    }

    const key = fileUrl.substring(baseUrl.length).replace(/^\/+/, "");
    return key || null;
  }

  private async resolveAssemblyId(
    districtId?: string | null,
    assemblyCodeOrName?: string | null,
  ) {
    // TODO: Re-enable assembly validation once the assemblies_constituencies table is populated.
    return null;
    /*
    const normalizedDistrictId = districtId?.toString().trim();
    const normalizedAssembly = assemblyCodeOrName?.toString().trim();
    if (!normalizedDistrictId || !normalizedAssembly) {
      return null;
    }

    const client = this.supabaseService.getClient();
    const fetchBy = async (column: "code" | "name") => {
      const { data, error } = await client
        .from("assemblies_constituencies")
        .select("id,code,name")
        .eq("district_id", normalizedDistrictId)
        .eq("is_active", true)
        .eq(column, normalizedAssembly)
        .maybeSingle();

      if (error) throw error;
      return data ?? null;
    };

    return (await fetchBy("code")) ?? (await fetchBy("name"));
    */
  }

  private async hydratePaymentStubAssembly(
    rawAddress?: string | null,
    assemblyId?: string | null,
  ) {
    if (!rawAddress?.trim() || !assemblyId?.trim()) {
      return rawAddress ?? null;
    }

    const parsed = this.parseJsonObject(rawAddress);
    if (!parsed) {
      return rawAddress;
    }

    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("assemblies_constituencies")
      .select("id,code,name")
      .eq("id", assemblyId.trim())
      .maybeSingle();

    if (error) throw error;
    if (!data) {
      return rawAddress;
    }

    parsed["assembly_code"] = data.code ?? parsed["assembly_code"] ?? null;
    parsed["assembly_name"] = data.name ?? parsed["assembly_name"] ?? null;
    return JSON.stringify(parsed);
  }

  private assertOrgAccess(tenant: TenantContext, requestedOrgId: string) {
    if (tenant.role !== "admin" && tenant.orgId !== requestedOrgId) {
      throw new ForbiddenException("Cross-organization access is not allowed");
    }
  }

  @Get("currencies")
  async getCurrencies(@Query("q") q?: string) {
    const client = this.supabaseService.getClient();
    const search = q?.trim();

    let query = client
      .from("currencies")
      .select("id,code,name,symbol,decimals,format")
      .eq("is_active", true);

    if (search) {
      query = query.or(`code.ilike.%${search}%,name.ilike.%${search}%`);
    }

    const { data, error } = await query.order("code", { ascending: true });
    if (error) throw error;
    return data ?? [];
  }

  @Get("countries")
  async getCountries(@Query("q") q?: string) {
    const client = this.supabaseService.getClient();
    const search = q?.trim();

    let query = client
      .from("countries")
      .select("id,name,full_label,phone_code,short_code")
      .eq("is_active", true);

    if (search) {
      query = query.or(
        `name.ilike.%${search}%,full_label.ilike.%${search}%,phone_code.ilike.%${search}%`,
      );
    }

    const { data, error } = await query.order("name", { ascending: true });
    if (error) throw error;
    return data ?? [];
  }

  @Get("industries")
  async getIndustries() {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("industries")
      .select("name")
      .eq("is_active", true)
      .order("sort_order", { ascending: true });
    if (error) throw error;
    return (data ?? []).map((r) => r.name);
  }

  @Get("timezones")
  async getTimezones(@Query("countryId") countryId?: string) {
    const client = this.supabaseService.getClient();
    let query = client
      .from("timezones")
      .select("id, name, tzdb_name, utc_offset, display, country_id")
      .eq("is_active", true);
    if (countryId) {
      query = query.eq("country_id", countryId);
    }
    const { data, error } = await query
      .order("sort_order", { ascending: true })
      .order("display", { ascending: true });
    if (error) throw error;
    return data ?? [];
  }

  @Get("company-id-labels")
  async getCompanyIdLabels() {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("company_id_labels")
      .select("label")
      .eq("is_active", true)
      .order("sort_order", { ascending: true });
    if (error) throw error;
    return (data ?? []).map((r) => r.label);
  }

  @Get("business-types")
  async getBusinessTypes() {
    return this.fetchActiveOptions(
      "business_types",
      "code,label,description,sort_order",
    );
  }

  @Get("gst-treatments")
  async getGstTreatments() {
    return this.fetchActiveOptions(
      "gst_treatments",
      "code,label,sort_order",
    );
  }

  @Get("gst-registration-types")
  async getGstRegistrationTypes() {
    return this.fetchActiveOptions(
      "gstin_registration_types",
      "code,label,sort_order",
    );
  }

  @Get("drug-licence-types")
  async getDrugLicenceTypes() {
    return this.fetchActiveOptions(
      "drug_licence_types",
      "code,label,sort_order",
    );
  }

  @Get("fiscal-year-presets")
  async getFiscalYearPresets() {
    return this.fetchActiveOptions(
      "fiscal_year_presets",
      "code,label,start_month,end_month,sort_order",
    );
  }

  @Get("date-format-options")
  async getDateFormatOptions() {
    return this.fetchActiveOptions(
      "date_format",
      "code,format_pattern,group_name,label,sort_order",
    );
  }

  @Get("date-separator-options")
  async getDateSeparatorOptions() {
    return this.fetchActiveOptions(
      "date_separator",
      "code,separator,label,sort_order",
    );
  }

  @Get("transaction-modules")
  async getTransactionModules() {
    return this.fetchActiveOptions(
      "transaction_series_modules",
      "code,label,sort_order",
    );
  }

  @Get("transaction-restart-options")
  async getTransactionRestartOptions() {
    return this.fetchActiveOptions(
      "transaction_series_restart_options",
      "code,label,sort_order",
    );
  }

  @Get("transaction-prefix-placeholders")
  async getTransactionPrefixPlaceholders() {
    return this.fetchActiveOptions(
      "transaction_series_placeholders",
      "token,label,sort_order",
    );
  }

  @Get("states/:countryCode?")
  async getStates(
    @Param("countryCode") countryCodeParam?: string,
    @Query("countryId") countryIdQuery?: string,
    @Query("q") q?: string,
  ) {
    const client = this.supabaseService.getClient();
    const search = q?.trim();
    const countryValue = countryCodeParam || countryIdQuery;
    let resolvedCountryId = countryValue;

    // Handle 2-letter country codes (e.g., "IN")
    if (countryValue && countryValue.length === 2) {
      const { data: countryData } = await client
        .from("countries")
        .select("id")
        .eq("short_code", countryValue.toUpperCase())
        .single();

      if (countryData) {
        resolvedCountryId = countryData.id;
      }
    }

    const runQuery = async (countryColumn: "country_id" | "state_id") => {
      let query = client
        .from("states")
        .select("id,name,code")
        .eq("is_active", true);

      if (resolvedCountryId) {
        query = query.eq(countryColumn, resolvedCountryId);
      }

      if (search) {
        query = query.ilike("name", `%${search}%`);
      }

      return query.order("name", { ascending: true });
    };

    let { data, error } = await runQuery("country_id");
    if (
      error &&
      typeof error.message === "string" &&
      error.message.toLowerCase().includes("country_id")
    ) {
      ({ data, error } = await runQuery("state_id"));
    }

    if (error) throw error;

    return data ?? [];
  }

  @Get("districts")
  async getDistricts(@Query("stateId") stateId?: string) {
    if (!stateId?.trim()) {
      throw new BadRequestException("stateId is required");
    }

    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("lsgd_districts")
      .select("id,name,code")
      .eq("state_id", stateId.trim())
      .eq("is_active", true)
      .order("name", { ascending: true });

    if (error) throw error;
    return data ?? [];
  }

  @Get("local-bodies")
  async getLocalBodies(
    @Query("districtId") districtId?: string,
    @Query("bodyType") bodyType?: string,
  ) {
    if (!districtId?.trim()) {
      throw new BadRequestException("districtId is required");
    }

    const client = this.supabaseService.getClient();
    let query = client
      .from("lsgd_local_bodies")
      .select("id,name,code,body_type")
      .eq("district_id", districtId.trim())
      .eq("is_active", true);

    if (bodyType?.trim()) {
      query = query.eq("body_type", bodyType.trim());
    }

    const { data, error } = await query.order("name", { ascending: true });
    if (error) throw error;
    return data ?? [];
  }

  @Get("wards")
  async getWards(@Query("localBodyId") localBodyId?: string) {
    if (!localBodyId?.trim()) {
      throw new BadRequestException("localBodyId is required");
    }

    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("lsgd_wards")
      .select("id,ward_no,name,code")
      .eq("local_body_id", localBodyId.trim())
      .eq("is_active", true)
      .order("ward_no", { ascending: true })
      .order("name", { ascending: true });

    if (error) throw error;

    return (data ?? []).map((ward: any) => ({
      ...ward,
      display_name:
        ward.ward_no != null ? `${ward.ward_no} - ${ward.name}` : ward.name,
    }));
  }

  @Get("assemblies")
  async getAssemblies(@Query("districtId") districtId?: string) {
    if (!districtId?.trim()) {
      throw new BadRequestException("districtId is required");
    }

    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("assemblies_constituencies")
      .select("id,code,name")
      .eq("district_id", districtId.trim())
      .eq("is_active", true)
      .order("name", { ascending: true });

    if (error) throw error;
    return (data ?? []).map((assembly: any) => ({
      id: assembly.id,
      code: assembly.code,
      name: assembly.name,
    }));
  }

  /** Returns full org profile — all columns live directly on the organization table,
   *  merged with branding settings from branding.
   *  Also resolves country name from state_id → states.state_id → countries. */
  @Get("org/:orgId")
  async getOrgDetails(@Param("orgId") orgId: string, @Tenant() tenant: TenantContext) {
    this.assertOrgAccess(tenant, orgId);
    const client = this.supabaseService.getClient();

    const [orgResult, brandingResult] = await Promise.all([
      client
        .from("organization")
        .select(
          "id, system_id, name, state_id, industry, logo_url, base_currency, base_currency_decimals, base_currency_format, fiscal_year, organization_language, communication_languages, timezone, date_format, date_separator, company_id_label, company_id_value, attention, street, place, city, pincode, phone, district_id, local_body_id, assembly_id, ward_id, payment_stub_address, has_separate_payment_stub_address, payment_stub_assembly_id, additional_fields",
        )
        .eq("id", orgId)
        .single(),
      client
        .from("branding")
        .select("accent_color, theme_mode, keep_branding")
        .eq("org_id", orgId)
        .maybeSingle(),
    ]);

    if (orgResult.error) throw orgResult.error;

    const org = orgResult.data as any;

    let timezoneDisplay: string | null = null;
    let timezoneTzdbName: string | null = null;
    if (org?.timezone) {
      const timezoneRow = await this.resolveTimezoneRow(org.timezone);
      timezoneDisplay = timezoneRow?.display ?? null;
      timezoneTzdbName = timezoneRow?.tzdb_name ?? null;
    }

    // Resolve country name: state_id → states(state_id FK = countries.id) → countries(name)
    let countryName: string | null = null;
    if (org?.state_id) {
      const { data: stateRow } = await client
        .from("states")
        .select("state_id")
        .eq("id", org.state_id)
        .maybeSingle();

      if (stateRow?.state_id) {
        const { data: countryRow } = await client
          .from("countries")
          .select("name")
          .eq("id", stateRow.state_id)
          .maybeSingle();
        countryName = countryRow?.name ?? null;
      }
    }

    return {
      ...org,
      payment_stub_address: await this.hydratePaymentStubAssembly(
        org?.payment_stub_address,
        org?.payment_stub_assembly_id,
      ),
      country: countryName,
      timezone_display: timezoneDisplay,
      timezone_tzdb_name: timezoneTzdbName,
      logo_url: await this.resolveLogoUrl(org?.logo_url),
      // Branding defaults if no row exists yet
      accent_color: brandingResult.data?.accent_color ?? "#22A95E",
      theme_mode: brandingResult.data?.theme_mode ?? "dark",
      keep_branding: brandingResult.data?.keep_branding ?? false,
    };
  }

  /** GET branding settings for an org. */
  @Get("org/:orgId/branding")
  async getOrgBranding(@Param("orgId") orgId: string, @Tenant() tenant: TenantContext) {
    this.assertOrgAccess(tenant, orgId);
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("branding")
      .select("accent_color, theme_mode, keep_branding")
      .eq("org_id", orgId)
      .maybeSingle();
    if (error) throw error;
    return {
      accent_color: data?.accent_color ?? "#22A95E",
      theme_mode: data?.theme_mode ?? "dark",
      keep_branding: data?.keep_branding ?? false,
    };
  }

  /** Upsert branding settings — creates or updates the branding row. */
  @Post("org/:orgId/branding")
  @HttpCode(HttpStatus.OK)
  async saveOrgBranding(
    @Param("orgId") orgId: string,
    @Body()
    body: {
      accent_color?: string;
      theme_mode?: string;
      keep_branding?: boolean;
    },
    @Tenant() tenant: TenantContext
  ) {
    this.assertOrgAccess(tenant, orgId);
    const client = this.supabaseService.getClient();

    const payload: Record<string, unknown> = { org_id: orgId };
    if (body.accent_color !== undefined)
      payload.accent_color = body.accent_color;
    if (body.theme_mode !== undefined) payload.theme_mode = body.theme_mode;
    if (body.keep_branding !== undefined)
      payload.keep_branding = body.keep_branding;

    const { error } = await client
      .from("branding")
      .upsert(payload, { onConflict: "org_id" });

    if (error) throw error;
    return { success: true };
  }

  /** Save org profile settings — all fields stored directly on the organization table. */
  @Post("org/:orgId/save")
  @HttpCode(HttpStatus.OK)
  async saveOrgProfile(
    @Param("orgId") orgId: string,
    @Body()
    body: {
      name?: string;
      state_id?: string;
      industry?: string;
      base_currency?: string;
      base_currency_decimals?: number;
      base_currency_format?: string;
      fiscal_year?: string;
      organization_language?: string;
      communication_languages?: string[];
      timezone?: string;
      date_format?: string;
      date_separator?: string;
      company_id_label?: string;
      company_id_value?: string;
      attention?: string;
      street?: string;
      place?: string;
      city?: string;
      pincode?: string;
      phone?: string;
      district_id?: string;
      local_body_id?: string;
      assembly_id?: string;
      ward_id?: string;
      payment_stub_address?: string;
      has_separate_payment_stub_address?: boolean;
      payment_stub_assembly_id?: string;
      additional_fields?: any;
    },
    @Tenant() tenant: TenantContext
  ) {
    this.assertOrgAccess(tenant, orgId);
    const client = this.supabaseService.getClient();
    const payload = { ...body } as Record<string, unknown>;
    
    if (typeof body.phone === "string" && body.phone.trim().length > 0) {
      const mobileRegex = /^[0-9]{10}$/;
      if (!mobileRegex.test(body.phone.trim())) {
        throw new BadRequestException("Phone number must be exactly 10 digits.");
      }
    }

    if (typeof body.timezone === "string" && body.timezone.trim().length > 0) {
      const rawTimezone = body.timezone.trim();
      const timezoneRow = await this.resolveTimezoneRow(rawTimezone);
      if (!timezoneRow?.tzdb_name) {
        throw new BadRequestException("Invalid timezone selection.");
      }

      payload.timezone = timezoneRow.tzdb_name;
    }

    if (
      typeof body.company_id_label === "string" &&
      body.company_id_label.trim().length > 0
    ) {
      const resolvedLabel = await this.resolveCompanyIdLabel(
        body.company_id_label.trim(),
      );
      if (!resolvedLabel) {
        throw new BadRequestException("Invalid company ID label selection.");
      }

      payload.company_id_label = resolvedLabel;
    }

    if (
      Array.isArray(body.communication_languages) &&
      body.communication_languages.length > 0
    ) {
      payload.communication_languages = body.communication_languages
        .map((value) => value?.toString().trim())
        .filter((value): value is string => Boolean(value));
    }

    if (body.has_separate_payment_stub_address === false) {
      payload.payment_stub_assembly_id = null;
    } else if (typeof body.payment_stub_address === "string") {
      const parsedAddress = this.parseJsonObject(body.payment_stub_address);
      const assemblyMatch = await this.resolveAssemblyId(
        parsedAddress?.district_id?.toString(),
        parsedAddress?.assembly_code?.toString() ??
          parsedAddress?.assembly_name?.toString(),
      );
      payload.payment_stub_assembly_id = assemblyMatch?.id ?? null;
    } else if (body.payment_stub_assembly_id !== undefined) {
      payload.payment_stub_assembly_id =
        body.payment_stub_assembly_id?.toString().trim() || null;
    }

    const { error } = await client
      .from("organization")
      .update({ ...payload, updated_at: new Date().toISOString() })
      .eq("id", orgId);
    if (error) throw error;
    await this.syncOrganisationMaster(orgId);

    return { success: true };
  }

  /** Upload or replace the organization logo. Accepts base64-encoded image. */
  @Post("org/:orgId/logo")
  async uploadOrgLogo(
    @Param("orgId") orgId: string,
    @Body() body: { fileName: string; fileData: string; mimeType?: string },
    @Tenant() tenant: TenantContext
  ) {
    this.assertOrgAccess(tenant, orgId);
    const { fileName, fileData, mimeType } = body;

    if (!fileName || !fileData) {
      throw new BadRequestException("fileName and fileData are required.");
    }

    const allowedExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "webp"];
    const ext = fileName.split(".").pop()?.toLowerCase() ?? "";
    if (!allowedExtensions.includes(ext)) {
      throw new BadRequestException(
        `Unsupported file type. Allowed: ${allowedExtensions.join(", ")}`,
      );
    }

    const base64 = fileData.includes(",") ? fileData.split(",")[1] : fileData;
    const buffer = Buffer.from(base64, "base64");

    const maxBytes = 1 * 1024 * 1024; // 1 MB
    if (buffer.byteLength > maxBytes) {
      throw new BadRequestException("Logo must be 1 MB or smaller.");
    }

    const resolvedMime = mimeType || `image/${ext === "jpg" ? "jpeg" : ext}`;

    const key = await this.r2StorageService.uploadFile(
      fileName,
      buffer,
      resolvedMime,
      "org-logos",
    );

    // Update logo_url on the organization row
    const client = this.supabaseService.getClient();
    const { error } = await client
      .from("organization")
      .update({ logo_url: key, updated_at: new Date().toISOString() })
      .eq("id", orgId);
    if (error) throw error;

    return { logoUrl: await this.resolveLogoUrl(key) };
  }

  @Post("uploads")
  async uploadFile(
    @Body()
    body: {
      fileName: string;
      fileData: string;
      mimeType?: string;
      prefix?: string;
    },
  ) {
    const { fileName, fileData, mimeType, prefix } = body;

    if (!fileName || !fileData) {
      throw new BadRequestException("fileName and fileData are required.");
    }

    const base64 = fileData.includes(",") ? fileData.split(",")[1] : fileData;
    const buffer = Buffer.from(base64, "base64");

    if (!buffer.byteLength) {
      throw new BadRequestException("Uploaded file is empty.");
    }

    const resolvedPrefix = (prefix?.trim() || "uploads").replace(
      /[^a-zA-Z0-9/_-]/g,
      "",
    );
    const resolvedMime = mimeType?.trim() || "application/octet-stream";

    const key = await this.r2StorageService.uploadFile(
      fileName,
      buffer,
      resolvedMime,
      resolvedPrefix,
    );

    return {
      success: true,
      fileKey: key,
      fileUrl: key,
    };
  }

  @Delete("uploads")
  async deleteUploadedFile(
    @Body()
    body: {
      fileUrl?: string;
      fileKey?: string;
    },
  ) {
    const fileKey =
      body.fileKey?.trim() ||
      (body.fileUrl?.trim() ? this.parseFileKeyFromUrl(body.fileUrl.trim()) : null);

    if (!fileKey) {
      throw new BadRequestException("fileKey or a valid fileUrl is required.");
    }

    await this.r2StorageService.deleteFile(fileKey);

    return { success: true };
  }
}
