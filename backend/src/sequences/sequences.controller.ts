import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Patch,
  Query,
} from "@nestjs/common";
import { SequencesService } from "./sequences.service";

@Controller("sequences")
export class SequencesController {
  constructor(private readonly sequencesService: SequencesService) {}

  @Get(":module/next")
  async getNext(
    @Param("module") module: string,
    @Query("outletId") outletId?: string,
  ) {
    const formatted = await this.sequencesService.getNextNumberFormatted(
      module,
      outletId,
    );
    return { nextNumber: formatted };
  }

  @Get(":module/check-duplicate")
  async checkDuplicate(
    @Param("module") module: string,
    @Query("number") number: string,
  ) {
    return this.sequencesService.checkDuplicate(module, number);
  }

  @Get(":module/settings")
  async getSettings(
    @Param("module") module: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.sequencesService.getSequence(module, outletId);
  }

  @Post(":module/increment")
  async increment(
    @Param("module") module: string,
    @Body() body: { usedNumber?: string; outletId?: string },
  ) {
    return this.sequencesService.incrementSequence(
      module,
      body.usedNumber,
      body.outletId,
    );
  }

  @Patch(":module/settings")
  async updateSettings(
    @Param("module") module: string,
    @Body()
    body: {
      prefix?: string;
      nextNumber?: number;
      padding?: number;
      suffix?: string;
      outletId?: string;
    },
  ) {
    return this.sequencesService.updateSettings(module, body);
  }
}
