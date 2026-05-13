import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { TenantContext } from "../../common/middleware/tenant.middleware";

const TABLE = "transaction_series";

@Injectable()
export class TransactionSeriesService {
  constructor(private readonly supabaseService: SupabaseService) {}


  async findAll(tenant: TenantContext) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from(TABLE)
      .select("*")
      .eq("entity_id", tenant.entityId)
      .order("created_at", { ascending: true });

    if (error)
      throw new Error(`Failed to fetch transaction series: ${error.message}`);
    return data ?? [];
  }

  async findOne(id: string, tenant: TenantContext) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from(TABLE)
      .select("*")
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .single();

    if (error) return null;
    return data;
  }

  async create(tenant: TenantContext, dto: any) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from(TABLE)
      .insert({
        entity_id: tenant.entityId,
        name: dto.name,
        code: dto.code ?? null,
        branch_code: dto.branch_code ?? null,
        warehouse_code: dto.warehouse_code ?? null,
        modules: dto.modules ?? [],
      })
      .select()
      .single();

    if (error)
      throw new Error(`Failed to create transaction series: ${error.message}`);
    return data;
  }

  async update(id: string, tenant: TenantContext, dto: any) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from(TABLE)
      .update({
        name: dto.name,
        code: dto.code ?? null,
        branch_code: dto.branch_code ?? null,
        warehouse_code: dto.warehouse_code ?? null,
        modules: dto.modules ?? [],
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .select()
      .single();

    if (error)
      throw new Error(`Failed to update transaction series: ${error.message}`);
    return data;
  }

  async remove(id: string, tenant: TenantContext) {
    const { error } = await this.supabaseService
      .getClient()
      .from(TABLE)
      .delete()
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (error)
      throw new Error(`Failed to delete transaction series: ${error.message}`);
    return { success: true };
  }
}
