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
import { db, client } from "../../db/db";
import { organizations, organisationBranchMaster } from "../../db/schema";
import { eq, and } from "drizzle-orm";

@Controller("lookups")
export class GlobalLookupsController {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly r2StorageService: R2StorageService,
  ) {}

  private async syncOrganisationMaster(orgId: string) {
    try {
      const rows = await db
        .select({
          id: organizations.id,
          name: organizations.name,
          isActive: organizations.isActive,
        })
        .from(organizations)
        .where(eq(organizations.id, orgId))
        .limit(1);

      const data = rows[0];
      if (!data?.id || !data?.name) return;

      const existingMaster = await db
        .select({ id: organisationBranchMaster.id })
        .from(organisationBranchMaster)
        .where(
          and(
            eq(organisationBranchMaster.type, "ORG"),
            eq(organisationBranchMaster.refId, data.id),
          ),
        )
        .limit(1);

      if (existingMaster[0]) {
        await db
          .update(organisationBranchMaster)
          .set({
            name: data.name,
            isActive: data.isActive ?? true,
          })
          .where(eq(organisationBranchMaster.id, existingMaster[0].id));
      } else {
        await db.insert(organisationBranchMaster).values({
          name: data.name,
          type: "ORG",
          refId: data.id,
          parentId: null,
          isActive: data.isActive ?? true,
        });
      }
    } catch (err) {
      console.error("[GlobalLookupsController] syncOrganisationMaster error:", err);
    }
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
    try {
      const rows = await client.unsafe(
        `SELECT display, tzdb_name FROM timezones WHERE is_active = true AND (tzdb_name = $1 OR display = $1 OR name = $1) LIMIT 1`,
        [rawTimezone],
      );
      return (
        ((rows[0] as unknown) as { display: string; tzdb_name: string } | null) ??
        null
      );
    } catch {
      return null;
    }
  }

  private async resolveCompanyIdLabel(
    rawLabel: string,
  ): Promise<string | null> {
    try {
      const rows = await client.unsafe(
        `SELECT label FROM company_id_labels WHERE is_active = true AND label = $1 LIMIT 1`,
        [rawLabel],
      );
      return rows[0]?.label ?? null;
    } catch {
      return null;
    }
  }

  private async fetchActiveOptions(
    table: string,
    select: string,
    orderBy: string[] = ["sort_order", "label"],
  ) {
    const sanitizedTable = table.replace(/[^a-zA-Z0-9_]/g, "");
    const sanitizedSelect = select.replace(/[^a-zA-Z0-9_,]/g, "");

    let sqlQuery = `SELECT ${sanitizedSelect} FROM "${sanitizedTable}" WHERE is_active = true`;
    if (orderBy.length > 0) {
      const sanitizedOrderBy = orderBy
        .map((col) => `"${col.replace(/[^a-zA-Z0-9_]/g, "")}" ASC`)
        .join(", ");
      sqlQuery += ` ORDER BY ${sanitizedOrderBy}`;
    }

    try {
      const data = await client.unsafe(sqlQuery);
      return data ?? [];
    } catch {
      return [];
    }
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
    _districtId?: string | null,
    _assemblyCodeOrName?: string | null,
  ) {
    return null;
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

    try {
      const rows = await client.unsafe(
        `SELECT id, code, name FROM assemblies_constituencies WHERE id = $1 LIMIT 1`,
        [assemblyId.trim()],
      );
      const data = rows[0];
      if (!data) return rawAddress;

      parsed["assembly_code"] = data.code ?? parsed["assembly_code"] ?? null;
      parsed["assembly_name"] = data.name ?? parsed["assembly_name"] ?? null;
      return JSON.stringify(parsed);
    } catch {
      return rawAddress;
    }
  }

  private assertOrgAccess(tenant: TenantContext, requestedOrgId: string) {
    if (tenant.role !== "admin" && tenant.orgId !== requestedOrgId) {
      throw new ForbiddenException("Cross-organization access is not allowed");
    }
  }

  @Get("currencies")
  async getCurrencies(@Query("q") q?: string) {
    const search = q?.trim();
    let sqlQuery = `SELECT id, code, name, symbol, decimals, format FROM currencies WHERE is_active = true`;
    const params: any[] = [];

    if (search) {
      params.push(`%${search}%`);
      sqlQuery += ` AND (code ILIKE $1 OR name ILIKE $1)`;
    }

    sqlQuery += ` ORDER BY code ASC`;

    try {
      const data = await client.unsafe(sqlQuery, params);
      return data ?? [];
    } catch {
      return [];
    }
  }

  @Get("countries")
  async getCountries(@Query("q") q?: string) {
    const search = q?.trim();
    let sqlQuery = `SELECT id, name, full_label, phone_code, short_code FROM countries WHERE is_active = true`;
    const params: any[] = [];

    if (search) {
      params.push(`%${search}%`);
      sqlQuery += ` AND (name ILIKE $1 OR full_label ILIKE $1 OR phone_code ILIKE $1)`;
    }

    sqlQuery += ` ORDER BY name ASC`;

    try {
      const data = await client.unsafe(sqlQuery, params);
      return data ?? [];
    } catch {
      return [];
    }
  }

  @Get("industries")
  async getIndustries() {
    try {
      const data = await client.unsafe(
        `SELECT name FROM industries WHERE is_active = true ORDER BY sort_order ASC`,
      );
      return (data ?? []).map((r: any) => r.name);
    } catch {
      return [];
    }
  }

  @Get("timezones")
  async getTimezones(@Query("countryId") countryId?: string) {
    let sqlQuery = `SELECT id, name, tzdb_name, utc_offset, display, country_id FROM timezones WHERE is_active = true`;
    const params: any[] = [];

    if (countryId) {
      params.push(countryId);
      sqlQuery += ` AND country_id = $1`;
    }

    sqlQuery += ` ORDER BY sort_order ASC, display ASC`;

    try {
      const data = await client.unsafe(sqlQuery, params);
      return data ?? [];
    } catch {
      return [];
    }
  }

  @Get("company-id-labels")
  async getCompanyIdLabels() {
    try {
      const data = await client.unsafe(
        `SELECT label FROM company_id_labels WHERE is_active = true ORDER BY sort_order ASC`,
      );
      return (data ?? []).map((r: any) => r.label);
    } catch {
      return [];
    }
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
    return this.fetchActiveOptions("gst_treatments", "code,label,sort_order");
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
    const search = q?.trim();
    const countryValue = countryCodeParam || countryIdQuery;
    let resolvedCountryId = countryValue;

    if (countryValue && countryValue.length === 2) {
      try {
        const countryRows = await client.unsafe(
          `SELECT id FROM countries WHERE UPPER(short_code) = $1 LIMIT 1`,
          [countryValue.toUpperCase()],
        );
        if (countryRows[0]?.id) {
          resolvedCountryId = countryRows[0].id;
        }
      } catch {
        // ignore
      }
    }

    let sqlQuery = `SELECT id, name, code FROM states WHERE is_active = true`;
    const params: any[] = [];

    if (resolvedCountryId) {
      params.push(resolvedCountryId);
      sqlQuery += ` AND (country_id = $1 OR state_id = $1)`;
    }

    if (search) {
      params.push(`%${search}%`);
      sqlQuery += ` AND name ILIKE $${params.length}`;
    }

    sqlQuery += ` ORDER BY name ASC`;

    try {
      const data = await client.unsafe(sqlQuery, params);
      return data ?? [];
    } catch {
      return [];
    }
  }

  @Get("districts")
  async getDistricts(@Query("stateId") stateId?: string) {
    if (!stateId?.trim()) {
      throw new BadRequestException("stateId is required");
    }

    try {
      const data = await client.unsafe(
        `SELECT id, name, code FROM lsgd_districts WHERE state_id = $1 AND is_active = true ORDER BY name ASC`,
        [stateId.trim()],
      );
      return data ?? [];
    } catch {
      return [];
    }
  }

  @Get("local-bodies")
  async getLocalBodies(
    @Query("districtId") districtId?: string,
    @Query("bodyType") bodyType?: string,
  ) {
    if (!districtId?.trim()) {
      throw new BadRequestException("districtId is required");
    }

    let sqlQuery = `SELECT id, name, code, body_type FROM lsgd_local_bodies WHERE district_id = $1 AND is_active = true`;
    const params: any[] = [districtId.trim()];

    if (bodyType?.trim()) {
      params.push(bodyType.trim());
      sqlQuery += ` AND body_type = $2`;
    }

    sqlQuery += ` ORDER BY name ASC`;

    try {
      const data = await client.unsafe(sqlQuery, params);
      return data ?? [];
    } catch {
      return [];
    }
  }

  @Get("wards")
  async getWards(@Query("localBodyId") localBodyId?: string) {
    if (!localBodyId?.trim()) {
      throw new BadRequestException("localBodyId is required");
    }

    try {
      const data = await client.unsafe(
        `SELECT id, ward_no, name, code FROM lsgd_wards WHERE local_body_id = $1 AND is_active = true ORDER BY ward_no ASC, name ASC`,
        [localBodyId.trim()],
      );

      return (data ?? []).map((ward: any) => ({
        ...ward,
        display_name:
          ward.ward_no != null ? `${ward.ward_no} - ${ward.name}` : ward.name,
      }));
    } catch {
      return [];
    }
  }

  @Get("assemblies")
  async getAssemblies(@Query("districtId") districtId?: string) {
    if (!districtId?.trim()) {
      throw new BadRequestException("districtId is required");
    }

    try {
      const data = await client.unsafe(
        `SELECT id, code, name FROM assemblies_constituencies WHERE district_id = $1 AND is_active = true ORDER BY name ASC`,
        [districtId.trim()],
      );

      return (data ?? []).map((assembly: any) => ({
        id: assembly.id,
        code: assembly.code,
        name: assembly.name,
      }));
    } catch {
      return [];
    }
  }

  @Get("org/:orgId")
  async getOrgDetails(
    @Param("orgId") orgId: string,
    @Tenant() tenant: TenantContext,
  ) {
    this.assertOrgAccess(tenant, orgId);

    try {
      const orgRows = await client.unsafe(
        `SELECT id, system_id, name, state_id, industry, logo_url, base_currency, base_currency_decimals, base_currency_format, fiscal_year, organization_language, communication_languages, timezone, date_format, date_separator, company_id_label, company_id_value, attention, street, place, city, pincode, phone, email, district_id, local_body_id, assembly_id, ward_id, payment_stub_address, has_separate_payment_stub_address, payment_stub_assembly_id, additional_fields, gstin, gst_treatment, source_of_supply, is_drug_registered, drug_licence_type, drug_license_20, drug_license_21, drug_license_20b, drug_license_21b, drug_license_20_url, drug_license_21_url, drug_license_20b_url, drug_license_21b_url, is_fssai_registered, fssai_number, fssai_url, is_msme_registered, msme_registration_type, msme_number, msme_url FROM organization WHERE id = $1 LIMIT 1`,
        [orgId],
      );

      const org = orgRows[0];
      if (!org) throw new BadRequestException("Organization not found");

      let branding = null;
      try {
        const brandingRows = await client.unsafe(
          `SELECT accent_color, theme_mode, keep_branding FROM branding WHERE org_id = $1 OR entity_id = $2 LIMIT 1`,
          [orgId, tenant.entityId],
        );
        branding = brandingRows[0];
      } catch {
        // ignore
      }

      let timezoneDisplay: string | null = null;
      let timezoneTzdbName: string | null = null;
      if (org?.timezone) {
        const timezoneRow = await this.resolveTimezoneRow(org.timezone);
        timezoneDisplay = timezoneRow?.display ?? null;
        timezoneTzdbName = timezoneRow?.tzdb_name ?? null;
      }

      let countryName: string | null = null;
      if (org?.state_id) {
        try {
          const countryRows = await client.unsafe(
            `SELECT c.name FROM states s JOIN countries c ON c.id = s.country_id OR c.id = s.state_id WHERE s.id = $1 LIMIT 1`,
            [org.state_id],
          );
          countryName = countryRows[0]?.name ?? null;
        } catch {
          // ignore
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
        accent_color: branding?.accent_color ?? "#22A95E",
        theme_mode: branding?.theme_mode ?? "dark",
        keep_branding: branding?.keep_branding ?? false,
      };
    } catch (error) {
      throw error;
    }
  }

  @Get("org/:orgId/branding")
  async getOrgBranding(
    @Param("orgId") orgId: string,
    @Tenant() tenant: TenantContext,
  ) {
    this.assertOrgAccess(tenant, orgId);

    try {
      const rows = await client.unsafe(
        `SELECT accent_color, theme_mode, keep_branding FROM branding WHERE entity_id = $1 LIMIT 1`,
        [tenant.entityId],
      );
      const data = rows[0];
      return {
        accent_color: data?.accent_color ?? "#22A95E",
        theme_mode: data?.theme_mode ?? "dark",
        keep_branding: data?.keep_branding ?? false,
      };
    } catch {
      return {
        accent_color: "#22A95E",
        theme_mode: "dark",
        keep_branding: false,
      };
    }
  }

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
    @Tenant() tenant: TenantContext,
  ) {
    this.assertOrgAccess(tenant, orgId);

    try {
      await client.unsafe(
        `INSERT INTO branding (entity_id, org_id, accent_color, theme_mode, keep_branding)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (entity_id) DO UPDATE SET
           accent_color = COALESCE(EXCLUDED.accent_color, branding.accent_color),
           theme_mode = COALESCE(EXCLUDED.theme_mode, branding.theme_mode),
           keep_branding = COALESCE(EXCLUDED.keep_branding, branding.keep_branding)`,
        [
          tenant.entityId,
          orgId,
          body.accent_color ?? "#22A95E",
          body.theme_mode ?? "dark",
          body.keep_branding ?? false,
        ],
      );
    } catch (err) {
      console.error("[GlobalLookupsController] saveOrgBranding error:", err);
    }

    return { success: true };
  }

  @Post("org/:orgId/save")
  @HttpCode(HttpStatus.OK)
  async saveOrgProfile(
    @Param("orgId") orgId: string,
    @Body()
    body: Record<string, any>,
    @Tenant() tenant: TenantContext,
  ) {
    this.assertOrgAccess(tenant, orgId);
    const payload = { ...body };

    if (typeof body.phone === "string" && body.phone.trim().length > 0) {
      const mobileRegex = /^[0-9]{10}$/;
      if (!mobileRegex.test(body.phone.trim())) {
        throw new BadRequestException(
          "Phone number must be exactly 10 digits.",
        );
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
      payload.payment_stub_assembly_id = (assemblyMatch as any)?.id ?? null;
    } else if (body.payment_stub_assembly_id !== undefined) {
      payload.payment_stub_assembly_id =
        body.payment_stub_assembly_id?.toString().trim() || null;
    }

    try {
      await db
        .update(organizations)
        .set({
          name: payload.name,
          stateId: payload.state_id,
          industry: payload.industry,
          baseCurrency: payload.base_currency,
          baseCurrencyDecimals: payload.base_currency_decimals,
          baseCurrencyFormat: payload.base_currency_format,
          fiscalYear: payload.fiscal_year,
          organizationLanguage: payload.organization_language,
          communicationLanguages: payload.communication_languages,
          timezone: payload.timezone,
          dateFormat: payload.date_format,
          dateSeparator: payload.date_separator,
          companyIdLabel: payload.company_id_label,
          companyIdValue: payload.company_id_value,
          attention: payload.attention,
          street: payload.street,
          place: payload.place,
          city: payload.city,
          pincode: payload.pincode,
          phone: payload.phone,
          districtId: payload.district_id,
          localBodyId: payload.local_body_id,
          wardId: payload.ward_id,
          paymentStubAddress: payload.payment_stub_address,
          hasSeparatePaymentStubAddress: payload.has_separate_payment_stub_address,
          additionalFields: payload.additional_fields,
          isDrugRegistered: payload.is_drug_registered,
          drugLicenceType: payload.drug_licence_type,
          drugLicense20: payload.drug_license_20,
          drugLicense21: payload.drug_license_21,
          drugLicense20b: payload.drug_license_20b,
          drugLicense21b: payload.drug_license_21b,
          drugLicense20Url: payload.drug_license_20_url,
          drugLicense21Url: payload.drug_license_21_url,
          drugLicense20bUrl: payload.drug_license_20b_url,
          drugLicense21bUrl: payload.drug_license_21b_url,
          isFssaiRegistered: payload.is_fssai_registered,
          fssaiNumber: payload.fssai_number,
          fssaiUrl: payload.fssai_url,
          isMsmeRegistered: payload.is_msme_registered,
          msmeRegistrationType: payload.msme_registration_type,
          msmeNumber: payload.msme_number,
          msmeUrl: payload.msme_url,
          updatedAt: new Date(),
        })
        .where(eq(organizations.id, orgId));
    } catch (err) {
      console.error("[GlobalLookupsController] saveOrgProfile error:", err);
      throw err;
    }

    await this.syncOrganisationMaster(orgId);
    return { success: true };
  }

  @Post("org/:orgId/logo")
  async uploadOrgLogo(
    @Param("orgId") orgId: string,
    @Body() body: { fileName: string; fileData: string; mimeType?: string },
    @Tenant() tenant: TenantContext,
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

    await db
      .update(organizations)
      .set({ logoUrl: key, updatedAt: new Date() })
      .where(eq(organizations.id, orgId));

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
      (body.fileUrl?.trim()
        ? this.parseFileKeyFromUrl(body.fileUrl.trim())
        : null);

    if (!fileKey) {
      throw new BadRequestException("fileKey or a valid fileUrl is required.");
    }

    await this.r2StorageService.deleteFile(fileKey);

    return { success: true };
  }
}
