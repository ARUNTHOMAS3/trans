import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../modules/supabase/supabase.service";
import { TenantContext } from "../common/middleware/tenant.middleware";

@Injectable()
export class SequencesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getSequence(module: string, tenant: TenantContext, _branchId?: string) {
    const client = this.supabaseService.getClient();

    const { data, error } = await client
      .from("transactional_sequences")
      .select("*")
      .eq("module", module)
      .eq("entity_id", tenant.entityId)
      .eq("is_active", true)
      .maybeSingle();

    if (!error && data) return data;

    // Auto-initialize if sequence is missing for this entity
    const defaults: Record<string, { prefix: string; next_number: number; padding: number }> = {
      vendor:   { prefix: "VEN-", next_number: 1, padding: 5 },
      customer: { prefix: "CUS-", next_number: 1, padding: 5 },
      sale:     { prefix: "SO-",  next_number: 1, padding: 5 },
      purchase: { prefix: "PO-",  next_number: 1, padding: 5 },
    };

    const config = defaults[module] ?? {
      prefix: `${module.toUpperCase()}-`,
      next_number: 1,
      padding: 5,
    };

    let nextNum = config.next_number;
    if (module === "vendor" || module === "customer") {
      const table = module === "vendor" ? "vendors" : "customers";
      const { count, error: countError } = await client
        .from(table)
        .select("*", { count: "exact", head: true })
        .eq("entity_id", tenant.entityId);
      if (!countError && count !== null) nextNum = count + 1;
    }

    const { data: created, error: initError } = await client
      .from("transactional_sequences")
      .insert([{
        module,
        prefix: config.prefix,
        next_number: nextNum,
        padding: config.padding,
        entity_id: tenant.entityId,
        is_active: true,
      }])
      .select()
      .single();

    if (initError) throw new Error(`Failed to initialize sequence: ${initError.message}`);
    return created;
  }

  async getNextNumberFormatted(module: string, tenant: TenantContext, branchId?: string) {
    const settings = await this.getSequence(module, tenant, branchId);
    return this.formatSequence(
      settings.prefix,
      settings.next_number,
      settings.padding,
      settings.suffix,
    );
  }

  private formatSequence(
    prefix: string,
    num: number,
    padding: number,
    suffix: string = "",
  ) {
    const paddedNum = num.toString().padStart(padding, "0");
    return `${prefix}${paddedNum}${suffix}`;
  }

  async incrementSequence(
    module: string,
    tenant: TenantContext,
    usedNumber?: string,
    branchId?: string,
  ) {
    const settings = await this.getSequence(module, tenant, branchId);

    if (usedNumber) {
      const currentFormatted = this.formatSequence(
        settings.prefix,
        settings.next_number,
        settings.padding,
        settings.suffix,
      );
      if (usedNumber !== currentFormatted) {
        return settings;
      }
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("transactional_sequences")
      .update({ next_number: settings.next_number + 1, updated_at: new Date() })
      .eq("id", settings.id)
      .select()
      .single();

    if (error) throw new Error(`Failed to increment sequence for ${module}`);
    return data;
  }

  async checkDuplicate(module: string, number: string, tenant: TenantContext) {
    const tableConfigs: any = {
      vendor: { table: "vendors", column: "vendor_number" },
      customer: { table: "customers", column: "customer_number" },
    };

    const config = tableConfigs[module];
    if (!config) return { exists: false };

    const { data, error } = await (
      this.supabaseService.getClient().from(config.table) as any
    )
      .select(config.column)
      .eq(config.column, number)
      .eq("entity_id", tenant.entityId)
      .maybeSingle();

    if (error) throw error;
    return { exists: !!data };
  }

  async updateSettings(
    module: string,
    tenant: TenantContext,
    updateDto: {
      prefix?: string;
      nextNumber?: number;
      padding?: number;
      suffix?: string;
      branchId?: string;
    },
  ) {
    const client = this.supabaseService.getClient();

    const updateData: any = { updated_at: new Date() };
    if (updateDto.prefix !== undefined) updateData.prefix = updateDto.prefix;
    if (updateDto.nextNumber !== undefined) updateData.next_number = updateDto.nextNumber;
    if (updateDto.padding !== undefined) updateData.padding = updateDto.padding;
    if (updateDto.suffix !== undefined) updateData.suffix = updateDto.suffix;

    const { data: existing } = await client
      .from("transactional_sequences")
      .select("id")
      .eq("module", module)
      .eq("entity_id", tenant.entityId)
      .maybeSingle();

    if (existing) {
      const { data, error } = await client
        .from("transactional_sequences")
        .update(updateData)
        .eq("id", existing.id)
        .select()
        .single();
      if (error) throw error;
      return data;
    } else {
      const { data, error } = await client
        .from("transactional_sequences")
        .insert({ module, entity_id: tenant.entityId, is_active: true, ...updateData })
        .select()
        .single();
      if (error) throw error;
      return data;
    }
  }
}
