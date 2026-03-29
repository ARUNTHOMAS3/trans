import { Injectable } from "@nestjs/common";
import { BranchesService } from "../branches/branches.service";
import { SupabaseService } from "../supabase/supabase.service";
import { WarehousesSettingsService } from "../warehouses-settings/warehouses-settings.service";

type OutletLocationType = "business" | "warehouse";

@Injectable()
export class OutletsService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly branchesService: BranchesService,
    private readonly warehousesSettingsService: WarehousesSettingsService,
  ) {}

  private normalizeUuid(value: unknown): string | null {
    const normalized = value?.toString().trim();
    return normalized ? normalized : null;
  }

  private normalizeLocationType(value: unknown): OutletLocationType {
    return value?.toString().trim().toLowerCase() === "warehouse"
      ? "warehouse"
      : "business";
  }

  private async fetchBranchTransactionSeriesMap(orgId: string, branchIds: string[]) {
    if (branchIds.length === 0) {
      return new Map<string, string[]>();
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("settings_branch_transaction_series")
      .select("branch_id, transaction_series_id")
      .eq("org_id", orgId)
      .in("branch_id", branchIds);

    if (error) {
      throw new Error(
        `Failed to fetch settings_branch_transaction_series: ${error.message}`,
      );
    }

    const seriesMap = new Map<string, string[]>();
    for (const row of data ?? []) {
      const branchId = row.branch_id?.toString();
      const transactionSeriesId = row.transaction_series_id?.toString();
      if (!branchId || !transactionSeriesId) continue;
      const current = seriesMap.get(branchId) ?? [];
      current.push(transactionSeriesId);
      seriesMap.set(branchId, current);
    }
    return seriesMap;
  }

  private mapBranch(branch: any, transactionSeriesIds: string[] = []) {
    return {
      id: branch.id?.toString() ?? "",
      org_id: branch.org_id?.toString() ?? "",
      name: (branch.name ?? "").toString(),
      outlet_code: (branch.branch_code ?? "").toString(),
      gstin: (branch.gstin ?? "").toString(),
      gstin_registration_type: branch.gstin_registration_type ?? null,
      gstin_legal_name: branch.gstin_legal_name ?? null,
      gstin_trade_name: branch.gstin_trade_name ?? null,
      gstin_registered_on: branch.gstin_registered_on ?? null,
      gstin_reverse_charge: branch.gstin_reverse_charge ?? false,
      gstin_import_export: branch.gstin_import_export ?? false,
      gstin_import_export_account_id:
        branch.gstin_import_export_account_id ?? null,
      email: (branch.email ?? "").toString(),
      phone: (branch.phone ?? "").toString(),
      attention: (branch.attention ?? "").toString(),
      address: (branch.address_street_1 ?? "").toString(),
      address2: (branch.address_street_2 ?? "").toString(),
      city: (branch.city ?? "").toString(),
      state: (branch.state ?? "").toString(),
      country: (branch.country ?? "India").toString(),
      pincode: (branch.pincode ?? "").toString(),
      fax: (branch.fax ?? "").toString(),
      website: (branch.website ?? "").toString(),
      is_active: branch.is_active ?? true,
      location_type: "business",
      parent_outlet_id: branch.parent_branch_id?.toString() ?? null,
      logo_url: branch.logo_url ?? null,
      is_primary: !branch.parent_branch_id,
      transaction_series_ids: transactionSeriesIds,
      default_transaction_series_id:
        branch.default_transaction_series_id?.toString() ?? null,
      primary_contact_id: branch.primary_contact_id?.toString() ?? null,
      created_at: branch.created_at ?? null,
      updated_at: branch.updated_at ?? null,
    };
  }

  private mapWarehouse(warehouse: any) {
    return {
      id: warehouse.id?.toString() ?? "",
      org_id: warehouse.org_id?.toString() ?? "",
      name: (warehouse.name ?? "").toString(),
      outlet_code: (warehouse.warehouse_code ?? "").toString(),
      gstin: "",
      gstin_registration_type: null,
      gstin_legal_name: null,
      gstin_trade_name: null,
      gstin_registered_on: null,
      gstin_reverse_charge: false,
      gstin_import_export: false,
      gstin_import_export_account_id: null,
      email: (warehouse.email ?? "").toString(),
      phone: (warehouse.phone ?? "").toString(),
      attention: (warehouse.attention ?? "").toString(),
      address: (warehouse.address_street_1 ?? "").toString(),
      address2: (warehouse.address_street_2 ?? "").toString(),
      city: (warehouse.city ?? "").toString(),
      state: (warehouse.state ?? "").toString(),
      country: (warehouse.country ?? "India").toString(),
      pincode: (warehouse.pincode ?? "").toString(),
      fax: "",
      website: "",
      is_active: warehouse.is_active ?? true,
      location_type: "warehouse",
      parent_outlet_id: warehouse.branch_id?.toString() ?? null,
      logo_url: null,
      is_primary: false,
      transaction_series_ids: [],
      default_transaction_series_id: null,
      primary_contact_id: null,
      customer_id: warehouse.customer_id?.toString() ?? null,
      vendor_id: warehouse.vendor_id?.toString() ?? null,
      created_at: warehouse.created_at ?? null,
      updated_at: warehouse.updated_at ?? null,
    };
  }

  private mapBranchPayload(dto: any) {
    const parentBranchId = this.normalizeUuid(dto.parent_outlet_id);
    return {
      org_id: dto.org_id,
      name: dto.name,
      branch_code: dto.outlet_code ?? null,
      email: dto.email ?? null,
      phone: dto.phone ?? null,
      attention: dto.attention ?? null,
      address_street_1: dto.address ?? null,
      address_street_2: dto.address2 ?? null,
      city: dto.city ?? null,
      state: dto.state ?? null,
      country: dto.country ?? "India",
      pincode: dto.pincode ?? null,
      fax: dto.fax ?? null,
      website: dto.website ?? null,
      gstin: dto.gstin ?? null,
      gstin_registration_type: dto.gstin_registration_type ?? null,
      gstin_legal_name: dto.gstin_legal_name ?? null,
      gstin_trade_name: dto.gstin_trade_name ?? null,
      gstin_registered_on: dto.gstin_registered_on ?? null,
      gstin_reverse_charge: dto.gstin_reverse_charge ?? false,
      gstin_import_export: dto.gstin_import_export ?? false,
      gstin_import_export_account_id:
        dto.gstin_import_export_account_id ??
        dto.gstin_custom_duty_account_id ??
        null,
      gstin_digital_services: dto.gstin_digital_services ?? false,
      logo_url: dto.logo_url ?? null,
      is_child_location: parentBranchId != null,
      parent_branch_id: parentBranchId,
      transaction_series_ids: Array.isArray(dto.transaction_series_ids)
        ? dto.transaction_series_ids
        : [],
      default_transaction_series_id: dto.default_transaction_series_id ?? null,
      location_users: Array.isArray(dto.location_users) ? dto.location_users : [],
      is_active: dto.is_active ?? true,
    };
  }

  private mapWarehousePayload(dto: any) {
    return {
      org_id: dto.org_id,
      name: dto.name,
      warehouse_code: dto.outlet_code ?? null,
      branch_id: this.normalizeUuid(dto.parent_outlet_id),
      customer_id: this.normalizeUuid(dto.customer_id),
      vendor_id: this.normalizeUuid(dto.vendor_id),
      attention: dto.attention ?? null,
      address_street_1: dto.address ?? null,
      address_street_2: dto.address2 ?? null,
      city: dto.city ?? null,
      state: dto.state ?? null,
      pincode: dto.pincode ?? null,
      country: dto.country ?? "India",
      phone: dto.phone ?? null,
      email: dto.email ?? null,
      is_active: dto.is_active ?? true,
    };
  }

  async findAll(orgId: string) {
    const client = this.supabaseService.getClient();
    const [branchesRes, warehousesRes] = await Promise.all([
      client
        .from("settings_branches")
        .select("*")
        .eq("org_id", orgId)
        .order("created_at", { ascending: true }),
      client
        .from("warehouses")
        .select("*")
        .eq("org_id", orgId)
        .order("created_at", { ascending: true }),
    ]);

    if (branchesRes.error) {
      throw new Error(
        `Failed to fetch settings_branches: ${branchesRes.error.message}`,
      );
    }
    if (warehousesRes.error) {
      throw new Error(`Failed to fetch warehouses: ${warehousesRes.error.message}`);
    }

    const branches = branchesRes.data ?? [];
    const warehouses = warehousesRes.data ?? [];
    const branchSeriesMap = await this.fetchBranchTransactionSeriesMap(
      orgId,
      branches.map((branch: any) => branch.id?.toString()).filter(Boolean),
    );

    return [
      ...branches.map((branch: any) =>
        this.mapBranch(branch, branchSeriesMap.get(branch.id?.toString() ?? "") ?? []),
      ),
      ...warehouses.map((warehouse: any) => this.mapWarehouse(warehouse)),
    ].sort((a, b) => {
      const aTime = new Date(a.created_at ?? 0).getTime();
      const bTime = new Date(b.created_at ?? 0).getTime();
      if (aTime !== bTime) return aTime - bTime;
      if (a.location_type !== b.location_type) {
        return a.location_type === "business" ? -1 : 1;
      }
      return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
    });
  }

  async findOne(id: string, orgId: string) {
    const client = this.supabaseService.getClient();
    const { data: branch, error: branchError } = await client
      .from("settings_branches")
      .select("*")
      .eq("id", id)
      .eq("org_id", orgId)
      .maybeSingle();

    if (branchError) {
      throw new Error(
        `Failed to fetch settings_branches row: ${branchError.message}`,
      );
    }
    if (branch) {
      const seriesMap = await this.fetchBranchTransactionSeriesMap(orgId, [id]);
      return this.mapBranch(branch, seriesMap.get(id) ?? []);
    }

    const { data: warehouse, error: warehouseError } = await client
      .from("warehouses")
      .select("*")
      .eq("id", id)
      .eq("org_id", orgId)
      .maybeSingle();

    if (warehouseError) {
      throw new Error(
        `Failed to fetch warehouses row: ${warehouseError.message}`,
      );
    }

    return warehouse ? this.mapWarehouse(warehouse) : null;
  }

  async create(dto: any) {
    const locationType = this.normalizeLocationType(dto.location_type);

    if (locationType === "warehouse") {
      const created = await this.warehousesSettingsService.create(
        this.mapWarehousePayload(dto),
      );
      return this.findOne(created.id, dto.org_id);
    }

    const created = await this.branchesService.create(this.mapBranchPayload(dto));
    return this.findOne(created.id, dto.org_id);
  }

  async update(id: string, orgId: string, dto: any) {
    const existing = await this.findOne(id, orgId);
    if (!existing) {
      throw new Error("Location not found");
    }

    const requestedType = dto.location_type
      ? this.normalizeLocationType(dto.location_type)
      : (existing.location_type as OutletLocationType);

    if (requestedType !== existing.location_type) {
      throw new Error("Changing location type is not supported");
    }

    if (requestedType === "warehouse") {
      await this.warehousesSettingsService.update(
        id,
        orgId,
        this.mapWarehousePayload({ ...dto, org_id: orgId }),
      );
      return this.findOne(id, orgId);
    }

    await this.branchesService.update(
      id,
      orgId,
      this.mapBranchPayload({ ...dto, org_id: orgId }),
    );
    return this.findOne(id, orgId);
  }

  async updateContacts(id: string, orgId: string, dto: any) {
    const existing = await this.findOne(id, orgId);
    if (!existing) {
      throw new Error("Location not found");
    }
    if (existing.location_type !== "warehouse") {
      throw new Error("Associate Contacts is available only for warehouse locations");
    }

    await this.warehousesSettingsService.update(id, orgId, {
      customer_id: this.normalizeUuid(dto.customer_id),
      vendor_id: this.normalizeUuid(dto.vendor_id),
    });
    return this.findOne(id, orgId);
  }

  async remove(id: string, orgId: string) {
    const existing = await this.findOne(id, orgId);
    if (!existing) {
      throw new Error("Location not found");
    }

    if (existing.location_type === "warehouse") {
      return this.warehousesSettingsService.remove(id, orgId);
    }

    return this.branchesService.remove(id, orgId);
  }
}
