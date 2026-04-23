import {
  Delete,
  Body,
  Controller,
  Get,
  Param,
  Post,
  Put,
  Query,
} from "@nestjs/common";
import { BulkBinActionDto } from "./dto/bulk-bin-action.dto";
import { BulkZoneActionDto } from "./dto/bulk-zone-action.dto";
import { CreateBinDto } from "./dto/create-bin.dto";
import { CreateZoneDto } from "./dto/create-zone.dto";
import { DisableBinLocationsDto } from "./dto/disable-bin-locations.dto";
import { EnsureDefaultZonesDto } from "./dto/ensure-default-zones.dto";
import { UpdateBinDto } from "./dto/update-bin.dto";
import { SettingsZonesService } from "./settings-zones.service";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Controller("zones")
export class SettingsZonesController {
  constructor(private readonly settingsZonesService: SettingsZonesService) {}

  @Get()
  async findAll(
    @Tenant() tenant: TenantContext,
    @Query("branch_id") branchId?: string,
  ) {
    return this.settingsZonesService.findAll(tenant, branchId);
  }

  @Get("counts")
  async getCounts(
    @Tenant() tenant: TenantContext,
    @Query("branch_ids") branchIds: string,
  ) {
    const parsedBranchIds = (branchIds ?? "")
      .split(",")
      .map((value) => value.trim())
      .filter(Boolean);
    return this.settingsZonesService.getCounts(tenant, parsedBranchIds);
  }

  @Post("ensure-defaults")
  async ensureDefaults(
    @Tenant() tenant: TenantContext,
    @Body() body: EnsureDefaultZonesDto,
  ) {
    return this.settingsZonesService.ensureDefaults(tenant, body);
  }

  @Post()
  async create(@Tenant() tenant: TenantContext, @Body() body: CreateZoneDto) {
    return this.settingsZonesService.create(tenant, body);
  }

  @Post("disable")
  async disable(
    @Tenant() tenant: TenantContext,
    @Body() body: DisableBinLocationsDto,
  ) {
    return this.settingsZonesService.disableBinLocations(tenant, body);
  }

  @Get(":zoneId/bins")
  async findBins(
    @Tenant() tenant: TenantContext,
    @Param("zoneId") zoneId: string,
    @Query("page") page?: string,
    @Query("page_size") pageSize?: string,
  ) {
    return this.settingsZonesService.findBins(tenant, zoneId, {
      page: Number.parseInt(page ?? "1", 10),
      pageSize: Number.parseInt(pageSize ?? "100", 10),
    });
  }

  @Post(":zoneId/bins")
  async createBin(
    @Tenant() tenant: TenantContext,
    @Param("zoneId") zoneId: string,
    @Body() body: CreateBinDto,
  ) {
    return this.settingsZonesService.createBin(tenant, zoneId, body);
  }

  @Put("bins/:binId")
  async updateBin(
    @Tenant() tenant: TenantContext,
    @Param("binId") binId: string,
    @Body() body: UpdateBinDto,
  ) {
    return this.settingsZonesService.updateBin(tenant, binId, body);
  }

  @Delete("bins/:binId")
  async deleteBin(
    @Tenant() tenant: TenantContext,
    @Param("binId") binId: string,
  ) {
    return this.settingsZonesService.deleteBin(tenant, binId);
  }

  @Post("bins/bulk-action")
  async bulkAction(@Tenant() tenant: TenantContext, @Body() body: BulkBinActionDto) {
    return this.settingsZonesService.bulkAction(tenant, body);
  }

  @Post("bulk-action")
  async bulkZoneAction(
    @Tenant() tenant: TenantContext,
    @Body() body: BulkZoneActionDto,
  ) {
    return this.settingsZonesService.bulkZoneAction(tenant, body);
  }
}
