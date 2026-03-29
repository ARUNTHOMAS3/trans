import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";

const DEFAULT_BRANCH_TYPES = [
  {
    business_type: "FOFO",
    description: "Franchise Owned Franchise Operated",
  },
  {
    business_type: "COCO",
    description: "Company Owned Company Operated",
  },
  {
    business_type: "FICO",
    description: "Franchise Invested Company Operated",
  },
  {
    business_type: "FOCO",
    description: "Franchise Owned Company Operated",
  },
];

@Injectable()
export class BranchesService {
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
    if (!Array.isArray(values)) return [] as Array<{
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

  private async syncTransactionSeries(
    orgId: string,
    branchId: string,
    transactionSeriesIds: string[],
  ) {
    const client = this.supabaseService.getClient();

    const { error: deleteError } = await client
      .from("settings_branch_transaction_series")
      .delete()
      .eq("org_id", orgId)
      .eq("branch_id", branchId);

    if (deleteError) {
      throw new Error(
        `Failed to replace settings_branch_transaction_series: ${deleteError.message}`,
      );
    }

    if (transactionSeriesIds.length === 0) return;

    const { error: insertError } = await client
      .from("settings_branch_transaction_series")
      .insert(
        transactionSeriesIds.map((transactionSeriesId) => ({
          org_id: orgId,
          branch_id: branchId,
          transaction_series_id: transactionSeriesId,
        })),
      );

    if (insertError) {
      throw new Error(
        `Failed to insert settings_branch_transaction_series: ${insertError.message}`,
      );
    }
  }

  private async syncLocationUsers(
    orgId: string,
    branchId: string,
    locationUsers: Array<{ user_id: string; role: string | null }>,
  ) {
    const client = this.supabaseService.getClient();

    const { error: deleteError } = await client
      .from("settings_branch_users")
      .delete()
      .eq("org_id", orgId)
      .eq("branch_id", branchId);

    if (deleteError) {
      throw new Error(
        `Failed to replace settings_branch_users: ${deleteError.message}`,
      );
    }

    if (locationUsers.length === 0) return;

    const { error: insertError } = await client
      .from("settings_branch_users")
      .insert(
        locationUsers.map((user) => ({
          org_id: orgId,
          branch_id: branchId,
          user_id: user.user_id,
          role: user.role,
        })),
      );

    if (insertError) {
      throw new Error(
        `Failed to insert settings_branch_users: ${insertError.message}`,
      );
    }
  }

  private async attachRelations(branch: any) {
    if (!branch?.id || !branch?.org_id) return branch;

    const client = this.supabaseService.getClient();
    const [transactionSeriesRes, locationUsersRes] = await Promise.all([
      client
        .from("settings_branch_transaction_series")
        .select("transaction_series_id")
        .eq("org_id", branch.org_id)
        .eq("branch_id", branch.id),
      client
        .from("settings_branch_users")
        .select("user_id, role")
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
        `Failed to fetch branch users: ${locationUsersRes.error.message}`,
      );
    }

    const transactionSeriesIds = (transactionSeriesRes.data ?? [])
      .map((row: any) => row.transaction_series_id?.toString())
      .filter((value: unknown): value is string => Boolean(value));

    return {
      ...branch,
      transaction_series_ids: transactionSeriesIds,
      transaction_series_id:
        transactionSeriesIds.length > 0 ? transactionSeriesIds[0] : null,
      location_users: (locationUsersRes.data ?? []).map((row: any) => ({
        user_id: row.user_id?.toString(),
        role: row.role?.toString() ?? null,
      })),
    };
  }

  async findBusinessTypes(orgId: string) {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("settings_branch_types")
      .select("*")
      .eq("org_id", orgId)
      .eq("is_active", true)
      .order("business_type", { ascending: true });

    if (error) {
      throw new Error(`Failed to fetch settings_branch_types: ${error.message}`);
    }

    if ((data ?? []).length > 0) {
      return data;
    }

    const { data: seeded, error: seedError } = await client
      .from("settings_branch_types")
      .insert(
        DEFAULT_BRANCH_TYPES.map((type) => ({
          org_id: orgId,
          business_type: type.business_type,
          description: type.description,
          is_active: true,
        })),
      )
      .select("*");

    if (seedError) {
      throw new Error(
        `Failed to seed settings_branch_types: ${seedError.message}`,
      );
    }

    return seeded ?? [];
  }

  async createBusinessType(dto: any) {
    const businessType = this.normalizeBranchType(dto.business_type);
    const description = dto.description?.toString().trim();

    const { data, error } = await this.supabaseService
      .getClient()
      .from("settings_branch_types")
      .insert({
        org_id: dto.org_id,
        business_type: businessType,
        description,
        is_active: true,
      })
      .select("*")
      .single();

    if (error) {
      throw new Error(`Failed to create business type: ${error.message}`);
    }

    return data;
  }

  async findAll(orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("settings_branches")
      .select("*")
      .eq("org_id", orgId)
      .order("created_at", { ascending: true });

    if (error) throw new Error(`Failed to fetch settings_branches: ${error.message}`);
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
        fax: dto.fax ?? null,
        website: dto.website ?? null,
        attention: dto.attention ?? null,
        address_street_1: dto.address_street_1 ?? null,
        address_street_2: dto.address_street_2 ?? null,
        city: dto.city ?? null,
        state: dto.state ?? null,
        district_id: this.normalizeUuid(dto.district_id),
        local_body_id: this.normalizeUuid(dto.local_body_id),
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
      "name", "branch_code", "branch_type",
      "email", "phone", "fax", "website",
      "attention", "address_street_1", "address_street_2",
      "city", "state", "district_id", "local_body_id", "ward_id", "pincode", "country",
      "gstin", "gstin_registration_type",
      "is_child_location", "parent_branch_id", "primary_contact_id",
      "gstin_legal_name", "gstin_trade_name", "gstin_registered_on",
      "gstin_reverse_charge", "gstin_import_export",
      "gstin_import_export_account_id", "gstin_digital_services",
      "logo_url", "subscription_from", "subscription_to",
      "default_transaction_series_id",
      "is_active",
    ];

    const payload: Record<string, any> = { updated_at: new Date().toISOString() };
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
