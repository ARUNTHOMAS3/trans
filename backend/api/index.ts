import { NestFactory } from "@nestjs/core";
import { ValidationPipe, BadRequestException } from "@nestjs/common";
import { AppModule } from "../src/app.module";
import { ExpressAdapter } from "@nestjs/platform-express";
import express from "express";
import { StandardResponseInterceptor } from "../src/common/interceptors/standard_response.interceptor";

const expressApp = express();
let isAppInitialized = false;

async function bootstrap() {
  if (isAppInitialized) {
    return expressApp;
  }

  const app = await NestFactory.create(
    AppModule,
    new ExpressAdapter(expressApp),
  );

  app.setGlobalPrefix("api/v1");

  const corsOrigins = process.env.CORS_ORIGINS?.split(",").map((o) =>
    o.trim().replace(/\/$/, ""),
  ) || [
    "http://localhost:3000",
    "http://localhost:8080",
    "http://localhost:3001",
    "https://zerpai-erp-one.vercel.app",
    "https://zerpai-erp-git-master-k4nn4ns-projects.vercel.app",
    "https://zerpai-erp-k4nn4ns-projects.vercel.app",
    "https://*.vercel.app",
  ];

  app.enableCors({
    origin: (origin, callback) => {
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
        /^https:\/\/[^\/]+\.vercel\.app$/.test(origin) ||
        /^https:\/\/[^\/]+\.netlify\.app$/.test(origin) ||
        /^https:\/\/[^\/]+\.github\.io$/.test(origin);

      if (isAllowed) {
        callback(null, true);
      } else {
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
        return new BadRequestException(messages);
      },
    }),
  );

  app.useGlobalInterceptors(new StandardResponseInterceptor());

  await app.init();
  isAppInitialized = true;

  return expressApp;
}

export default async (req, res) => {
  await bootstrap();
  return expressApp(req, res);
};
