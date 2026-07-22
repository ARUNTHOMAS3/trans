import { Controller, Get, Header, Query, Res } from "@nestjs/common";
import { Response } from "express";
import { ObservabilityService } from "./observability.service";

@Controller("telemetry")
export class ObservabilityController {
  constructor(private readonly observability: ObservabilityService) {}

  @Get("export")
  @Header("Cache-Control", "no-store")
  export(
    @Query("format") format: string | undefined,
    @Res({ passthrough: true }) response: Response,
  ): string {
    const isCsv = format?.toLowerCase() === "csv";
    response.setHeader("Content-Type", isCsv ? "text/csv" : "application/json");
    if (isCsv) {
      return this.observability.exportCsv();
    }
    return this.observability.exportJson();
  }
}
