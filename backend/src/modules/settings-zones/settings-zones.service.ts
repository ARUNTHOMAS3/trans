import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { SupabaseService } from "../supabase/supabase.service";
import { BulkBinActionDto } from "./dto/bulk-bin-action.dto";
import { BulkZoneActionDto } from "./dto/bulk-zone-action.dto";
import { CreateBinDto } from "./dto/create-bin.dto";
import { CreateZoneDto, ZoneLevelInput } from "./dto/create-zone.dto";
import { DisableBinLocationsDto } from "./dto/disable-bin-locations.dto";
import { EnsureDefaultZonesDto } from "./dto/ensure-default-zones.dto";
import { UpdateBinDto } from "./dto/update-bin.dto";
import { TenantContext } from "../../common/middleware/tenant.middleware";

type ZoneStatus = "Active";
type BinStatus = "Active" | "Inactive";

type ZoneLevelRecord = {
  level: number;
  location: string;
  delimiter: string;
  alias_name: string;
  total: number;
};

type WarehouseScope = {
  id: string;
  name: string;
};

type ZoneRow = {
  id: string;
  entity_id: string;
  warehouse_id: string;
  zone_name: string;
  is_active: boolean | null;
  created_at: string | null;
};

type ZoneLevelRow = {
  id: string;
  zone_id: string;
  level_no: number;
  level_name: string | null;
  alias: string | null;
  delimiter: string | null;
  total: number;
};

type BinRow = {
  id: string;
  zone_id: string;
  entity_id: string;
  warehouse_id: string;
  bin_code: string;
  level_path: string | null;
  bin_type: string | null;
  is_active: boolean | null;
  created_at: string | null;
};

@Injectable()
export class SettingsZonesService {
  private static readonly maxLevels = 5;
  private static readonly maxAliasAndDelimiterLength = 50;
  private static readonly defaultZoneNames = new Set([
    "default zone",
    "receiving zone",
    "package zone",
  ]);

  constructor(private readonly supabaseService: SupabaseService) {}

  private get client() {
    return this.supabaseService.getClient();
  }

  private async resolveScopeWarehouses(
    tenant: TenantContext,
    scopeId: string,
    fallbackName?: string,
  ): Promise<WarehouseScope[]> {
    const normalizedId = scopeId?.toString().trim();
    if (!normalizedId) return [];

    const byWarehouseId = await this.client
      .from("warehouses")
      .select("id,name")
      .eq("entity_id", tenant.entityId)
      .eq("id", normalizedId);
    if (byWarehouseId.error) {
      throw new Error(
        `Failed to resolve warehouse scope: ${byWarehouseId.error.message}`,
      );
    }
    if ((byWarehouseId.data ?? []).length > 0) {
      return (byWarehouseId.data ?? []).map((warehouse: any) => ({
        id: warehouse.id.toString(),
        name: (warehouse.name ?? fallbackName ?? "").toString(),
      }));
    }

    const byBranchId = await this.client
      .from("warehouses")
      .select("id,name,is_default_for_branch,created_at")
      .eq("entity_id", tenant.entityId)
      .eq("source_branch_id", normalizedId)
      .order("is_default_for_branch", { ascending: false })
      .order("created_at", { ascending: true });
    if (byBranchId.error) {
      throw new Error(
        `Failed to resolve branch warehouses: ${byBranchId.error.message}`,
      );
    }
    const mappedBranchWarehouses = (byBranchId.data ?? []).map((warehouse: any) => ({
      id: warehouse.id.toString(),
      name: (warehouse.name ?? fallbackName ?? "").toString(),
    }));
    if (mappedBranchWarehouses.length > 0) {
      return mappedBranchWarehouses;
    }

    // Defensive fallback: scope id is a valid branch, but no warehouse is linked to it.
    const branchLookup = await this.client
      .from("branches")
      .select("id,name")
      .eq("org_id", tenant.orgId)
      .eq("id", normalizedId)
      .maybeSingle();
    if (branchLookup.error) {
      throw new Error(
        `Failed to resolve branch scope: ${branchLookup.error.message}`,
      );
    }
    if (branchLookup.data) {
      const branchName = (branchLookup.data.name ?? fallbackName ?? normalizedId)
        .toString()
        .trim();
      throw new BadRequestException(
        `No warehouse linked to branch "${branchName}". Create/link a warehouse for this branch before managing zones.`,
      );
    }

    return mappedBranchWarehouses;
  }

