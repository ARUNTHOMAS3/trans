import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";

@Injectable()
export class OutletsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private async fetchSettingsMap(orgId: string): Promise<Map<string, any>> {
    const { data } = await this.supabaseService
      .getClient()
      .from("settings_locations")
      .select("outlet_id, location_type, parent_outlet_id, logo_url, is_primary")
      .eq("org_id", orgId);
    return new Map((data ?? []).map((s: any) => [s.outlet_id, s]));
  }

  private mergeSettings(outlet: any, settings: any) {
    return {
      ...outlet,
      location_type: settings?.location_type ?? "business",
      parent_outlet_id: settings?.parent_outlet_id ?? null,
      logo_url: settings?.logo_url ?? null,
      is_primary: settings?.is_primary ?? false,
    };
  }

  async findAll(orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("settings_outlets")
      .select("*")
      .eq("org_id", orgId)
      .order("created_at", { ascending: true });

    if (error) throw new Error(`Failed to fetch settings_outlets: ${error.message}`);

    const settingsMap = await this.fetchSettingsMap(orgId);
    return (data ?? []).map((o: any) => this.mergeSettings(o, settingsMap.get(o.id)));
  }

  async findOne(id: string, orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("settings_outlets")
      .select("*")
      .eq("id", id)
      .eq("org_id", orgId)
      .single();

    if (error) return null;

    const { data: settings } = await this.supabaseService
      .getClient()
      .from("settings_locations")
      .select("location_type, parent_outlet_id, logo_url, is_primary")
      .eq("outlet_id", id)
      .single();

    return this.mergeSettings(data, settings);
  }

  async create(dto: any) {
    const { data: outlet, error: outletError } = await this.supabaseService
      .getClient()
      .from("settings_outlets")
      .insert({
        org_id: dto.org_id,
        name: dto.name,
        outlet_code: dto.outlet_code,
        gstin: dto.gstin ?? null,
        email: dto.email ?? null,
        phone: dto.phone ?? null,
        address: dto.address ?? null,
        city: dto.city ?? null,
        state: dto.state ?? null,
        country: dto.country ?? "India",
        pincode: dto.pincode ?? null,
        is_active: dto.is_active ?? true,
      })
      .select()
      .single();

    if (outletError) throw new Error(`Failed to create settings_outlet: ${outletError.message}`);

    const { error: settingsError } = await this.supabaseService
      .getClient()
      .from("settings_locations")
      .insert({
        outlet_id: outlet.id,
        org_id: dto.org_id,
        location_type: dto.location_type ?? "business",
        parent_outlet_id: dto.parent_outlet_id ?? null,
        logo_url: dto.logo_url ?? null,
        is_primary: dto.is_primary ?? false,
      });

    if (settingsError) throw new Error(`Failed to create location settings: ${settingsError.message}`);

    return this.mergeSettings(outlet, {
      location_type: dto.location_type ?? "business",
      parent_outlet_id: dto.parent_outlet_id ?? null,
      logo_url: dto.logo_url ?? null,
      is_primary: dto.is_primary ?? false,
    });
  }

  async update(id: string, orgId: string, dto: any) {
    const outletPayload: Record<string, any> = {
      updated_at: new Date().toISOString(),
    };
    const outletFields = [
      "name", "outlet_code", "gstin", "email", "phone",
      "address", "city", "state", "country", "pincode", "is_active",
    ];
    for (const field of outletFields) {
      if (field in dto) outletPayload[field] = dto[field] ?? null;
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("settings_outlets")
      .update(outletPayload)
      .eq("id", id)
      .eq("org_id", orgId)
      .select()
      .single();

    if (error) throw new Error(`Failed to update settings_outlet: ${error.message}`);

    const settingsFields = ["location_type", "parent_outlet_id", "logo_url", "is_primary"];
    const hasSettingsUpdate = settingsFields.some((f) => f in dto);

    if (hasSettingsUpdate) {
      const settingsPayload: Record<string, any> = {
        outlet_id: id,
        org_id: orgId,
        updated_at: new Date().toISOString(),
      };
      for (const field of settingsFields) {
        if (field in dto) settingsPayload[field] = dto[field] ?? null;
      }

      const { error: settingsError } = await this.supabaseService
        .getClient()
        .from("settings_locations")
        .upsert(settingsPayload, { onConflict: "outlet_id" });

      if (settingsError) throw new Error(`Failed to update location settings: ${settingsError.message}`);
    }

    return data;
  }

  async remove(id: string, orgId: string) {
    await this.supabaseService
      .getClient()
      .from("settings_locations")
      .delete()
      .eq("outlet_id", id);

    const { error } = await this.supabaseService
      .getClient()
      .from("settings_outlets")
      .delete()
      .eq("id", id)
      .eq("org_id", orgId);

    if (error) throw new Error(`Failed to delete settings_outlet: ${error.message}`);
    return { success: true };
  }
}
