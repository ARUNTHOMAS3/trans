import { Inject, Injectable, forwardRef } from "@nestjs/common";
import { randomUUID } from "crypto";
import { SupabaseService } from "../supabase/supabase.service";
import { UsersService } from "../users/users.service";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { ResendService } from "../email/resend.service";
import { R2StorageService } from "../accountant/r2-storage.service";

@Injectable()
export class BranchesService {
  constructor(
    private readonly supabaseService: SupabaseService,
    @Inject(forwardRef(() => UsersService))
    private readonly usersService: UsersService,
    private readonly resendService: ResendService,
    private readonly r2StorageService: R2StorageService,
  ) {}

  private async resolveLogoUrl(keyOrUrl?: string | null): Promise<string | null> {
    if (!keyOrUrl?.trim()) return null;
    const v = keyOrUrl.trim();
    if (v.startsWith("data:")) return v;

    // If it's a full R2 URL (legacy: stored as public URL), extract the key and re-sign.
    // Pattern: https://<account>.r2.cloudflarestorage.com/<bucket>/<key>
    if (v.startsWith("http://") || v.startsWith("https://")) {
      const bucket = process.env.CLOUDFLARE_BUCKET_NAME?.trim();
      if (bucket) {
        const marker = `/${bucket}/`;
        const idx = v.indexOf(marker);
        if (idx !== -1) {
          const key = v.substring(idx + marker.length);
          try {
            return await this.r2StorageService.getPresignedUrl(key);
          } catch {
            return null;
          }
        }
      }
      // Unknown public URL — return as-is (may fail, but nothing we can do)
      return v;
    }

    try {
      return await this.r2StorageService.getPresignedUrl(v);
    } catch {
      return null;
    }
  }

  private async ensureBranchAdminUser(
    orgId: string,
    email: string,
    fullName: string,
  ): Promise<string> {
    const orgEntityId = await this.ensureOrganisationMaster(orgId);
    if (!orgEntityId) {
      throw new Error("ORG entity_id is required to provision Branch Admin user");
    }

    const provisionedUser = await this.usersService.provisionManagedUser(
      {
        orgId,
        entityId: orgEntityId,
        userId: null,
        role: "branch_admin",
      } as TenantContext,
      {
        email,
        fullName,
        role: "branch_admin",
        publicEntityId: orgEntityId,
        isActive: true,
      },
    );

    return provisionedUser.id;
  }

  private deriveLocationPrefix(
    branchType?: unknown,
    branchPlace?: unknown,
    localBodyName?: unknown,
  ): string {
    const type = (branchType?.toString() ?? "").toUpperCase();
    const place = branchPlace?.toString().trim() ?? "";
    const localBody = localBodyName?.toString().trim() ?? "";
    return type === "FOFO" ? (localBody || place) : place;
  }

  private deriveBranchAdminFullName(
    branchName?: unknown,
    branchPlace?: unknown,
    branchType?: unknown,
    localBodyName?: unknown,
  ) {
    const name = branchName?.toString().trim() ?? "";
    const prefix = this.deriveLocationPrefix(branchType, branchPlace, localBodyName);
    return `${prefix} ${name}`.trim() || "Branch Admin";
  }

  private deriveBranchWarehouseName(
    branchPlace?: unknown,
    branchName?: unknown,
    branchType?: unknown,
    localBodyName?: unknown,
  ) {
    const name = branchName?.toString().trim() ?? "";
    const prefix = this.deriveLocationPrefix(branchType, branchPlace, localBodyName);
    return prefix ? `${prefix} ${name}`.trim() : (name || "Store");
  }

  private buildBranchWarehousePayload(
    branch: {
      id: string;
      org_id: string;
      branch_code?: unknown;
      name?: unknown;
      branch_type?: unknown;
      local_body_name?: unknown;
      attention?: unknown;
      street?: unknown;
      place?: unknown;
      city?: unknown;
      state?: unknown;
      phone?: unknown;
      email?: unknown;
      is_active?: unknown;
      pincode?: unknown;
      country?: unknown;
      district_id?: unknown;
      local_body_id?: unknown;
      assembly_id?: unknown;
      ward_id?: unknown;
    },
    branchEntityId: string,
  ) {
    return {
      entity_id: branchEntityId,
      org_id: branch.org_id,
      source_branch_id: branch.id,
      is_default_for_branch: true,
      name: this.deriveBranchWarehouseName(branch.place, branch.name, branch.branch_type, branch.local_body_name),
      warehouse_code: null,
      attention: branch.attention?.toString().trim() || null,
      street: branch.street?.toString().trim() || null,
      place: branch.place?.toString().trim() || null,
      city: branch.city?.toString().trim() || null,
      state: branch.state?.toString().trim() || null,
      phone: branch.phone?.toString().trim() || null,
      email: branch.email?.toString().trim().toLowerCase() || null,
      is_active: branch.is_active ?? true,
      pincode: branch.pincode?.toString().trim() || null,
      country: branch.country?.toString().trim() || "India",
      district_id: this.normalizeUuid(branch.district_id),
      local_body_id: this.normalizeUuid(branch.local_body_id),
      assembly_id: this.normalizeUuid(branch.assembly_id),
      ward_id: this.normalizeUuid(branch.ward_id),
    };
  }

  private async deriveNextWarehouseCode(orgId: string, client: any): Promise<string> {
    const { data } = await client
      .from("warehouses")
      .select("warehouse_code")
      .eq("org_id", orgId)
      .not("warehouse_code", "is", null);

    const codeRx = /^WH-(\d+)$/i;
    let max = 0;
    for (const row of data ?? []) {
      const m = codeRx.exec(row.warehouse_code ?? "");
      if (m) {
        const n = parseInt(m[1], 10);
        if (n > max) max = n;
      }
    }
    return `WH-${String(max + 1).padStart(5, "0")}`;
  }