  private async resolveSingleWarehouse(
    tenant: TenantContext,
    scopeId: string,
    fallbackName?: string,
  ): Promise<WarehouseScope> {
    const warehouses = await this.resolveScopeWarehouses(
      tenant,
      scopeId,
      fallbackName,
    );
    if (warehouses.length === 0) {
      throw new BadRequestException(
        "No warehouse found for this location. Create or link a warehouse first.",
      );
    }
    return warehouses[0];
  }

  private async fetchZonesByWarehouseIds(
    tenant: TenantContext,
    warehouseIds: string[],
  ): Promise<ZoneRow[]> {
    if (warehouseIds.length === 0) return [];
    const { data, error } = await this.client
      .from("zone_master")
      .select("id,entity_id,warehouse_id,zone_name,is_active,created_at")
      .eq("entity_id", tenant.entityId)
      .in("warehouse_id", warehouseIds)
      .order("created_at", { ascending: true });
    if (error) {
      throw new Error(`Failed to fetch zones: ${error.message}`);
    }
    return (data ?? []) as ZoneRow[];
  }

  private async fetchZoneLevels(
    zoneIds: string[],
  ): Promise<Map<string, ZoneLevelRecord[]>> {
    const levelMap = new Map<string, ZoneLevelRecord[]>();
    if (zoneIds.length === 0) return levelMap;
    const { data, error } = await this.client
      .from("zone_levels")
      .select("id,zone_id,level_no,level_name,alias,delimiter,total")
      .in("zone_id", zoneIds)
      .order("level_no", { ascending: true });
    if (error) {
      throw new Error(`Failed to fetch zone levels: ${error.message}`);
    }
    for (const row of (data ?? []) as ZoneLevelRow[]) {
      const normalized: ZoneLevelRecord = {
        level: Number(row.level_no ?? 1),
        location: (row.level_name ?? "").toString(),
        delimiter: (row.delimiter ?? "").toString(),
        alias_name: (row.alias ?? "").toString(),
        total: Number(row.total ?? 1),
      };
      const list = levelMap.get(row.zone_id) ?? [];
      list.push(normalized);
      levelMap.set(row.zone_id, list);
    }
    return levelMap;
  }

  private async fetchBinRows(
    zoneIds: string[],
  ): Promise<BinRow[]> {
    if (zoneIds.length === 0) return [];
    const { data, error } = await this.client
      .from("bin_master")
      .select(
        "id,zone_id,entity_id,warehouse_id,bin_code,level_path,bin_type,is_active,created_at",
      )
      .in("zone_id", zoneIds)
      .order("created_at", { ascending: true });
    if (error) {
      throw new Error(`Failed to fetch bins: ${error.message}`);
    }
    return (data ?? []) as BinRow[];
  }

  private async fetchBinCounts(
    zoneIds: string[],
  ): Promise<Map<string, number>> {
    const bins = await this.fetchBinRows(zoneIds);
    const counts = new Map<string, number>();
    for (const bin of bins) {
      counts.set(bin.zone_id, (counts.get(bin.zone_id) ?? 0) + 1);
    }
    return counts;
  }

  async findAll(tenant: TenantContext, scopeId?: string) {
    const normalizedScopeId = scopeId?.toString().trim() || tenant.branchId;
    const scopeWarehouses = await this.resolveScopeWarehouses(
      tenant,
      normalizedScopeId,
    );
    const warehouseIds = scopeWarehouses.map((warehouse) => warehouse.id);
    if (warehouseIds.length === 0) return [];

    const warehouseNameMap = new Map(
      scopeWarehouses.map((warehouse) => [warehouse.id, warehouse.name]),
    );
    const zones = await this.fetchZonesByWarehouseIds(tenant, warehouseIds);
    const zoneIds = zones.map((zone) => zone.id);
    const levelsMap = await this.fetchZoneLevels(zoneIds);
    const binCounts = await this.fetchBinCounts(zoneIds);

    return zones.map((zone) => {
      const levels = levelsMap.get(zone.id) ?? [];
      return this.presentZone(
        zone,
        levels,
        binCounts.get(zone.id) ?? 0,
        warehouseNameMap.get(zone.warehouse_id) ?? "",
      );
    });
  }

