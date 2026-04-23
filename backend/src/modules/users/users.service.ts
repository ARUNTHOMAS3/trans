import { Inject, Injectable, forwardRef } from "@nestjs/common";
import { BranchesService } from "../branches/branches.service";
import { SupabaseService } from "../supabase/supabase.service";
import { TenantContext } from "../../common/middleware/tenant.middleware";

// Auth is enabled: users are resolved under org context and merged with the
// org-scoped public users table for runtime role and location behavior.

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
      throw new Error("entityId is required but was not resolved from tenant context");
    }
    return entityId;
  }

  private readonly roleCatalog = [
    {
      id: "admin",
      label: "Admin",
      description:
        "Internal platform admin with unrestricted access.",
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

  private readonly reservedRoleLabels = new Set<string>([
    "admin",
    "ho admin",
    "branch admin",
  ]);

  private readonly reservedRoleIds = new Set<string>([
    "admin",
    "ho_admin",
    "branch_admin",
  ]);

  private getBranchAdminDefaultPermissions() {
    return {
      branches: ["view", "create", "edit", "delete"],
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
      transaction_series: ["view", "edit"],
    } as Record<string, unknown>;
  }

  private normalizeRoleLabel(value: unknown): string {
    return value?.toString().trim().toLowerCase() ?? "";
  }

  private isReservedRoleLabel(value: unknown): boolean {
    return this.reservedRoleLabels.has(this.normalizeRoleLabel(value));
  }

  async ensureCoreDefaultRoles(tenant: TenantContext) {
    const client = this.supabaseService.getClient();

    const upsertByLabel = async (
      label: string,
      description: string,
      permissions: Record<string, unknown>,
    ) => {
      const entityId = tenant.entityId?.toString().trim();
      const orgId = tenant.orgId?.toString().trim();

      const { data: existing, error: findError } = await client
        .from("roles")
        .select("id")
        .eq("entity_id", entityId)
        .ilike("label", label)
        .limit(1)
        .maybeSingle();

      if (findError) {
        throw new Error(`Failed to fetch role '${label}': ${findError.message}`);
      }

      if (existing?.id) {
        return existing.id.toString();
      }

      const { data: inserted, error: insertError } = await client
        .from("roles")
        .insert({
          entity_id: tenant.entityId,
          label,
          description,
          permissions,
          is_active: true,
        })
        .select("id")
        .single();

      if (insertError) {
        throw new Error(`Failed to create role '${label}': ${insertError.message}`);
      }

      return inserted.id?.toString() ?? "";
    };

    const hoAdminRoleId = await upsertByLabel(
      "HO Admin",
      "Head office administrator with organization-wide operational access.",
      { full_access: true },
    );
    const branchAdminRoleId = await upsertByLabel(
      "Branch Admin",
      "Branch-scoped administrator with operational access to assigned locations.",
      this.getBranchAdminDefaultPermissions(),
    );

    return { hoAdminRoleId, branchAdminRoleId };
  }

  private normalizeRole(role: unknown): string {
    const raw = role?.toString().trim() ?? "";
    const value = raw.toLowerCase();

    const isUuid =
      /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$/.test(
        raw,
      );

    if (isUuid) {
      return raw;
    }

    switch (value) {
      case "super_admin":
        return "admin";
      case "manager":
      case "staff":
      case "branch_manager":
      case "branch_staff":
        return "branch_admin";
      case "admin":
      case "ho_admin":
      case "branch_admin":
        return value;
      default:
        return raw;
    }
  }

  private async fetchCustomRoles(tenant: TenantContext): Promise<any[]> {
    const entityId = tenant.entityId?.toString().trim();
    if (!entityId || entityId === "undefined") return [];

    const { data, error } = await this.supabaseService
      .getClient()
      .from("roles")
      .select("*")
      .eq("entity_id", entityId)
      .eq("is_active", true)
      .order("label", { ascending: true });

    if (error) {
      throw new Error(`Failed to fetch roles: ${error.message}`);
    }

    return data ?? [];
  }

  private async fetchRoleByLabel(tenant: TenantContext, label: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("roles")
      .select("*")
      .eq("entity_id", this.getEntityId(tenant))
      .ilike("label", label)
      .limit(1)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to fetch role by label: ${error.message}`);
    }

    return data ?? null;
  }

  private async getMergedRoles(tenant: TenantContext) {
    await this.ensureCoreDefaultRoles(tenant);

    const customRoles = await this.fetchCustomRoles(tenant);
    const consumedIds = new Set<string>();

    const mergedBuiltinRoles = await Promise.all(
      this.roleCatalog.map(async (role) => {
        if (role.id === "admin") {
          return {
            ...role,
            is_default: true,
            permissions: { full_access: true },
          };
        }

        const storedRole = await this.fetchRoleByLabel(tenant, role.label);
        if (storedRole?.id != null) {
          consumedIds.add(storedRole.id.toString());
        }

        return {
          ...role,
          description:
            (storedRole?.description ?? "").toString().trim().length > 0
              ? (storedRole?.description ?? "").toString()
              : role.description,
          is_default: true,
          permissions:
            storedRole?.permissions != null
              ? storedRole.permissions
              : role.id === "ho_admin"
                ? { full_access: true }
                : role.id === "branch_admin"
                  ? this.getBranchAdminDefaultPermissions()
                  : {},
        };
      }),
    );

    return [
      ...mergedBuiltinRoles,
      ...customRoles.map((role) => ({
        id: role.id?.toString() ?? "",
        label: (role.label ?? "").toString(),
        description: (role.description ?? "").toString(),
        is_default: false,
        permissions: role.permissions ?? {},
      })).filter((role) => !consumedIds.has(role.id)),
    ];
  }

  private async getRoleMap(tenant: TenantContext): Promise<Map<string, any>> {
    const mergedRoles = await this.getMergedRoles(tenant);
    return new Map(
      mergedRoles.map((role) => [
        role.id.toString(),
        { label: role.label, is_default: role.is_default === true },
      ]),
    );
  }

  private normalizeUuid(value: unknown): string | null {
    const normalized = value?.toString().trim();
    return normalized ? normalized : null;
  }

  private normalizeUuidList(values: unknown): string[] {
    if (!Array.isArray(values)) return [];
    return Array.from(
      new Set(
        values
          .map((value) => this.normalizeUuid(value))
          .filter((value: unknown): value is string => typeof value === 'string' && value.length > 0),
      ),
    );
  }

  private generateTemporaryPassword() {
    return "Zabnix@2025";
  }

  private async findPublicUserByEmail(email: string) {
    const normalizedEmail = email.toLowerCase().trim();
    const { data, error } = await this.supabaseService
      .getClient()
      .from("users")
      .select("id,email,full_name,role,is_active,entity_id")
      .eq("email", normalizedEmail)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to fetch users row by email: ${error.message}`);
    }

    return data ?? null;
  }

  private async findAuthUserByEmail(email: string) {
    const normalizedEmail = email.toLowerCase().trim();
    const { data, error } = await this.supabaseService
      .getClient()
      .auth.admin.listUsers({ perPage: 1000 });

    if (error) {
      throw new Error(`Failed to list auth users: ${error.message}`);
    }

    const authUsers = data?.users ?? [];
    return (
      authUsers.find(
        (user: any) =>
          user.email?.toString().trim().toLowerCase() === normalizedEmail,
      ) ?? null
    );
  }

  async provisionManagedUser(
    tenant: TenantContext,
    options: {
      email: string;
      fullName: string;
      role: unknown;
      authUserId?: string | null;
      publicEntityId?: string | null;
      isActive?: boolean;
    },
  ) {
    const email = options.email?.toString().trim().toLowerCase();
    const fullName = options.fullName?.toString().trim();
    const role = this.normalizeRole(options.role);
    const isActive = options.isActive ?? true;
    const publicEntityId =
      options.publicEntityId?.toString().trim() || this.getEntityId(tenant);

    if (!tenant.orgId?.toString().trim()) {
      throw new Error("org_id is required");
    }
    if (!email) {
      throw new Error("Email address is required");
    }
    if (!fullName) {
      throw new Error("Name is required");
    }
    if (!publicEntityId) {
      throw new Error("entity_id is required");
    }

    const [publicUser, authUserByEmail] = await Promise.all([
      this.findPublicUserByEmail(email),
      options.authUserId?.toString().trim()
        ? this.supabaseService
            .getClient()
            .auth.admin.getUserById(options.authUserId.toString().trim())
            .then(({ data, error }) => {
              if (error) {
                throw new Error(`Failed to fetch auth user: ${error.message}`);
              }
              return data.user ?? null;
            })
        : this.findAuthUserByEmail(email),
    ]);

    if (
      publicUser?.id &&
      authUserByEmail?.id &&
      publicUser.id.toString() !== authUserByEmail.id.toString()
    ) {
      throw new Error(
        `User sync conflict for ${email}: auth.users.id and public.users.id do not match`,
      );
    }

    let userId = authUserByEmail?.id?.toString() ?? publicUser?.id?.toString() ?? "";
    const authPayload = {
      email,
      ban_duration: isActive ? "none" : "876000h",
      user_metadata: {
        full_name: fullName,
        name: fullName,
        role,
        org_id: tenant.orgId,
        entity_id: publicEntityId,
      },
      app_metadata: {
        role,
        org_id: tenant.orgId,
        entity_id: publicEntityId,
      },
    };

    if (authUserByEmail?.id) {
      const authRes = await this.supabaseService
        .getClient()
        .auth.admin.updateUserById(authUserByEmail.id, authPayload);
      if (authRes.error) {
        throw new Error(`Failed to update user: ${authRes.error.message}`);
      }
      userId = authUserByEmail.id;
    } else {
      if (publicUser?.id) {
        throw new Error(
          `User sync conflict for ${email}: public.users row exists without auth.users record`,
        );
      }

      const authRes = await this.supabaseService
        .getClient()
        .auth.admin.createUser({
          email,
          password: this.generateTemporaryPassword(),
          email_confirm: true,
          user_metadata: authPayload.user_metadata,
          app_metadata: authPayload.app_metadata,
        });

      if (authRes.error || !authRes.data.user?.id) {
        throw new Error(
          `Failed to create user: ${authRes.error?.message ?? "Unknown error"}`,
        );
      }
      userId = authRes.data.user.id;
    }

    await this.upsertPublicUser(
      { ...tenant, entityId: publicEntityId } as TenantContext,
      {
        id: userId,
        email,
        full_name: fullName,
        role,
        is_active: isActive,
      },
    );

    return {
      id: userId,
      email,
      fullName,
      role,
      isActive,
    };
  }

  private async fetchPublicUsers(tenantOrOrgId: TenantContext | string): Promise<Map<string, any>> {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("users")
      .select("*")
      .eq("entity_id", this.getEntityId(tenantOrOrgId));

    if (error) {
      throw new Error(`Failed to fetch users table: ${error.message}`);
    }

    return new Map((data ?? []).map((row: any) => [row.id, row]));
  }

  private async upsertPublicUser(
    tenant: TenantContext,
    payload: {
      id: string;
      email: string;
      full_name: string;
      role: string;
      is_active: boolean;
    },
  ) {
    const { error } = await this.supabaseService
      .getClient()
      .from("users")
      .upsert(
        {
          id: payload.id,
          entity_id: tenant.entityId,
          email: payload.email,
          full_name: payload.full_name,
          role: payload.role,
          is_active: payload.is_active,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "id" },
      );

    if (error) {
      throw new Error(`Failed to upsert users table row: ${error.message}`);
    }
  }

  private async fetchAllLocations(tenantOrOrgId: TenantContext | string): Promise<any[]> {
    const { orgId } = this.resolveTenant(tenantOrOrgId);
    const branches = await this.branchesService.findAll(tenantOrOrgId);
    const branchLocations = branches
      .map((location: any) => {
        const entityId = location.entity_id?.toString().trim() ?? "";
        if (!entityId) return null;

        return {
          id: entityId,
          source_id: location.id?.toString() ?? "",
          name: (location.display_name ?? location.name ?? "").toString(),
          is_active: location.is_active ?? true,
          location_type: (location.location_type ?? "business").toString(),
          parent_branch_id: location.parent_branch_id?.toString() ?? null,
          is_primary: location.is_primary ?? false,
        };
      })
      .filter((location): location is any => Boolean(location));

    const { data: warehouses } = await this.supabaseService
      .getClient()
      .from("warehouses")
      .select("id, name, is_active, warehouse_code")
      .eq("org_id", orgId);

    const warehouseLocations = (warehouses ?? []).map((w: any) => ({
      id: w.id?.toString() ?? "",
      name: (w.name ?? "").toString(),
      is_active: w.is_active ?? true,
      location_type: "warehouse",
      parent_branch_id: null,
      is_primary: false,
    }));

    return [...branchLocations, ...warehouseLocations];
  }

  private async fetchLocationAccessRows(
    tenantOrOrgId: TenantContext | string,
    userId: string,
  ): Promise<any[]> {
    const { orgId, entityId } = this.resolveTenant(tenantOrOrgId);
    let query = this.supabaseService
      .getClient()
      .from("user_branch_access")
      .select("*")
      .eq("org_id", orgId)
      .eq("user_id", userId)
      .order("created_at", { ascending: true });

    const { data, error } = await query;

    if (error) {
      throw new Error(
        `Failed to fetch user_branch_access: ${error.message}`,
      );
    }

    return data ?? [];
  }

  private async fetchUserWarehouseDefault(userId: string): Promise<string | null> {
    const { data } = await this.supabaseService
      .getClient()
      .from("users")
      .select("default_warehouse_id")
      .eq("id", userId)
      .maybeSingle();
    return data?.default_warehouse_id?.toString() ?? null;
  }

  private async buildLocationAccess(tenantOrOrgId: TenantContext | string, userId: string) {
    const [locations, accessRows, defaultWarehouseId] = await Promise.all([
      this.fetchAllLocations(tenantOrOrgId),
      this.fetchLocationAccessRows(tenantOrOrgId, userId),
      this.fetchUserWarehouseDefault(userId),
    ]);

    const locationMap = new Map(
      locations.map((location) => [location.id, location]),
    );

    // Branch access rows only (entity_id = organisation_branch_master id)
    const accessibleBranchLocations = accessRows
      .map((row) => {
        const location = locationMap.get(row.entity_id);
        if (!location) return null;
        return {
          id: location.id,
          name: location.name,
          location_type: location.location_type,
          is_default_business: row.is_default_business ?? false,
          is_default_warehouse: false,
          parent_branch_id: location.parent_branch_id ?? null,
        };
      })
      .filter((row): row is any => Boolean(row));

    // Warehouse default (stored on users.default_warehouse_id, not in user_branch_access)
    const defaultWarehouseLocation = defaultWarehouseId
      ? locationMap.get(defaultWarehouseId) ?? null
      : null;

    const accessibleLocations = [...accessibleBranchLocations];
    if (defaultWarehouseLocation && !accessibleLocations.find((l) => l.id === defaultWarehouseLocation.id)) {
      accessibleLocations.push({
        id: defaultWarehouseLocation.id,
        name: defaultWarehouseLocation.name,
        location_type: "warehouse",
        is_default_business: false,
        is_default_warehouse: true,
        parent_branch_id: null,
      });
    }

    const defaultBusiness = accessibleBranchLocations.find(
      (row) => row.is_default_business,
    );

    return {
      available_locations: locations,
      accessible_locations: accessibleLocations,
      accessible_branch_ids: accessibleLocations.map((row) => row.id),
      default_business_branch_id: defaultBusiness?.id ?? null,
      default_business_branch_name: defaultBusiness?.name ?? null,
      default_warehouse_branch_id: defaultWarehouseId ?? null,
      default_warehouse_branch_name: defaultWarehouseLocation?.name ?? null,
    };
  }

  private async syncLocationAccess(tenant: TenantContext, userId: string, input: any) {
    const allIds = this.normalizeUuidList(
      input?.accessible_branch_ids ?? input?.branch_ids,
    );
    let defaultBusinessBranchId = this.normalizeUuid(
      input?.default_business_branch_id,
    );
    const defaultWarehouseId = this.normalizeUuid(
      input?.default_warehouse_branch_id,
    );

    const client = this.supabaseService.getClient();

    // Split: only OBM-backed branch IDs go into user_branch_access
    const locations = await this.fetchAllLocations(tenant);
    const locationMap = new Map<string, any>();
    for (const location of locations) {
      if (location.id) {
        locationMap.set(location.id, location);
      }
      if (location.source_id) {
        locationMap.set(location.source_id, location);
      }
    }

    const branchOnlyIds = Array.from(
      new Set(
        allIds
          .map((id) => locationMap.get(id) ?? null)
          .filter((location): location is any => Boolean(location))
          .filter((location) => location.location_type !== "warehouse")
          .map((location) => location.id?.toString() ?? "")
          .filter((id) => id.length > 0),
      ),
    );

    if (defaultBusinessBranchId) {
      const normalizedDefaultBusiness = locationMap.get(defaultBusinessBranchId);
      defaultBusinessBranchId =
        normalizedDefaultBusiness?.location_type !== "warehouse"
          ? normalizedDefaultBusiness?.id?.toString() ?? null
          : null;
    }

    if (defaultBusinessBranchId && !branchOnlyIds.includes(defaultBusinessBranchId)) {
      branchOnlyIds.push(defaultBusinessBranchId);
    }

    if (!defaultBusinessBranchId) {
      defaultBusinessBranchId = branchOnlyIds[0] ?? null;
    }

    // Save warehouse default on users row (FK → warehouses, not OBM)
    const { error: warehouseUpdateError } = await client
      .from("users")
      .update({ default_warehouse_id: defaultWarehouseId ?? null, updated_at: new Date().toISOString() })
      .eq("id", userId);

    if (warehouseUpdateError) {
      throw new Error(`Failed to update default_warehouse_id: ${warehouseUpdateError.message}`);
    }

    const { error: deleteError } = await client
      .from("user_branch_access")
      .delete()
      .eq("org_id", tenant.orgId)
      .eq("user_id", userId);

    if (deleteError) {
      throw new Error(
        `Failed to replace user_branch_access: ${deleteError.message}`,
      );
    }

    if (branchOnlyIds.length > 0) {
      console.log("[UsersService.syncLocationAccess] resolved", {
        orgId: tenant.orgId,
        userId,
        allIds,
        defaultBusinessBranchId,
        defaultWarehouseId,
        branchOnlyIds,
        locations: locations.map((location) => ({
          id: location.id,
          source_id: location.source_id ?? null,
          location_type: location.location_type,
          name: location.name,
        })),
      });

      const { error: insertError } = await client
        .from("user_branch_access")
        .insert(
          branchOnlyIds.map((branchId) => ({
            org_id: tenant.orgId,
            user_id: userId,
            entity_id: branchId,
            is_default_business: branchId === defaultBusinessBranchId,
            is_default_warehouse: false,
          })),
        );

      if (insertError) {
        throw new Error(
          `Failed to insert user_branch_access: ${insertError.message}`,
        );
      }
    }

    return this.buildLocationAccess(tenant, userId);
  }

  async setDefaultBranch(userId: string, entityId: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();

    const { error } = await client
      .from("user_branch_access")
      .update({ is_default_business: false, updated_at: new Date().toISOString() })
      .eq("org_id", tenant.orgId)
      .eq("user_id", userId);

    if (error) {
      throw new Error(`Failed to clear default branch: ${error.message}`);
    }

    const { error: setError } = await client
      .from("user_branch_access")
      .update({ is_default_business: true, updated_at: new Date().toISOString() })
      .eq("org_id", tenant.orgId)
      .eq("user_id", userId)
      .eq("entity_id", entityId);

    if (setError) {
      throw new Error(`Failed to set default branch: ${setError.message}`);
    }

    return { success: true };
  }

  private normalizeAuthUser(
    user: any,
    publicRow: any,
    accessCount: number,
    roleMap: Map<string, any>,
  ) {
    const roleId = this.normalizeRole(
      publicRow?.role ?? user?.user_metadata?.role ?? user?.app_metadata?.role,
    );
    const roleInfo = roleMap.get(roleId) ?? null;

    return {
      id: user?.id ?? publicRow?.id,
      public_user_id: publicRow?.id?.toString() ?? null,
      email: (user?.email ?? publicRow?.email ?? "").toString(),
      name: (
        user?.user_metadata?.full_name ??
        user?.user_metadata?.name ??
        publicRow?.full_name ??
        publicRow?.email ??
        user?.email ??
        ""
      ).toString(),
      full_name: (
        user?.user_metadata?.full_name ??
        user?.user_metadata?.name ??
        publicRow?.full_name ??
        ""
      ).toString(),
      role: roleId,
      role_label: roleInfo?.label ?? (
        /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(roleId)
          ? "Unknown Role"
          : roleId
      ),
      role_is_default: roleInfo?.is_default === true,
      is_active:
        typeof publicRow?.is_active === "boolean"
          ? publicRow.is_active
          : !user?.banned_until,
      created_at: publicRow?.created_at ?? user?.created_at,
      accessible_location_count: accessCount,
      can_assign_branch_access: publicRow != null,
    };
  }

  async findAll(tenantOrOrgId: TenantContext | string, status = "all"): Promise<any[]> {
    const client = this.supabaseService.getClient();
    const tenantCtx = typeof tenantOrOrgId === "string"
      ? { orgId: tenantOrOrgId, entityId: tenantOrOrgId } as TenantContext
      : tenantOrOrgId;
    const [{ data, error }, publicUsers, accessRows, roleMap] =
      await Promise.all([
      client.auth.admin.listUsers({ perPage: 1000 }),
      this.fetchPublicUsers(tenantOrOrgId),
      client
        .from("user_branch_access")
        .select("user_id")
        .eq("entity_id", this.getEntityId(tenantOrOrgId)),
      this.getRoleMap(tenantCtx),
    ]);

    if (error) {
      throw new Error(`Failed to list users: ${error.message}`);
    }
    if (accessRows.error) {
      throw new Error(
        `Failed to fetch user_branch_access: ${accessRows.error.message}`,
      );
    }

    const accessCount = new Map<string, number>();
    for (const row of accessRows.data ?? []) {
      const userId = row.user_id?.toString();
      if (!userId) continue;
      accessCount.set(userId, (accessCount.get(userId) ?? 0) + 1);
    }

    const authUsers = data?.users ?? [];
    const authIds = new Set(authUsers.map((user) => user.id));
    const mergedUsers = [
      ...authUsers.map((user) =>
        this.normalizeAuthUser(
          user,
          publicUsers.get(user.id),
          accessCount.get(user.id) ?? 0,
          roleMap,
        ),
      ),
      ...Array.from(publicUsers.values())
        .filter((row: any) => !authIds.has(row.id))
        .map((row: any) =>
          this.normalizeAuthUser(
            null,
            row,
            accessCount.get(row.id) ?? 0,
            roleMap,
          ),
        ),
    ];

    const normalizedStatus = status.toLowerCase().trim();
    return mergedUsers
      .filter((user) => {
        if (normalizedStatus === "active") return user["is_active"] === true;
        if (normalizedStatus === "inactive") return user["is_active"] !== true;
        return true;
      })
      .sort((a, b) =>
        (a["name"] as string)
          .toLowerCase()
          .localeCompare((b["name"] as string).toLowerCase()),
      );
  }

  async findOne(id: string, tenantOrOrgId: TenantContext | string): Promise<any | null> {
    const client = this.supabaseService.getClient();
    const [{ data, error }, publicUsers, locationAccess, roleMap] =
      await Promise.all([
        client.auth.admin.getUserById(id),
        this.fetchPublicUsers(tenantOrOrgId),
        this.buildLocationAccess(tenantOrOrgId, id),
        this.getRoleMap(typeof tenantOrOrgId === "string" ? { orgId: tenantOrOrgId } as TenantContext : tenantOrOrgId),
      ]);

    const publicRow = publicUsers.get(id);
    if (error && publicRow == null) return null;

    const u = data?.user;
    const meta = u?.user_metadata ?? {};
    const roleId = this.normalizeRole(
      publicRow?.role ?? meta.role ?? u?.app_metadata?.role,
    );
    const roleInfo = roleMap.get(roleId) ?? null;

    return {
      id: id,
      public_user_id: publicRow?.id?.toString() ?? null,
      email: (u?.email ?? publicRow?.email ?? "").toString(),
      name: (
        meta.full_name ??
        meta.name ??
        publicRow?.full_name ??
        u?.email ??
        ""
      ).toString(),
      full_name: (
        meta.full_name ??
        meta.name ??
        publicRow?.full_name ??
        ""
      ).toString(),
      role: roleId,
      role_label: roleInfo?.label ?? roleId,
      role_is_default: roleInfo?.is_default === true,
      is_active:
        typeof publicRow?.is_active === "boolean"
          ? publicRow.is_active
          : !(u?.banned_until != null),
      created_at: publicRow?.created_at ?? u?.created_at,
      can_assign_branch_access: publicRow != null,
      ...locationAccess,
    };
  }

  async findActivities(id: string, tenant: TenantContext): Promise<any[]> {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("audit_logs_all")
      .select(
        "id, created_at, action, table_name, record_pk, actor_name, module_name, old_values, new_values",
      )
      .eq("entity_id", this.getEntityId(tenant))
      .eq("user_id", id)
      .order("created_at", { ascending: false })
      .limit(100);

    if (error) {
      throw new Error(`Failed to fetch user activities: ${error.message}`);
    }

    return data ?? [];
  }

  async getLocationAccess(id: string, tenant: TenantContext) {
    return this.buildLocationAccess(tenant, id);
  }

  async updateLocationAccess(id: string, tenant: TenantContext, dto: any) {
    return this.syncLocationAccess(tenant, id, dto);
  }

  async create(tenant: TenantContext, dto: any) {
    const email = dto?.email?.toString().trim().toLowerCase();
    const fullName =
      dto?.full_name?.toString().trim() || dto?.name?.toString().trim();
    const provisionedUser = await this.provisionManagedUser(tenant, {
      email,
      fullName,
      role: dto?.role,
      publicEntityId: tenant.entityId,
      isActive: true,
    });

    if (dto?.location_access != null) {
      await this.syncLocationAccess(tenant, provisionedUser.id, dto.location_access);
    }

    return this.findOne(provisionedUser.id, tenant);
  }

  async update(id: string, tenant: TenantContext, dto: any, actorUserId?: string) {
    const current = await this.findOne(id, tenant);
    if (!current) {
      throw new Error("User not found");
    }

    const email = dto?.email?.toString().trim().toLowerCase() || current.email;
    const fullName =
      dto?.full_name?.toString().trim() ||
      dto?.name?.toString().trim() ||
      current.full_name ||
      current.name;
    const role = this.normalizeRole(dto?.role ?? current.role);
    if (
      actorUserId &&
      actorUserId === id &&
      dto?.role != null &&
      this.normalizeRole(current.role) !== role
    ) {
      throw new Error("You cannot change your own role");
    }
    const isActive =
      typeof dto?.is_active === "boolean"
        ? dto.is_active
        : current.is_active === true;

    const authRes = await this.supabaseService
      .getClient()
      .auth.admin.updateUserById(id, {
        email,
        ban_duration: isActive ? "none" : "876000h",
        user_metadata: {
          full_name: fullName,
          name: fullName,
          role,
          org_id: tenant.orgId,
          entity_id: tenant.entityId,
        },
        app_metadata: {
          role,
          org_id: tenant.orgId,
          entity_id: tenant.entityId,
        },
      });

    if (authRes.error) {
      throw new Error(`Failed to update user: ${authRes.error.message}`);
    }

    await this.upsertPublicUser(tenant, {
      id,
      email,
      full_name: fullName,
      role,
      is_active: isActive,
    });

    if (dto?.location_access != null) {
      await this.syncLocationAccess(tenant, id, dto.location_access);
    }

    return this.findOne(id, tenant);
  }

  async updateStatus(id: string, tenant: TenantContext, isActive: boolean) {
    const authRes = await this.supabaseService
      .getClient()
      .auth.admin.updateUserById(id, {
        ban_duration: isActive ? "none" : "876000h",
      });

    if (authRes.error) {
      throw new Error(`Failed to update user status: ${authRes.error.message}`);
    }

    const current = await this.findOne(id, tenant);
    if (!current) {
      throw new Error("User not found");
    }

    await this.upsertPublicUser(tenant, {
      id: current.id,
      email: current.email,
      full_name: current.full_name,
      role: current.role,
      is_active: isActive,
    });

    return this.findOne(id, tenant);
  }

  async remove(id: string, tenant: TenantContext) {
    const client = this.supabaseService.getClient();

    const { error: accessError } = await client
      .from("user_branch_access")
      .delete()
      .eq("entity_id", this.getEntityId(tenant))
      .eq("user_id", id);

    if (accessError) {
      throw new Error(
        `Failed to delete user_branch_access: ${accessError.message}`,
      );
    }

    const { error: publicDeleteError } = await client
      .from("users")
      .delete()
      .eq("entity_id", this.getEntityId(tenant))
      .eq("id", id);

    if (publicDeleteError) {
      throw new Error(
        `Failed to delete user row: ${publicDeleteError.message}`,
      );
    }

    const authDelete = await client.auth.admin.deleteUser(id);
    if (authDelete.error) {
      throw new Error(
        `Failed to delete auth user: ${authDelete.error.message}`,
      );
    }

    return { success: true };
  }

  async getRoleCatalog(tenant: TenantContext) {
    const users = await this.findAll(tenant, "all");
    const counts: Record<string, number> = {};
    const roleMap = await this.getRoleMap(tenant);
    for (const user of users) {
      const rawRole = user["role"]?.toString().trim() ?? "";
      const normalizedRole = this.normalizeRole(rawRole);
      const countKey =
        roleMap.has(rawRole) && rawRole.length > 0 ? rawRole : normalizedRole;
      counts[countKey] = (counts[countKey] ?? 0) + 1;
    }

    const mergedRoles = await this.getMergedRoles(tenant);
    return mergedRoles.map((role) => ({
      id: role.id,
      label: role.label,
      description: role.description,
      user_count: counts[role.id.toString().toLowerCase()] ?? 0,
      is_default: role.is_default === true,
      permissions: role.permissions ?? null,
    }));
  }

  async getRole(id: string, tenant: TenantContext) {
    const normalizedId = id.toLowerCase().trim();
    const defaultRole = this.roleCatalog.find((role) => role.id === normalizedId);
    if (defaultRole) {
      if (normalizedId === "admin") {
        return {
          ...defaultRole,
          is_default: true,
          permissions: { full_access: true },
        };
      }

      const storedRole = await this.fetchRoleByLabel(tenant, defaultRole.label);
      return {
        id: defaultRole.id,
        label: defaultRole.label,
        description:
          (storedRole?.description ?? "").toString().trim().length > 0
            ? (storedRole?.description ?? "").toString()
            : defaultRole.description,
        is_default: true,
        permissions:
          storedRole?.permissions != null ? storedRole.permissions : {},
      };
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("roles")
      .select("*")
      .eq("entity_id", this.getEntityId(tenant))
      .eq("id", id)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to fetch role: ${error.message}`);
    }

    if (!data) return null;

    return {
      id: data.id?.toString() ?? "",
      label: (data.label ?? "").toString(),
      description: (data.description ?? "").toString(),
      permissions: data.permissions ?? {},
      is_default: false,
    };
  }

  async createRole(tenant: TenantContext, body: any) {
    const label = body?.label?.toString().trim();
    if (!label) {
      throw new Error("Role label is required");
    }
    if (this.isReservedRoleLabel(label)) {
      throw new Error(
        "Role name is reserved. Admin, HO Admin, and Branch Admin are system roles.",
      );
    }

    const { data: existingRole, error: existingRoleError } = await this.supabaseService
      .getClient()
      .from("roles")
      .select("id")
      .eq("entity_id", this.getEntityId(tenant))
      .ilike("label", label)
      .maybeSingle();

    if (existingRoleError) {
      throw new Error(`Failed to validate role label: ${existingRoleError.message}`);
    }
    if (existingRole?.id) {
      throw new Error("Role label already exists");
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("roles")
      .insert({
        entity_id: tenant.entityId,
        label,
        description: body?.description?.toString().trim() ?? "",
        permissions: body?.permissions ?? {},
        is_active: true,
      })
      .select("*")
      .single();

    if (error) {
      throw new Error(`Failed to create role: ${error.message}`);
    }

    return {
      id: data.id?.toString() ?? "",
      label: (data.label ?? "").toString(),
      description: (data.description ?? "").toString(),
      permissions: data.permissions ?? {},
      is_default: false,
    };
  }

  async updateRole(id: string, tenant: TenantContext, body: any) {
    const normalizedId = id.toLowerCase().trim();
    if (this.reservedRoleIds.has(normalizedId)) {
      throw new Error("Default roles cannot be edited");
    }

    const label = body?.label?.toString().trim();
    if (!label) {
      throw new Error("Role label is required");
    }
    if (this.isReservedRoleLabel(label)) {
      throw new Error(
        "Role name is reserved. Admin, HO Admin, and Branch Admin are system roles.",
      );
    }

    const { data: sameLabelRole, error: sameLabelRoleError } = await this.supabaseService
      .getClient()
      .from("roles")
      .select("id")
      .eq("entity_id", this.getEntityId(tenant))
      .ilike("label", label)
      .maybeSingle();

    if (sameLabelRoleError) {
      throw new Error(`Failed to validate role label: ${sameLabelRoleError.message}`);
    }
    if (sameLabelRole?.id && sameLabelRole.id?.toString() !== id) {
      throw new Error("Role label already exists");
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("roles")
      .update({
        label,
        description: body?.description?.toString().trim() ?? "",
        permissions: body?.permissions ?? {},
        updated_at: new Date().toISOString(),
      })
      .eq("entity_id", this.getEntityId(tenant))
      .eq("id", id)
      .select("*")
      .single();

    if (error) {
      throw new Error(`Failed to update role: ${error.message}`);
    }

    return {
      id: data.id?.toString() ?? "",
      label: (data.label ?? "").toString(),
      description: (data.description ?? "").toString(),
      permissions: data.permissions ?? {},
      is_default: false,
    };
  }

  async deleteRole(id: string, tenant: TenantContext) {
    const normalizedId = id.toLowerCase().trim();
    if (this.reservedRoleIds.has(normalizedId)) {
      throw new Error("Default roles cannot be deleted");
    }

    const client = this.supabaseService.getClient();

    const { data: role, error: roleError } = await client
      .from("roles")
      .select("id, label")
      .eq("entity_id", this.getEntityId(tenant))
      .eq("id", id)
      .maybeSingle();

    if (roleError) {
      throw new Error(`Failed to fetch role: ${roleError.message}`);
    }
    if (!role) {
      throw new Error("Role not found");
    }
    if (this.isReservedRoleLabel(role.label)) {
      throw new Error("Default roles cannot be deleted");
    }

    const { count, error: usersCountError } = await client
      .from("users")
      .select("id", { count: "exact", head: true })
      .eq("entity_id", this.getEntityId(tenant))
      .eq("role", id);

    if (usersCountError) {
      throw new Error(
        `Failed to validate role assignments: ${usersCountError.message}`,
      );
    }
    if ((count ?? 0) > 0) {
      throw new Error(
        "Cannot delete role while users are assigned. Reassign users first.",
      );
    }

    const { error: deleteError } = await client
      .from("roles")
      .delete()
      .eq("entity_id", this.getEntityId(tenant))
      .eq("id", id);

    if (deleteError) {
      throw new Error(`Failed to delete role: ${deleteError.message}`);
    }

    return { success: true };
  }
}
