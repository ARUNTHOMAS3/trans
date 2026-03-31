import { Controller, Get, Query, HttpStatus, Res } from "@nestjs/common";
import { Response } from "express";
import { GstService } from "./gst.service";

@Controller("gst")
export class GstController {
  constructor(private readonly gstService: GstService) {}

  @Get("taxpayer-details")
  async getTaxpayerDetails(
    @Query("gstin") gstin: string,
    @Res() res: Response,
  ) {
    if (!gstin || gstin.trim().length === 0) {
      return res
        .status(HttpStatus.BAD_REQUEST)
        .json({ message: "gstin query param is required" });
    }

    const normalised = gstin.trim().toUpperCase();

    try {
      const data = await this.gstService.lookupGstin(normalised);
      return res.status(HttpStatus.OK).json(data);
    } catch (error: any) {
      return res
        .status(HttpStatus.BAD_REQUEST)
        .json({ message: error.message ?? "GSTIN lookup failed" });
    }
  }
}