  async getCounts(tenant: TenantContext, scopeIds: string[]) {
    const counts: Record<string, number> = {};
    const uniqueScopeIds = Array.from(
      new Set(scopeIds.map((id) => id.trim()).filter(Boolean)),
    );

    for (const scopeId of uniqueScopeIds) {
      const scopeWarehouses = await this.resolveScopeWarehouses(tenant, scopeId);
      const warehouseIds = scopeWarehouses.map((warehouse) => warehouse.id);
      if (warehouseIds.length === 0) {
        counts[scopeId] = 0;
        continue;
      }
      const zones = await this.fetchZonesByWarehouseIds(tenant, warehouseIds);
      counts[scopeId] = zones.length;
    }

    return counts;
  }

  async ensureDefaults(tenant: TenantContext, body: EnsureDefaultZonesDto) {
    const scopeId = body.branch_id;
    const scopeWarehouses = await this.resolveScopeWarehouses(
      tenant,
      scopeId,
      body.branch_name,
    );
    if (scopeWarehouses.length === 0) {
      throw new BadRequestException(
        "No warehouse found for this location. Create or link a warehouse first.",
      );
    }

    for (const warehouse of scopeWarehouses) {
      const existing = await this.fetchZonesByWarehouseIds(tenant, [warehouse.id]);
      if (existing.length > 0) {
        continue;
      }
      const seeded = this.defaultZones(warehouse.id, warehouse.name);
      for (const zoneSeed of seeded) {
        const { data: insertedZone, error: zoneInsertError } = await this.client
          .from("zone_master")
          .insert({
            id: zoneSeed.id,
            entity_id: tenant.entityId,
            warehouse_id: warehouse.id,
            zone_name: zoneSeed.zone_name,
            is_active: true,
          })
          .select("id,entity_id,warehouse_id,zone_name,is_active,created_at")
          .single();
        if (zoneInsertError || !insertedZone) {
          throw new Error(
            `Failed to create default zone: ${zoneInsertError?.message ?? "unknown error"}`,
          );
        }

        if (zoneSeed.levels.length > 0) {
          const { error: levelInsertError } = await this.client
            .from("zone_levels")
            .insert(
              zoneSeed.levels.map((level) => ({
                id: randomUUID(),
                zone_id: insertedZone.id,
                level_no: level.level,
                level_name: level.location,
                alias: level.alias_name,
                delimiter: level.delimiter,
                total: level.total,
              })),
            );
          if (levelInsertError) {
            throw new Error(
              `Failed to create default zone levels: ${levelInsertError.message}`,
            );
          }
        }

        const bins = this.buildZoneBins(
          {
            id: insertedZone.id,
            entity_id: tenant.entityId,
            warehouse_id: warehouse.id,
            zone_name: insertedZone.zone_name,
            is_active: insertedZone.is_active,
            created_at: insertedZone.created_at,
          },
          zoneSeed.levels,
        );
        if (bins.length > 0) {
          const { error: binInsertError } = await this.client
            .from("bin_master")
            .insert(bins);
          if (binInsertError) {
            throw new Error(
              `Failed to create default bins: ${binInsertError.message}`,
            );
          }
        }
      }
    }

    return this.findAll(tenant, scopeId);
  }

  async create(tenant: TenantContext, body: CreateZoneDto) {
    const warehouse = await this.resolveSingleWarehouse(
      tenant,
      body.branch_id,
      body.branch_name,
    );
    const levels = this.normalizeLevels(body.levels);
    this.validateLevels(levels);

    const { data: insertedZone, error: zoneInsertError } = await this.client
      .from("zone_master")
      .insert({
        entity_id: tenant.entityId,
        warehouse_id: warehouse.id,
        zone_name: body.zone_name.trim(),
        is_active: true,
      })
      .select("id,entity_id,warehouse_id,zone_name,is_active,created_at")
      .single();
    if (zoneInsertError || !insertedZone) {
      throw new Error(`Failed to create zone: ${zoneInsertError?.message}`);
    }

    if (levels.length > 0) {
      const { error: levelInsertError } = await this.client.from("zone_levels").insert(
        levels.map((level) => ({
          id: randomUUID(),
          zone_id: insertedZone.id,
          level_no: level.level,
          level_name: level.location,
          alias: level.alias_name,
          delimiter: level.delimiter,
          total: level.total,
        })),
      );
      if (levelInsertError) {
        throw new Error(`Failed to create zone levels: ${levelInsertError.message}`);
      }
    }

    const bins = this.buildZoneBins(
      {
        id: insertedZone.id,
        entity_id: tenant.entityId,
        warehouse_id: warehouse.id,
        zone_name: insertedZone.zone_name,
        is_active: insertedZone.is_active,
        created_at: insertedZone.created_at,
      },
      levels,
    );
    if (bins.length > 0) {
      const { error: binInsertError } = await this.client.from("bin_master").insert(bins);
      if (binInsertError) {
        throw new Error(`Failed to create bins: ${binInsertError.message}`);
      }
    }

    return this.presentZone(
      {
        id: insertedZone.id,
        entity_id: tenant.entityId,
        warehouse_id: warehouse.id,
        zone_name: insertedZone.zone_name,
        is_active: insertedZone.is_active,
        created_at: insertedZone.created_at,
      },
      levels,
      bins.length,
      warehouse.name,
    );
  }

