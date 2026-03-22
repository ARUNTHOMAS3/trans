import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";

@Injectable()
export class OutletsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("outlets")
      .select("*")
      .eq("org_id", orgId)
      .order("created_at", { ascending: true });

    if (error) throw new Error(`Failed to fetch outlets: ${error.message}`);
    return data ?? [];
  }

  async findOne(id: string, orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("outlets")
      .select("*")
      .eq("id", id)
      .eq("org_id", orgId)
      .single();

    if (error) return null;
    return data;
  }

  async create(dto: any) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("outlets")
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

    if (error) throw new Error(`Failed to create outlet: ${error.message}`);
    return data;
  }

  async update(id: string, orgId: string, dto: any) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("outlets")
      .update({
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
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .eq("org_id", orgId)
      .select()
      .single();

    if (error) throw new Error(`Failed to update outlet: ${error.message}`);
    return data;
  }

  async remove(id: string, orgId: string) {
    const { error } = await this.supabaseService
      .getClient()
      .from("outlets")
      .delete()
      .eq("id", id)
      .eq("org_id", orgId);

    if (error) throw new Error(`Failed to delete outlet: ${error.message}`);
    return { success: true };
  }
}
