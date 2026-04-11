import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";

@Injectable()
export class SettingsBranchesService {
  constructor(private readonly supabaseService: SupabaseService) {}

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
    orgId: string,
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
      .eq("org_id", orgId)
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
    orgId: string,
    branchId: string,
    transactionSeriesIds: string[],
  ) {
    const client = this.supabaseService.getClient();

    const { error: deleteError } = await client
      .from("branch_transaction_series")
      .delete()
      .eq("org_id", orgId)
      .eq("branch_id", branchId);

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
          org_id: orgId,
          branch_id: branchId,
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
    orgId: string,
    branchId: string,
    locationUsers: Array<{ user_id: string; role: string | null }>,
  ) {
    const client = this.supabaseService.getClient();
    const roleIdsByLabel = await this.resolveBranchAccessRoleIds(
      orgId,
      locationUsers,
    );

    const { error: deleteError } = await client
      .from("branch_user_access")
      .delete()
      .eq("org_id", orgId)
      .eq("branch_id", branchId);

    if (deleteError) {
      throw new Error(
        `Failed to replace branch_user_access: ${deleteError.message}`,
      );
    }

    if (locationUsers.length === 0) return;

    const { error: insertError } = await client
      .from("branch_user_access")
      .insert(
        locationUsers.map((user) => ({
          org_id: orgId,
          branch_id: branchId,
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
    if (!branch?.id || !branch?.org_id) return branch;

    const client = this.supabaseService.getClient();
    const [transactionSeriesRes, locationUsersRes] = await Promise.all([
      client
        .from("branch_transaction_series")
        .select("transaction_series_id")
        .eq("org_id", branch.org_id)
        .eq("branch_id", branch.id),
      client
        .from("branch_user_access")
        .select("user_id, role_id")
        .eq("org_id", branch.org_id)
        .eq("branch_id", branch.id),
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
      .filter((value: unknown): value is string => Boolean(value));

    const [usersRes, rolesRes] = await Promise.all([
      assignedUserIds.length > 0
        ? client.from("users").select("id,role").in("id", assignedUserIds)
        : Promise.resolve({ data: [], error: null }),
      assignedRoleIds.length > 0
        ? client
            .from("roles")
            .select("id,label")
            .eq("org_id", branch.org_id)
            .in("id", assignedRoleIds)
        : Promise.resolve({ data: [], error: null }),
    ]);

    if (usersRes.error) {
      throw new Error(`Failed to fetch branch users: ${usersRes.error.message}`);
    }
    if (rolesRes.error) {
      throw new Error(`Failed to fetch branch roles: ${rolesRes.error.message}`);
    }

    const userRoleMap = new Map(
      (usersRes.data ?? []).map((row: any) => [
        row.id?.toString(),
        row.role?.toString() ?? null,
      ]),
    );
    const roleLabelMap = new Map(
      (rolesRes.data ?? []).map((row: any) => [
        row.id?.toString(),
        row.label?.toString() ?? null,
      ]),
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

  async findBusinessTypes(_orgId: string) {
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

  async findAll(orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("settings_branches")
      .select("*")
      .eq("org_id", orgId)
      .order("created_at", { ascending: true });

    if (error)
      throw new Error(`Failed to fetch settings_branches: ${error.message}`);
    return data ?? [];
  }

  async findOne(id: string, orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("settings_branches")
      .select("*")
      .eq("id", id)
      .eq("org_id", orgId)
      .single();

    if (error) return null;
    return this.attachRelations(data);
  }

  async create(dto: any) {
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
      .from("settings_branches")
      .insert({
        org_id: dto.org_id,
        name: dto.name,
        branch_code: dto.branch_code ?? null,
        branch_type: this.normalizeBranchType(dto.branch_type),
        email: dto.email ?? null,
        phone: dto.phone ?? null,
        website: dto.website ?? null,
        attention: dto.attention ?? null,
        address_street_1: dto.address_street_1 ?? null,
        address_street_2: dto.address_street_2 ?? null,
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
    await Promise.all([
      this.syncTransactionSeries(dto.org_id, data.id, transactionSeriesIds),
      this.syncLocationUsers(dto.org_id, data.id, locationUsers),
    ]);
    return this.findOne(data.id, dto.org_id);
  }

  async update(id: string, orgId: string, dto: any) {
    const fields = [
      "name",
      "branch_code",
      "branch_type",
      "email",
      "phone",
      "website",
      "attention",
      "address_street_1",
      "address_street_2",
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
      .from("settings_branches")
      .update(payload)
      .eq("id", id)
      .eq("org_id", orgId)
      .select()
      .single();

    if (error) throw new Error(`Failed to update branch: ${error.message}`);

    if ("transaction_series_ids" in dto) {
      await this.syncTransactionSeries(
        orgId,
        id,
        this.normalizeUuidList(dto.transaction_series_ids),
      );
    }

    if ("location_users" in dto) {
      await this.syncLocationUsers(
        orgId,
        id,
        this.normalizeLocationUsers(dto.location_users),
      );
    }

    return this.findOne(data.id, orgId);
  }

  async remove(id: string, orgId: string) {
    const { error } = await this.supabaseService
      .getClient()
      .from("settings_branches")
      .delete()
      .eq("id", id)
      .eq("org_id", orgId);

    if (error) throw new Error(`Failed to delete branch: ${error.message}`);
    return { success: true };
  }
}