  async disableBinLocations(tenant: TenantContext, body: DisableBinLocationsDto) {
    const scopeWarehouses = await this.resolveScopeWarehouses(
      tenant,
      body.branch_id,
    );
    const warehouseIds = scopeWarehouses.map((warehouse) => warehouse.id);
    if (warehouseIds.length === 0) {
      throw new BadRequestException("Bin locations are not enabled for this location");
    }

    const zones = await this.fetchZonesByWarehouseIds(tenant, warehouseIds);
    if (zones.length === 0) {
      throw new BadRequestException("Bin locations are not enabled for this location");
    }

    const zoneIds = zones.map((zone) => zone.id);
    const bins = await this.fetchBinRows(zoneIds);
    const binIds = bins.map((bin) => bin.id);

    if (binIds.length > 0) {
      const { data: stockRows, error: stockError } = await this.client
        .from("batch_stock_layers")
        .select("bin_id,qty")
        .in("bin_id", binIds)
        .gt("qty", 0);
      if (stockError) {
        throw new Error(
          `Failed to verify bin stock before disable: ${stockError.message}`,
        );
      }
      if ((stockRows ?? []).length > 0) {
        throw new BadRequestException(
          "Cannot disable bin locations while one or more bins still have stock on hand",
        );
      }
    }

    if (zoneIds.length > 0) {
      const { error: levelDeleteError } = await this.client
        .from("zone_levels")
        .delete()
        .in("zone_id", zoneIds);
      if (levelDeleteError) {
        throw new Error(`Failed to remove zone levels: ${levelDeleteError.message}`);
      }

      const { error: binDeleteError } = await this.client
        .from("bin_master")
        .delete()
        .in("zone_id", zoneIds);
      if (binDeleteError) {
        throw new Error(`Failed to remove bins: ${binDeleteError.message}`);
      }

      const { error: zoneDeleteError } = await this.client
        .from("zone_master")
        .delete()
        .eq("entity_id", tenant.entityId)
        .in("id", zoneIds);
      if (zoneDeleteError) {
        throw new Error(`Failed to remove zones: ${zoneDeleteError.message}`);
      }
    }

    return {
      success: true,
      removed_zones: zones.length,
      removed_bins: bins.length,
    };
  }

  async findBins(
    tenant: TenantContext,
    zoneId: string,
    options: { page: number; pageSize: number },
  ) {
    const zone = await this.findZoneOrThrow(zoneId, tenant);
    const levels = await this.fetchLevelsByZone(zone.id);
    const changed = await this.ensureZoneBins(zone, levels);

    const pageSize = [10, 25, 50, 100, 200].includes(options.pageSize)
      ? options.pageSize
      : 100;
    const page = options.page > 0 ? options.page : 1;

    const { data: allBins, error: allBinsError } = await this.client
      .from("bin_master")
      .select(
        "id,zone_id,entity_id,warehouse_id,bin_code,level_path,bin_type,is_active,created_at",
      )
      .eq("zone_id", zone.id)
      .order("created_at", { ascending: true });
    if (allBinsError) {
      throw new Error(`Failed to fetch bins: ${allBinsError.message}`);
    }
    const bins = (allBins ?? []) as BinRow[];
    const totalCount = bins.length;
    const start = (page - 1) * pageSize;
    const pageBins = bins.slice(start, start + pageSize);

    const stockByBin = await this.fetchBinStockMap(pageBins.map((bin) => bin.id));

    const warehouseName = await this.resolveWarehouseName(zone.warehouse_id);

    return {
      zone: this.presentZone(zone, levels, totalCount, warehouseName),
      items: pageBins.map((bin) => this.presentBin(bin, stockByBin.get(bin.id) ?? 0)),
      total_count: totalCount,
      page,
      page_size: pageSize,
      changed,
    };
  }

