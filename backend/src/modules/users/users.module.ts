import { Module, forwardRef } from "@nestjs/common";
import { BranchesModule } from "../branches/branches.module";
import { UsersService } from "./users.service";
import { UsersController } from "./users.controller";
import { SupabaseModule } from "../supabase/supabase.module";

@Module({
  imports: [SupabaseModule, forwardRef(() => BranchesModule)],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