  private async syncDefaultBranchWarehouse(
    branch: {
      id: string;
      org_id: string;
      branch_code?: unknown;
      name?: unknown;
      branch_type?: unknown;
      attention?: unknown;
      street?: unknown;
      place?: unknown;
      city?: unknown;
      state?: unknown;
      phone?: unknown;
      email?: unknown;
      is_active?: unknown;
      pincode?: unknown;
      country?: unknown;
      district_id?: unknown;
      local_body_id?: unknown;
      assembly_id?: unknown;
      ward_id?: unknown;
    },
    branchEntityId: string,
  ) {
    const client = this.supabaseService.getClient();

    // Resolve local_body_name for display name derivation
    let localBodyName: string | null = null;
    const localBodyId = this.normalizeUuid(branch.local_body_id);
    if (localBodyId) {
      const { data: lb } = await client
        .from("lsgd_local_bodies")
        .select("name")
        .eq("id", localBodyId)
        .maybeSingle();
      localBodyName = lb?.name ?? null;
    }

    const payload = this.buildBranchWarehousePayload(
      { ...branch, local_body_name: localBodyName },
      branchEntityId,
    );
    const { data: canonicalWarehouse, error: fetchError } = await client
      .from("warehouses")
      .select("id")
      .eq("source_branch_id", branch.id)
      .eq("is_default_for_branch", true)
      .maybeSingle();

    if (fetchError) {
      throw new Error(
        `Failed to fetch default branch warehouse: ${fetchError.message}`,
      );
    }

    if (!canonicalWarehouse?.id) {
      const warehouseCode = await this.deriveNextWarehouseCode(branch.org_id, client);
      const { error: createError } = await client
        .from("warehouses")
        .insert({ ...payload, warehouse_code: warehouseCode });
      if (createError) {
        throw new Error(`Failed to create default warehouse: ${createError.message}`);
      }
      return;
    }

    const { error: updateError } = await client
      .from("warehouses")
      .update({
        ...payload,
        updated_at: new Date().toISOString(),
      })
      .eq("id", canonicalWarehouse.id);

    if (updateError) {
      throw new Error(`Failed to update default warehouse: ${updateError.message}`);
    }
  }

  private async attachBranchAdminAccess(
    orgId: string,
    branchEntityId: string,
    userId: string,
    roleId: string,
  ) {
    const client = this.supabaseService.getClient();
    const { data: existingBranchAdmins, error: fetchError } = await client
      .from("branch_user_access")
      .select("user_id")
      .eq("entity_id", branchEntityId)
      .eq("role_id", roleId);

    if (fetchError) {
      throw new Error(
        `Failed to fetch existing branch admin access: ${fetchError.message}`,
      );
    }

    const staleAdminUserIds = Array.from(
      new Set(
        (existingBranchAdmins ?? [])
          .map((row: any) => row.user_id?.toString())
          .filter(
            (value: unknown): value is string =>
              typeof value === "string" && value.length > 0 && value !== userId,
          ),
      ),
    );

    const { error: cleanupError } = await client
      .from("branch_user_access")
      .delete()
      .eq("entity_id", branchEntityId)
      .or(`role_id.eq.${roleId},user_id.eq.${userId}`);

    if (cleanupError) {
      throw new Error(
        `Failed to clean existing branch admin access: ${cleanupError.message}`,
      );
    }

    const { error: branchAccessError } = await client
      .from("branch_user_access")
      .insert({
        entity_id: branchEntityId,
        user_id: userId,
        role_id: roleId,
        is_default_branch: true,
        updated_at: new Date().toISOString(),
      });

    if (branchAccessError) {
      throw new Error(
        `Failed to insert branch_user_access for branch admin: ${branchAccessError.message}`,
      );
    }

    if (staleAdminUserIds.length > 0) {
      const { error: staleLocationCleanupError } = await client
        .from("user_branch_access")
        .delete()
        .eq("org_id", orgId)
        .eq("entity_id", branchEntityId)
        .in("user_id", staleAdminUserIds);

      if (staleLocationCleanupError) {
        throw new Error(
          `Failed to clean stale branch admin user_branch_access: ${staleLocationCleanupError.message}`,
        );
      }
    }

    const { data: existingLocationAccess, error: locationFetchError } =
      await client
        .from("user_branch_access")
        .select("id")
        .eq("user_id", userId)
        .limit(1);

    if (locationFetchError) {
      throw new Error(
        `Failed to fetch user_branch_access rows: ${locationFetchError.message}`,
      );
    }

    const hasAnyLocation = (existingLocationAccess ?? []).length > 0;
    const { error: locationUpsertError } = await client
      .from("user_branch_access")
      .upsert(
        {
          org_id: orgId,
          user_id: userId,
          entity_id: branchEntityId,
          is_default_business: !hasAnyLocation,
          is_default_warehouse: false,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "org_id,user_id,entity_id" },
      );

    if (locationUpsertError) {
      throw new Error(
        `Failed to upsert user_branch_access for branch admin: ${locationUpsertError.message}`,
      );
    }
  }