  async createBin(tenant: TenantContext, zoneId: string, body: CreateBinDto) {
    const zone = await this.findZoneOrThrow(zoneId, tenant);
    const payload = {
      id: randomUUID(),
      entity_id: tenant.entityId,
      warehouse_id: zone.warehouse_id,
      zone_id: zone.id,
      bin_code: body.name.trim(),
      level_path: (body.description ?? "").trim() || null,
      bin_type: null as string | null,
      is_active: true,
    };

    const { data, error } = await this.client
      .from("bin_master")
      .insert(payload)
      .select(
        "id,zone_id,entity_id,warehouse_id,bin_code,level_path,bin_type,is_active,created_at",
      )
      .single();
    if (error || !data) {
      throw new Error(`Failed to create bin: ${error?.message ?? "unknown error"}`);
    }
    return this.presentBin(data as BinRow, 0);
  }

  async updateBin(tenant: TenantContext, binId: string, body: UpdateBinDto) {
    const { data: existing, error: existingError } = await this.client
      .from("bin_master")
      .select(
        "id,zone_id,entity_id,warehouse_id,bin_code,level_path,bin_type,is_active,created_at",
      )
      .eq("id", binId)
      .eq("entity_id", tenant.entityId)
      .maybeSingle();
    if (existingError) {
      throw new Error(`Failed to fetch bin: ${existingError.message}`);
    }
    if (!existing) {
      throw new NotFoundException("Bin not found");
    }

    const updatePayload: Record<string, unknown> = {};
    if (body.name != null) updatePayload.bin_code = body.name.trim();
    if (body.description != null) {
      updatePayload.level_path = body.description.trim() || null;
    }
    if (body.status != null) {
      updatePayload.is_active = body.status === "Active";
    }

    const { data, error } = await this.client
      .from("bin_master")
      .update(updatePayload)
      .eq("id", binId)
      .eq("entity_id", tenant.entityId)
      .select(
        "id,zone_id,entity_id,warehouse_id,bin_code,level_path,bin_type,is_active,created_at",
      )
      .single();
    if (error || !data) {
      throw new Error(`Failed to update bin: ${error?.message ?? "unknown error"}`);
    }
    const stock = await this.fetchBinStockMap([binId]);
    return this.presentBin(data as BinRow, stock.get(binId) ?? 0);
  }

  async deleteBin(tenant: TenantContext, binId: string) {
    const { data, error } = await this.client
      .from("bin_master")
      .delete()
      .eq("id", binId)
      .eq("entity_id", tenant.entityId)
      .select("id");
    if (error) {
      throw new Error(`Failed to delete bin: ${error.message}`);
    }
    if (!data || data.length === 0) {
      throw new NotFoundException("Bin not found");
    }
    return { success: true };
  }

  async bulkAction(tenant: TenantContext, body: BulkBinActionDto) {
    const targetIds = Array.from(
      new Set(body.bin_ids.map((id) => id.trim()).filter(Boolean)),
    );
    if (targetIds.length === 0) {
      throw new NotFoundException("No bins matched the selected action");
    }

    if (body.action === "delete") {
      const { data, error } = await this.client
        .from("bin_master")
        .delete()
        .eq("entity_id", tenant.entityId)
        .in("id", targetIds)
        .select("id");
      if (error) {
        throw new Error(`Failed to delete bins: ${error.message}`);
      }
      if (!data || data.length === 0) {
        throw new NotFoundException("No bins matched the selected action");
      }
      return { success: true };
    }

    const nextStatus = body.action === "mark_active";
    const { data, error } = await this.client
      .from("bin_master")
      .update({ is_active: nextStatus })
      .eq("entity_id", tenant.entityId)
      .in("id", targetIds)
      .select("id");
    if (error) {
      throw new Error(`Failed to update bins: ${error.message}`);
    }
    if (!data || data.length === 0) {
      throw new NotFoundException("No bins matched the selected action");
    }
    return { success: true };
  }

