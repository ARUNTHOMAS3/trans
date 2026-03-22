import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  HttpStatus,
} from '@nestjs/common';
import { TransactionSeriesService } from './transaction-series.service';

@Controller('transaction-series')
export class TransactionSeriesController {
  constructor(private readonly service: TransactionSeriesService) {}

  @Get()
  async findAll(@Query('org_id') orgId: string) {
    if (!orgId) {
      return { statusCode: HttpStatus.BAD_REQUEST, message: 'org_id is required' };
    }
    try {
      return await this.service.findAll(orgId);
    } catch (error: any) {
      return { statusCode: HttpStatus.INTERNAL_SERVER_ERROR, message: error.message };
    }
  }

  @Get(':id')
  async findOne(@Param('id') id: string, @Query('org_id') orgId: string) {
    if (!orgId) {
      return { statusCode: HttpStatus.BAD_REQUEST, message: 'org_id is required' };
    }
    const item = await this.service.findOne(id, orgId);
    if (!item) {
      return { statusCode: HttpStatus.NOT_FOUND, message: 'Transaction series not found' };
    }
    return item;
  }

  @Post()
  async create(@Body() body: any) {
    try {
      const data = await this.service.create(body);
      return { data, message: 'Transaction series created successfully' };
    } catch (error: any) {
      return { statusCode: HttpStatus.INTERNAL_SERVER_ERROR, message: error.message };
    }
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() body: any) {
    try {
      const orgId = body.org_id;
      if (!orgId) {
        return { statusCode: HttpStatus.BAD_REQUEST, message: 'org_id is required' };
      }
      const data = await this.service.update(id, orgId, body);
      return { data, message: 'Transaction series updated successfully' };
    } catch (error: any) {
      return { statusCode: HttpStatus.INTERNAL_SERVER_ERROR, message: error.message };
    }
  }

  @Delete(':id')
  async remove(@Param('id') id: string, @Query('org_id') orgId: string) {
    if (!orgId) {
      return { statusCode: HttpStatus.BAD_REQUEST, message: 'org_id is required' };
    }
    try {
      await this.service.remove(id, orgId);
      return { message: 'Transaction series deleted successfully' };
    } catch (error: any) {
      return { statusCode: HttpStatus.INTERNAL_SERVER_ERROR, message: error.message };
    }
  }
}
