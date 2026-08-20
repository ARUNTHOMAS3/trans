import { ForbiddenException, Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { db, client } from "../../db/db";
import { warehouses, organisationBranchMaster } from "../../db/schema";
import { eq, and, inArray } from "drizzle-orm";

@Injectable()
export class WarehousesSettingsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private normalizeUuid(value: unknown) {
    const normalized = value?.toString().trim() ?? "";
    return normalized.length > 0 ? normalized : null;
  }

  private async fetchNameMap(
    table: string,
    ids: string[],
    displayField = "name",
  ): Promise<Map<string, string>> {
    const normalizedIds = ids.filter((id) => id.toString().trim().length > 0);
    if (normalizedIds.length === 0) {
      return new Map<string, string>();
    }

    const sanitizedTable = table.replace(/[^a-zA-Z0-9_]/g, "");
    const sanitizedField = displayField.replace(/[^a-zA-Z0-9_]/g, "");

    try {
      const data = await client.unsafe(
        `SELECT id, "${sanitizedField}" as display FROM "${sanitizedTable}" WHERE id = ANY($1)`,
        [normalizedIds],
      );

    const entries = (data ?? []).map(
      (row: any) =>
        [row.id?.toString() ?? "", (row.display ?? "").toString().trim()] as [
          string,
          string,
        ],
    );
    return new Map<string, string>(entries);
    } catch {
      return new Map<string, string>();
    }
  }

  private async resolveBranchRegistryEntityId(branchId: string) {
    const normalizedBranchId = this.normalizeUuid(branchId);
    if (!normalizedBranchId) return null;

    const rows = await db
      .select({ id: organisationBranchMaster.id })
      .from(organisationBranchMaster)
      .where(
        and(
          eq(organisationBranchMaster.type, "BRANCH"),
          eq(organisationBranchMaster.refId, normalizedBranchId),
        ),
      )
      .limit(1);

    return rows[0]?.id?.toString() ?? null;
  }

  private mapWarehouse(
    row: any,
    branchNames: Map<string, string>,
    customerNames: Map<string, string>,
    vendorNames: Map<string, string>,
  ) {
    return {
      ...row,
      branch_id: row.branch_id ?? null,
      customer_id: row.customer_id ?? null,
      vendor_id: row.vendor_id ?? null,
      parent_branch_name: branchNames.get(row.branch_id ?? "") ?? null,
      customer_name: customerNames.get(row.customer_id ?? "") ?? null,
      vendor_name: vendorNames.get(row.vendor_id ?? "") ?? null,
      is_default_for_branch: row.is_default_for_branch ?? false,
      source_branch_id: row.source_branch_id ?? null,
    };
  }

  async findAll(tenant: TenantContext) {
    let sqlQuery = `SELECT * FROM warehouses WHERE org_id = $1`;
    const params: any[] = [tenant.orgId];

    if (tenant.role !== "admin" && tenant.accessibleBranchIds.length > 0) {
      params.push(tenant.accessibleBranchIds);
      sqlQuery += ` AND source_branch_id = ANY($2)`;
    }

    sqlQuery += ` ORDER BY created_at ASC`;

    const data = await client.unsafe(sqlQuery, params);
    const warehouseList = data ?? [];

    const [branchNames, customerNames, vendorNames] = await Promise.all([
      this.fetchNameMap(
        "branches",
        warehouseList.map((w: any) => w.branch_id?.toString() ?? ""),
      ),
      this.fetchNameMap(
        "customers",
        warehouseList.map((w: any) => w.customer_id?.toString() ?? ""),
        "display_name",
      ),
      this.fetchNameMap(
        "vendors",
        warehouseList.map((w: any) => w.vendor_id?.toString() ?? ""),
        "display_name",
      ),
    ]);

    return warehouseList.map((w: any) =>
      this.mapWarehouse(w, branchNames, customerNames, vendorNames),
    );
  }

  async findOne(id: string, tenant: TenantContext) {
    const rows = await db
      .select()
      .from(warehouses)
      .where(and(eq(warehouses.id, id), eq(warehouses.entityId, tenant.entityId)))
      .limit(1);

    const data = rows[0];
    if (!data) return null;

    const [branchNames, customerNames, vendorNames] = await Promise.all([
      this.fetchNameMap("branches", [(data as any).branch_id?.toString() ?? ""]),
      this.fetchNameMap(
        "customers",
        [(data as any).customer_id?.toString() ?? ""],
        "display_name",
      ),
      this.fetchNameMap(
        "vendors",
        [(data as any).vendor_id?.toString() ?? ""],
        "display_name",
      ),
    ]);
    return this.mapWarehouse(data, branchNames, customerNames, vendorNames);
  }

  async create(dto: any, tenant: TenantContext) {
    const branchId = this.normalizeUuid(
      dto.source_branch_id ?? dto.branch_id ?? tenant.branchId,
    );
    const branchEntityId = branchId
      ? await this.resolveBranchRegistryEntityId(branchId)
      : null;

    const [data] = await db
      .insert(warehouses)
      .values({
        entityId: branchEntityId ?? tenant.entityId,
        orgId: tenant.orgId,
        name: dto.name,
        warehouseCode: dto.warehouse_code ?? null,
        sourceBranchId: branchId,
        customerId: this.normalizeUuid(dto.customer_id),
        vendorId: this.normalizeUuid(dto.vendor_id),
        attention: dto.attention ?? null,
        street: dto.street ?? null,
        place: dto.place ?? null,
        city: dto.city ?? null,
        state: dto.state ?? null,
        districtId: this.normalizeUuid(dto.district_id),
        localBodyId: this.normalizeUuid(dto.local_body_id),
        assemblyId: this.normalizeUuid(dto.assembly_id),
        wardId: this.normalizeUuid(dto.ward_id),
        pincode: dto.pincode ?? null,
        country: dto.country ?? "India",
        phone: dto.phone ?? null,
        email: dto.email ?? null,
        isActive: dto.is_active ?? true,
      })
      .returning();

    return data;
  }

  private async assertNotDefault(id: string, tenant: TenantContext) {
    const rows = await db
      .select({ isDefaultForBranch: warehouses.isDefaultForBranch })
      .from(warehouses)
      .where(and(eq(warehouses.id, id), eq(warehouses.entityId, tenant.entityId)))
      .limit(1);

    if (rows[0]?.isDefaultForBranch) {
      throw new ForbiddenException(
        "Default warehouses cannot be edited or deleted",
      );
    }
  }

  async update(id: string, tenant: TenantContext, dto: any) {
    await this.assertNotDefault(id, tenant);

    const updatePayload: Record<string, any> = { updatedAt: new Date() };

    if ("name" in dto) updatePayload.name = dto.name;
    if ("warehouse_code" in dto) updatePayload.warehouseCode = dto.warehouse_code;
    if ("customer_id" in dto) updatePayload.customerId = this.normalizeUuid(dto.customer_id);
    if ("vendor_id" in dto) updatePayload.vendorId = this.normalizeUuid(dto.vendor_id);
    if ("attention" in dto) updatePayload.attention = dto.attention;
    if ("street" in dto) updatePayload.street = dto.street;
    if ("place" in dto) updatePayload.place = dto.place;
    if ("city" in dto) updatePayload.city = dto.city;
    if ("state" in dto) updatePayload.state = dto.state;
    if ("district_id" in dto) updatePayload.districtId = this.normalizeUuid(dto.district_id);
    if ("local_body_id" in dto) updatePayload.localBodyId = this.normalizeUuid(dto.local_body_id);
    if ("assembly_id" in dto) updatePayload.assemblyId = this.normalizeUuid(dto.assembly_id);
    if ("ward_id" in dto) updatePayload.wardId = this.normalizeUuid(dto.ward_id);
    if ("pincode" in dto) updatePayload.pincode = dto.pincode;
    if ("country" in dto) updatePayload.country = dto.country;
    if ("phone" in dto) updatePayload.phone = dto.phone;
    if ("email" in dto) updatePayload.email = dto.email;
    if ("is_active" in dto) updatePayload.isActive = dto.is_active;
    if ("branch_id" in dto || "source_branch_id" in dto) {
      updatePayload.sourceBranchId = this.normalizeUuid(
        dto.source_branch_id ?? dto.branch_id,
      );
    }

    const [data] = await db
      .update(warehouses)
      .set(updatePayload)
      .where(and(eq(warehouses.id, id), eq(warehouses.entityId, tenant.entityId)))
      .returning();

    return data;
  }

  async remove(id: string, tenant: TenantContext) {
    await this.assertNotDefault(id, tenant);
    await db
      .delete(warehouses)
      .where(and(eq(warehouses.id, id), eq(warehouses.entityId, tenant.entityId)));

    return { success: true };
  }
}
