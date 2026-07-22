import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
} from "@nestjs/common";
import { SettingsTaxesService } from "./settings-taxes.service";

@Controller("settings-taxes")
export class SettingsTaxesController {
  constructor(private readonly service: SettingsTaxesService) {}

  @Get("summary")
  summary() {
    return this.service.summary();
  }

  @Get("rates")
  findTaxRates(@Query("status") status?: string) {
    return this.service.findTaxRates(status);
  }

  @Post("rates")
  createTaxRate(@Body() body: any) {
    return this.service.createTaxRate(body);
  }

  @Patch("rates/:id")
  updateTaxRate(@Param("id") id: string, @Body() body: any) {
    return this.service.updateTaxRate(id, body);
  }

  @Delete("rates/:id")
  deleteTaxRate(@Param("id") id: string) {
    return this.service.deleteById("tax_rates", id, "tax rate");
  }

  @Get("groups")
  findTaxGroups(@Query("status") status?: string) {
    return this.service.findTaxGroups(status);
  }

  @Post("groups")
  createTaxGroup(@Body() body: any) {
    return this.service.createTaxGroup(body);
  }

  @Patch("groups/:id")
  updateTaxGroup(@Param("id") id: string, @Body() body: any) {
    return this.service.updateTaxGroup(id, body);
  }

  @Delete("groups/:id")
  deleteTaxGroup(@Param("id") id: string) {
    return this.service.deleteTaxGroup(id);
  }

  @Get("tds/sections")
  findTdsSections(@Query("status") status?: string) {
    return this.service.findSimple("tds_sections", status, "section_name");
  }

  @Post("tds/sections")
  createTdsSection(@Body() body: any) {
    return this.service.createSimple("tds_sections", body, {
      nameKey: "section_name",
      description: true,
    });
  }

  @Patch("tds/sections/:id")
  updateTdsSection(@Param("id") id: string, @Body() body: any) {
    return this.service.updateSimple("tds_sections", id, body, {
      nameKey: "section_name",
      description: true,
    });
  }

  @Delete("tds/sections/:id")
  deleteTdsSection(@Param("id") id: string) {
    return this.service.deleteById("tds_sections", id, "TDS section");
  }

  @Get("tds/rates")
  findTdsRates(@Query("status") status?: string) {
    return this.service.findSimple("tds_rates", status, "tax_name");
  }

  @Post("tds/rates")
  createTdsRate(@Body() body: any) {
    return this.service.createTdsRate(body);
  }

  @Patch("tds/rates/:id")
  updateTdsRate(@Param("id") id: string, @Body() body: any) {
    return this.service.updateTdsRate(id, body);
  }

  @Delete("tds/rates/:id")
  deleteTdsRate(@Param("id") id: string) {
    return this.service.deleteById("tds_rates", id, "TDS rate");
  }

  @Get("tds/groups")
  findTdsGroups(@Query("status") status?: string) {
    return this.service.findTdsGroups(status);
  }

  @Post("tds/groups")
  createTdsGroup(@Body() body: any) {
    return this.service.createTdsGroup(body);
  }

  @Patch("tds/groups/:id")
  updateTdsGroup(@Param("id") id: string, @Body() body: any) {
    return this.service.updateTdsGroup(id, body);
  }

  @Delete("tds/groups/:id")
  deleteTdsGroup(@Param("id") id: string) {
    return this.service.deleteTdsGroup(id);
  }

  @Get("tcs/natures")
  findTcsNatures(@Query("status") status?: string) {
    return this.service.findSimple("tcs_natures", status, "nature_name");
  }

  @Post("tcs/natures")
  createTcsNature(@Body() body: any) {
    return this.service.createSimple("tcs_natures", body, {
      nameKey: "nature_name",
      description: true,
    });
  }

  @Patch("tcs/natures/:id")
  updateTcsNature(@Param("id") id: string, @Body() body: any) {
    return this.service.updateSimple("tcs_natures", id, body, {
      nameKey: "nature_name",
      description: true,
    });
  }

  @Delete("tcs/natures/:id")
  deleteTcsNature(@Param("id") id: string) {
    return this.service.deleteById("tcs_natures", id, "TCS nature");
  }

  @Get("tcs/higher-rate-reasons")
  findTcsHigherRateReasons(@Query("status") status?: string) {
    return this.service.findSimple(
      "tcs_higher_rate_reasons",
      status,
      "reason_name",
    );
  }

  @Post("tcs/higher-rate-reasons")
  createTcsHigherRateReason(@Body() body: any) {
    return this.service.createSimple("tcs_higher_rate_reasons", body, {
      nameKey: "reason_name",
      description: true,
    });
  }

  @Patch("tcs/higher-rate-reasons/:id")
  updateTcsHigherRateReason(@Param("id") id: string, @Body() body: any) {
    return this.service.updateSimple("tcs_higher_rate_reasons", id, body, {
      nameKey: "reason_name",
      description: true,
    });
  }

  @Delete("tcs/higher-rate-reasons/:id")
  deleteTcsHigherRateReason(@Param("id") id: string) {
    return this.service.deleteById(
      "tcs_higher_rate_reasons",
      id,
      "TCS higher-rate reason",
    );
  }

  @Get("tcs/rates")
  findTcsRates(@Query("status") status?: string) {
    return this.service.findSimple("tcs_rates", status, "tax_name");
  }

  @Post("tcs/rates")
  createTcsRate(@Body() body: any) {
    return this.service.createTcsRate(body);
  }

  @Patch("tcs/rates/:id")
  updateTcsRate(@Param("id") id: string, @Body() body: any) {
    return this.service.updateTcsRate(id, body);
  }

  @Delete("tcs/rates/:id")
  deleteTcsRate(@Param("id") id: string) {
    return this.service.deleteById("tcs_rates", id, "TCS rate");
  }
}
