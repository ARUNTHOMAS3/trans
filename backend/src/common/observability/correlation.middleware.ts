import { Injectable, NestMiddleware } from "@nestjs/common";
import { Request, Response, NextFunction } from "express";
import { ObservabilityService } from "./observability.service";

declare module "express-serve-static-core" {
  interface Request {
    correlationId?: string;
    observabilityStartedAt?: bigint;
  }
}

@Injectable()
export class CorrelationMiddleware implements NestMiddleware {
  constructor(private readonly observability: ObservabilityService) {}

  use(req: Request, res: Response, next: NextFunction): void {
    if (!this.observability.isEnabled) {
      next();
      return;
    }
    const correlationId =
      req.header("x-request-id")?.trim() || this.observability.newCorrelationId();
    req.correlationId = correlationId;
    req.observabilityStartedAt = process.hrtime.bigint();
    res.setHeader("X-Request-ID", correlationId);
    next();
  }
}
