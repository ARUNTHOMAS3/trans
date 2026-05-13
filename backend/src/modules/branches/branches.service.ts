import { Inject, Injectable, forwardRef } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { UsersService } from "../users/users.service";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { ResendService } from "../email/resend.service";

@Injectable()
export class BranchesService {
  constructor(
    private readonly supabaseService: SupabaseService,
    @Inject(forwardRef(() => UsersService))
    private readonly usersService: UsersService,
    private readonly resendService: ResendService,
  ) {}

  private generateTemporaryPassword() {
    return "Zabnix@2025";
  }

  private async ensureBranchAdminUser(
    orgId: string,
    email: string,
    fullName: string,
  ): Promise<string> {
    const normalizedEmail = email?.toString().trim().toLowerCase();
    if (!normalizedEmail) {
      throw new Error("Branch email is required to auto-link Branch Admin user");
    }

    const client = this.supabaseService.getClient();
    const { data: existingUser, error: userFindError } = await client
      .from("users")
      .select("id, full_name")
      .eq("email", normalizedEmail)
      .maybeSingle();

    if (userFindError) {
      throw new Error(`Failed to fetch users row by email: ${userFindError.message}`);
    }

    if (existingUser?.id) {
      const userId = existingUser.id.toString();
      const authUpdate = await client.auth.admin.updateUserById(userId, {
        user_metadata: {
          role: "branch_admin",
          org_id: orgId,
          full_name: fullName,
        },
        app_metadata: {
          role: "branch_admin",
          org_id: orgId,
        },
      });
      if (authUpdate.error) {
        throw new Error(
          `Failed to update auth user metadata: ${authUpdate.error.message}`,
        );
      }

      const { error: usersUpdateError } = await client
        .from("users")
        .update({
          full_name: fullName,
          role: "branch_admin",
          is_active: true,
          updated_at: new Date().toISOString(),
        })
        .eq("id", userId);

      if (usersUpdateError) {
        throw new Error(`Failed to update users row: ${usersUpdateError.message}`);
      }

      return userId;
    }

    const authCreate = await client.auth.admin.createUser({
      email: normalizedEmail,
      password: this.generateTemporaryPassword(),
      email_confirm: true,
      user_metadata: {
        full_name: fullName,
        name: fullName,
        role: "branch_admin",
        org_id: orgId,
      },
      app_metadata: {
        role: "branch_admin",
        org_id: orgId,
      },
    });

    if (authCreate.error || !authCreate.data.user?.id) {
      throw new Error(
        `Failed to create Branch Admin auth user: ${authCreate.error?.message ?? "Unknown error"}`,
      );
    }

    const userId = authCreate.data.user.id;
    const { error: usersInsertError } = await client
      .from("users")
      .upsert(
        {
          id: userId,
          email: normalizedEmail,
          full_name: fullName,
          role: "branch_admin",
          is_active: true,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "id" },
      );

    if (usersInsertError) {
      throw new Error(
        `Failed to insert users row for branch admin: ${usersInsertError.message}`,
      );
    }

    return userId;
  }

  private async attachBranchAdminAccess(
    orgId: string,
    branchId: string,
    userId: string,
    roleId: string,
  ) {
    const client = this.supabaseService.getClient();

    const { error: branchAccessError } = await client
      .from("branch_user_access")
      .upsert(
        {
          branch_id: branchId,
          user_id: userId,
          role_id: roleId,
          is_default_branch: true,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "branch_id,user_id" },
      );

    if (branchAccessError) {
      throw new Error(
        `Failed to upsert branch_user_access for branch admin: ${branchAccessError.message}`,
      );
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
          outlet_id: branchId,
          is_default_business: !hasAnyLocation,
          is_default_warehouse: false,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "org_id,user_id,outlet_id" },
      );

    if (locationUpsertError) {
      throw new Error(
        `Failed to upsert user_branch_access for branch admin: ${locationUpsertError.message}`,
      );
    }
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

    const { error } = await client.from("organisation_branch_master").upsert(
      {
        name: branch.name,
        type: "BRANCH",
        ref_id: branch.id,
        parent_id: parentId,
        is_active: branch.is_active ?? true,
      },
      { onConflict: "type,ref_id" },
    );

    if (error) {
      throw new Error(
        `Failed to sync organisation_branch_master BRANCH row: ${error.message}`,
      );
    }
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
    
