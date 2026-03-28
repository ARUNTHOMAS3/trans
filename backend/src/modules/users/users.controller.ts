import {
  Controller,
  Get,
  Param,
  Query,
  HttpStatus,
} from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /** GET /users?org_id=<uuid> */
  @Get()
  async findAll(@Query('org_id') orgId: string) {
    if (!orgId) {
      return { statusCode: HttpStatus.BAD_REQUEST, message: 'org_id is required' };
    }
    try {
      const data = await this.usersService.findAll(orgId);
      return data;
    } catch (error: any) {
      return { statusCode: HttpStatus.INTERNAL_SERVER_ERROR, message: error.message };
    }
  }

  /** GET /users/:id?org_id=<uuid> */
  @Get(':id')
  async findOne(@Param('id') id: string, @Query('org_id') orgId: string) {
    if (!orgId) {
      return { statusCode: HttpStatus.BAD_REQUEST, message: 'org_id is required' };
    }
    try {
      const data = await this.usersService.findOne(id, orgId);
      if (!data) {
        return { statusCode: HttpStatus.NOT_FOUND, message: 'User not found' };
      }
      return data;
    } catch (error: any) {
      return { statusCode: HttpStatus.INTERNAL_SERVER_ERROR, message: error.message };
    }
  }
}
