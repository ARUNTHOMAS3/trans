import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";

@Injectable()
export class WarehousesService {
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

    const { data, error } = await this.supabaseService
      .getClient()
      .from(table)
      .select(`id, ${displayField}`)
      .in("id", normalizedIds);

    if (error) {
      throw new Error(`Failed to fetch ${table}: ${error.message}`);
    }

    return new Map(
      (data ?? []).map((row: any) => [
        row.id?.toString() ?? "",
        (row[displayField] ?? "").toString().trim(),
      ]),
    );
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
    };
  }

  async findAll(orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("warehouses")
      .select("*")
      .eq("org_id", orgId)
      .order("created_at", { ascending: true });

    if (error) throw new Error(`Failed to fetch warehouses: ${error.message}`);
    const warehouses = data ?? [];
    const [branchNames, customerNames, vendorNames] = await Promise.all([
      this.fetchNameMap(
        "settings_branches",
        warehouses.map(
          (warehouse: any) => warehouse.branch_id?.toString() ?? "",
        ),
      ),
      this.fetchNameMap(
        "customers",
        warehouses.map(
          (warehouse: any) => warehouse.customer_id?.toString() ?? "",
        ),
        "display_name",
      ),
      this.fetchNameMap(
        "vendors",
        warehouses.map(
          (warehouse: any) => warehouse.vendor_id?.toString() ?? "",
        ),
        "display_name",
      ),
    ]);
    return warehouses.map((warehouse: any) =>
      this.mapWarehouse(warehouse, branchNames, customerNames, vendorNames),
    );
  }

  async findOne(id: string, orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("warehouses")
      .select("*")
      .eq("id", id)
      .eq("org_id", orgId)
      .single();

    if (error) return null;
    const [branchNames, customerNames, vendorNames] = await Promise.all([
      this.fetchNameMap("settings_branches", [
        data.branch_id?.toString() ?? "",
      ]),
      this.fetchNameMap(
        "customers",
        [data.customer_id?.toString() ?? ""],
        "display_name",
      ),
      this.fetchNameMap(
        "vendors",
        [data.vendor_id?.toString() ?? ""],
        "display_name",
      ),
    ]);
    return this.mapWarehouse(data, branchNames, customerNames, vendorNames);
  }

  async create(dto: any) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("warehouses")
      .insert({
        org_id: dto.org_id,
        name: dto.name,
        warehouse_code: dto.warehouse_code ?? null,
        branch_id: this.normalizeUuid(dto.branch_id),
        customer_id: this.normalizeUuid(dto.customer_id),
        vendor_id: this.normalizeUuid(dto.vendor_id),
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
        phone: dto.phone ?? null,
        email: dto.email ?? null,
        is_active: dto.is_active ?? true,
      })
      .select()
      .single();

    if (error) throw new Error(`Failed to create warehouse: ${error.message}`);
    return data;
  }

  async update(id: string, orgId: string, dto: any) {
    const fields = [
      "name",
      "warehouse_code",
      "branch_id",
      "customer_id",
      "vendor_id",
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
      "phone",
      "email",
      "is_active",
    ];

    const payload: Record<string, any> = {
      updated_at: new Date().toISOString(),
    };
    for (const field of fields) {
      if (field in dto) payload[field] = dto[field] ?? null;
    }
    if ("branch_id" in payload) {
      payload.branch_id = this.normalizeUuid(payload.branch_id);
    }
    if ("customer_id" in payload) {
      payload.customer_id = this.normalizeUuid(payload.customer_id);
    }
    if ("vendor_id" in payload) {
      payload.vendor_id = this.normalizeUuid(payload.vendor_id);
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

    const { data, error } = await this.supabaseService
      .getClient()
      .from("warehouses")
      .update(payload)
      .eq("id", id)
      .eq("org_id", orgId)
      .select()
      .single();

    if (error) throw new Error(`Failed to update warehouse: ${error.message}`);
    return data;
  }

  async remove(id: string, orgId: string) {
    const { error } = await this.supabaseService
      .getClient()
      .from("warehouses")
      .delete()
      .eq("id", id)
      .eq("org_id", orgId);

    if (error) throw new Error(`Failed to delete warehouse: ${error.message}`);
    return { success: true };
  }
}
