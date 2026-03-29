import {
  Controller,
  Get,
  Post,
  HttpCode,
  HttpStatus,
  Query,
  Param,
  Body,
  BadRequestException,
} from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { R2StorageService } from "../accountant/r2-storage.service";

@Controller("lookups")
export class GlobalLookupsController {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly r2StorageService: R2StorageService,
  ) {}

  private async resolveLogoUrl(
    keyOrUrl?: string | null,
  ): Promise<string | null> {
    if (!keyOrUrl || !keyOrUrl.trim()) {
      return null;
    }

    const value = keyOrUrl.trim();
    if (
      value.startsWith("http://") ||
      value.startsWith("https://") ||
      value.startsWith("data:")
    ) {
      return value;
    }

    try {
      return await this.r2StorageService.getPresignedUrl(value);
    } catch (error) {
      console.error(
        "[GlobalLookupsController] Failed to sign org logo:",
        error,
      );
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
      .from("settings_districts")
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
      .from("settings_local_bodies")
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
      .from("settings_wards")
      .select("id,ward_no,name,code")
      .eq("local_body_id", localBodyId.trim())
      .eq("is_active", true)
      .order("ward_no", { ascending: true })
      .order("name", { ascending: true });

    if (error) throw error;

    return (data ?? []).map((ward: any) => ({
      ...ward,
      display_name:
        ward.ward_no != null
          ? `${ward.ward_no} - ${ward.name}`
          : ward.name,
    }));
  }

  /** Returns full org profile — all columns live directly on the organization table,
   *  merged with branding settings from settings_branding.
   *  Also resolves country name from state_id → states.state_id → countries. */
  @Get("org/:orgId")
  async getOrgDetails(@Param("orgId") orgId: string) {
    const client = this.supabaseService.getClient();

    const [orgResult, brandingResult] = await Promise.all([
      client
        .from("organization")
        .select(
          "id, system_id, name, state_id, industry, logo_url, base_currency, base_currency_decimals, base_currency_format, fiscal_year, organization_language, communication_languages, timezone, date_format, date_separator, company_id_label, company_id_value, payment_stub_address, has_separate_payment_stub_address",
        )
        .eq("id", orgId)
        .single(),
      client
        .from("settings_branding")
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
  async getOrgBranding(@Param("orgId") orgId: string) {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("settings_branding")
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

  /** Upsert branding settings — creates or updates the settings_branding row. */
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
  ) {
    const client = this.supabaseService.getClient();

    const payload: Record<string, unknown> = { org_id: orgId };
    if (body.accent_color !== undefined)
      payload.accent_color = body.accent_color;
    if (body.theme_mode !== undefined) payload.theme_mode = body.theme_mode;
    if (body.keep_branding !== undefined)
      payload.keep_branding = body.keep_branding;

    const { error } = await client
      .from("settings_branding")
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
      payment_stub_address?: string;
      has_separate_payment_stub_address?: boolean;
    },
  ) {
    const client = this.supabaseService.getClient();
    const payload = { ...body } as Record<string, unknown>;

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

    const { error } = await client
      .from("organization")
      .update({ ...payload, updated_at: new Date().toISOString() })
      .eq("id", orgId);
    if (error) throw error;

    return { success: true };
  }

  /** Upload or replace the organization logo. Accepts base64-encoded image. */
  @Post("org/:orgId/logo")
  async uploadOrgLogo(
    @Param("orgId") orgId: string,
    @Body() body: { fileName: string; fileData: string; mimeType?: string },
  ) {
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
}
