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

@Controller("users")
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /** GET /users?org_id=<uuid> */
  @Get()
  async findAll(
    @Query("org_id") orgId: string,
    @Query("status") status?: string,
  ) {
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      const data = await this.usersService.findAll(orgId, status ?? "all");
      return data;
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get("roles/catalog")
  async getRoleCatalog(@Query("org_id") orgId: string) {
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      return await this.usersService.getRoleCatalog(orgId);
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get("roles/:id")
  async getRole(@Param("id") id: string, @Query("org_id") orgId: string) {
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      const data = await this.usersService.getRole(id, orgId);
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
  async createRole(@Body() body: any) {
    const orgId = body?.org_id?.toString();
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      const data = await this.usersService.createRole(orgId, body);
      return { data, message: "Role created successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Put("roles/:id")
  async updateRole(@Param("id") id: string, @Body() body: any) {
    const orgId = body?.org_id?.toString();
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      const data = await this.usersService.updateRole(id, orgId, body);
      return { data, message: "Role updated successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Post()
  async create(@Body() body: any) {
    try {
      const data = await this.usersService.create(body);
      return { data, message: "User invited successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  /** GET /users/:id?org_id=<uuid> */
  @Get(":id/location-access")
  async getLocationAccess(
    @Param("id") id: string,
    @Query("org_id") orgId: string,
  ) {
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      return await this.usersService.getLocationAccess(id, orgId);
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Put(":id/location-access")
  async updateLocationAccess(@Param("id") id: string, @Body() body: any) {
    const orgId = body?.org_id?.toString();
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      const data = await this.usersService.updateLocationAccess(
        id,
        orgId,
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
    @Param("id") id: string,
    @Query("org_id") orgId: string,
  ) {
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      return await this.usersService.findActivities(id, orgId);
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Get(":id")
  async findOne(@Param("id") id: string, @Query("org_id") orgId: string) {
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      const data = await this.usersService.findOne(id, orgId);
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
  async update(@Param("id") id: string, @Body() body: any) {
    const orgId = body?.org_id?.toString();
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      const data = await this.usersService.update(id, orgId, body);
      return { data, message: "User updated successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Patch(":id/status")
  async updateStatus(@Param("id") id: string, @Body() body: any) {
    const orgId = body?.org_id?.toString();
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      const data = await this.usersService.updateStatus(
        id,
        orgId,
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
  async remove(@Param("id") id: string, @Query("org_id") orgId: string) {
    if (!orgId) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "org_id is required",
      };
    }
    try {
      await this.usersService.remove(id, orgId);
      return { message: "User deleted successfully" };
    } catch (error: any) {
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }
}
