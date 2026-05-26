import { Module } from "@nestjs/common";
import { InventoryService } from "./inventory.service";
import { PicklistsService } from "./services/picklists.service";
import { PicklistsController } from "./controllers/picklists.controller";
import { PackagesService } from "./services/packages.service";
import { PackagesController } from "./controllers/packages.controller";
import {
  InventoryAdjustmentsController,
  InventoryAdjustmentsLegacyLookupController,
} from "./controllers/inventory-adjustments.controller";
import { InventoryAdjustmentsService } from "./services/inventory-adjustments.service";
import { TransferOrdersController } from "./controllers/transfer-orders.controller";
import { TransferOrdersService } from "./services/transfer-orders.service";
import { MoveOrdersController } from "./controllers/move-orders.controller";
import { MoveOrdersService } from "./services/move-orders.service";
import { SequencesModule } from "../../sequences/sequences.module";

@Module({
  imports: [SequencesModule],
  controllers: [
    PicklistsController,
    PackagesController,
    InventoryAdjustmentsController,
    InventoryAdjustmentsLegacyLookupController,
    TransferOrdersController,
    MoveOrdersController,
  ],
  providers: [
    InventoryService,
    PicklistsService,
    PackagesService,
    InventoryAdjustmentsService,
    TransferOrdersService,
    MoveOrdersService,
  ],
  exports: [
    InventoryService,
    PicklistsService,
    PackagesService,
    InventoryAdjustmentsService,
    TransferOrdersService,
    MoveOrdersService,
  ],
})
export class InventoryModule {}
