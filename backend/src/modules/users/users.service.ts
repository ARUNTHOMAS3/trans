import { Inject, Injectable, forwardRef } from "@nestjs/common";
import { BranchesService } from "../branches/branches.service";
import { SupabaseService } from "../supabase/supabase.service";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { db, client } from "../../db/db";
import {
  users,
  settingsRoles,
  branchUserAccess,
  userBranchAccess,
  organisationBranchMaster,
} from "../../db/schema";
import { eq, and, inArray } from "drizzle-orm";

@Injectable()
export class UsersService {
  constructor(
    private readonly supabaseService: SupabaseService,
    @Inject(forwardRef(() => BranchesService))
    private readonly branchesService: BranchesService,
  ) {}

  private resolveTenant(tenantOrOrgId: TenantContext | string): {
    orgId: string;
    entityId?: string;
  } {
    if (typeof tenantOrOrgId === "string") {
      return { orgId: tenantOrOrgId };
    }
    return { orgId: tenantOrOrgId.orgId, entityId: tenantOrOrgId.entityId };
  }

  private getEntityId(tenantOrOrgId: TenantContext | string): string {
    const { entityId } = this.resolveTenant(tenantOrOrgId);
    if (!entityId || entityId === "undefined") {
      throw new Error(
        "entityId is required but was not resolved from tenant context",
      );
    }
    return entityId;
  }

  private readonly roleCatalog = [
    {
      id: "admin",
      label: "Admin",
      description: "Internal platform admin with unrestricted access.",
    },
    {
      id: "ho_admin",
      label: "HO Admin",
      description:
        "Head office administrator with organization-wide operational access.",
    },
    {
      id: "branch_admin",
      label: "Branch Admin",
      description:
        "Branch-scoped administrator with operational access to assigned locations.",
    },
  ];

  private getBranchAdminDefaultPermissions() {
    return {
      branches: ["view", "edit"],
      users: ["view"],
      warehouses: ["view", "create", "edit", "delete"],
      zones: ["view", "create", "edit", "delete"],
      item: ["full"],
      composite_items: ["full"],
      item_groups: ["full"],
      price_list: ["full"],
      item_mapping: ["view", "edit"],
      assemblies: ["full"],
      inventory_adjustments: ["full"],
      picklists: ["full"],
      packages: ["full"],
      shipments: ["full"],
      transfer_orders: ["full", "approve"],
      customers: ["full"],
      quotations: ["full"],
      sales_orders: ["full"],
      invoices: ["full"],
      delivery_challans: ["full"],
      customer_payments: ["full"],
      sales_returns: ["full"],
      credit_notes: ["full"],
      retainer_invoices: ["full"],
      ewaybill_perms: ["view", "create", "delete"],
      payment_links: ["view", "create", "delete"],
      recurring_invoices: ["full"],
      vendors: ["full"],
      expenses: ["full"],
      purchase_orders: ["full"],
      purchase_receives: ["view", "create", "delete"],
      bills: ["full"],
      vendor_payments: ["full"],
      vendor_credits: ["full"],
      chart_of_accounts: ["full"],
      manual_journals: ["full"],
      journal_templates: ["full"],
      opening_balances: ["view", "edit"],
      bulk_update: ["view", "edit"],
      transaction_locking: ["view", "edit"],
      reports: ["view", "export"],
      audit_logs: ["view"],
      documents: ["view"],
      dashboard_charts: ["view"],
      general_prefs: ["view", "edit"],
      transaction_series: ["view", "create", "edit", "delete"],
    } as Record<string, unknown>;
  }

  private normalizeRoleLabel(value: unknown): string {
    return value?.toString().trim().toLowerCase() ?? "";
  }

