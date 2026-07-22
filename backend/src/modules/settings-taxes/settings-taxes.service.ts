import { BadRequestException, Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";

type SimpleOptions = {
  nameKey: string;
  description?: boolean;
};

@Injectable()
export class SettingsTaxesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private get client() {
    return this.supabaseService.getClient();
  }

  private statusFilter(query: any, status?: string) {
    if (status === "active") return query.eq("is_active", true);
    if (status === "inactive") return query.eq("is_active", false);
    return query;
  }

  private requiredString(body: any, key: string) {
    const value = body?.[key]?.toString().trim();
    if (!value) throw new BadRequestException(`${key} is required`);
    return value;
  }

  private optionalNumber(value: any) {
    if (value === undefined || value === null || value === "") return null;
    const numberValue = Number(value);
    if (Number.isNaN(numberValue)) {
      throw new BadRequestException("Numeric value is invalid");
    }
    return numberValue;
  }

  private async replaceMappings(
    table: string,
    parentKey: string,
    childKey: string,
    parentId: string,
    childIds?: string[],
  ) {
    if (!Array.isArray(childIds)) return;

    const { error: deleteError } = await this.client
      .from(table)
      .delete()
      .eq(parentKey, parentId);
    if (deleteError) throw deleteError;

    const rows = childIds
      .map((id) => id?.toString().trim())
      .filter(Boolean)
      .map((id) => ({ [parentKey]: parentId, [childKey]: id }));

    if (!rows.length) return;

    const { error } = await this.client.from(table).insert(rows);
    if (error) throw error;
  }

  async summary() {
    const [
      taxRates,
      taxGroups,
      tdsSections,
      tdsRates,
      tdsGroups,
      tcsNatures,
      tcsRates,
      tcsReasons,
    ] = await Promise.all([
      this.countActive("tax_rates"),
      this.countActive("tax_groups"),
      this.countActive("tds_sections"),
      this.countActive("tds_rates"),
      this.countActive("tds_groups"),
      this.countActive("tcs_natures"),
      this.countActive("tcs_rates"),
      this.countActive("tcs_higher_rate_reasons"),
    ]);

    return {
      tax_rates: taxRates,
      tax_groups: taxGroups,
      tds_sections: tdsSections,
      tds_rates: tdsRates,
      tds_groups: tdsGroups,
      tcs_natures: tcsNatures,
      tcs_rates: tcsRates,
      tcs_higher_rate_reasons: tcsReasons,
    };
  }

  private async countActive(table: string) {
    const { count, error } = await this.client
      .from(table)
      .select("id", { count: "exact", head: true })
      .eq("is_active", true);
    if (error) throw error;
    return count ?? 0;
  }

  async findSimple(table: string, status?: string, orderBy = "created_at") {
    const query = this.statusFilter(
      this.client.from(table).select("*"),
      status,
    ).order(orderBy, { ascending: true });
    const { data, error } = await query;
    if (error) throw error;
    return data ?? [];
  }

  async createSimple(table: string, body: any, options: SimpleOptions) {
    const payload: any = {
      [options.nameKey]: this.requiredString(body, options.nameKey),
      is_active: body?.is_active ?? true,
    };
    if (options.description) payload.description = body?.description ?? null;

    const { data, error } = await this.client
      .from(table)
      .insert(payload)
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async updateSimple(
    table: string,
    id: string,
    body: any,
    options: SimpleOptions,
  ) {
    const payload: any = {};
    if (body?.[options.nameKey] !== undefined) {
      payload[options.nameKey] = this.requiredString(body, options.nameKey);
    }
    if (options.description && body?.description !== undefined) {
      payload.description = body.description ?? null;
    }
    if (body?.is_active !== undefined) payload.is_active = body.is_active;

    const { data, error } = await this.client
      .from(table)
      .update(payload)
      .eq("id", id)
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async deleteById(table: string, id: string, label: string) {
    const { error } = await this.client.from(table).delete().eq("id", id);
    if (error) throw new Error(`Failed to delete ${label}: ${error.message}`);
    return { success: true };
  }

  async findTaxRates(status?: string) {
    return this.findSimple("tax_rates", status, "tax_name");
  }

  async createTaxRate(body: any) {
    const payload = {
      tax_name: this.requiredString(body, "tax_name"),
      tax_rate: this.optionalNumber(body?.tax_rate),
      tax_type: body?.tax_type ?? null,
      is_active: body?.is_active ?? true,
    };
    if (payload.tax_rate === null) {
      throw new BadRequestException("tax_rate is required");
    }

    const { data, error } = await this.client
      .from("tax_rates")
      .insert(payload)
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async updateTaxRate(id: string, body: any) {
    const payload: any = {};
    if (body?.tax_name !== undefined) {
      payload.tax_name = this.requiredString(body, "tax_name");
    }
    if (body?.tax_rate !== undefined) {
      payload.tax_rate = this.optionalNumber(body.tax_rate);
    }
    if (body?.tax_type !== undefined) payload.tax_type = body.tax_type;
    if (body?.is_active !== undefined) payload.is_active = body.is_active;

    const { data, error } = await this.client
      .from("tax_rates")
      .update(payload)
      .eq("id", id)
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async findTaxGroups(status?: string) {
    const { data, error } = await this.statusFilter(
      this.client.from("tax_groups").select("*"),
      status,
    ).order("tax_group_name", { ascending: true });
    if (error) throw error;

    return Promise.all((data ?? []).map((group) => this.withTaxGroupRates(group)));
  }

  async createTaxGroup(body: any) {
    const payload = {
      tax_group_name: this.requiredString(body, "tax_group_name"),
      tax_rate: this.optionalNumber(body?.tax_rate) ?? 0,
      is_active: body?.is_active ?? true,
    };

    const { data, error } = await this.client
      .from("tax_groups")
      .insert(payload)
      .select()
      .single();
    if (error) throw error;

    await this.replaceMappings(
      "tax_group_rates",
      "tax_group_id",
      "tax_id",
      data.id,
      body?.tax_ids,
    );
    return this.withTaxGroupRates(data);
  }

  async updateTaxGroup(id: string, body: any) {
    const payload: any = {};
    if (body?.tax_group_name !== undefined) {
      payload.tax_group_name = this.requiredString(body, "tax_group_name");
    }
    if (body?.tax_rate !== undefined) {
      payload.tax_rate = this.optionalNumber(body.tax_rate);
    }
    if (body?.is_active !== undefined) payload.is_active = body.is_active;

    const { data, error } = await this.client
      .from("tax_groups")
      .update(payload)
      .eq("id", id)
      .select()
      .single();
    if (error) throw error;

    await this.replaceMappings(
      "tax_group_rates",
      "tax_group_id",
      "tax_id",
      id,
      body?.tax_ids,
    );
    return this.withTaxGroupRates(data);
  }

  async deleteTaxGroup(id: string) {
    await this.replaceMappings("tax_group_rates", "tax_group_id", "tax_id", id, []);
    return this.deleteById("tax_groups", id, "tax group");
  }

  private async withTaxGroupRates(group: any) {
    const { data, error } = await this.client
      .from("tax_group_rates")
      .select("tax_id,tax_rates(*)")
      .eq("tax_group_id", group.id);
    if (error) throw error;
    return {
      ...group,
      tax_ids: (data ?? []).map((row: any) => row.tax_id),
      taxes: (data ?? []).map((row: any) => row.tax_rates).filter(Boolean),
    };
  }

  async createTdsRate(body: any) {
    const payload = this.tdsRatePayload(body, true);
    const { data, error } = await this.client
      .from("tds_rates")
      .insert(payload)
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async updateTdsRate(id: string, body: any) {
    const payload = this.tdsRatePayload(body, false);
    const { data, error } = await this.client
      .from("tds_rates")
      .update(payload)
      .eq("id", id)
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  private tdsRatePayload(body: any, creating: boolean) {
    const payload: any = {};
    if (creating || body?.tax_name !== undefined) {
      payload.tax_name = this.requiredString(body, "tax_name");
    }
    for (const key of [
      "section_id",
      "payable_account_id",
      "receivable_account_id",
      "reason_higher_rate",
      "applicable_from",
      "applicable_to",
    ]) {
      if (body?.[key] !== undefined) payload[key] = body[key] || null;
    }
    for (const key of ["base_rate", "surcharge_rate", "cess_rate"]) {
      if (creating || body?.[key] !== undefined) {
        payload[key] = this.optionalNumber(body?.[key]) ?? 0;
      }
    }
    if (body?.is_higher_rate !== undefined) {
      payload.is_higher_rate = body.is_higher_rate;
    }
    if (body?.is_active !== undefined) payload.is_active = body.is_active;
    return payload;
  }

  async findTdsGroups(status?: string) {
    const { data, error } = await this.statusFilter(
      this.client.from("tds_groups").select("*"),
      status,
    ).order("group_name", { ascending: true });
    if (error) throw error;
    return Promise.all((data ?? []).map((group) => this.withTdsGroupRates(group)));
  }

  async createTdsGroup(body: any) {
    const payload = {
      group_name: this.requiredString(body, "group_name"),
      applicable_from: body?.applicable_from ?? null,
      applicable_to: body?.applicable_to ?? null,
      is_active: body?.is_active ?? true,
    };
    const { data, error } = await this.client
      .from("tds_groups")
      .insert(payload)
      .select()
      .single();
    if (error) throw error;
    await this.replaceMappings(
      "tds_group_items",
      "tds_group_id",
      "tds_rate_id",
      data.id,
      body?.tds_rate_ids,
    );
    return this.withTdsGroupRates(data);
  }

  async updateTdsGroup(id: string, body: any) {
    const payload: any = {};
    for (const key of ["group_name", "applicable_from", "applicable_to"]) {
      if (body?.[key] !== undefined) payload[key] = body[key] || null;
    }
    if (body?.group_name !== undefined) {
      payload.group_name = this.requiredString(body, "group_name");
    }
    if (body?.is_active !== undefined) payload.is_active = body.is_active;

    const { data, error } = await this.client
      .from("tds_groups")
      .update(payload)
      .eq("id", id)
      .select()
      .single();
    if (error) throw error;

    await this.replaceMappings(
      "tds_group_items",
      "tds_group_id",
      "tds_rate_id",
      id,
      body?.tds_rate_ids,
    );
    return this.withTdsGroupRates(data);
  }

  async deleteTdsGroup(id: string) {
    await this.replaceMappings(
      "tds_group_items",
      "tds_group_id",
      "tds_rate_id",
      id,
      [],
    );
    return this.deleteById("tds_groups", id, "TDS group");
  }

  private async withTdsGroupRates(group: any) {
    const { data, error } = await this.client
      .from("tds_group_items")
      .select("tds_rate_id,tds_rates(*)")
      .eq("tds_group_id", group.id);
    if (error) throw error;
    return {
      ...group,
      tds_rate_ids: (data ?? []).map((row: any) => row.tds_rate_id),
      rates: (data ?? []).map((row: any) => row.tds_rates).filter(Boolean),
    };
  }

  async createTcsRate(body: any) {
    const payload = this.tcsRatePayload(body, true);
    const { data, error } = await this.client
      .from("tcs_rates")
      .insert(payload)
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async updateTcsRate(id: string, body: any) {
    const payload = this.tcsRatePayload(body, false);
    const { data, error } = await this.client
      .from("tcs_rates")
      .update(payload)
      .eq("id", id)
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  private tcsRatePayload(body: any, creating: boolean) {
    const payload: any = {};
    if (creating || body?.tax_name !== undefined) {
      payload.tax_name = this.requiredString(body, "tax_name");
    }
    if (creating || body?.nature_id !== undefined) {
      payload.nature_id = this.requiredString(body, "nature_id");
    }
    if (creating || body?.rate !== undefined) {
      payload.rate = this.optionalNumber(body?.rate);
    }
    for (const key of [
      "payable_account_id",
      "receivable_account_id",
      "higher_rate_reason_id",
      "income_tax_act",
      "applicable_from",
      "applicable_to",
    ]) {
      if (body?.[key] !== undefined) payload[key] = body[key] || null;
    }
    if (body?.is_higher_rate !== undefined) {
      payload.is_higher_rate = body.is_higher_rate;
    }
    if (body?.is_active !== undefined) payload.is_active = body.is_active;
    return payload;
  }
}
