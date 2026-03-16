import { Injectable, NotFoundException } from "@nestjs/common";
import { SupabaseService } from "../modules/supabase/supabase.service";

@Injectable()
export class SequencesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getSequence(module: string, outletId?: string) {
    // Try outlet-specific first
    if (outletId) {
      const { data } = await this.supabaseService
        .getClient()
        .from("transactional_sequences")
        .select("*")
        .eq("module", module)
        .eq("is_active", true)
        .eq("outlet_id", outletId);

      if (data && data.length > 0) return data[0];
    }

    // Fallback to global
    const { data: globalData, error } = await this.supabaseService
      .getClient()
      .from("transactional_sequences")
      .select("*")
      .eq("module", module)
      .is("outlet_id", null);

    if (error || !globalData || globalData.length === 0) {
      // Auto-initialize if global sequence is missing
      const defaults: any = {
        vendor: { prefix: "VEN-", next_number: 1, padding: 5 },
        customer: { prefix: "CUS-", next_number: 1, padding: 5 },
        sale: { prefix: "SO-", next_number: 1, padding: 5 },
        purchase: { prefix: "PO-", next_number: 1, padding: 5 },
      };

      const config = defaults[module] || {
        prefix: `${module.toUpperCase()}-`,
        next_number: 1,
        padding: 5,
      };

      // Try to find the latest number if it's a known module
      let nextNum = config.next_number;
      if (module === "vendor" || module === "customer") {
        const table = module === "vendor" ? "vendors" : "customers";
        const { count, error: countError } = await this.supabaseService
          .getClient()
          .from(table)
          .select("*", { count: "exact", head: true });

        if (!countError && count !== null) {
          nextNum = count + 1;
        }
      }

      console.log(
        `📡 Initializing missing sequence for module: ${module} starting at ${nextNum}`,
      );
      const { data, error: initError } = await this.supabaseService
        .getClient()
        .from("transactional_sequences")
        .insert([
          {
            module,
            prefix: config.prefix,
            next_number: nextNum,
            padding: config.padding,
            outlet_id: null,
            is_active: true,
          },
        ])
        .select()
        .single();

      if (initError) {
        console.error(
          `❌ Failed to initialize sequence for ${module}:`,
          initError,
        );
        throw new NotFoundException(
          `Sequence for module ${module} not found and could not be initialized`,
        );
      }
      return data;
    }

    return globalData[0];
  }

  async getNextNumberFormatted(module: string, outletId?: string) {
    const settings = await this.getSequence(module, outletId);
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
    usedNumber?: string,
    outletId?: string,
  ) {
    const settings = await this.getSequence(module, outletId);

    // If usedNumber is provided, only increment if it matches the CURRENT formatted sequence.
    // This prevents manual entries from "stealing" or breaking the sequence.
    if (usedNumber) {
      const currentFormatted = this.formatSequence(
        settings.prefix,
        settings.next_number,
        settings.padding,
        settings.suffix,
      );
      if (usedNumber !== currentFormatted) {
        console.log(
          `ℹ️ [${module}] Manual sequence usage detected (${usedNumber}). Skipping auto-increment of ${currentFormatted}.`,
        );
        return settings; // No change
      }
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("transactional_sequences")
      .update({ next_number: settings.next_number + 1, updated_at: new Date() })
      .eq("id", settings.id)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to increment sequence for ${module}`);
    }

    return data;
  }

  async checkDuplicate(module: string, number: string) {
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
      .maybeSingle();

    if (error) throw error;
    return { exists: !!data };
  }

  async updateSettings(
    module: string,
    updateDto: {
      prefix?: string;
      nextNumber?: number;
      padding?: number;
      suffix?: string;
      outletId?: string;
    },
  ) {
    const updateData: any = { updated_at: new Date() };
    if (updateDto.prefix !== undefined) updateData.prefix = updateDto.prefix;
    if (updateDto.nextNumber !== undefined)
      updateData.next_number = updateDto.nextNumber;
    if (updateDto.padding !== undefined) updateData.padding = updateDto.padding;
    if (updateDto.suffix !== undefined) updateData.suffix = updateDto.suffix;

    // Find existing to update or insert new outlet-specific
    let query = this.supabaseService
      .getClient()
      .from("transactional_sequences")
      .select("id, outlet_id")
      .eq("module", module);

    if (updateDto.outletId) {
      query = query.eq("outlet_id", updateDto.outletId);
    } else {
      query = query.is("outlet_id", null);
    }

    const { data: existing } = await query.maybeSingle();

    if (existing) {
      const { data, error } = await this.supabaseService
        .getClient()
        .from("transactional_sequences")
        .update(updateData)
        .eq("id", existing.id)
        .select()
        .single();
      if (error) throw error;
      return data;
    } else {
      // Insert new outlet-specific record
      const insertData = {
        module,
        ...updateData,
        outlet_id: updateDto.outletId || null,
        padding: updateDto.padding ?? 6,
      };
      const { data, error } = await this.supabaseService
        .getClient()
        .from("transactional_sequences")
        .insert(insertData)
        .select()
        .single();
      if (error) throw error;
      return data;
    }
  }
}
