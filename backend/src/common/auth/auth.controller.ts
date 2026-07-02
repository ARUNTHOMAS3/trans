import {
  Body,
  Controller,
  Get,
  Headers,
  HttpStatus,
  Post,
  Req,
} from "@nestjs/common";
import { Request } from "express";
import { AuthService } from "./auth.service";

@Controller("auth")
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  private toErrorResponse(
    error: any,
    fallbackStatus: HttpStatus = HttpStatus.BAD_REQUEST,
  ) {
    const statusCode =
      typeof error?.getStatus === "function"
        ? error.getStatus()
        : fallbackStatus;

    return {
      statusCode,
      message: error?.message ?? "Unexpected auth error",
    };
  }

  @Post("login")
  async login(@Body() body: any) {
    const email = body?.email?.toString().trim().toLowerCase();
    const password = body?.password?.toString() ?? "";

    if (!email || !password) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "Email and password are required",
      };
    }

    try {
      return await this.authService.login(email, password);
    } catch (error: any) {
      return this.toErrorResponse(error, HttpStatus.UNAUTHORIZED);
    }
  }

  @Post("refresh")
  async refresh(@Body() body: any) {
    const refreshToken = body?.refresh_token?.toString() ?? "";

    if (!refreshToken) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "refresh_token is required",
      };
    }

    try {
      return await this.authService.refreshToken(refreshToken);
    } catch (error: any) {
      return this.toErrorResponse(error, HttpStatus.UNAUTHORIZED);
    }
  }

  @Post("logout")
  async logout(
    @Body() body: any,
    @Headers("authorization") authHeader?: string,
  ) {
    const accessToken = authHeader?.startsWith("Bearer ")
      ? authHeader.substring(7)
      : undefined;
    const refreshToken = body?.refresh_token?.toString();

    try {
      return await this.authService.logout(accessToken, refreshToken);
    } catch (error: any) {
      return this.toErrorResponse(error, HttpStatus.BAD_REQUEST);
    }
  }

  @Post("forgot-password")
  async forgotPassword(@Body() body: any) {
    const email = body?.email?.toString().trim().toLowerCase();
    const redirectTo = body?.redirect_to?.toString();

    if (!email) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "email is required",
      };
    }

    try {
      return await this.authService.requestPasswordReset(email, redirectTo);
    } catch (error: any) {
      return this.toErrorResponse(error, HttpStatus.BAD_REQUEST);
    }
  }

  @Post("change-password")
  async changePassword(
    @Body() body: any,
    @Headers("authorization") authHeader?: string,
  ) {
    const accessToken = authHeader?.startsWith("Bearer ")
      ? authHeader.substring(7)
      : "";
    const refreshToken = body?.refresh_token?.toString() ?? "";
    const newPassword = body?.newPassword?.toString() ?? "";

    if (!accessToken || !refreshToken || !newPassword) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: "Authorization, refresh_token and newPassword are required",
      };
    }

    try {
      return await this.authService.changePassword(
        accessToken,
        refreshToken,
        newPassword,
      );
    } catch (error: any) {
      return this.toErrorResponse(error, HttpStatus.BAD_REQUEST);
    }
  }

  @Get("profile")
  async profile(@Req() req: Request) {
    try {
      return req.tenantContext?.user ?? null;
    } catch (error: any) {
      return this.toErrorResponse(error, HttpStatus.UNAUTHORIZED);
    }
  }
}
