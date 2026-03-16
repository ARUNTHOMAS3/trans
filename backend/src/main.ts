// PATH: backend/src/main.ts

import { NestFactory } from "@nestjs/core";
import { ValidationPipe, BadRequestException } from "@nestjs/common";
import { AppModule } from "./app.module";
import * as dotenv from "dotenv";
import { StandardResponseInterceptor } from "./common/interceptors/standard_response.interceptor";
import { GlobalExceptionFilter } from "./common/filters/global_exception.filter";

dotenv.config();

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 🔢 API Versioning (PRD Section 18.1)
  // All backend APIs are versioned from day one for future compatibility
  app.setGlobalPrefix("api/v1");

  // Enable CORS for Flutter web
  const corsOrigins = process.env.CORS_ORIGINS?.split(",").map((origin) =>
    origin.trim().replace(/\/$/, ""),
  ) || [
    "http://localhost:3000",
    "http://localhost:8080",
    "http://localhost:3001",
    // Your specific deployment domain
    "https://zerpai-erp-one.vercel.app",
    "https://zerpai-erp-git-master-k4nn4ns-projects.vercel.app",
    "https://zerpai-erp-k4nn4ns-projects.vercel.app",
    // Wildcard for Vercel deployments
    "https://*.vercel.app",
  ];

  app.enableCors({
    origin: (origin, callback) => {
      // Allow requests with no origin (like mobile apps or curl)
      if (!origin) return callback(null, true);

      const isAllowed =
        corsOrigins.some((allowedOrigin) => {
          if (allowedOrigin.includes("*")) {
            const regex = new RegExp(
              "^" + allowedOrigin.replace(/\*/g, ".*") + "$",
            );
            return regex.test(origin);
          }
          return allowedOrigin === origin;
        }) ||
        /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin) ||
        // Allow common development platforms
        /^https:\/\/[^\/]+\.vercel\.app$/.test(origin);

      if (isAllowed) {
        callback(null, true);
      } else {
        console.error(`❌ CORS blocked for origin: ${origin}`);
        callback(new Error("Not allowed by CORS"));
      }
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: [
      "Content-Type",
      "Authorization",
      "Accept",
      "X-Org-Id",
      "X-Outlet-Id",
      "X-Request-ID",
    ],
  });

  // Global validation pipe with detailed error logging
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      exceptionFactory: (errors) => {
        const messages = errors.map((error) => ({
          field: error.property,
          constraints: error.constraints,
          value: error.value,
        }));
        console.error(
          "❌ Validation Error:",
          JSON.stringify(messages, null, 2),
        );
        return new BadRequestException(messages);
      },
    }),
  );

  app.useGlobalInterceptors(new StandardResponseInterceptor());
  app.useGlobalFilters(new GlobalExceptionFilter());

  const port = process.env.PORT || 3001;
  await app.listen(port, "0.0.0.0");

  console.log("");
  console.log("🚀 ZERPAI ERP Backend");
  console.log(`📍 Server running on: http://0.0.0.0:${port}`);
  console.log(`🌍 Local Access: http://localhost:${port}`);
  console.log(`🌍 IP Access: http://127.0.0.1:${port}`);
  console.log(`🌍 CORS enabled for: ${corsOrigins.join(", ")}`);
  console.log(`🔒 Supabase URL: ${process.env.SUPABASE_URL}`);
  console.log("");
}

bootstrap();