    // Add reserved role mappings
    roleIdMap.set("Admin", "admin");
    roleIdMap.set("HO Admin", "ho_admin");
    roleIdMap.set("Branch Admin", "branch_admin");

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

    return {
      ...branch,
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

  async findAll(tenantOrOrgId: TenantContext | string) {
    const { orgId } = this.resolveTenant(tenantOrOrgId);
    const { data, error } = await this.supabaseService
      .getClient()
      .from("branches")
      .select(`
        *,
        entity:organisation_branch_master!ref_id(id)
      `)
      .eq("org_id", orgId)
      .order("created_at", { ascending: true });

    if (error) throw new Error(`Failed to fetch branches: ${error.message}`);
    
    // Flatten the entity id for easier consumption
    return (data ?? []).map(branch => ({
      ...branch,
      entity_id: branch.entity?.[0]?.id || null
    }));
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
      const mobileRegex = /^[0-9]{10}$/;
      if (!mobileRegex.test(normalizedPhone)) {
        throw new Error("Phone number must be exactly 10 digits.");
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
    const { data, error } = await this.supabaseService
      .getClient()
      .from("branches")
      .insert({
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
        msme_registration_type:
          dto.msme_registration_type ?? dto.msme_type ?? null,
        msme_number: dto.msme_number ?? null,
        msme_type: dto.msme_type ?? dto.msme_registration_type ?? null,
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

    const { branchAdminRoleId } =
      await this.usersService.ensureCoreDefaultRoles(tenant);

    const branchEmail = dto.email?.toString().trim();
    if (branchEmail) {
      const branchPlace = dto.place?.toString().trim() ?? "";
      const branchName = dto.name?.toString().trim() ?? "";
      const fullName = `${branchPlace} ${branchName}`.trim() || "Branch Admin";

      const branchAdminUserId = await this.ensureBranchAdminUser(
        orgId,
        branchEmail,
        fullName,
      );
      await this.attachBranchAdminAccess(
        orgId,
        data.id,
        branchAdminUserId,
        branchAdminRoleId,
      );

      // Send greeting email via Resend
      try {
        const loginUrl = "https://zerpai--erp.web.app/";
        const defaultPassword = "Zabnix@2025";

        await this.resendService.sendEmail({
          to: branchEmail,
          subject: "Branch Created - Zerpai",
          html: `
            <div style="font-family: sans-serif; line-height: 1.5; color: #333;">
              <h2>Welcome to Zerpai</h2>
              <p>Hello <strong>${fullName}</strong>,</p>
              <p>A new branch has been created and associated with your email ID in Zerpai ERP.</p>
              <div style="background: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0;">
                <p style="margin: 0;"><strong>Branch:</strong> ${branchName}</p>
                <p style="margin: 5px 0;"><strong>Email:</strong> ${branchEmail}</p>
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

    await this.syncOrganisationBranchMasterRow(data);
    await Promise.all([
      this.syncTransactionSeries(tenant.entityId, transactionSeriesIds),
      this.syncLocationUsers(tenant.entityId, locationUsers),
    ]);
    return this.findOne(data.id, tenant);
  }

  async update(id: string, tenant: TenantContext, dto: any) {
    const orgId = tenant.orgId;
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
      const mobileRegex = /^[0-9]{10}$/;
      if (!mobileRegex.test(dto.phone.toString().trim())) {
        throw new Error("Phone number must be exactly 10 digits.");
      }
    }
    for (const field of fields) {
      if (field in dto) payload[field] = dto[field] ?? null;
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
    if ("drug_licence_20" in payload && payload.drug_licence_20 === "") {
      payload.drug_licence_20 = null;
    }
    if ("drug_licence_21" in payload && payload.drug_licence_21 === "") {
      payload.drug_licence_21 = null;
    }
    if ("drug_licence_20b" in payload && payload.drug_licence_20b === "") {
      payload.drug_licence_20b = null;
    }
    if ("drug_licence_21b" in payload && payload.drug_licence_21b === "") {
      payload.drug_licence_21b = null;
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
    await this.syncOrganisationBranchMasterRow(data);

    if ("transaction_series_ids" in dto) {
      await this.syncTransactionSeries(
        tenant.entityId,
        this.normalizeUuidList(dto.transaction_series_ids),
      );
    }

    if ("location_users" in dto) {
      await this.syncLocationUsers(
        tenant.entityId,
        this.normalizeLocationUsers(dto.location_users),
      );
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