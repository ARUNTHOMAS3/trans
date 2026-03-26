import { Module } from "@nestjs/common";
import { BranchesService } from "./branches.service";
import { BranchesController } from "./branches.controller";
import { SupabaseModule } from "../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [BranchesController],
  providers: [BranchesService],
  exports: [BranchesService],
})
export class BranchesModule {}
