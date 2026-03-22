import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";

// settings_locations has two FKs pointing at settings_outlets (outlet_id and parent_outlet_id).
// We must hint PostgREST which FK to use by specifying the constraint name.
const SETTINGS_SELECT =
  "*, settings_locations!settings_locations_outlet_id_fkey(location_type, parent_outlet_id, logo_url, is_primary)";

@Injectable()
export class OutletsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private flattenOutlet(outlet: any): any {
    const settings = Array.isArray(outlet.settings_locations)
      ? outlet.settings_locations[0]
      : outlet.settings_locations;
    const { settings_locations, ...rest } = outlet;
    return {
      ...rest,
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
      .select(SETTINGS_SELECT)
      .eq("org_id", orgId)
      .order("created_at", { ascending: true });

    if (error) throw new Error(`Failed to fetch settings_outlets: ${error.message}`);
    return (data ?? []).map((o) => this.flattenOutlet(o));
  }

  async findOne(id: string, orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("settings_outlets")
      .select(SETTINGS_SELECT)
      .eq("id", id)
      .eq("org_id", orgId)
      .single();

    if (error) return null;
    return this.flattenOutlet(data);
  }

  async create(dto: any) {
    // 1. Insert into settings_outlets (only its own columns)
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

    // 2. Insert into settings_locations
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

    return {
      ...outlet,
      location_type: dto.location_type ?? "business",
      parent_outlet_id: dto.parent_outlet_id ?? null,
      logo_url: dto.logo_url ?? null,
      is_primary: dto.is_primary ?? false,
    };
  }

  async update(id: string, orgId: string, dto: any) {
    // 1. Update settings_outlets table (only its own columns)
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

    // 2. Upsert settings_locations (creates row if missing, updates if present)
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
    // Delete settings_locations first (FK constraint)
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
