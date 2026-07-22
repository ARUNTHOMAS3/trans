import { BadRequestException, Injectable, NotFoundException } from "@nestjs/common";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { SupabaseService } from "../supabase/supabase.service";

@Injectable()
export class SettingsCustomizationService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getReportingTags(tenant: TenantContext) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("reporting_tags")
      .select("id, tag_name, is_active, entity_id")
      .eq("entity_id", tenant.entityId)
      .order("tag_name", { ascending: true });

    if (error) throw error;
    return data ?? [];
  }

  async createReportingTag(body: any, tenant: TenantContext) {
    const tagName = body?.tag_name ?? body?.name;
    if (!tagName || String(tagName).trim().length === 0) {
      throw new BadRequestException("Reporting tag name is required");
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("reporting_tags")
      .insert({
        tag_name: String(tagName).trim(),
        is_active: body?.is_active !== false,
        entity_id: tenant.entityId,
      })
      .select("id, tag_name, is_active, entity_id")
      .single();

    if (error) throw error;
    return data;
  }

  async updateReportingTag(id: string, body: any) {
    const payload: Record<string, unknown> = {};
    if (body?.tag_name !== undefined || body?.name !== undefined) {
      const tagName = body.tag_name ?? body.name;
      if (!tagName || String(tagName).trim().length === 0) {
        throw new BadRequestException("Reporting tag name is required");
      }
      payload.tag_name = String(tagName).trim();
    }
    if (body?.is_active !== undefined) {
      payload.is_active = Boolean(body.is_active);
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("reporting_tags")
      .update(payload)
      .eq("id", id)
      .select("id, tag_name, is_active, entity_id")
      .maybeSingle();

    if (error) throw error;
    if (!data) throw new NotFoundException("Reporting tag not found");
    return data;
  }
}
