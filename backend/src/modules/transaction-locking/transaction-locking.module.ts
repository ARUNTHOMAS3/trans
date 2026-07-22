import { Module } from "@nestjs/common";
import { TransactionLockingController } from "./transaction-locking.controller";
import { TransactionLockingService } from "./transaction-locking.service";
import { SupabaseModule } from "../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [TransactionLockingController],
  providers: [TransactionLockingService],
  exports: [TransactionLockingService],
})
export class TransactionLockingModule {}
