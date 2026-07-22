import { Body, Controller, Delete, Get, Param, Patch, Post } from "@nestjs/common";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { SettingsCustomizationService } from "./settings-customization.service";

@Controller("settings-customization")
export class SettingsCustomizationController {
  constructor(private readonly service: SettingsCustomizationService) {}

  @Get("reporting-tags")
  getReportingTags(@Tenant() tenant: TenantContext) {
    return this.service.getReportingTags(tenant);
  }

  @Post("reporting-tags")
  createReportingTag(@Body() body: any, @Tenant() tenant: TenantContext) {
    return this.service.createReportingTag(body, tenant);
  }

  @Patch("reporting-tags/:id")
  updateReportingTag(@Param("id") id: string, @Body() body: any) {
    return this.service.updateReportingTag(id, body);
  }

  @Delete("reporting-tags/:id")
  deactivateReportingTag(@Param("id") id: string) {
    return this.service.updateReportingTag(id, { is_active: false });
  }
}
