import { Module } from "@nestjs/common";
import { ResendModule } from "../../modules/email/resend.module";
import { UsersModule } from "../../modules/users/users.module";
import { SupabaseModule } from "../../modules/supabase/supabase.module";
import { AuthController } from "./auth.controller";
import { AuthService } from "./auth.service";

@Module({
  imports: [SupabaseModule, UsersModule, ResendModule],
  controllers: [AuthController],
  providers: [AuthService],
  exports: [AuthService],
})
export class AuthModule {}
