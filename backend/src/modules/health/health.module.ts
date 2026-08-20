import { Module } from "@nestjs/common";
import { HealthController } from "./health.controller";
import { SupabaseModule } from "../supabase/supabase.module";
import { SyncRdsService } from "./sync-rds.service";

@Module({
  imports: [SupabaseModule],
  controllers: [HealthController],
  providers: [SyncRdsService],
})
export class HealthModule {}

