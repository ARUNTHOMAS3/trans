import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
} from "@nestjs/common";
import { TransactionLockingService } from "./transaction-locking.service";

@Controller("transaction-locking")
export class TransactionLockingController {
  constructor(private readonly service: TransactionLockingService) {}

  @Get()
  async findAll(@Query("orgId") orgId?: string) {
    return this.service.findAll(orgId);
  }

  @Post()
  async upsert(@Body() data: any, @Query("orgId") orgId?: string) {
    return this.service.upsertLock(orgId, data);
  }

  @Delete(":moduleName")
  async remove(
    @Param("moduleName") moduleName: string,
    @Query("orgId") orgId?: string,
  ) {
    return this.service.deleteLock(moduleName, orgId);
  }
}
