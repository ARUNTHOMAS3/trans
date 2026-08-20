import { BadRequestException, Injectable, NotFoundException } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { db, client } from "../../db/db";
import { defaultPaymentTerms, currency } from "../../db/schema";
import { eq } from "drizzle-orm";

@Injectable()
export class SettingsSetupService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getPaymentTerms(tenant: TenantContext) {
    try {
      const [terms, defaultTerms] = await Promise.all([
        client.unsafe(
          `SELECT id, term_name, number_of_days, description, is_active, created_at FROM payment_terms ORDER BY term_name ASC`,
        ),
        tenant.entityId
          ? db
              .select({ paymentTermsId: defaultPaymentTerms.paymentTermsId })
              .from(defaultPaymentTerms)
              .where(eq(defaultPaymentTerms.entityId, tenant.entityId))
              .limit(1)
          : Promise.resolve([]),
      ]);

      const defaultId = defaultTerms[0]?.paymentTermsId ?? null;
      return (terms ?? []).map((term: any) => ({
        ...term,
        is_default: term.id === defaultId,
      }));
    } catch (error) {
      throw error;
    }
  }

  async createPaymentTerm(body: any, tenant: TenantContext) {
    const payload = this.paymentTermPayload(body);
    try {
      const rows = await client.unsafe(
        `INSERT INTO payment_terms (term_name, number_of_days, description, is_active)
         VALUES ($1, $2, $3, $4)
         RETURNING id, term_name, number_of_days, description, is_active, created_at`,
        [
          payload.term_name,
          payload.number_of_days ?? 0,
          payload.description ?? null,
          payload.is_active ?? true,
        ],
      );

      const data = rows[0];
      if (body?.is_default === true && data?.id) {
        await this.setDefaultPaymentTerm(data.id, tenant);
      }

      return data;
    } catch (error) {
      throw error;
    }
  }

  async updatePaymentTerm(id: string, body: any) {
    const payload = this.paymentTermPayload(body, false);
    try {
      const rows = await client.unsafe(
        `UPDATE payment_terms SET
           term_name = COALESCE($1, term_name),
           number_of_days = COALESCE($2, number_of_days),
           description = COALESCE($3, description),
           is_active = COALESCE($4, is_active)
         WHERE id = $5
         RETURNING id, term_name, number_of_days, description, is_active, created_at`,
        [
          payload.term_name ?? null,
          payload.number_of_days ?? null,
          payload.description ?? null,
          payload.is_active ?? null,
          id,
        ],
      );

      const data = rows[0];
      if (!data) throw new NotFoundException("Payment term not found");
      return data;
    } catch (error) {
      throw error;
    }
  }

  async deactivatePaymentTerm(id: string) {
    try {
      const rows = await client.unsafe(
        `UPDATE payment_terms SET is_active = false WHERE id = $1 RETURNING id, term_name, number_of_days, description, is_active, created_at`,
        [id],
      );

      const data = rows[0];
      if (!data) throw new NotFoundException("Payment term not found");
      return data;
    } catch (error) {
      throw error;
    }
  }

  async setDefaultPaymentTerm(id: string, tenant: TenantContext) {
    if (!tenant.entityId) throw new BadRequestException("Entity context required");

    try {
      const terms = await client.unsafe(
        `SELECT id FROM payment_terms WHERE id = $1 LIMIT 1`,
        [id],
      );
      if (!terms[0]) throw new NotFoundException("Payment term not found");

      const [data] = await db
        .insert(defaultPaymentTerms)
        .values({
          entityId: tenant.entityId,
          paymentTermsId: id,
        })
        .onConflictDoUpdate({
          target: defaultPaymentTerms.entityId,
          set: {
            paymentTermsId: id,
          },
        })
        .returning();

      return {
        id: data.id,
        entity_id: data.entityId,
        payment_terms_id: data.paymentTermsId,
      };
    } catch (error) {
      throw error;
    }
  }

  async getCurrencies() {
    try {
      const rows = await db
        .select({
          id: currency.id,
          code: currency.code,
          name: currency.name,
          symbol: currency.symbol,
          decimals: currency.decimals,
          format: currency.format,
          is_active: currency.isActive,
          created_at: currency.createdAt,
        })
        .from(currency)
        .where(eq(currency.isActive, true));

      return rows ?? [];
    } catch (error) {
      throw error;
    }
  }

  async createCurrency(body: any) {
    const payload = this.currencyPayload(body);
    try {
      const [data] = await db
        .insert(currency)
        .values({
          code: payload.code as string,
          name: payload.name as string,
          symbol: payload.symbol as string ?? "",
          decimals: payload.decimals as number ?? 2,
          format: payload.format as string ?? null,
          isActive: payload.is_active as boolean ?? true,
        })
        .returning();

      return {
        id: data.id,
        code: data.code,
        name: data.name,
        symbol: data.symbol,
        decimals: data.decimals,
        format: data.format,
        is_active: data.isActive,
        created_at: data.createdAt,
      };
    } catch (error) {
      throw error;
    }
  }

  async updateCurrency(id: string, body: any) {
    const payload = this.currencyPayload(body, false);
    try {
      const updateData: Record<string, any> = {};
      if (payload.code !== undefined) updateData.code = payload.code;
      if (payload.name !== undefined) updateData.name = payload.name;
      if (payload.symbol !== undefined) updateData.symbol = payload.symbol;
      if (payload.decimals !== undefined) updateData.decimals = payload.decimals;
      if (payload.format !== undefined) updateData.format = payload.format;
      if (payload.is_active !== undefined) updateData.isActive = payload.is_active;

      const [data] = await db
        .update(currency)
        .set(updateData)
        .where(eq(currency.id, id))
        .returning();

      if (!data) throw new NotFoundException("Currency not found");
      return {
        id: data.id,
        code: data.code,
        name: data.name,
        symbol: data.symbol,
        decimals: data.decimals,
        format: data.format,
        is_active: data.isActive,
        created_at: data.createdAt,
      };
    } catch (error) {
      throw error;
    }
  }

  async getDateFormats() {
    try {
      const data = await client.unsafe(
        `SELECT id, code, format_pattern, group_name, label, sort_order FROM date_format WHERE is_active = true ORDER BY sort_order ASC`,
      );
      return data ?? [];
    } catch (error) {
      throw error;
    }
  }

  async getDateSeparators() {
    try {
      const data = await client.unsafe(
        `SELECT id, code, separator, label, sort_order FROM date_separator WHERE is_active = true ORDER BY sort_order ASC`,
      );
      return data ?? [];
    } catch (error) {
      throw error;
    }
  }

  async getFiscalYears(tenant: TenantContext) {
    if (!tenant.entityId) return [];
    try {
      const data = await client.unsafe(
        `SELECT id, name, start_date, end_date, is_active, entity_id FROM fiscal_years WHERE entity_id = $1 ORDER BY start_date DESC`,
        [tenant.entityId],
      );
      return data ?? [];
    } catch (error) {
      throw error;
    }
  }

  private paymentTermPayload(body: any, requireName = true): Record<string, any> {
    const name = body?.term_name ?? body?.name;
    if (requireName && (!name || String(name).trim().length === 0)) {
      throw new BadRequestException("Payment term name is required");
    }

    const payload: Record<string, any> = {};
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
