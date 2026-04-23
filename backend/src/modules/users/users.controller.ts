import {
  Body,
  Controller,
  Delete,
  Get,
  Patch,
  Param,
  Post,
  Put,
  Query,
  HttpStatus,
} from "@nestjs/common";
import { UsersService } from "./users.service";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Controller("users")
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /** GET /users */
  @Get()
  async findAll(
    @Tenant() tenant: TenantContext,
    @Query("status") status?: string,
  ) {
    try {
      const data = await this.usersService.findAll(tenant, status ?? "all");
      return data;
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get("roles/catalog")
  async getRoleCatalog(@Tenant() tenant: TenantContext) {
    try {
      return await this.usersService.getRoleCatalog(tenant);
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get("roles/:id")
  async getRole(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    try {
      const data = await this.usersService.getRole(id, tenant);
      if (!data) {
        return { statusCode: HttpStatus.NOT_FOUND, message: "Role not found" };
      }
      return data;
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Post("roles")
  async createRole(@Tenant() tenant: TenantContext, @Body() body: any) {
    try {
      const data = await this.usersService.createRole(tenant, body);
      return { data, message: "Role created successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Put("roles/:id")
  async updateRole(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() body: any,
  ) {
    try {
      const data = await this.usersService.updateRole(id, tenant, body);
      return { data, message: "Role updated successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Post()
  async create(@Tenant() tenant: TenantContext, @Body() body: any) {
    try {
      const data = await this.usersService.create(tenant, body);
      return { data, message: "User invited successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get(":id/location-access")
  async getLocationAccess(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    try {
      return await this.usersService.getLocationAccess(id, tenant);
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Put(":id/location-access")
  async updateLocationAccess(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() body: any,
  ) {
    try {
      const data = await this.usersService.updateLocationAccess(
        id,
        tenant,
        body,
      );
      return { data, message: "Location access updated successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get(":id/activities")
  async findActivities(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    try {
      return await this.usersService.findActivities(id, tenant);
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Patch(":id/default-branch")
  async setDefaultBranch(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() body: any,
  ) {
    try {
      const entityId = body?.entity_id?.toString().trim();
      if (!entityId) {
        return { statusCode: HttpStatus.BAD_REQUEST, message: "entity_id is required" };
      }
      const data = await this.usersService.setDefaultBranch(id, entityId, tenant);
      return { data, message: "Default branch updated successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get(":id")
  async findOne(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    try {
      const data = await this.usersService.findOne(id, tenant);
      if (!data) {
        return { statusCode: HttpStatus.NOT_FOUND, message: "User not found" };
      }
      return data;
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Put(":id")
  async update(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() body: any,
  ) {
    try {
      const data = await this.usersService.update(id, tenant, body);
      return { data, message: "User updated successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Patch(":id/status")
  async updateStatus(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() body: any,
  ) {
    try {
      const data = await this.usersService.updateStatus(
        id,
        tenant,
        body?.is_active === true,
      );
      return { data, message: "User status updated successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Delete(":id")
  async remove(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    try {
      await this.usersService.remove(id, tenant);
      return { message: "User deleted successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Delete("roles/:id")
  async deleteRole(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    try {
      await this.usersService.deleteRole(id, tenant);
      return { message: "Role deleted successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }
}
