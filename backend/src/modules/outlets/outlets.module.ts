import { Module } from "@nestjs/common";
import { OutletsService } from "./outlets.service";
import { OutletsController } from "./outlets.controller";
import { SupabaseModule } from "../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [OutletsController],
  providers: [OutletsService],
  exports: [OutletsService],
})
export class OutletsModule {}
