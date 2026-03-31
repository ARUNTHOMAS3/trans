import { Controller, Get, Post, Body, Param, Put, Delete, Query } from "@nestjs/common";
import { PicklistsService } from "../services/picklists.service";

@Controller("inventory/picklists")
export class PicklistsController {
  constructor(private readonly picklistsService: PicklistsService) {}

  @Get()
  findAll(
    @Query('page') page: string,
    @Query('limit') limit: string,
    @Query('search') search?: string,
    @Query('status') status?: string,
  ) {
    return this.picklistsService.findAll(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 100,
      search,
      status
    );
  }

  @Get(":id")
  findOne(@Param("id") id: string) {
    return this.picklistsService.findOne(id);
  }

  @Post()
  create(@Body() createDto: any) {
    return this.picklistsService.create(createDto);
  }

  @Put(":id")
  update(@Param("id") id: string, @Body() updateDto: any) {
    return this.picklistsService.update(id, updateDto);
  }

  @Delete(":id")
  remove(@Param("id") id: string) {
    return this.picklistsService.remove(id);
  }
}