  private async syncCanonicalBranchAdmin(
    tenant: TenantContext,
    branch: { id: string; org_id: string; email?: unknown; name?: unknown; place?: unknown; branch_type?: unknown; local_body_id?: unknown },
    branchEntityId: string,
  ) {
    const branchEmail = branch.email?.toString().trim().toLowerCase() ?? "";
    if (!branchEmail) {
      return null;
    }

    // Resolve local_body_name for admin name derivation
    let localBodyName: string | null = null;
    const localBodyId = this.normalizeUuid(branch.local_body_id);
    if (localBodyId) {
      const { data: lb } = await this.supabaseService.getClient()
        .from("lsgd_local_bodies")
        .select("name")
        .eq("id", localBodyId)
        .maybeSingle();
      localBodyName = lb?.name ?? null;
    }

    const { branchAdminRoleId } =
      await this.usersService.ensureCoreDefaultRoles(tenant);
    const fullName = this.deriveBranchAdminFullName(branch.name, branch.place, branch.branch_type, localBodyName);
    const branchAdminUserId = await this.ensureBranchAdminUser(
      branch.org_id,
      branchEmail,
      fullName,
    );

    await this.attachBranchAdminAccess(
      branch.org_id,
      branchEntityId,
      branchAdminUserId,
      branchAdminRoleId,
    );

    return {
      branchAdminUserId,
      branchEmail,
      fullName,
    };
  }

  private async ensureOrganisationMaster(orgId: string) {
    const client = this.supabaseService.getClient();
    const normalizedOrgId = this.normalizeUuid(orgId);
    if (!normalizedOrgId) return null;

    const existingRes = await client
      .from("organisation_branch_master")
      .select("id")
      .eq("type", "ORG")
      .eq("ref_id", normalizedOrgId)
      .maybeSingle();

    if (existingRes.error) {
      throw new Error(
        `Failed to fetch organisation_branch_master ORG row: ${existingRes.error.message}`,
      );
    }

    if (existingRes.data?.id) {
      return existingRes.data.id.toString();
    }

    const orgRes = await client
      .from("organization")
      .select("id,name,is_active")
      .eq("id", normalizedOrgId)
      .maybeSingle();

    if (orgRes.error) {
      throw new Error(`Failed to fetch organization row: ${orgRes.error.message}`);
    }

    if (!orgRes.data?.id || !orgRes.data?.name) {
      return null;
    }

    const upsertRes = await client
      .from("organisation_branch_master")
      .upsert(
        {
          name: orgRes.data.name,
          type: "ORG",
          ref_id: orgRes.data.id,
          parent_id: null,
          is_active: orgRes.data.is_active ?? true,
        },
        { onConflict: "type,ref_id" },
      )
      .select("id")
      .single();

    if (upsertRes.error) {
      throw new Error(
        `Failed to upsert organisation_branch_master ORG row: ${upsertRes.error.message}`,
      );
    }

    return upsertRes.data.id?.toString() ?? null;
  }

  private async syncOrganisationBranchMasterRow(branch: {
    id: string;
    org_id: string;
    name: string;
    is_active?: boolean | null;
  }) {
    const client = this.supabaseService.getClient();
    const parentId = await this.ensureOrganisationMaster(branch.org_id);

    const { data, error } = await client
      .from("organisation_branch_master")
      .upsert(
        {
          name: branch.name,
          type: "BRANCH",
          ref_id: branch.id,
          parent_id: parentId,
          is_active: branch.is_active ?? true,
        },
        { onConflict: "type,ref_id" },
      )
      .select("id")
      .single();

    if (error) {
      throw new Error(
        `Failed to sync organisation_branch_master BRANCH row: ${error.message}`,
      );
    }

    return data?.id?.toString() ?? null;
  }

  private async removeOrganisationBranchMasterRow(branchId: string) {
    const { error } = await this.supabaseService
      .getClient()
      .from("organisation_branch_master")
      .delete()
      .eq("type", "BRANCH")
      .eq("ref_id", branchId);

    if (error) {
      throw new Error(
        `Failed to delete organisation_branch_master BRANCH row: ${error.message}`,
      );
    }
  }

  private normalizeBranchType(value: unknown) {
    return value?.toString().trim().toUpperCase() || null;
  }

