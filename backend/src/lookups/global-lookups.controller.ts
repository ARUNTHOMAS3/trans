import { Controller, Get, Query } from "@nestjs/common";
import { SupabaseService } from "../modules/supabase/supabase.service";

@Controller("lookups")
export class GlobalLookupsController {
  constructor(private readonly supabaseService: SupabaseService) {}

  @Get("currencies")
  async getCurrencies(@Query("q") q?: string) {
    const client = this.supabaseService.getClient();
    const search = q?.trim();

    let query = client
      .from("currencies")
      .select("code,name,symbol,decimals,format")
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
      .select("name,full_label,phone_code,short_code")
      .eq("is_active", true);

    if (search) {
      query = query.or(
        `name.ilike.%${search}%,short_code.ilike.%${search}%,phone_code.ilike.%${search}%`,
      );
    }

    const { data, error } = await query.order("name", {
      ascending: true,
    });
    if (error) throw error;
    return data ?? [];
  }
}
