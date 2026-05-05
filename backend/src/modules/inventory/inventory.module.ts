import { Module } from "@nestjs/common";
import { InventoryService } from "./inventory.service";
import { PicklistsService } from "./services/picklists.service";
import { PicklistsController } from "./controllers/picklists.controller";
import { PackagesService } from "./services/packages.service";
import { PackagesController } from "./controllers/packages.controller";
import { SequencesModule } from "../../sequences/sequences.module";

@Module({
  imports: [SequencesModule],
  controllers: [PicklistsController, PackagesController],
  providers: [InventoryService, PicklistsService, PackagesService],
  exports: [InventoryService, PicklistsService, PackagesService],
})
export class InventoryModule {}
