import { BadRequestException, Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { client } from "../../db/db";

type SimpleOptions = {
  nameKey: string;
  description?: boolean;
};

@Injectable()
export class SettingsTaxesService {
  constructor(private readonly supabaseService: SupabaseService) {}

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

    const sanitizedTable = table.replace(/[^a-zA-Z0-9_]/g, "");
    const sanitizedParentKey = parentKey.replace(/[^a-zA-Z0-9_]/g, "");
    const sanitizedChildKey = childKey.replace(/[^a-zA-Z0-9_]/g, "");

    await client.unsafe(
      `DELETE FROM "${sanitizedTable}" WHERE "${sanitizedParentKey}" = $1`,
      [parentId],
    );

    const validChildIds = childIds
      .map((id) => id?.toString().trim())
      .filter((id): id is string => Boolean(id));

    if (validChildIds.length === 0) return;

    for (const childId of validChildIds) {
      await client.unsafe(
        `INSERT INTO "${sanitizedTable}" ("${sanitizedParentKey}", "${sanitizedChildKey}") VALUES ($1, $2)`,
        [parentId, childId],
      );
    }
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
    const sanitizedTable = table.replace(/[^a-zA-Z0-9_]/g, "");
    try {
      const rows = await client.unsafe(
        `SELECT COUNT(*)::int as count FROM "${sanitizedTable}" WHERE is_active = true`,
      );
      return rows[0]?.count ?? 0;
    } catch {
      return 0;
    }
  }

  async findSimple(table: string, status?: string, orderBy = "created_at") {
    const sanitizedTable = table.replace(/[^a-zA-Z0-9_]/g, "");
    const sanitizedOrderBy = orderBy.replace(/[^a-zA-Z0-9_]/g, "");

    let sqlQuery = `SELECT * FROM "${sanitizedTable}" WHERE 1=1`;
    if (status === "active") sqlQuery += ` AND is_active = true`;
    if (status === "inactive") sqlQuery += ` AND is_active = false`;
    sqlQuery += ` ORDER BY "${sanitizedOrderBy}" ASC`;

    try {
      const data = await client.unsafe(sqlQuery);
      return data ?? [];
    } catch {
      return [];
    }
  }

  async createSimple(table: string, body: any, options: SimpleOptions) {
    const sanitizedTable = table.replace(/[^a-zA-Z0-9_]/g, "");
    const nameVal = this.requiredString(body, options.nameKey);
    const descVal = options.description ? (body?.description ?? null) : null;
    const isActive = body?.is_active ?? true;

    try {
      const rows = await client.unsafe(
        `INSERT INTO "${sanitizedTable}" ("${options.nameKey}", description, is_active) VALUES ($1, $2, $3) RETURNING *`,
        [nameVal, descVal, isActive],
      );
      return rows[0];
    } catch (err) {
      throw err;
    }
  }

  async updateSimple(
    table: string,
    id: string,
    body: any,
    options: SimpleOptions,
  ) {
    const sanitizedTable = table.replace(/[^a-zA-Z0-9_]/g, "");
    const nameVal = body?.[options.nameKey] !== undefined ? this.requiredString(body, options.nameKey) : null;
    const descVal = options.description && body?.description !== undefined ? (body.description ?? null) : null;
    const isActive = body?.is_active !== undefined ? body.is_active : null;

    try {
      const rows = await client.unsafe(
        `UPDATE "${sanitizedTable}" SET
           "${options.nameKey}" = COALESCE($1, "${options.nameKey}"),
           description = COALESCE($2, description),
           is_active = COALESCE($3, is_active)
         WHERE id = $4 RETURNING *`,
        [nameVal, descVal, isActive, id],
      );
      return rows[0];
    } catch (err) {
      throw err;
    }
  }

  async deleteById(table: string, id: string, label: string) {
    const sanitizedTable = table.replace(/[^a-zA-Z0-9_]/g, "");
    try {
      await client.unsafe(`DELETE FROM "${sanitizedTable}" WHERE id = $1`, [id]);
      return { success: true };
    } catch (error) {
      throw new Error(`Failed to delete ${label}: ${(error as Error).message}`);
    }
  }

  async findTaxRates(status?: string) {
    return this.findSimple("tax_rates", status, "tax_name");
  }

  async createTaxRate(body: any) {
    const taxName = this.requiredString(body, "tax_name");
    const taxRate = this.optionalNumber(body?.tax_rate);
    const taxType = body?.tax_type ?? null;
    const isActive = body?.is_active ?? true;

    if (taxRate === null) {
      throw new BadRequestException("tax_rate is required");
    }

    const rows = await client.unsafe(
      `INSERT INTO tax_rates (tax_name, tax_rate, tax_type, is_active) VALUES ($1, $2, $3, $4) RETURNING *`,
      [taxName, taxRate, taxType, isActive],
    );
    return rows[0];
  }

  async updateTaxRate(id: string, body: any) {
    const taxName = body?.tax_name !== undefined ? this.requiredString(body, "tax_name") : null;
    const taxRate = body?.tax_rate !== undefined ? this.optionalNumber(body.tax_rate) : null;
    const taxType = body?.tax_type !== undefined ? body.tax_type : null;
    const isActive = body?.is_active !== undefined ? body.is_active : null;

    const rows = await client.unsafe(
      `UPDATE tax_rates SET
         tax_name = COALESCE($1, tax_name),
         tax_rate = COALESCE($2, tax_rate),
         tax_type = COALESCE($3, tax_type),
         is_active = COALESCE($4, is_active)
       WHERE id = $5 RETURNING *`,
      [taxName, taxRate, taxType, isActive, id],
    );
    return rows[0];
  }

  async findTaxGroups(status?: string) {
    let sqlQuery = `SELECT * FROM tax_groups WHERE 1=1`;
    if (status === "active") sqlQuery += ` AND is_active = true`;
    if (status === "inactive") sqlQuery += ` AND is_active = false`;
    sqlQuery += ` ORDER BY tax_group_name ASC`;

    const data = await client.unsafe(sqlQuery);
    return Promise.all((data ?? []).map((group: any) => this.withTaxGroupRates(group)));
  }

  async createTaxGroup(body: any) {
    const name = this.requiredString(body, "tax_group_name");
    const rate = this.optionalNumber(body?.tax_rate) ?? 0;
    const isActive = body?.is_active ?? true;

    const rows = await client.unsafe(
      `INSERT INTO tax_groups (tax_group_name, tax_rate, is_active) VALUES ($1, $2, $3) RETURNING *`,
      [name, rate, isActive],
    );
    const data = rows[0];

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
    const name = body?.tax_group_name !== undefined ? this.requiredString(body, "tax_group_name") : null;
    const rate = body?.tax_rate !== undefined ? this.optionalNumber(body.tax_rate) : null;
    const isActive = body?.is_active !== undefined ? body.is_active : null;

    const rows = await client.unsafe(
      `UPDATE tax_groups SET
         tax_group_name = COALESCE($1, tax_group_name),
         tax_rate = COALESCE($2, tax_rate),
         is_active = COALESCE($3, is_active)
       WHERE id = $4 RETURNING *`,
      [name, rate, isActive, id],
    );
    const data = rows[0];

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
    const data = await client.unsafe(
      `SELECT tgr.tax_id, tr.*
       FROM tax_group_rates tgr
       LEFT JOIN tax_rates tr ON tr.id = tgr.tax_id
       WHERE tgr.tax_group_id = $1`,
      [group.id],
    );

    return {
      ...group,
      tax_ids: (data ?? []).map((row: any) => row.tax_id),
      taxes: (data ?? []).map((row: any) => (row.id ? row : null)).filter(Boolean),
    };
  }

  async createTdsRate(body: any) {
    const payload = this.tdsRatePayload(body, true);
    const rows = await client.unsafe(
      `INSERT INTO tds_rates (tax_name, section_id, payable_account_id, receivable_account_id, reason_higher_rate, applicable_from, applicable_to, base_rate, surcharge_rate, cess_rate, is_higher_rate, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING *`,
      [
        payload.tax_name,
        payload.section_id ?? null,
        payload.payable_account_id ?? null,
        payload.receivable_account_id ?? null,
        payload.reason_higher_rate ?? null,
        payload.applicable_from ?? null,
        payload.applicable_to ?? null,
        payload.base_rate ?? 0,
        payload.surcharge_rate ?? 0,
        payload.cess_rate ?? 0,
        payload.is_higher_rate ?? false,
        payload.is_active ?? true,
      ],
    );
    return rows[0];
  }

  async updateTdsRate(id: string, body: any) {
    const payload = this.tdsRatePayload(body, false);
    const rows = await client.unsafe(
      `UPDATE tds_rates SET
         tax_name = COALESCE($1, tax_name),
         section_id = COALESCE($2, section_id),
         payable_account_id = COALESCE($3, payable_account_id),
         receivable_account_id = COALESCE($4, receivable_account_id),
         reason_higher_rate = COALESCE($5, reason_higher_rate),
         applicable_from = COALESCE($6, applicable_from),
         applicable_to = COALESCE($7, applicable_to),
         base_rate = COALESCE($8, base_rate),
         surcharge_rate = COALESCE($9, surcharge_rate),
         cess_rate = COALESCE($10, cess_rate),
         is_higher_rate = COALESCE($11, is_higher_rate),
         is_active = COALESCE($12, is_active)
       WHERE id = $13 RETURNING *`,
      [
        payload.tax_name ?? null,
        payload.section_id ?? null,
        payload.payable_account_id ?? null,
        payload.receivable_account_id ?? null,
        payload.reason_higher_rate ?? null,
        payload.applicable_from ?? null,
        payload.applicable_to ?? null,
        payload.base_rate ?? null,
        payload.surcharge_rate ?? null,
        payload.cess_rate ?? null,
        payload.is_higher_rate ?? null,
        payload.is_active ?? null,
        id,
      ],
    );
    return rows[0];
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
    let sqlQuery = `SELECT * FROM tds_groups WHERE 1=1`;
    if (status === "active") sqlQuery += ` AND is_active = true`;
    if (status === "inactive") sqlQuery += ` AND is_active = false`;
    sqlQuery += ` ORDER BY group_name ASC`;

    const data = await client.unsafe(sqlQuery);
    return Promise.all((data ?? []).map((group: any) => this.withTdsGroupRates(group)));
  }

  async createTdsGroup(body: any) {
    const name = this.requiredString(body, "group_name");
    const appFrom = body?.applicable_from ?? null;
    const appTo = body?.applicable_to ?? null;
    const isActive = body?.is_active ?? true;

    const rows = await client.unsafe(
      `INSERT INTO tds_groups (group_name, applicable_from, applicable_to, is_active) VALUES ($1, $2, $3, $4) RETURNING *`,
      [name, appFrom, appTo, isActive],
    );
    const data = rows[0];

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
    const name = body?.group_name !== undefined ? this.requiredString(body, "group_name") : null;
    const appFrom = body?.applicable_from !== undefined ? body.applicable_from : null;
    const appTo = body?.applicable_to !== undefined ? body.applicable_to : null;
    const isActive = body?.is_active !== undefined ? body.is_active : null;

    const rows = await client.unsafe(
      `UPDATE tds_groups SET
         group_name = COALESCE($1, group_name),
         applicable_from = COALESCE($2, applicable_from),
         applicable_to = COALESCE($3, applicable_to),
         is_active = COALESCE($4, is_active)
       WHERE id = $5 RETURNING *`,
      [name, appFrom, appTo, isActive, id],
    );
    const data = rows[0];

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
    const data = await client.unsafe(
      `SELECT tgi.tds_rate_id, tr.*
       FROM tds_group_items tgi
       LEFT JOIN tds_rates tr ON tr.id = tgi.tds_rate_id
       WHERE tgi.tds_group_id = $1`,
      [group.id],
    );

    return {
      ...group,
      tds_rate_ids: (data ?? []).map((row: any) => row.tds_rate_id),
      rates: (data ?? []).map((row: any) => (row.id ? row : null)).filter(Boolean),
    };
  }

  async createTcsRate(body: any) {
    const payload = this.tcsRatePayload(body, true);
    const rows = await client.unsafe(
      `INSERT INTO tcs_rates (tax_name, nature_id, rate, payable_account_id, receivable_account_id, higher_rate_reason_id, income_tax_act, applicable_from, applicable_to, is_higher_rate, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *`,
      [
        payload.tax_name,
        payload.nature_id,
        payload.rate ?? 0,
        payload.payable_account_id ?? null,
        payload.receivable_account_id ?? null,
        payload.higher_rate_reason_id ?? null,
        payload.income_tax_act ?? null,
        payload.applicable_from ?? null,
        payload.applicable_to ?? null,
        payload.is_higher_rate ?? false,
        payload.is_active ?? true,
      ],
    );
    return rows[0];
  }

  async updateTcsRate(id: string, body: any) {
    const payload = this.tcsRatePayload(body, false);
    const rows = await client.unsafe(
      `UPDATE tcs_rates SET
         tax_name = COALESCE($1, tax_name),
         nature_id = COALESCE($2, nature_id),
         rate = COALESCE($3, rate),
         payable_account_id = COALESCE($4, payable_account_id),
         receivable_account_id = COALESCE($5, receivable_account_id),
         higher_rate_reason_id = COALESCE($6, higher_rate_reason_id),
         income_tax_act = COALESCE($7, income_tax_act),
         applicable_from = COALESCE($8, applicable_from),
         applicable_to = COALESCE($9, applicable_to),
         is_higher_rate = COALESCE($10, is_higher_rate),
         is_active = COALESCE($11, is_active)
       WHERE id = $12 RETURNING *`,
      [
        payload.tax_name ?? null,
        payload.nature_id ?? null,
        payload.rate ?? null,
        payload.payable_account_id ?? null,
        payload.receivable_account_id ?? null,
        payload.higher_rate_reason_id ?? null,
        payload.income_tax_act ?? null,
        payload.applicable_from ?? null,
        payload.applicable_to ?? null,
        payload.is_higher_rate ?? null,
        payload.is_active ?? null,
        id,
      ],
    );
    return rows[0];
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
