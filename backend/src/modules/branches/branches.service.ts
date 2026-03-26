import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";

@Injectable()
export class BranchesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("settings_branches")
      .select("*")
      .eq("org_id", orgId)
      .order("created_at", { ascending: true });

    if (error) throw new Error(`Failed to fetch settings_branches: ${error.message}`);
    return data ?? [];
  }

  async findOne(id: string, orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("settings_branches")
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
      .from("settings_branches")
      .insert({
        org_id: dto.org_id,
        name: dto.name,
        branch_code: dto.branch_code ?? null,
        branch_type: dto.branch_type ?? null,
        email: dto.email ?? null,
        phone: dto.phone ?? null,
        website: dto.website ?? null,
        attention: dto.attention ?? null,
        address_street_1: dto.address_street_1 ?? null,
        address_street_2: dto.address_street_2 ?? null,
        city: dto.city ?? null,
        state: dto.state ?? null,
        pincode: dto.pincode ?? null,
        country: dto.country ?? "India",
        gstin: dto.gstin ?? null,
        gstin_registration_type: dto.gstin_registration_type ?? null,
        logo_url: dto.logo_url ?? null,
        subscription_from: dto.subscription_from ?? null,
        subscription_to: dto.subscription_to ?? null,
        is_active: dto.is_active ?? true,
      })
      .select()
      .single();

    if (error) throw new Error(`Failed to create branch: ${error.message}`);
    return data;
  }

  async update(id: string, orgId: string, dto: any) {
    const fields = [
      "name", "branch_code", "branch_type",
      "email", "phone", "website",
      "attention", "address_street_1", "address_street_2",
      "city", "state", "pincode", "country",
      "gstin", "gstin_registration_type",
      "logo_url", "subscription_from", "subscription_to",
      "is_active",
    ];

    const payload: Record<string, any> = { updated_at: new Date().toISOString() };
    for (const field of fields) {
      if (field in dto) payload[field] = dto[field] ?? null;
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("settings_branches")
      .update(payload)
      .eq("id", id)
      .eq("org_id", orgId)
      .select()
      .single();

    if (error) throw new Error(`Failed to update branch: ${error.message}`);
    return data;
  }

  async remove(id: string, orgId: string) {
    const { error } = await this.supabaseService
      .getClient()
      .from("settings_branches")
      .delete()
      .eq("id", id)
      .eq("org_id", orgId);

    if (error) throw new Error(`Failed to delete branch: ${error.message}`);
    return { success: true };
  }
}
