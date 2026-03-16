import { Controller, Get, Query, Param } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";

@Controller("lookups")
export class GlobalLookupsController {
  constructor(private readonly supabaseService: SupabaseService) {}

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

    let query = client.from("states").select("*").eq("is_active", true);

    if (resolvedCountryId) {
      query = query.eq("country_id", resolvedCountryId);
    }

    if (search) {
      query = query.ilike("name", `%${search}%`);
    }

    const { data, error } = await query.order("name", { ascending: true });
    if (error) throw error;

    return data ?? [];
  }

  /** Returns the org's state_id for Smart-Tax resolution. */
  @Get("org/:orgId")
  async getOrgDetails(@Param("orgId") orgId: string) {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("organization")
      .select("id, name, state_id")
      .eq("id", orgId)
      .single();
    if (error) throw error;
    return data;
  }
}
