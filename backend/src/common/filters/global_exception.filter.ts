import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
} from "@nestjs/common";
import { Response } from "express";

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  catch(exception: any, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const isProduction = process.env.NODE_ENV === "production";

    // 1. Log the full error to the console for internal debugging
    console.error("❌ [GlobalExceptionFilter] Full Error:", exception);

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = "An unexpected error occurred. Please try again later.";
    let errorResponse: any = {
      statusCode: status,
      message,
      timestamp: new Date().toISOString(),
    };

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === "string") {
        message = exceptionResponse;
      } else if (typeof exceptionResponse === "object") {
        errorResponse = {
          ...errorResponse,
          ...exceptionResponse,
        };
        message = (exceptionResponse as any).message || message;
      }
      errorResponse.statusCode = status;
    } else if (exception?.message) {
      // Handle generic errors (like DB errors, syntax errors, etc.)
      if (!isProduction) {
        // In development, show more details
        message = exception.message;
      } else {
        // In production, sanitize common sensitive error patterns
        if (
          exception.message.toLowerCase().includes("select") ||
          exception.message.toLowerCase().includes("update") ||
          exception.message.toLowerCase().includes("insert") ||
          exception.message.toLowerCase().includes("delete")
        ) {
          message =
            "A database error occurred. Internal details have been hidden.";
        } else {
          message = "An internal server error occurred.";
        }
      }
    }

    // Ensure the message is always set in the response
    errorResponse.message = message;

    // Send the sanitized response
    response.status(status).json({
      data: null,
      meta: {
        timestamp: new Date().toISOString(),
        error: errorResponse,
      },
      success: false,
    });
  }
}
