import { BadRequestException, Injectable, NotFoundException } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Injectable()
export class SettingsSetupService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getPaymentTerms(tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const [{ data: terms, error: termsError }, { data: defaultTerm }] =
      await Promise.all([
        client
          .from("payment_terms")
          .select("id, term_name, number_of_days, description, is_active, created_at")
          .order("term_name", { ascending: true }),
        client
          .from("default_payment_terms")
          .select("payment_terms_id")
          .eq("entity_id", tenant.entityId)
          .maybeSingle(),
      ]);

    if (termsError) throw termsError;

    const defaultId = defaultTerm?.payment_terms_id ?? null;
    return (terms ?? []).map((term) => ({
      ...term,
      is_default: term.id === defaultId,
    }));
  }

  async createPaymentTerm(body: any, tenant: TenantContext) {
    const payload = this.paymentTermPayload(body);
    const { data, error } = await this.supabaseService
      .getClient()
      .from("payment_terms")
      .insert(payload)
      .select("id, term_name, number_of_days, description, is_active, created_at")
      .single();

    if (error) throw error;

    if (body?.is_default === true) {
      await this.setDefaultPaymentTerm(data.id, tenant);
    }

    return data;
  }

  async updatePaymentTerm(id: string, body: any) {
    const payload = this.paymentTermPayload(body, false);
    const { data, error } = await this.supabaseService
      .getClient()
      .from("payment_terms")
      .update(payload)
      .eq("id", id)
      .select("id, term_name, number_of_days, description, is_active, created_at")
      .maybeSingle();

    if (error) throw error;
    if (!data) throw new NotFoundException("Payment term not found");
    return data;
  }

  async deactivatePaymentTerm(id: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("payment_terms")
      .update({ is_active: false })
      .eq("id", id)
      .select("id, term_name, number_of_days, description, is_active, created_at")
      .maybeSingle();

    if (error) throw error;
    if (!data) throw new NotFoundException("Payment term not found");
    return data;
  }

  async setDefaultPaymentTerm(id: string, tenant: TenantContext) {
    const { data: term, error: termError } = await this.supabaseService
      .getClient()
      .from("payment_terms")
      .select("id")
      .eq("id", id)
      .maybeSingle();

    if (termError) throw termError;
    if (!term) throw new NotFoundException("Payment term not found");

    const { data, error } = await this.supabaseService
      .getClient()
      .from("default_payment_terms")
      .upsert(
        { entity_id: tenant.entityId, payment_terms_id: id },
        { onConflict: "entity_id" },
      )
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getCurrencies() {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("currencies")
      .select("id, code, name, symbol, decimals, format, is_active, created_at")
      .order("code", { ascending: true });

    if (error) throw error;
    return data ?? [];
  }

  async createCurrency(body: any) {
    const payload = this.currencyPayload(body);
    const { data, error } = await this.supabaseService
      .getClient()
      .from("currencies")
      .insert(payload)
      .select("id, code, name, symbol, decimals, format, is_active, created_at")
      .single();

    if (error) throw error;
    return data;
  }

  async updateCurrency(id: string, body: any) {
    const payload = this.currencyPayload(body, false);
    const { data, error } = await this.supabaseService
      .getClient()
      .from("currencies")
      .update(payload)
      .eq("id", id)
      .select("id, code, name, symbol, decimals, format, is_active, created_at")
      .maybeSingle();

    if (error) throw error;
    if (!data) throw new NotFoundException("Currency not found");
    return data;
  }

  async getDateFormats() {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("date_format")
      .select("id, code, format_pattern, group_name, label, sort_order")
      .eq("is_active", true)
      .order("sort_order", { ascending: true });

    if (error) throw error;
    return data ?? [];
  }

  async getDateSeparators() {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("date_separator")
      .select("id, code, separator, label, sort_order")
      .eq("is_active", true)
      .order("sort_order", { ascending: true });

    if (error) throw error;
    return data ?? [];
  }

  async getFiscalYears(tenant: TenantContext) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("fiscal_years")
      .select("id, name, start_date, end_date, is_active, entity_id")
      .eq("entity_id", tenant.entityId)
      .order("start_date", { ascending: false });

    if (error) throw error;
    return data ?? [];
  }

  private paymentTermPayload(body: any, requireName = true) {
    const name = body?.term_name ?? body?.name;
    if (requireName && (!name || String(name).trim().length === 0)) {
      throw new BadRequestException("Payment term name is required");
    }

    const payload: Record<string, unknown> = {};
    if (name !== undefined) payload.term_name = String(name).trim();
    if (body?.number_of_days !== undefined || body?.days !== undefined) {
      const days = Number(body.number_of_days ?? body.days);
      payload.number_of_days = Number.isFinite(days) ? days : 0;
    }
    if (body?.description !== undefined) {
      payload.description = body.description;
    }
    if (body?.is_active !== undefined) {
      payload.is_active = Boolean(body.is_active);
    }
    return payload;
  }

  private currencyPayload(body: any, requireCore = true) {
    const code = body?.code;
    const name = body?.name;
    if (requireCore && (!code || !name)) {
      throw new BadRequestException("Currency code and name are required");
    }

    const payload: Record<string, unknown> = {};
    if (code !== undefined) payload.code = String(code).trim().toUpperCase();
    if (name !== undefined) payload.name = String(name).trim();
    if (body?.symbol !== undefined) payload.symbol = String(body.symbol).trim();
    if (body?.decimals !== undefined) {
      const decimals = Number(body.decimals);
      payload.decimals = Number.isFinite(decimals) ? decimals : 2;
    }
    if (body?.format !== undefined) payload.format = body.format;
    if (body?.is_active !== undefined) payload.is_active = Boolean(body.is_active);
    return payload;
  }
}
