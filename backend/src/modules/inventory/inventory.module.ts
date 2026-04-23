import { Module } from "@nestjs/common";
import { InventoryService } from "./inventory.service";
import { PicklistsService } from "./services/picklists.service";
import { PicklistsController } from "./controllers/picklists.controller";

@Module({
  controllers: [PicklistsController],
  providers: [InventoryService, PicklistsService],
  exports: [InventoryService, PicklistsService],
})
export class InventoryModule {}