  async bulkZoneAction(tenant: TenantContext, body: BulkZoneActionDto) {
    const targetIds = Array.from(
      new Set(body.zone_ids.map((id) => id.trim()).filter(Boolean)),
    );
    if (targetIds.length === 0) {
      throw new NotFoundException("No zones matched the selected action");
    }

    if (body.action === "mark_inactive") {
      const { data: zones, error: zonesError } = await this.client
        .from("zone_master")
        .select("id,zone_name")
        .eq("entity_id", tenant.entityId)
        .in("id", targetIds);
      if (zonesError) {
        throw new Error(`Failed to validate zones: ${zonesError.message}`);
      }
      const hasDefaultZone = (zones ?? []).some((zone: any) =>
        SettingsZonesService.defaultZoneNames.has(
          (zone.zone_name ?? "").toString().trim().toLowerCase(),
        ),
      );
      if (hasDefaultZone) {
        throw new BadRequestException("Default zone can't be set as inactive");
      }
    }

    const nextStatus = body.action === "mark_active";
    const { data, error } = await this.client
      .from("zone_master")
      .update({ is_active: nextStatus })
      .eq("entity_id", tenant.entityId)
      .in("id", targetIds)
      .select("id");
    if (error) {
      throw new Error(`Failed to update zones: ${error.message}`);
    }
    if (!data || data.length === 0) {
      throw new NotFoundException("No zones matched the selected action");
    }
    return { success: true };
  }

  private normalizeLevels(levels: ZoneLevelInput[]): ZoneLevelRecord[] {
    if (!Array.isArray(levels)) return [];
    return levels.map((level) => ({
      level: Number(level.level),
      location: level.location.trim(),
      delimiter: (level.delimiter ?? "").trim(),
      alias_name: level.alias_name.trim(),
      total: Number(level.total),
    }));
  }

  private validateLevels(levels: ZoneLevelRecord[]): void {
    if (levels.length < 1) {
      throw new BadRequestException("At least one level is required");
    }
    if (levels.length > SettingsZonesService.maxLevels) {
      throw new BadRequestException("A zone can have at most five levels");
    }

    const aliasAndDelimiterLength = levels.reduce(
      (sum, level) => sum + level.alias_name.length + level.delimiter.length,
      0,
    );
    if (
      aliasAndDelimiterLength >
      SettingsZonesService.maxAliasAndDelimiterLength
    ) {
      throw new BadRequestException(
        "The total combined length of the Alias Name and Delimiter fields across all five levels must not exceed 50 characters",
      );
    }
  }

  private buildStructureLayout(levels: ZoneLevelRecord[]): string {
    return levels
      .map(
        (level) =>
          `Level ${level.level}: ${level.location} (${level.alias_name}) Count: ${level.total}`,
      )
      .join(" | ");
  }

  private buildBinName(
    levels: ZoneLevelRecord[],
    indexes: number[],
  ): string {
    return levels
      .map((level, idx) => `${level.alias_name}${indexes[idx]}${level.delimiter}`)
      .join("");
  }

  private isSingleDefaultBinZone(levels: ZoneLevelRecord[]): boolean {
    return levels.length === 1 && levels[0]?.total === 1;
  }

  private buildSingleDefaultBinName(levels: ZoneLevelRecord[]): string {
    const firstLevel = levels[0];
    return firstLevel.location.trim() || firstLevel.alias_name.trim();
  }

  private generateBinNames(levels: ZoneLevelRecord[]): string[] {
    if (this.isSingleDefaultBinZone(levels)) {
      return [this.buildSingleDefaultBinName(levels)];
    }
    const names: string[] = [];
    const visit = (depth: number, indexes: number[]) => {
      if (depth >= levels.length) {
        names.push(this.buildBinName(levels, indexes));
        return;
      }
      for (let count = 1; count <= levels[depth].total; count += 1) {
        visit(depth + 1, [...indexes, count]);
      }
    };
    visit(0, []);
    return names;
  }

  private buildZoneBins(zone: ZoneRow, levels: ZoneLevelRecord[]) {
    return this.generateBinNames(levels).map((name) => ({
      id: randomUUID(),
      entity_id: zone.entity_id,
      warehouse_id: zone.warehouse_id,
      zone_id: zone.id,
      bin_code: name,
      level_path: null as string | null,
      bin_type: null as string | null,
      is_active: true,
    }));
  }

  private presentZone(
    zone: ZoneRow,
    levels: ZoneLevelRecord[],
    binCount: number,
    warehouseName: string,
  ) {
    return {
      id: zone.id,
      branch_id: zone.warehouse_id,
      branch_name: warehouseName,
      zone_name: zone.zone_name,
      status: (zone.is_active ?? true) ? "Active" : "Inactive",
      levels,
      total_bins: binCount,
      structure_layout: this.buildStructureLayout(levels),
      created_at: zone.created_at,
      updated_at: zone.created_at,
    };
  }