  async ensureCoreDefaultRoles(tenantOrOrgId: TenantContext | string) {
    const entityId = this.getEntityId(tenantOrOrgId);

    const rows = await db
      .select()
      .from(settingsRoles)
      .where(eq(settingsRoles.entityId, entityId));

    let hoAdminRoleId: string | null = null;
    let branchAdminRoleId: string | null = null;

    for (const role of rows ?? []) {
      const normalized = this.normalizeRoleLabel(role.label);
      if (normalized === "ho admin") hoAdminRoleId = role.id;
      if (normalized === "branch admin") branchAdminRoleId = role.id;
    }

    if (!hoAdminRoleId) {
      const [inserted] = await db
        .insert(settingsRoles)
        .values({
          entityId,
          label: "HO Admin",
          description: "Head office administrator role",
          permissions: { full_access: true },
          isActive: true,
        })
        .returning();
      hoAdminRoleId = inserted.id;
    }

    if (!branchAdminRoleId) {
      const [inserted] = await db
        .insert(settingsRoles)
        .values({
          entityId,
          label: "Branch Admin",
          description: "Branch administrator role",
          permissions: this.getBranchAdminDefaultPermissions(),
          isActive: true,
        })
        .returning();
      branchAdminRoleId = inserted.id;
    }

    return { hoAdminRoleId, branchAdminRoleId };
  }

  async listRoles(tenantOrOrgId: TenantContext | string) {
    const entityId = this.getEntityId(tenantOrOrgId);
    await this.ensureCoreDefaultRoles(tenantOrOrgId);

    const rows = await db
      .select()
      .from(settingsRoles)
      .where(eq(settingsRoles.entityId, entityId));

    return (rows ?? []).map((row) => ({
      id: row.id,
      label: row.label,
      description: row.description,
      permissions: row.permissions,
      is_active: row.isActive,
      created_at: row.createdAt,
      updated_at: row.updatedAt,
    }));
  }

  async getRole(id: string, tenantOrOrgId: TenantContext | string) {
    const entityId = this.getEntityId(tenantOrOrgId);
    const rows = await db
      .select()
      .from(settingsRoles)
      .where(and(eq(settingsRoles.id, id), eq(settingsRoles.entityId, entityId)))
      .limit(1);

    const row = rows[0];
    if (!row) return null;
    return {
      id: row.id,
      label: row.label,
      description: row.description,
      permissions: row.permissions,
      is_active: row.isActive,
      created_at: row.createdAt,
      updated_at: row.updatedAt,
    };
  }

  async createRole(tenantOrOrgId: TenantContext | string, dto: any) {
    const entityId = this.getEntityId(tenantOrOrgId);
    const [inserted] = await db
      .insert(settingsRoles)
      .values({
        entityId,
        label: dto.label,
        description: dto.description ?? "",
        permissions: dto.permissions ?? {},
        isActive: dto.is_active ?? true,
      })
      .returning();

    return {
      id: inserted.id,
      label: inserted.label,
      description: inserted.description,
      permissions: inserted.permissions,
      is_active: inserted.isActive,
    };
  }

  async updateRole(id: string, tenantOrOrgId: TenantContext | string, dto: any) {
    const entityId = this.getEntityId(tenantOrOrgId);

    const updatePayload: Record<string, any> = { updatedAt: new Date() };
    if (dto.label !== undefined) updatePayload.label = dto.label;
    if (dto.description !== undefined) updatePayload.description = dto.description;
    if (dto.permissions !== undefined) updatePayload.permissions = dto.permissions;
    if (dto.is_active !== undefined) updatePayload.isActive = dto.is_active;

    const [updated] = await db
      .update(settingsRoles)
      .set(updatePayload)
      .where(and(eq(settingsRoles.id, id), eq(settingsRoles.entityId, entityId)))
      .returning();

    return {
      id: updated.id,
      label: updated.label,
      description: updated.description,
      permissions: updated.permissions,
      is_active: updated.isActive,
    };
  }

  async deleteRole(id: string, tenantOrOrgId: TenantContext | string) {
    const entityId = this.getEntityId(tenantOrOrgId);

    await db
      .delete(settingsRoles)
      .where(and(eq(settingsRoles.id, id), eq(settingsRoles.entityId, entityId)));

    return { success: true };
  }

  async getRoleCatalog(_tenantOrOrgId?: TenantContext | string) {
    return this.roleCatalog;
  }

