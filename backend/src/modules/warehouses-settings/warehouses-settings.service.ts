import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";

@Injectable()
export class WarehousesSettingsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("warehouses")
      .select("*, settings_branches(id, name)")
      .eq("org_id", orgId)
      .order("created_at", { ascending: true });

    if (error) throw new Error(`Failed to fetch warehouses: ${error.message}`);
    return (data ?? []).map((w: any) => ({
      ...w,
      parent_branch_name: w.settings_branches?.name ?? null,
      settings_branches: undefined,
    }));
  }

  async findOne(id: string, orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("warehouses")
      .select("*, settings_branches(id, name)")
      .eq("id", id)
      .eq("org_id", orgId)
      .single();

    if (error) return null;
    return {
      ...data,
      parent_branch_name: data.settings_branches?.name ?? null,
      settings_branches: undefined,
    };
  }

  async create(dto: any) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("warehouses")
      .insert({
        org_id: dto.org_id,
        name: dto.name,
        warehouse_code: dto.warehouse_code ?? null,
        branch_id: dto.branch_id ?? null,
        attention: dto.attention ?? null,
        address_street_1: dto.address_street_1 ?? null,
        address_street_2: dto.address_street_2 ?? null,
        city: dto.city ?? null,
        state: dto.state ?? null,
        pincode: dto.pincode ?? null,
        country: dto.country ?? "India",
        phone: dto.phone ?? null,
        email: dto.email ?? null,
        is_active: dto.is_active ?? true,
      })
      .select()
      .single();

    if (error) throw new Error(`Failed to create warehouse: ${error.message}`);
    return data;
  }

  async update(id: string, orgId: string, dto: any) {
    const fields = [
      "name", "warehouse_code", "branch_id",
      "attention", "address_street_1", "address_street_2",
      "city", "state", "pincode", "country",
      "phone", "email", "is_active",
    ];

    const payload: Record<string, any> = { updated_at: new Date().toISOString() };
    for (const field of fields) {
      if (field in dto) payload[field] = dto[field] ?? null;
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("warehouses")
      .update(payload)
      .eq("id", id)
      .eq("org_id", orgId)
      .select()
      .single();

    if (error) throw new Error(`Failed to update warehouse: ${error.message}`);
    return data;
  }

  async remove(id: string, orgId: string) {
    const { error } = await this.supabaseService
      .getClient()
      .from("warehouses")
      .delete()
      .eq("id", id)
      .eq("org_id", orgId);

    if (error) throw new Error(`Failed to delete warehouse: ${error.message}`);
    return { success: true };
  }
}
