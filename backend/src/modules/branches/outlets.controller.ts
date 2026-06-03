import { Controller, Get, HttpStatus } from "@nestjs/common";
import { BranchesService } from "./branches.service";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Controller("outlets")
export class OutletsController {
  constructor(private readonly branchesService: BranchesService) {}

  @Get()
  async findAll(@Tenant() tenant: TenantContext) {
    try {
      return await this.branchesService.findAll(tenant);
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }
}