  async findAll(tenantOrOrgId: TenantContext | string, status = "all") {
    const { orgId, entityId } = this.resolveTenant(tenantOrOrgId);
    const clientSupabase = this.supabaseService.getClient();

    try {
      // 1. Resolve Org Entity ID from organisation_branch_master for ref_id = orgId (type = 'ORG')
      const { data: orgObm } = await clientSupabase
        .from("organisation_branch_master")
        .select("id")
        .eq("type", "ORG")
        .eq("ref_id", orgId)
        .maybeSingle();

      const validEntityIds: string[] = [];
      if (orgObm?.id) {
        validEntityIds.push(orgObm.id);

        // 2. Resolve all child Branch Entity IDs belonging to this parent Org Entity ID
        const { data: branchObms } = await clientSupabase
          .from("organisation_branch_master")
          .select("id")
          .eq("type", "BRANCH")
          .eq("parent_id", orgObm.id);

        if (branchObms && branchObms.length > 0) {
          validEntityIds.push(...branchObms.map((b: any) => b.id));
        }
      }

      if (entityId && entityId !== "undefined") {
        validEntityIds.push(entityId);
      }

      const uniqueEntityIds = Array.from(new Set(validEntityIds.filter(Boolean)));

      let query = clientSupabase.from("users").select("*");

      if (uniqueEntityIds.length > 0) {
        query = query.or(
          `entity_id.in.(${uniqueEntityIds.join(",")}),org_id.eq.${orgId}`,
        );
      } else {
        query = query.eq("org_id", orgId);
      }

      if (status === "active") query = query.eq("is_active", true);
      if (status === "inactive") query = query.eq("is_active", false);

      query = query.order("created_at", { ascending: false });

      const { data, error } = await query;
      if (error) {
        console.error("[UsersService] findAll Supabase query error:", error);
        return [];
      }

      return (data ?? []).map((u: any) => ({
        id: u.id,
        email: u.email,
        full_name: u.full_name,
        role: u.role,
        entity_id: u.entity_id,
        is_active: u.is_active,
        created_at: u.created_at,
        updated_at: u.updated_at,
      }));
    } catch (err) {
      console.error("[UsersService] findAll error:", err);
      return [];
    }
  }

  async findOne(id: string, _tenantOrOrgId: TenantContext | string) {
    const clientSupabase = this.supabaseService.getClient();

    try {
      const { data, error } = await clientSupabase
        .from("users")
        .select("*")
        .eq("id", id)
        .maybeSingle();

      if (error || !data) return null;

      return {
        id: data.id,
        email: data.email,
        full_name: data.full_name,
        role: data.role,
        entity_id: data.entity_id,
        is_active: data.is_active,
        created_at: data.created_at,
        updated_at: data.updated_at,
      };
    } catch {
      return null;
    }
  }

  async create(tenant: TenantContext, dto: any) {
    const orgId = tenant.orgId;
    const clientSupabase = this.supabaseService.getClient();

    const fullName = (dto.full_name || dto.name || "").trim() || dto.email.split("@")[0] || "User";
    const role = dto.role ?? "user";

    const authRes = await clientSupabase.auth.admin.createUser({
      email: dto.email,
      password: dto.password || "Zabnix@2025",
      email_confirm: true,
      user_metadata: {
        full_name: fullName,
        name: fullName,
        role: role,
        org_id: orgId,
      },
    });

    if (authRes.error || !authRes.data.user) {
      throw new Error(authRes.error?.message ?? "Failed to create user in auth");
    }

    const userId = authRes.data.user.id;

    const [inserted] = await db
      .insert(users)
      .values({
        id: userId,
        orgId,
        entityId: tenant.entityId,
        email: dto.email,
        fullName: fullName,
        role: role,
        isActive: true,
      })
      .returning();

    if (dto.location_access && Array.isArray(dto.location_access.branch_ids)) {
      for (const branchId of dto.location_access.branch_ids) {
        const { data: obmRow } = await clientSupabase
          .from("organisation_branch_master")
          .select("id")
          .eq("type", "BRANCH")
          .eq("ref_id", branchId)
          .maybeSingle();

        if (obmRow?.id) {
          await clientSupabase
            .from("user_branch_access")
            .upsert(
              {
                user_id: userId,
                entity_id: obmRow.id,
                is_default_business:
                  branchId === dto.location_access.default_business_branch_id,
                is_default_warehouse:
                  branchId === dto.location_access.default_warehouse_branch_id,
              },
              { onConflict: "user_id,entity_id" },
            );
        }
      }
    }

    return {
      id: inserted.id,
      email: inserted.email,
      full_name: inserted.fullName,
      name: inserted.fullName,
      role: inserted.role,
      is_active: inserted.isActive,
    };
  }

