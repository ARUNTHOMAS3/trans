// PATH: backend/src/common/middleware/tenant.middleware.ts

import {
  Injectable,
  NestMiddleware,
  UnauthorizedException,
} from "@nestjs/common";
import { Request, Response, NextFunction } from "express";
import { AuthService } from "../auth/auth.service";

export interface TenantContext {
  userId: string;
  email: string;
  orgId: string;
  outletId: string | null;
  role: string;
}

// Extend Express Request to include tenant context
declare module "express-serve-static-core" {
  interface Request {
    tenantContext?: TenantContext;
  }
}

@Injectable()
export class TenantMiddleware implements NestMiddleware {
  constructor(private authService: AuthService) {}

  async use(req: Request, res: Response, next: NextFunction) {
    // Skip tenant check for health/ping endpoints
    const path = req.path;
    if (
      path.includes("/health") ||
      path.includes("/ping") ||
      path.includes("/auth")
    ) {
      return next();
    }

    // Extract Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      throw new UnauthorizedException("Missing authorization header");
    }

    try {
      const token = authHeader.split(" ")[1];
      const payload = await this.authService.validateToken(token);

      // Attach tenant context to request
      req.tenantContext = {
        userId: payload.sub,
        email: payload.email,
        orgId: payload.orgId,
        outletId: payload.outletId,
        role: payload.role,
      };

      next();
    } catch (error) {
      throw new UnauthorizedException("Invalid or expired token");
    }
  }
}
