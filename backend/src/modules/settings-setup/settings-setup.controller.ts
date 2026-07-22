import { Body, Controller, Delete, Get, Param, Patch, Post } from "@nestjs/common";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { SettingsSetupService } from "./settings-setup.service";

@Controller("settings-setup")
export class SettingsSetupController {
  constructor(private readonly settingsSetupService: SettingsSetupService) {}

  @Get("payment-terms")
  getPaymentTerms(@Tenant() tenant: TenantContext) {
    return this.settingsSetupService.getPaymentTerms(tenant);
  }

  @Post("payment-terms")
  createPaymentTerm(@Body() body: any, @Tenant() tenant: TenantContext) {
    return this.settingsSetupService.createPaymentTerm(body, tenant);
  }

  @Patch("payment-terms/:id")
  updatePaymentTerm(@Param("id") id: string, @Body() body: any) {
    return this.settingsSetupService.updatePaymentTerm(id, body);
  }

  @Delete("payment-terms/:id")
  deactivatePaymentTerm(@Param("id") id: string) {
    return this.settingsSetupService.deactivatePaymentTerm(id);
  }

  @Post("payment-terms/:id/default")
  setDefaultPaymentTerm(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.settingsSetupService.setDefaultPaymentTerm(id, tenant);
  }

  @Get("currencies")
  getCurrencies() {
    return this.settingsSetupService.getCurrencies();
  }

  @Post("currencies")
  createCurrency(@Body() body: any) {
    return this.settingsSetupService.createCurrency(body);
  }

  @Patch("currencies/:id")
  updateCurrency(@Param("id") id: string, @Body() body: any) {
    return this.settingsSetupService.updateCurrency(id, body);
  }

  @Delete("currencies/:id")
  deactivateCurrency(@Param("id") id: string) {
    return this.settingsSetupService.updateCurrency(id, { is_active: false });
  }

  @Get("date-formats")
  getDateFormats() {
    return this.settingsSetupService.getDateFormats();
  }

  @Get("date-separators")
  getDateSeparators() {
    return this.settingsSetupService.getDateSeparators();
  }

  @Get("fiscal-years")
  getFiscalYears(@Tenant() tenant: TenantContext) {
    return this.settingsSetupService.getFiscalYears(tenant);
  }
}