  async update(id: string, tenantOrOrgId: TenantContext | string, dto: any) {
    const { orgId } = this.resolveTenant(tenantOrOrgId);
    const fullName = dto.full_name || dto.name;

    const updatePayload: Record<string, any> = { updatedAt: new Date() };
    if (fullName !== undefined) updatePayload.fullName = fullName;
    if (dto.role !== undefined) updatePayload.role = dto.role;
    if (dto.is_active !== undefined) updatePayload.isActive = dto.is_active;

    const [updated] = await db
      .update(users)
      .set(updatePayload)
      .where(and(eq(users.id, id), eq(users.orgId, orgId)))
      .returning();

    return {
      id: updated.id,
      email: updated.email,
      full_name: updated.fullName,
      name: updated.fullName,
      role: updated.role,
      is_active: updated.isActive,
    };
  }

  async remove(id: string, tenantOrOrgId: TenantContext | string) {
    const { orgId } = this.resolveTenant(tenantOrOrgId);

    await db
      .delete(users)
      .where(and(eq(users.id, id), eq(users.orgId, orgId)));

    return { success: true };
  }

  async getLocationAccess(userId: string, tenantOrOrgId: TenantContext | string) {
    const { orgId } = this.resolveTenant(tenantOrOrgId);
    try {
      const data = await client.unsafe(
        `SELECT uba.entity_id, uba.is_default_business, uba.is_default_warehouse, obm.name
         FROM user_branch_access uba
         LEFT JOIN organisation_branch_master obm ON obm.id = uba.entity_id
         WHERE uba.user_id = $1 AND uba.org_id = $2`,
        [userId, orgId],
      );
      return data ?? [];
    } catch {
      return [];
    }
  }

  async updateLocationAccess(
    userId: string,
    tenantOrOrgId: TenantContext | string,
    body: any,
  ) {
    const locations = Array.isArray(body?.locations)
      ? body.locations
      : Array.isArray(body)
        ? body
        : [];
    return this.updateUserLocations(userId, tenantOrOrgId, locations);
  }

  async updateUserLocations(
    userId: string,
    tenantOrOrgId: TenantContext | string,
    locations: Array<{ entity_id: string; is_default_business?: boolean; is_default_warehouse?: boolean }>,
  ) {
    const { orgId } = this.resolveTenant(tenantOrOrgId);

    await db
      .delete(userBranchAccess)
      .where(
        and(
          eq(userBranchAccess.userId, userId),
          eq(userBranchAccess.orgId, orgId),
        ),
      );

    if (locations && locations.length > 0) {
      await db.insert(userBranchAccess).values(
        locations.map((loc) => ({
          userId,
          orgId,
          entityId: loc.entity_id,
          isDefaultBusiness: loc.is_default_business ?? false,
          isDefaultWarehouse: loc.is_default_warehouse ?? false,
        })),
      );
    }

    return { success: true };
  }

  async findActivities(_userId: string, _tenantOrOrgId: TenantContext | string) {
    return [];
  }

  async setDefaultBranch(
    userId: string,
    entityId: string,
    tenantOrOrgId: TenantContext | string,
  ) {
    const { orgId } = this.resolveTenant(tenantOrOrgId);

    await client.unsafe(
      `UPDATE user_branch_access SET is_default_business = false WHERE user_id = $1 AND org_id = $2`,
      [userId, orgId],
    );

    await client.unsafe(
      `UPDATE user_branch_access SET is_default_business = true WHERE user_id = $1 AND org_id = $2 AND entity_id = $3`,
      [userId, orgId, entityId],
    );

    return { success: true };
  }

  async updateStatus(
    userId: string,
    tenantOrOrgId: TenantContext | string,
    isActive: boolean,
  ) {
    return this.toggleUserStatus(userId, isActive, tenantOrOrgId);
  }

  async toggleUserStatus(
    id: string,
    isActive: boolean,
    tenantOrOrgId: TenantContext | string,
  ) {
    const { orgId } = this.resolveTenant(tenantOrOrgId);

    const [updated] = await db
      .update(users)
      .set({ isActive, updatedAt: new Date() })
      .where(and(eq(users.id, id), eq(users.orgId, orgId)))
      .returning();

    return {
      id: updated.id,
      email: updated.email,
      full_name: updated.fullName,
      role: updated.role,
      is_active: updated.isActive,
    };
  }
}
