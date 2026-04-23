import { Module, forwardRef } from "@nestjs/common";
import { BranchesService } from "./branches.service";
import { BranchesController } from "./branches.controller";
import { SupabaseModule } from "../supabase/supabase.module";
import { UsersModule } from "../users/users.module";
import { AccountantModule } from "../accountant/accountant.module";

@Module({
  imports: [SupabaseModule, forwardRef(() => UsersModule), AccountantModule],
  controllers: [BranchesController],
  providers: [BranchesService],
  exports: [BranchesService],
})
export class BranchesModule {}
