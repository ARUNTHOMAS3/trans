import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Patch,
  Query,
} from "@nestjs/common";
import { SequencesService } from "./sequences.service";
import { Tenant } from "../common/decorators/tenant.decorator";
import { TenantContext } from "../common/middleware/tenant.middleware";

@Controller("sequences")
export class SequencesController {
  constructor(private readonly sequencesService: SequencesService) {}

  @Get(":module/next")
  async getNext(
    @Param("module") module: string,
    @Tenant() tenant: TenantContext,
    @Query("branchId") branchId?: string,
  ) {
    const resolvedBranchId = branchId || tenant.branchId;

    const formatted = await this.sequencesService.getNextNumberFormatted(
      module,
      tenant,
      resolvedBranchId,
    );
    return { nextNumber: formatted };
  }

  @Get(":module/check-duplicate")
  async checkDuplicate(
    @Param("module") module: string,
    @Query("number") number: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.sequencesService.checkDuplicate(module, number, tenant);
  }

  @Get(":module/settings")
  async getSettings(
    @Param("module") module: string,
    @Tenant() tenant: TenantContext,
    @Query("branchId") branchId?: string,
  ) {
    const resolvedBranchId = branchId || tenant.branchId;

    return this.sequencesService.getSequence(
      module,
      tenant,
      resolvedBranchId,
    );
  }

  @Post(":module/increment")
  async increment(
    @Param("module") module: string,
    @Tenant() tenant: TenantContext,
    @Body() body: { usedNumber?: string; branchId?: string },
  ) {
    const resolvedBranchId = body.branchId || tenant.branchId;

    return this.sequencesService.incrementSequence(
      module,
      tenant,
      body.usedNumber,
      resolvedBranchId,
    );
  }

  @Patch(":module/settings")
  async updateSettings(
    @Param("module") module: string,
    @Tenant() tenant: TenantContext,
    @Body()
    body: {
      prefix?: string;
      nextNumber?: number;
      padding?: number;
      suffix?: string;
      branchId?: string;
    },
  ) {
    const resolvedBranchId = body.branchId || tenant.branchId;

    return this.sequencesService.updateSettings(module, tenant, {
      ...body,
      branchId: resolvedBranchId,
    });
  }
}
