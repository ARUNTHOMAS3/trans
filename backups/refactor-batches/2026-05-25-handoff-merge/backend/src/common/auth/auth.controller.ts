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
      return {
        statusCode: HttpStatus.UNAUTHORIZED,
        message: error.message,
      };
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
      return {
        statusCode: HttpStatus.UNAUTHORIZED,
        message: error.message,
      };
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
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: error.message,
      };
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
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: error.message,
      };
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
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: error.message,
      };
    }
  }

  @Get("profile")
  async profile(@Req() req: Request) {
    try {
      return req.tenantContext?.user ?? null;
    } catch (error: any) {
      return {
        statusCode: HttpStatus.UNAUTHORIZED,
        message: error.message,
      };
    }
  }
}
