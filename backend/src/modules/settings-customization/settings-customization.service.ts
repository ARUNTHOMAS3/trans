import { BadRequestException, Injectable, NotFoundException } from "@nestjs/common";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { SupabaseService } from "../supabase/supabase.service";
import { client } from "../../db/db";

@Injectable()
export class SettingsCustomizationService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getReportingTags(tenant: TenantContext) {
    if (!tenant.entityId) return [];
    try {
      const data = await client.unsafe(
        `SELECT id, tag_name, is_active, entity_id FROM reporting_tags WHERE entity_id = $1 ORDER BY tag_name ASC`,
        [tenant.entityId],
      );
      return data ?? [];
    } catch (error) {
      throw error;
    }
  }

  async createReportingTag(body: any, tenant: TenantContext) {
    const tagName = body?.tag_name ?? body?.name;
    if (!tagName || String(tagName).trim().length === 0) {
      throw new BadRequestException("Reporting tag name is required");
    }

    try {
      const rows = await client.unsafe(
        `INSERT INTO reporting_tags (tag_name, is_active, entity_id) VALUES ($1, $2, $3) RETURNING id, tag_name, is_active, entity_id`,
        [String(tagName).trim(), body?.is_active !== false, tenant.entityId],
      );
      return rows[0];
    } catch (error) {
      throw error;
    }
  }

  async updateReportingTag(id: string, body: any) {
    const tagName = body?.tag_name ?? body?.name;
    let nameVal = null;
    if (tagName !== undefined) {
      if (!tagName || String(tagName).trim().length === 0) {
        throw new BadRequestException("Reporting tag name is required");
      }
      nameVal = String(tagName).trim();
    }
    const isActiveVal = body?.is_active !== undefined ? Boolean(body.is_active) : null;

    try {
      const rows = await client.unsafe(
        `UPDATE reporting_tags SET
           tag_name = COALESCE($1, tag_name),
           is_active = COALESCE($2, is_active)
         WHERE id = $3
         RETURNING id, tag_name, is_active, entity_id`,
        [nameVal, isActiveVal, id],
      );

      const data = rows[0];
      if (!data) throw new NotFoundException("Reporting tag not found");
      return data;
    } catch (error) {
      throw error;
    }
  }
}
