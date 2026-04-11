import { Injectable } from "@nestjs/common";
import { OutletsService } from "../outlets/outlets.service";
import { SupabaseService } from "../supabase/supabase.service";

// TODO(auth): Once auth is enabled, filter users by org_id from user_metadata
// or app_metadata (set at sign-up). For now auth is disabled so we return all
// users from auth.users unfiltered — the org_id query param is accepted but
// ignored. Re-enable the org filter in findAll() and findOne() when auth lands.

@Injectable()
export class UsersService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly outletsService: OutletsService,
  ) {}

  private readonly roleCatalog = [
    {
      id: "admin",
      label: "Admin",
      description:
        "Unrestricted access to users, settings, and operational data.",
    },
    {
      id: "manager",
      label: "Manager",
      description:
        "Operational access to assigned locations and day-to-day workflows.",
    },
    {
      id: "staff",
      label: "Staff",
      description:
        "Task-oriented access to assigned locations with limited configuration rights.",
    },
  ];

  private async fetchCustomRoles(orgId: string): Promise<any[]> {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("roles")
      .select("*")
      .eq("org_id", orgId)
      .eq("is_active", true)
      .order("label", { ascending: true });

    if (error) {
      throw new Error(`Failed to fetch roles: ${error.message}`);
    }

    return data ?? [];
  }

  private async getMergedRoles(orgId: string) {
    const customRoles = await this.fetchCustomRoles(orgId);
    return [
      ...this.roleCatalog.map((role) => ({
        ...role,
        is_default: true,
        permissions: null,
      })),
      ...customRoles.map((role) => ({
        id: role.id?.toString() ?? "",
        label: (role.label ?? "").toString(),
        description: (role.description ?? "").toString(),
        is_default: false,
        permissions: role.permissions ?? {},
      })),
    ];
  }

  private async getRoleMap(orgId: string): Promise<Map<string, any>> {
    const mergedRoles = await this.getMergedRoles(orgId);
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
          .filter((value): value is string => Boolean(value)),
      ),
    );
  }

  private generateTemporaryPassword() {
    return `Zerpai#${Math.random().toString(36).slice(2, 10)}A1`;
  }

  private async fetchPublicUsers(orgId: string): Promise<Map<string, any>> {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("users")
      .select("*")
      .eq("org_id", orgId);

    if (error) {
      throw new Error(`Failed to fetch users table: ${error.message}`);
    }

    return new Map((data ?? []).map((row: any) => [row.id, row]));
  }

  private async upsertPublicUser(
    orgId: string,
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
          org_id: orgId,
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

  private async fetchAllLocations(orgId: string): Promise<any[]> {
    const locations = await this.outletsService.findAll(orgId);
    return locations.map((location: any) => ({
      id: location.id?.toString() ?? "",
      name: (location.name ?? "").toString(),
      is_active: location.is_active ?? true,
      location_type: (location.location_type ?? "business").toString(),
      parent_outlet_id: location.parent_outlet_id?.toString() ?? null,
      is_primary: location.is_primary ?? false,
    }));
  }

  private async fetchLocationAccessRows(
    orgId: string,
    userId: string,
  ): Promise<any[]> {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("user_branch_access")
      .select("*")
      .eq("org_id", orgId)
      .eq("user_id", userId)
      .order("created_at", { ascending: true });

    if (error) {
      throw new Error(
        `Failed to fetch user_branch_access: ${error.message}`,
      );
    }

    return data ?? [];
  }

  private async buildLocationAccess(orgId: string, userId: string) {
    const [locations, accessRows] = await Promise.all([
      this.fetchAllLocations(orgId),
      this.fetchLocationAccessRows(orgId, userId),
    ]);

    const locationMap = new Map(
      locations.map((location) => [location.id, location]),
    );
    const accessibleLocations = accessRows
      .map((row) => {
        const location = locationMap.get(row.outlet_id);
        if (!location) return null;
        return {
          id: location.id,
          name: location.name,
          location_type: location.location_type,
          is_default_business: row.is_default_business ?? false,
          is_default_warehouse: row.is_default_warehouse ?? false,
          parent_outlet_id: location.parent_outlet_id ?? null,
        };
      })
      .filter((row): row is any => Boolean(row));

    const defaultBusiness = accessibleLocations.find(
      (row) => row.is_default_business,
    );
    const defaultWarehouse = accessibleLocations.find(
      (row) => row.is_default_warehouse,
    );

    return {
      available_locations: locations,
      accessible_locations: accessibleLocations,
      accessible_outlet_ids: accessibleLocations.map((row) => row.id),
      default_business_outlet_id: defaultBusiness?.id ?? null,
      default_business_outlet_name: defaultBusiness?.name ?? null,
      default_warehouse_outlet_id: defaultWarehouse?.id ?? null,
      default_warehouse_outlet_name: defaultWarehouse?.name ?? null,
    };
  }

  private async syncLocationAccess(orgId: string, userId: string, input: any) {
    const outletIds = this.normalizeUuidList(
      input?.accessible_outlet_ids ?? input?.outlet_ids,
    );
    let defaultBusinessOutletId = this.normalizeUuid(
      input?.default_business_outlet_id,
    );
    let defaultWarehouseOutletId = this.normalizeUuid(
      input?.default_warehouse_outlet_id,
    );

    if (
      defaultBusinessOutletId &&
      !outletIds.includes(defaultBusinessOutletId)
    ) {
      outletIds.push(defaultBusinessOutletId);
    }
    if (
      defaultWarehouseOutletId &&
      !outletIds.includes(defaultWarehouseOutletId)
    ) {
      outletIds.push(defaultWarehouseOutletId);
    }

    const client = this.supabaseService.getClient();

    const { error: deleteError } = await client
      .from("user_branch_access")
      .delete()
      .eq("org_id", orgId)
      .eq("user_id", userId);

    if (deleteError) {
      throw new Error(
        `Failed to replace user_branch_access: ${deleteError.message}`,
      );
    }

    if (outletIds.length === 0) {
      return this.buildLocationAccess(orgId, userId);
    }

    const locationMap = new Map(
      (await this.fetchAllLocations(orgId)).map((location) => [
        location.id,
        location,
      ]),
    );

    if (!defaultBusinessOutletId) {
      const businessDefault =
        outletIds.find(
          (id) => locationMap.get(id)?.location_type === "business",
        ) ?? outletIds[0];
      defaultBusinessOutletId = businessDefault ?? null;
    }
    if (!defaultWarehouseOutletId) {
      defaultWarehouseOutletId =
        outletIds.find(
          (id) => locationMap.get(id)?.location_type === "warehouse",
        ) ?? null;
    }

    const { error: insertError } = await client
      .from("user_branch_access")
      .insert(
        outletIds.map((outletId) => ({
          org_id: orgId,
          user_id: userId,
          outlet_id: outletId,
          is_default_business: outletId == defaultBusinessOutletId,
          is_default_warehouse: outletId == defaultWarehouseOutletId,
        })),
      );

    if (insertError) {
      throw new Error(
        `Failed to insert user_branch_access: ${insertError.message}`,
      );
    }

    return this.buildLocationAccess(orgId, userId);
  }

  private normalizeAuthUser(
    user: any,
    publicRow: any,
    accessCount: number,
    roleMap: Map<string, any>,
  ) {
    const roleId = (
      publicRow?.role ??
      user?.user_metadata?.role ??
      user?.app_metadata?.role ??
      "staff"
    ).toString();
    const roleInfo = roleMap.get(roleId) ?? null;

    return {
      id: user?.id ?? publicRow?.id,
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
      role_label: roleInfo?.label ?? roleId,
      role_is_default: roleInfo?.is_default === true,
      is_active:
        typeof publicRow?.is_active === "boolean"
          ? publicRow.is_active
          : !user?.banned_until,
      created_at: publicRow?.created_at ?? user?.created_at,
      accessible_location_count: accessCount,
    };
  }

  async findAll(orgId: string, status = "all"): Promise<any[]> {
    const client = this.supabaseService.getClient();
    const [{ data, error }, publicUsers, accessRows, roleMap] =
      await Promise.all([
      client.auth.admin.listUsers({ perPage: 1000 }),
      this.fetchPublicUsers(orgId),
      client
        .from("user_branch_access")
        .select("user_id")
        .eq("org_id", orgId),
      this.getRoleMap(orgId),
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

  async findOne(id: string, orgId: string): Promise<any | null> {
    const client = this.supabaseService.getClient();
    const [{ data, error }, publicUsers, locationAccess, roleMap] =
      await Promise.all([
        client.auth.admin.getUserById(id),
        this.fetchPublicUsers(orgId),
        this.buildLocationAccess(orgId, id),
        this.getRoleMap(orgId),
      ]);

    const publicRow = publicUsers.get(id);
    if (error && publicRow == null) return null;

    const u = data?.user;
    const meta = u?.user_metadata ?? {};
    const roleId = (
      publicRow?.role ??
      meta.role ??
      u?.app_metadata?.role ??
      "staff"
    ).toString();
    const roleInfo = roleMap.get(roleId) ?? null;

    return {
      id: id,
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
      ...locationAccess,
    };
  }

  async findActivities(id: string, orgId: string): Promise<any[]> {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("audit_logs_all")
      .select(
        "id, created_at, action, table_name, record_pk, actor_name, module_name, old_values, new_values",
      )
      .eq("org_id", orgId)
      .eq("user_id", id)
      .order("created_at", { ascending: false })
      .limit(100);

    if (error) {
      throw new Error(`Failed to fetch user activities: ${error.message}`);
    }

    return data ?? [];
  }

  async getLocationAccess(id: string, orgId: string) {
    return this.buildLocationAccess(orgId, id);
  }

  async updateLocationAccess(id: string, orgId: string, dto: any) {
    return this.syncLocationAccess(orgId, id, dto);
  }

  async create(dto: any) {
    const orgId = this.normalizeUuid(dto?.org_id);
    const email = dto?.email?.toString().trim().toLowerCase();
    const fullName =
      dto?.full_name?.toString().trim() || dto?.name?.toString().trim();
    const role = dto?.role?.toString().trim().toLowerCase() || "staff";

    if (!orgId) {
      throw new Error("org_id is required");
    }
    if (!email) {
      throw new Error("Email address is required");
    }
    if (!fullName) {
      throw new Error("Name is required");
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .auth.admin.createUser({
        email,
        password: this.generateTemporaryPassword(),
        email_confirm: true,
        user_metadata: {
          full_name: fullName,
          name: fullName,
          role,
          org_id: orgId,
        },
        app_metadata: {
          role,
          org_id: orgId,
        },
      });

    if (error || !data.user) {
      throw new Error(
        `Failed to create user: ${error?.message ?? "Unknown error"}`,
      );
    }

    await this.upsertPublicUser(orgId, {
      id: data.user.id,
      email,
      full_name: fullName,
      role,
      is_active: true,
    });

    if (dto?.location_access != null) {
      await this.syncLocationAccess(orgId, data.user.id, dto.location_access);
    }

    return this.findOne(data.user.id, orgId);
  }

  async update(id: string, orgId: string, dto: any) {
    const current = await this.findOne(id, orgId);
    if (!current) {
      throw new Error("User not found");
    }

    const email = dto?.email?.toString().trim().toLowerCase() || current.email;
    const fullName =
      dto?.full_name?.toString().trim() ||
      dto?.name?.toString().trim() ||
      current.full_name ||
      current.name;
    const role = dto?.role?.toString().trim().toLowerCase() || current.role;
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
          org_id: orgId,
        },
        app_metadata: {
          role,
          org_id: orgId,
        },
      });

    if (authRes.error) {
      throw new Error(`Failed to update user: ${authRes.error.message}`);
    }

    await this.upsertPublicUser(orgId, {
      id,
      email,
      full_name: fullName,
      role,
      is_active: isActive,
    });

    if (dto?.location_access != null) {
      await this.syncLocationAccess(orgId, id, dto.location_access);
    }

    return this.findOne(id, orgId);
  }

  async updateStatus(id: string, orgId: string, isActive: boolean) {
    const authRes = await this.supabaseService
      .getClient()
      .auth.admin.updateUserById(id, {
        ban_duration: isActive ? "none" : "876000h",
      });

    if (authRes.error) {
      throw new Error(`Failed to update user status: ${authRes.error.message}`);
    }

    const current = await this.findOne(id, orgId);
    if (!current) {
      throw new Error("User not found");
    }

    await this.upsertPublicUser(orgId, {
      id,
      email: current.email,
      full_name: current.full_name,
      role: current.role,
      is_active: isActive,
    });

    return this.findOne(id, orgId);
  }

  async remove(id: string, orgId: string) {
    const client = this.supabaseService.getClient();

    const { error: accessError } = await client
      .from("user_branch_access")
      .delete()
      .eq("org_id", orgId)
      .eq("user_id", id);

    if (accessError) {
      throw new Error(
        `Failed to delete user_branch_access: ${accessError.message}`,
      );
    }

    const { error: publicDeleteError } = await client
      .from("users")
      .delete()
      .eq("org_id", orgId)
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

  async getRoleCatalog(orgId: string) {
    const users = await this.findAll(orgId, "all");
    const counts: Record<string, number> = {};
    for (const user of users) {
      const role = (user["role"] ?? "staff").toString().toLowerCase();
      counts[role] = (counts[role] ?? 0) + 1;
    }

    const mergedRoles = await this.getMergedRoles(orgId);
    return mergedRoles.map((role) => ({
      id: role.id,
      label: role.label,
      description: role.description,
      user_count: counts[role.id.toString().toLowerCase()] ?? 0,
      is_default: role.is_default === true,
      permissions: role.permissions ?? null,
    }));
  }

  async getRole(id: string, orgId: string) {
    const normalizedId = id.toLowerCase().trim();
    const defaultRole = this.roleCatalog.find((role) => role.id === normalizedId);
    if (defaultRole) {
      return {
        ...defaultRole,
        is_default: true,
        permissions: null,
      };
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("roles")
      .select("*")
      .eq("org_id", orgId)
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

  async createRole(orgId: string, body: any) {
    const label = body?.label?.toString().trim();
    if (!label) {
      throw new Error("Role label is required");
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("roles")
      .insert({
        org_id: orgId,
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

  async updateRole(id: string, orgId: string, body: any) {
    const normalizedId = id.toLowerCase().trim();
    if (this.roleCatalog.some((role) => role.id === normalizedId)) {
      throw new Error("Default roles cannot be edited");
    }

    const label = body?.label?.toString().trim();
    if (!label) {
      throw new Error("Role label is required");
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
      .eq("org_id", orgId)
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
}
