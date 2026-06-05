import { Controller, Get } from "@nestjs/common";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { BranchesService } from "./branches.service";

@Controller("outlets")
export class OutletsController {
  constructor(private readonly branchesService: BranchesService) {}

  @Get()
  findAll(@Tenant() tenant: TenantContext) {
    return this.branchesService.findAll(tenant);
  }
}
