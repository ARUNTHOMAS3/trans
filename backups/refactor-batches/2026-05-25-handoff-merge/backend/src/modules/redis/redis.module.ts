import { Global, Module } from "@nestjs/common";
import { BullBoardService } from "./bull_board.service";
import { RedisService } from "./redis.service";

@Global()
@Module({
  providers: [RedisService, BullBoardService],
  exports: [RedisService, BullBoardService],
})
export class RedisModule {}