  private presentBin(bin: BinRow, stockOnHand = 0) {
    return {
      id: bin.id,
      zone_id: bin.zone_id,
      branch_id: bin.warehouse_id,
      branch_name: "",
      zone_name: "",
      name: bin.bin_code,
      description: bin.level_path ?? "",
      status: (bin.is_active ?? true) ? "Active" : "Inactive",
      stock_on_hand: stockOnHand.toFixed(2),
      created_at: bin.created_at,
      updated_at: bin.created_at,
    };
  }

  private async resolveWarehouseName(warehouseId: string): Promise<string> {
    const { data, error } = await this.client
      .from("warehouses")
      .select("name")
      .eq("id", warehouseId)
      .maybeSingle();
    if (error) {
      throw new Error(`Failed to resolve warehouse name: ${error.message}`);
    }
    return (data?.name ?? "").toString();
  }

  private async fetchLevelsByZone(zoneId: string): Promise<ZoneLevelRecord[]> {
    const map = await this.fetchZoneLevels([zoneId]);
    return map.get(zoneId) ?? [];
  }

  private async findZoneOrThrow(
    zoneId: string,
    tenant: TenantContext,
  ): Promise<ZoneRow> {
    const { data, error } = await this.client
      .from("zone_master")
      .select("id,entity_id,warehouse_id,zone_name,is_active,created_at")
      .eq("id", zoneId)
      .eq("entity_id", tenant.entityId)
      .maybeSingle();
    if (error) {
      throw new Error(`Failed to fetch zone: ${error.message}`);
    }
    if (!data) {
      throw new NotFoundException("Zone not found");
    }
    return data as ZoneRow;
  }

  private async ensureZoneBins(
    zone: ZoneRow,
    levels: ZoneLevelRecord[],
  ): Promise<boolean> {
    const existingBins = await this.fetchBinRows([zone.id]);
    if (existingBins.length > 0) {
      if (this.isSingleDefaultBinZone(levels) && existingBins.length === 1) {
        const expectedName = this.buildSingleDefaultBinName(levels);
        if (existingBins[0].bin_code !== expectedName) {
          const { error } = await this.client
            .from("bin_master")
            .update({ bin_code: expectedName })
            .eq("id", existingBins[0].id);
          if (error) {
            throw new Error(`Failed to normalize default bin name: ${error.message}`);
          }
          return true;
        }
      }
      return false;
    }
    const bins = this.buildZoneBins(zone, levels);
    if (bins.length === 0) return false;
    const { error } = await this.client.from("bin_master").insert(bins);
    if (error) {
      throw new Error(`Failed to generate missing bins: ${error.message}`);
    }
    return true;
  }

  private async fetchBinStockMap(
    binIds: string[],
  ): Promise<Map<string, number>> {
    const stock = new Map<string, number>();
    if (binIds.length === 0) return stock;
    const { data, error } = await this.client
      .from("batch_stock_layers")
      .select("bin_id,qty")
      .in("bin_id", binIds);
    if (error) {
      throw new Error(`Failed to fetch bin stock: ${error.message}`);
    }
    for (const row of data ?? []) {
      const id = row.bin_id?.toString();
      if (!id) continue;
      const qty = Number(row.qty ?? 0);
      stock.set(id, (stock.get(id) ?? 0) + qty);
    }
    return stock;
  }

  private defaultZones(
    warehouseId: string,
    warehouseName: string,
  ): Array<{ id: string; zone_name: string; levels: ZoneLevelRecord[] }> {
    void warehouseName;
    return [
      {
        id: randomUUID(),
        zone_name: "Default Zone",
        levels: [
          {
            level: 1,
            location: "Default Area",
            delimiter: "",
            alias_name: "Default Area",
            total: 1,
          },
        ],
      },
      {
        id: randomUUID(),
        zone_name: "Receiving Zone",
        levels: [
          {
            level: 1,
            location: "Receiving Area",
            delimiter: "",
            alias_name: "Receiving Area",
            total: 1,
          },
        ],
      },
      {
        id: randomUUID(),
        zone_name: "Package Zone",
        levels: [
          {
            level: 1,
            location: "Package Area",
            delimiter: "",
            alias_name: "Package Area",
            total: 1,
          },
        ],
      },
    ];
  }
}
