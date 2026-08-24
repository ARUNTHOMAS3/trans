import { Module } from "@nestjs/common";
import { SupabaseModule } from "../../supabase/supabase.module";
import { SequencesModule } from '../../../sequences/sequences.module';
import { WarehousesSettingsModule } from '../../warehouses-settings/warehouses-settings.module';
import { CreditNotesController } from "./credit-notes.controller";
import { CreditNotesService } from "./credit-notes.service";

@Module({
  imports: [SupabaseModule, SequencesModule, WarehousesSettingsModule],
  controllers: [CreditNotesController],
  providers: [CreditNotesService],
  exports: [CreditNotesService],
})
export class CreditNotesModule {}
