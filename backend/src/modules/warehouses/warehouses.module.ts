import { Module } from "@nestjs/common";
import { WarehousesService } from "./warehouses.service";
import { WarehousesController } from "./warehouses.controller";
import { SupabaseModule } from "../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [WarehousesController],
  providers: [WarehousesService],
  exports: [WarehousesService],
})
export class WarehousesModule {}