  private normalizeUuid(value: unknown) {
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

  private normalizeLocationUsers(values: unknown) {
    if (!Array.isArray(values))
      return [] as Array<{
        user_id: string;
        role: string | null;
      }>;

    const seen = new Set<string>();
    return values
      .map((value) => {
        const userId = this.normalizeUuid(value?.user_id);
        if (!userId || seen.has(userId)) return null;
        seen.add(userId);
        const role = value?.role?.toString().trim() || null;
        return { user_id: userId, role };
      })
      .filter(
        (
          value,
        ): value is {
          user_id: string;
          role: string | null;
        } => Boolean(value),
      );
  }

  private parseJsonObject(rawValue?: string | null) {
    if (!rawValue?.trim()) {
      return null as Record<string, any> | null;
    }

    try {
      const parsed = JSON.parse(rawValue);
      return parsed && typeof parsed === "object" && !Array.isArray(parsed)
        ? (parsed as Record<string, any>)
        : null;
    } catch {
      return null;
    }
  }

  private async resolveAssemblyId(
    districtId?: string | null,
    assemblyCodeOrName?: string | null,
  ) {
    // TODO: Re-enable assembly validation once the assemblies_constituencies table is populated.
    return null;
    /*
    const normalizedDistrictId = districtId?.toString().trim();
    const normalizedAssembly = assemblyCodeOrName?.toString().trim();
    if (!normalizedDistrictId || !normalizedAssembly) {
      return null;
    }

    const client = this.supabaseService.getClient();
    const fetchBy = async (column: "code" | "name") => {
      const { data, error } = await client
        .from("assemblies_constituencies")
        .select("id,code,name")
        .eq("district_id", normalizedDistrictId)
        .eq("is_active", true)
        .eq(column, normalizedAssembly)
        .maybeSingle();

      if (error) {
        throw new Error(`Failed to fetch assemblies_constituencies: ${error.message}`);
      }

      return data ?? null;
    };

    return (await fetchBy("code")) ?? (await fetchBy("name"));
    */
  }

  private async hydratePaymentStubAssembly(
    rawAddress?: string | null,
    assemblyId?: string | null,
  ) {
    if (!rawAddress?.trim() || !assemblyId?.trim()) {
      return rawAddress ?? null;
    }

    const parsed = this.parseJsonObject(rawAddress);
    if (!parsed) {
      return rawAddress;
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("assemblies_constituencies")
      .select("id,code,name")
      .eq("id", assemblyId.trim())
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to fetch assemblies_constituencies: ${error.message}`);
    }
    if (!data) {
      return rawAddress;
    }

    parsed["assembly_code"] = data.code ?? parsed["assembly_code"] ?? null;
    parsed["assembly_name"] = data.name ?? parsed["assembly_name"] ?? null;
    return JSON.stringify(parsed);
  }

  private async resolveBranchAccessRoleIds(
    entityId: string,
    locationUsers: Array<{ user_id: string; role: string | null }>,
  ) {
    const roleLabels = Array.from(
      new Set(
        locationUsers
          .map((user) => user.role?.trim())
          .filter((role): role is string => Boolean(role)),
      ),
    );

    if (roleLabels.length === 0) {
      return new Map<string, string | null>();
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("roles")
      .select("id,label")
      .eq("entity_id", entityId)
      .eq("is_active", true)
      .in("label", roleLabels);

    if (error) {
      throw new Error(`Failed to fetch roles: ${error.message}`);
    }

    const roleIdMap = new Map<string, string | null>();
    for (const role of roleLabels) {
      roleIdMap.set(role, null);
    }

    for (const row of data ?? []) {
      const label = row.label?.toString().trim();
      const id = row.id?.toString().trim();
      if (label && id) {
        roleIdMap.set(label, id);
      }
    }

    return roleIdMap;
  }

  private async syncTransactionSeries(
    entityId: string,
    transactionSeriesIds: string[],
  ) {
    const client = this.supabaseService.getClient();

    const { error: deleteError } = await client
      .from("branch_transaction_series")
      .delete()
      .eq("entity_id", entityId);

    if (deleteError) {
      throw new Error(
        `Failed to replace branch_transaction_series: ${deleteError.message}`,
      );
    }

    if (transactionSeriesIds.length === 0) return;

    const { error: insertError } = await client
      .from("branch_transaction_series")
      .insert(
        transactionSeriesIds.map((transactionSeriesId) => ({
          entity_id: entityId,
          transaction_series_id: transactionSeriesId,
        })),
      );

    if (insertError) {
      throw new Error(
        `Failed to insert branch_transaction_series: ${insertError.message}`,
      );
    }
  }

  private async syncLocationUsers(
    entityId: string,
    locationUsers: Array<{ user_id: string; role: string | null }>,
  ) {
    const client = this.supabaseService.getClient();
    const roleIdsByLabel = await this.resolveBranchAccessRoleIds(
      entityId,
      locationUsers,
    );

    const { error: deleteError } = await client
      .from("branch_user_access")
      .delete()
      .eq("entity_id", entityId);

    if (deleteError) {
      throw new Error(
        `Failed to replace branch_user_access: ${deleteError.message}`,
      );
    }

    if (locationUsers.length === 0) return;

    const { error: insertError = null } = await client
      .from("branch_user_access")
      .insert(
        locationUsers.map((user) => ({
          entity_id: entityId,
          user_id: user.user_id,
          role_id: user.role ? roleIdsByLabel.get(user.role) ?? null : null,
        })),
      );

    if (insertError) {
      throw new Error(
        `Failed to insert branch_user_access: ${insertError.message}`,
      );
    }
  }

  private async attachRelations(branch: any) {
    if (!branch?.id) return branch;

    const client = this.supabaseService.getClient();

    // Resolve entity_id for this branch via organisation_branch_master
    const { data: obmRow } = await client
      .from("organisation_branch_master")
      .select("id")
      .eq("ref_id", branch.id)
      .eq("type", "BRANCH")
      .maybeSingle();
    const entityId = obmRow?.id ?? null;

    if (!entityId) {
      return { ...branch, transaction_series_ids: [], location_users: [] };
    }

    const [transactionSeriesRes, locationUsersRes] = await Promise.all([
      client
        .from("branch_transaction_series")
        .select("transaction_series_id")
        .eq("entity_id", entityId),
      client
        .from("branch_user_access")
        .select("user_id, role_id")
        .eq("entity_id", entityId),
    ]);

    if (transactionSeriesRes.error) {
      throw new Error(
        `Failed to fetch branch transaction series: ${transactionSeriesRes.error.message}`,
      );
    }
    if (locationUsersRes.error) {
      throw new Error(
        `Failed to fetch branch user access: ${locationUsersRes.error.message}`,
      );
    }

    const transactionSeriesIds = (transactionSeriesRes.data ?? [])
      .map((row: any) => row.transaction_series_id?.toString())
      .filter((value: unknown): value is string => Boolean(value));

    const assignedUserIds = (locationUsersRes.data ?? [])
      .map((row: any) => row.user_id?.toString())
      .filter((value: unknown): value is string => Boolean(value));
    const assignedRoleIds = (locationUsersRes.data ?? [])
      .map((row: any) => row.role_id?.toString())
      .filter((value: unknown): value is string => typeof value === 'string' && value.length > 0);

    const usersRes = assignedUserIds.length > 0
      ? await client.from("users").select("id,role").in("id", assignedUserIds)
      : { data: [], error: null };

    if (usersRes.error) {
      throw new Error(`Failed to fetch branch users: ${usersRes.error.message}`);
    }

    // Also collect role IDs from the users' default roles
    const userDefaultRoleIds = (usersRes.data ?? [])
      .map((row: any) => row.role?.toString())
      .filter((value: unknown): value is string => typeof value === 'string' && value.length > 0 && 
        !["admin", "ho_admin", "branch_admin"].includes(value));

    const allRoleIds = Array.from(new Set([...assignedRoleIds, ...userDefaultRoleIds]));

    const rolesRes = allRoleIds.length > 0
      ? await client.from("roles").select("id,label").in("id", allRoleIds)
      : { data: [], error: null };

    if (rolesRes.error) {
      throw new Error(`Failed to fetch branch roles: ${rolesRes.error.message}`);
    }

    const roleLabelMap = new Map(
      (rolesRes.data ?? []).map((row: any) => [
        row.id?.toString(),
        row.label?.toString() ?? null,
      ]),
    );

    // Standard labels for reserved roles
    roleLabelMap.set("admin", "Admin");
    roleLabelMap.set("ho_admin", "HO Admin");
    roleLabelMap.set("branch_admin", "Branch Admin");

    const userRoleMap = new Map(
      (usersRes.data ?? []).map((row: any) => {
        const rId = row.role?.toString() ?? null;
        return [
          row.id?.toString(),
          rId ? (roleLabelMap.get(rId) ?? rId) : null,
        ];
      }),
    );

    // Resolve location names in parallel
    const districtId = branch.district_id?.toString().trim();
    const localBodyId = branch.local_body_id?.toString().trim();
    const assemblyId = branch.assembly_id?.toString().trim();
    const wardId = branch.ward_id?.toString().trim();

    const [districtRes, localBodyRes, assemblyRes, wardRes] = await Promise.all([
      districtId
        ? client.from("lsgd_districts").select("name").eq("id", districtId).maybeSingle()
        : Promise.resolve({ data: null }),
      localBodyId
        ? client.from("lsgd_local_bodies").select("name,body_type").eq("id", localBodyId).maybeSingle()
        : Promise.resolve({ data: null }),
      assemblyId
        ? client.from("assemblies_constituencies").select("name").eq("id", assemblyId).maybeSingle()
        : Promise.resolve({ data: null }),
      wardId
        ? client.from("lsgd_wards").select("name,ward_no").eq("id", wardId).maybeSingle()
        : Promise.resolve({ data: null }),
    ]);

    const districtName = (districtRes as any).data?.name ?? null;
    const localBodyName = (localBodyRes as any).data?.name ?? null;
    const localBodyType = (localBodyRes as any).data?.body_type ?? branch.local_body_type ?? null;
    const assemblyName = (assemblyRes as any).data?.name ?? null;
    const wardData = (wardRes as any).data;
    const wardDisplayName = wardData
      ? wardData.ward_no != null
        ? `${wardData.ward_no} - ${wardData.name}`
        : wardData.name
      : null;

    const enrichedBranch = {
      ...branch,
      local_body_name: localBodyName,
    };
    return {
      ...enrichedBranch,
      display_name: this.computeDisplayName(enrichedBranch),
      logo_url: await this.resolveLogoUrl(branch.logo_url),
      district_name: districtName,
      local_body_name: localBodyName,
      local_body_type: localBodyType,
      assembly_name: assemblyName,
      ward_name: wardData?.name ?? null,
      ward_display_name: wardDisplayName,
      payment_stub_address: await this.hydratePaymentStubAssembly(
        branch.payment_stub_address,
        branch.payment_stub_assembly_id,
      ),
      transaction_series_ids: transactionSeriesIds,
      transaction_series_id:
        transactionSeriesIds.length > 0 ? transactionSeriesIds[0] : null,
      location_users: (locationUsersRes.data ?? []).map((row: any) => ({
        user_id: row.user_id?.toString(),
        role:
          roleLabelMap.get(row.role_id?.toString()) ??
          userRoleMap.get(row.user_id?.toString()) ??
          null,
        role_id: row.role_id?.toString() ?? null,
      })),
    };
  }

  async findBusinessTypes(tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("business_types")
      .select("code,label,description,sort_order")
      .eq("is_active", true)
      .order("sort_order", { ascending: true })
      .order("label", { ascending: true });

    if (error) {
      throw new Error(
        `Failed to fetch business_types: ${error.message}`,
      );
    }

    return (data ?? []).map((row: any) => ({
      id: row.code?.toString() ?? "",
      code: row.code?.toString() ?? "",
      label: row.label?.toString() ?? "",
      description: row.description?.toString() ?? "",
      sort_order: row.sort_order ?? 0,
    }));
  }

  async createBusinessType(dto: any) {
    const businessType = this.normalizeBranchType(
      dto.business_type ?? dto.code,
    );
    const label =
      dto.label?.toString().trim() || dto.description?.toString().trim();

    if (!businessType) {
      throw new Error("Business type code is required");
    }
    if (!label) {
      throw new Error("Business type label is required");
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("business_types")
      .insert({
        code: businessType,
        label,
        description: dto.description?.toString().trim() ?? "",
        is_active: true,
      })
      .select("code,label,description,sort_order")
      .single();

    if (error) {
      throw new Error(`Failed to create business type: ${error.message}`);
    }

    return {
      id: data.code?.toString() ?? "",
      code: data.code?.toString() ?? "",
      label: data.label?.toString() ?? "",
      description: data.description?.toString() ?? "",
      sort_order: data.sort_order ?? 0,
    };
  }

  private resolveTenant(tenantOrOrgId: TenantContext | string): {
    orgId: string;
    entityId?: string | null;
  } {
    if (typeof tenantOrOrgId === "string") {
      return { orgId: tenantOrOrgId };
    }
    return { orgId: tenantOrOrgId.orgId, entityId: tenantOrOrgId.entityId };
  }

  private computeDisplayName(branch: {
    name?: unknown;
    place?: unknown;
    branch_type?: unknown;
    local_body_name?: unknown;
  }): string {
    const name = branch.name?.toString().trim() ?? "";
    const place = branch.place?.toString().trim() ?? "";
    const type = (branch.branch_type?.toString() ?? "").toUpperCase();
    const localBody = branch.local_body_name?.toString().trim() ?? "";
    const prefix = type === "FOFO" ? (localBody || place) : place;
    return prefix ? `${prefix} ${name}`.trim() : name;
  }

  async findAll(tenantOrOrgId: TenantContext | string) {
    const { orgId } = this.resolveTenant(tenantOrOrgId);
    const { data, error } = await this.supabaseService
      .getClient()
      .from("branches")
      .select(`
        *,
        entity:organisation_branch_master!ref_id(id),
        local_body:lsgd_local_bodies!local_body_id(name)
      `)
      .eq("org_id", orgId)
      .order("created_at", { ascending: true });

    if (error) throw new Error(`Failed to fetch branches: ${error.message}`);

    return (data ?? []).map((branch: any) => {
      const localBodyName = branch.local_body?.name ?? null;
      const entityId = Array.isArray(branch.entity)
        ? branch.entity[0]?.id
        : branch.entity?.id;
      const enriched = {
        ...branch,
        entity_id: entityId?.toString() ?? null,
        local_body_name: localBodyName,
      };
      return {
        ...enriched,
        display_name: this.computeDisplayName(enriched),
      };
    });
  }

  async findOne(id: string, tenantOrOrgId: TenantContext | string) {
    const { orgId } = this.resolveTenant(tenantOrOrgId);
    const { data, error } = await this.supabaseService
      .getClient()
      .from("branches")
      .select("*")
      .eq("id", id)
      .eq("org_id", orgId)
      .single();

    if (error) return null;
    return this.attachRelations(data);
  }

  async create(dto: any, tenant: TenantContext) {
    const orgId = tenant.orgId;
    const normalizedPhone = dto.phone?.toString().trim();
    if (normalizedPhone) {
      const digitsOnly = normalizedPhone.replace(/\D/g, "");
      if (digitsOnly.length < 10) {
        throw new Error("Phone number must be at least 10 digits.");
      }
    }

    const transactionSeriesIds = this.normalizeUuidList(
      dto.transaction_series_ids,
    );
    const locationUsers = this.normalizeLocationUsers(dto.location_users);
    const hasSeparatePaymentStubAddress =
      dto.has_separate_payment_stub_address ?? false;
    const paymentStubAddress =
      typeof dto.payment_stub_address === "string"
        ? dto.payment_stub_address
        : null;
    const parsedPaymentStubAddress =
      this.parseJsonObject(paymentStubAddress) ?? undefined;
    const assemblyMatch = hasSeparatePaymentStubAddress
      ? await this.resolveAssemblyId(
          parsedPaymentStubAddress?.district_id?.toString(),
          parsedPaymentStubAddress?.assembly_code?.toString() ??
            parsedPaymentStubAddress?.assembly_name?.toString(),
        )
      : null;

    const branchId = randomUUID();
    const branchEntityId = await this.syncOrganisationBranchMasterRow({
      id: branchId,
      org_id: orgId,
      name: dto.name,
      is_active: dto.is_active ?? true,
    });

    const { data, error } = await this.supabaseService
      .getClient()
      .from("branches")
      .insert({
        id: branchId,
        org_id: orgId,
        name: dto.name,
        branch_code: dto.branch_code ?? null,
        branch_type: this.normalizeBranchType(dto.branch_type),
        email: dto.email ?? null,
        phone: dto.phone ?? null,
        website: dto.website ?? null,
        attention: dto.attention ?? null,
        street: dto.street ?? null,
        place: dto.place ?? null,
        city: dto.city ?? null,
        state: dto.state ?? null,
        district_id: this.normalizeUuid(dto.district_id),
        local_body_id: this.normalizeUuid(dto.local_body_id),
        assembly_id: this.normalizeUuid(dto.assembly_id),
        ward_id: this.normalizeUuid(dto.ward_id),
        pincode: dto.pincode ?? null,
        country: dto.country ?? "India",
        is_child_location: dto.is_child_location ?? false,
        parent_branch_id: this.normalizeUuid(dto.parent_branch_id),
        primary_contact_id: this.normalizeUuid(dto.primary_contact_id),
        gstin: dto.gstin ?? null,
        gstin_registration_type: dto.gstin_registration_type ?? null,
        gstin_legal_name: dto.gstin_legal_name ?? null,
        gstin_trade_name: dto.gstin_trade_name ?? null,
        gstin_registered_on: dto.gstin_registered_on ?? null,
        gstin_reverse_charge: dto.gstin_reverse_charge ?? false,
        gstin_import_export: dto.gstin_import_export ?? false,
        gstin_import_export_account_id: this.normalizeUuid(
          dto.gstin_import_export_account_id,
        ),
        gstin_digital_services: dto.gstin_digital_services ?? false,
        gst_treatment: dto.gst_treatment ?? null,
        pan: dto.pan ?? null,
        industry: dto.industry ?? null,
        is_drug_registered: dto.is_drug_registered ?? false,
        drug_licence_type: dto.drug_licence_type ?? null,
        drug_licence_20: dto.drug_licence_20 ?? dto.drug_license_20 ?? null,
        drug_licence_21: dto.drug_licence_21 ?? dto.drug_license_21 ?? null,
        drug_licence_20b:
          dto.drug_licence_20b ?? dto.drug_license_20b ?? null,
        drug_licence_21b:
          dto.drug_licence_21b ?? dto.drug_license_21b ?? null,
        is_fssai_registered: dto.is_fssai_registered ?? false,
        fssai_number: dto.fssai_number ?? null,
        is_msme_registered: dto.is_msme_registered ?? false,
        msme_registration_type: dto.msme_registration_type ?? null,
        msme_number: dto.msme_number ?? null,
        msme_type: dto.msme_type ?? null,
        fiscal_year: dto.fiscal_year ?? null,
        report_basis: dto.report_basis ?? null,
        has_separate_payment_stub_address: hasSeparatePaymentStubAddress,
        payment_stub_address: paymentStubAddress,
        payment_stub_assembly_id: assemblyMatch?.id ?? null,
        logo_url: dto.logo_url ?? null,
        subscription_from: dto.subscription_from ?? null,
        subscription_to: dto.subscription_to ?? null,
        default_transaction_series_id: this.normalizeUuid(
          dto.default_transaction_series_id,
        ),
        is_active: dto.is_active ?? true,
      })
      .select()
      .single();

    if (error) throw new Error(`Failed to create branch: ${error.message}`);

    const branchAdminEmail = data.email?.toString().trim().toLowerCase() ?? "";
    const branchAdminFullName = this.deriveBranchAdminFullName(
      data.name,
      data.place,
    );
    if (branchAdminEmail) {
      // Send greeting email via Resend
      try {
        const loginUrl = "https://zerpai--erp.web.app/";
        const defaultPassword = "Zabnix@2025";

        await this.resendService.sendEmail({
          to: branchAdminEmail,
          subject: "Branch Created - Zerpai",
          html: `
            <div style="font-family: sans-serif; line-height: 1.5; color: #333;">
              <h2>Welcome to Zerpai</h2>
              <p>Hello <strong>${branchAdminFullName}</strong>,</p>
              <p>A new branch has been created and associated with your email ID in Zerpai ERP.</p>
              <div style="background: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0;">
                <p style="margin: 0;"><strong>Branch:</strong> ${data.name ?? ""}</p>
                <p style="margin: 5px 0;"><strong>Email:</strong> ${branchAdminEmail}</p>
                <p style="margin: 0;"><strong>Default Password:</strong> <code style="background: #eee; padding: 2px 4px;">${defaultPassword}</code></p>
              </div>
              <p>You can log in to your account by clicking the button below:</p>
              <p style="margin-top: 25px;">
                <a href="${loginUrl}" style="background-color: #0088FF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold;">Click here to Login</a>
              </p>
              <p style="margin-top: 30px; font-size: 0.9em; color: #777;">
                If the button above doesn't work, copy and paste this URL into your browser:<br>
                <a href="${loginUrl}">${loginUrl}</a>
              </p>
              <hr style="border: 0; border-top: 1px solid #eee; margin: 30px 0;">
              <p style="font-size: 0.8em; color: #999;">This is an automated message, please do not reply.</p>
            </div>
          `,
        });
      } catch (emailError) {
        // We don't want to fail the whole branch creation if email fails, but we should log it
        console.error("Failed to send branch creation email:", emailError);
      }
    }

    await this.syncTransactionSeries(branchEntityId, transactionSeriesIds);
    await this.syncLocationUsers(branchEntityId, locationUsers);
    await this.syncCanonicalBranchAdmin(tenant, data, branchEntityId);
    await this.syncDefaultBranchWarehouse(data, branchEntityId);
    return this.findOne(data.id, tenant);
  }

  async update(id: string, tenant: TenantContext, dto: any) {
    const orgId = tenant.orgId;

    // Capture old email before update to detect changes
    const { data: existingBranch } = await this.supabaseService
      .getClient()
      .from("branches")
      .select(
        "email, name, place, branch_code, attention, street, city, state, phone, pincode, country, district_id, local_body_id, assembly_id, ward_id",
      )
      .eq("id", id)
      .eq("org_id", orgId)
      .single();
    const oldEmail = existingBranch?.email?.toString().trim().toLowerCase() ?? "";

    const fields = [
      "name",
      "branch_code",
      "branch_type",
      "email",
      "phone",
      "website",
      "attention",
      "street",
      "place",
      "city",
      "state",
      "district_id",
      "local_body_id",
      "assembly_id",
      "ward_id",
      "pincode",
      "country",
      "gstin",
      "gstin_registration_type",
      "is_child_location",
      "parent_branch_id",
      "primary_contact_id",
      "gstin_legal_name",
      "gstin_trade_name",
      "gstin_registered_on",
      "gstin_reverse_charge",
      "gstin_import_export",
      "gstin_import_export_account_id",
      "gstin_digital_services",
      "gst_treatment",
      "pan",
      "industry",
      "is_drug_registered",
      "drug_licence_type",
      "drug_licence_20",
      "drug_licence_21",
      "drug_licence_20b",
      "drug_licence_21b",
      "is_fssai_registered",
      "fssai_number",
      "is_msme_registered",
      "msme_registration_type",
      "msme_number",
      "msme_type",
      "fiscal_year",
      "report_basis",
      "has_separate_payment_stub_address",
      "payment_stub_address",
      "logo_url",
      "subscription_from",
      "subscription_to",
      "default_transaction_series_id",
      "is_active",
    ];

    const payload: Record<string, any> = {
      updated_at: new Date().toISOString(),
    };
    if (dto.phone) {
      const digitsOnly = dto.phone.toString().trim().replace(/\D/g, "");
      if (digitsOnly.length < 10) {
        throw new Error("Phone number must be at least 10 digits.");
      }
    }
    for (const field of fields) {
      if (field in dto) {
        payload[field] = dto[field] ?? null;
      }
    }

    if ("branch_type" in payload) {
      payload.branch_type = this.normalizeBranchType(payload.branch_type);
    }
    if ("parent_branch_id" in payload) {
      payload.parent_branch_id = this.normalizeUuid(payload.parent_branch_id);
    }
    if ("primary_contact_id" in payload) {
      payload.primary_contact_id = this.normalizeUuid(
        payload.primary_contact_id,
      );
    }
    if ("district_id" in payload) {
      payload.district_id = this.normalizeUuid(payload.district_id);
    }
    if ("local_body_id" in payload) {
      payload.local_body_id = this.normalizeUuid(payload.local_body_id);
    }
    if ("assembly_id" in payload) {
      payload.assembly_id = this.normalizeUuid(payload.assembly_id);
    }
    if ("ward_id" in payload) {
      payload.ward_id = this.normalizeUuid(payload.ward_id);
    }
    if ("gstin_import_export_account_id" in payload) {
      payload.gstin_import_export_account_id = this.normalizeUuid(
        payload.gstin_import_export_account_id,
      );
    }
    if ("default_transaction_series_id" in payload) {
      payload.default_transaction_series_id = this.normalizeUuid(
        payload.default_transaction_series_id,
      );
    }
    if ("has_separate_payment_stub_address" in payload) {
      payload.has_separate_payment_stub_address = Boolean(
        payload.has_separate_payment_stub_address,
      );
    }
    if (payload.has_separate_payment_stub_address === false) {
      payload.payment_stub_assembly_id = null;
    } else if (typeof payload.payment_stub_address === "string") {
      const parsedAddress = this.parseJsonObject(payload.payment_stub_address);
      const assemblyMatch = await this.resolveAssemblyId(
        parsedAddress?.district_id?.toString(),
        parsedAddress?.assembly_code?.toString() ??
          parsedAddress?.assembly_name?.toString(),
      );
      payload.payment_stub_assembly_id = assemblyMatch?.id ?? null;
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("branches")
      .update(payload)
      .eq("id", id)
      .eq("org_id", orgId)
      .select()
      .single();

    if (error) throw new Error(`Failed to update branch: ${error.message}`);
    const branchEntityId = await this.syncOrganisationBranchMasterRow(data);

    const newEmail = dto.email?.toString().trim().toLowerCase() ?? "";
    if ("transaction_series_ids" in dto) {
      await this.syncTransactionSeries(
        branchEntityId,
        this.normalizeUuidList(dto.transaction_series_ids),
      );
    }

    if ("location_users" in dto) {
      await this.syncLocationUsers(
        branchEntityId,
        this.normalizeLocationUsers(dto.location_users),
      );
    }
    const canonicalBranchAdmin = await this.syncCanonicalBranchAdmin(
      tenant,
      data,
      branchEntityId,
    );
    await this.syncDefaultBranchWarehouse(data, branchEntityId);
    if (canonicalBranchAdmin && newEmail && newEmail !== oldEmail) {
      const loginUrl = "https://zerpai--erp.web.app/";
      const defaultPassword = "Zabnix@2025";
      try {
        await this.resendService.sendEmail({
          to: canonicalBranchAdmin.branchEmail,
          subject: "Branch Email Updated - Zerpai",
          html: `
            <div style="font-family: sans-serif; line-height: 1.5; color: #333;">
              <h2>Branch Email Updated</h2>
              <p>Hello <strong>${canonicalBranchAdmin.fullName}</strong>,</p>
              <p>The email address for your branch in Zerpai ERP has been updated to this address.</p>
              <div style="background: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0;">
                <p style="margin: 0;"><strong>Branch:</strong> ${data.name ?? ""}</p>
                <p style="margin: 5px 0;"><strong>New Email:</strong> ${canonicalBranchAdmin.branchEmail}</p>
                <p style="margin: 0;"><strong>Default Password:</strong> <code style="background: #eee; padding: 2px 4px;">${defaultPassword}</code></p>
              </div>
              <p>You can log in to your account by clicking the button below:</p>
              <p style="margin-top: 25px;">
                <a href="${loginUrl}" style="background-color: #0088FF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold;">Click here to Login</a>
              </p>
              <p style="margin-top: 30px; font-size: 0.9em; color: #777;">
                If the button above doesn't work, copy and paste this URL into your browser:<br>
                <a href="${loginUrl}">${loginUrl}</a>
              </p>
              <hr style="border: 0; border-top: 1px solid #eee; margin: 30px 0;">
              <p style="font-size: 0.8em; color: #999;">This is an automated message, please do not reply.</p>
            </div>
          `,
        });
      } catch (emailError) {
        console.error("Failed to send branch email update notification:", emailError);
      }
    }

    return this.findOne(data.id, tenant);
  }

  async remove(id: string, tenant: TenantContext) {
    const { error } = await this.supabaseService
      .getClient()
      .from("branches")
      .delete()
      .eq("id", id)
      .eq("org_id", tenant.orgId);

    if (error) throw new Error(`Failed to delete branch: ${error.message}`);
    await this.removeOrganisationBranchMasterRow(id);
    return { success: true };
  }
}
