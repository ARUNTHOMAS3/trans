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

    if (!error && data) {
      const tableMapping: Record<
        string,
        { table: string; column: string; prefix: string }
      > = {
        vendor: { table: "vendors", column: "vendor_number", prefix: "VEN-" },
        customer: {
          table: "customers",
          column: "customer_number",
          prefix: "CUS-",
        },
        sale: { table: "sales_orders", column: "sale_number", prefix: "SO-" },
        purchase: {
          table: "purchase_orders",
          column: "order_number",
          prefix: "PO-",
        },
        inventory_packages: {
          table: "inventory_packages",
          column: "package_number",
          prefix: "PKG-",
        },
      };

      if (tableMapping[module]) {
        const { table, column } = tableMapping[module];
        const prefix = data.prefix;
        const { data: latestItems, error: fetchError } = await client
          .from(table)
          .select(column)
          .ilike(column, `${prefix}%`)
          .eq("entity_id", tenant.entityId)
          .order(column, { ascending: false })
          .limit(10);

        if (!fetchError && latestItems && latestItems.length > 0) {
          let maxNum = 0;
          for (const item of latestItems) {
            const val = item[column] as string;
            if (val && val.toLowerCase().startsWith(prefix.toLowerCase())) {
              let numPart = val.substring(prefix.length);
              if (data.suffix) {
                numPart = numPart.replace(new RegExp(data.suffix, "i"), "");
              }
              const parsed = parseInt(numPart, 10);
              if (!isNaN(parsed) && parsed > maxNum) {
                maxNum = parsed;
              }
            }
          }
          if (maxNum >= data.next_number) {
            data.next_number = maxNum + 1;
            await client
              .from("transactional_sequences")
              .update({ next_number: data.next_number, updated_at: new Date() })
              .eq("id", data.id);
          }
        } else {
          const { count, error: countError } = await client
            .from(table)
            .select("*", { count: "exact", head: true })
            .eq("entity_id", tenant.entityId);

          if (!countError && count === 0 && data.next_number !== 1) {
            data.next_number = 1;
            await client
              .from("transactional_sequences")
              .update({ next_number: 1, updated_at: new Date() })
              .eq("id", data.id);
          }
        }
      }
      return data;
    }

    // Auto-initialize if sequence is missing for this entity
    const defaults: Record<
      string,
      { prefix: string; next_number: number; padding: number }
    > = {
      vendor: { prefix: "VEN-", next_number: 1, padding: 5 },
      customer: { prefix: "CUS-", next_number: 1, padding: 5 },
      sale: { prefix: "SO-", next_number: 1, padding: 5 },
      purchase: { prefix: "PO-", next_number: 1, padding: 5 },
      inventory_packages: { prefix: "PKG-", next_number: 1, padding: 5 },
    };

    const config = defaults[module] ?? {
      prefix: `${module.toUpperCase()}-`,
      next_number: 1,
      padding: 5,
    };

    let nextNum = config.next_number;
    const tableMapping: Record<
      string,
      { table: string; column: string; prefix: string }
    > = {
      vendor: { table: "vendors", column: "vendor_number", prefix: "VEN-" },
      customer: {
        table: "customers",
        column: "customer_number",
        prefix: "CUS-",
      },
      sale: { table: "sales_orders", column: "sale_number", prefix: "SO-" },
      purchase: {
        table: "purchase_orders",
        column: "order_number",
        prefix: "PO-",
      },
      inventory_packages: {
        table: "inventory_packages",
        column: "package_number",
        prefix: "PKG-",
      },
    };

    if (tableMapping[module]) {
      const { table, column, prefix } = tableMapping[module];
      const { data: latestItems, error: fetchError } = await client
        .from(table)
        .select(column)
        .ilike(column, `${prefix}%`)
        .eq("entity_id", tenant.entityId)
        .order(column, { ascending: false })
        .limit(10); // Check a few to find the actual max numeric part

      if (!fetchError && latestItems && latestItems.length > 0) {
        let maxNum = 0;
        for (const item of latestItems) {
          const val = item[column] as string;
          const numPart = val.substring(prefix.length);
          const parsed = parseInt(numPart, 10);
          if (!isNaN(parsed) && parsed > maxNum) {
            maxNum = parsed;
          }
        }
        if (maxNum > 0) nextNum = maxNum + 1;
      } else if (!fetchError) {
        // Fallback to simple count if ilike fails or no items with prefix found
        const { count, error: countError } = await client
          .from(table)
          .select("*", { count: "exact", head: true })
          .eq("entity_id", tenant.entityId);
        if (!countError && count !== null && count > 0) nextNum = count + 1;
      }
    }

    const { data: created, error: initError } = await client
      .from("transactional_sequences")
      .insert([
        {
          module,
          prefix: config.prefix,
          next_number: nextNum,
          padding: config.padding,
          entity_id: tenant.entityId,
          is_active: true,
        },
      ])
      .select()
      .single();

    if (initError)
      throw new Error(`Failed to initialize sequence: ${initError.message}`);
    return created;
  }

  async getNextNumberFormatted(
    module: string,
    tenant: TenantContext,
    branchId?: string,
  ) {
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

    const currentFormatted = this.formatSequence(
      settings.prefix,
      settings.next_number,
      settings.padding,
      settings.suffix,
    );

    let nextNumber = settings.next_number;

    if (!usedNumber || usedNumber === currentFormatted) {
      // Used the suggested number or no number provided: increment by 1
      nextNumber = settings.next_number + 1;
    } else if (usedNumber.startsWith(settings.prefix)) {
      // Used a manual number with SAME prefix: check if we should jump ahead
      try {
        const numPart = usedNumber
          .substring(settings.prefix.length)
          .replace(settings.suffix || "", "");
        const parsed = parseInt(numPart, 10);
        if (!isNaN(parsed) && parsed >= settings.next_number) {
          nextNumber = parsed + 1;
        } else {
          // Manually entered an OLD number with same prefix: don't increment next_number
          return settings;
        }
      } catch (e) {
        nextNumber = settings.next_number + 1;
      }
    } else {
      // Used a manual number with DIFFERENT prefix: do not advance the sequence
      return settings;
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("transactional_sequences")
      .update({ next_number: nextNumber, updated_at: new Date() })
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
      isActive?: boolean;
      nextNumber?: number;
      padding?: number;
      suffix?: string;
      branchId?: string;
    },
  ) {
    const client = this.supabaseService.getClient();

    const updateData: any = { updated_at: new Date() };
    if (updateDto.isActive !== undefined) updateData.is_active = updateDto.isActive;
    if (updateDto.prefix !== undefined) updateData.prefix = updateDto.prefix;
    if (updateDto.nextNumber !== undefined)
      updateData.next_number = updateDto.nextNumber;
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
        .insert({
          module,
          entity_id: tenant.entityId,
          is_active: true,
          ...updateData,
        })
        .select()
        .single();
      if (error) throw error;
      return data;
    }
  }
}
