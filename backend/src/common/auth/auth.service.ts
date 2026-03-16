import { Injectable } from "@nestjs/common";

export interface JwtPayload {
  sub: string;
  email: string;
  orgId: string;
  outletId: string | null;
  role: string;
}

@Injectable()
export class AuthService {
  async validateToken(_token: string): Promise<JwtPayload> {
    // Stub implementation: in future, replace with actual token validation logic.
    return {
      sub: "system",
      email: "system@example.com",
      orgId: "default-org",
      outletId: null,
      role: "system",
    };
  }
}
