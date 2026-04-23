import { Module } from "@nestjs/common";
import { TransactionLockingController } from "./transaction-locking.controller";
import { TransactionLockingService } from "./transaction-locking.service";

@Module({
  controllers: [TransactionLockingController],
  providers: [TransactionLockingService],
  exports: [TransactionLockingService],
})
export class TransactionLockingModule {}
