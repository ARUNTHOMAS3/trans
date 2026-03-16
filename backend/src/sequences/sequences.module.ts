import { Module } from "@nestjs/common";
import { SequencesService } from "./sequences.service";
import { SequencesController } from "./sequences.controller";
import { SupabaseModule } from "../modules/supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  providers: [SequencesService],
  controllers: [SequencesController],
  exports: [SequencesService],
})
export class SequencesModule {}
