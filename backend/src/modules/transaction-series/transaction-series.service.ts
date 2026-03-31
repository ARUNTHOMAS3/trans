import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";

const TABLE = "settings_transaction_series";

@Injectable()
export class TransactionSeriesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from(TABLE)
      .select("*")
      .eq("org_id", orgId)
      .order("created_at", { ascending: true });

    if (error)
      throw new Error(`Failed to fetch transaction series: ${error.message}`);
    return data ?? [];
  }

  async findOne(id: string, orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from(TABLE)
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
      .from(TABLE)
      .insert({
        org_id: dto.org_id,
        name: dto.name,
        modules: dto.modules ?? [],
      })
      .select()
      .single();

    if (error)
      throw new Error(`Failed to create transaction series: ${error.message}`);
    return data;
  }

  async update(id: string, orgId: string, dto: any) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from(TABLE)
      .update({
        name: dto.name,
        modules: dto.modules ?? [],
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .eq("org_id", orgId)
      .select()
      .single();

    if (error)
      throw new Error(`Failed to update transaction series: ${error.message}`);
    return data;
  }

  async remove(id: string, orgId: string) {
    const { error } = await this.supabaseService
      .getClient()
      .from(TABLE)
      .delete()
      .eq("id", id)
      .eq("org_id", orgId);

    if (error)
      throw new Error(`Failed to delete transaction series: ${error.message}`);
    return { success: true };
  }
}
