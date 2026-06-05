// Sentry must be initialized before any other imports.
// This file is imported as the very first line of main.ts.
import * as dotenv from "dotenv";
import * as Sentry from "@sentry/nestjs";

dotenv.config({ path: ".env.local" });

const sentryDsn = process.env.SENTRY_DSN;

if (sentryDsn) {
  Sentry.init({
    dsn: sentryDsn,
    tracesSampleRate: process.env.NODE_ENV === "production" ? 0.2 : 0.0,
    environment: process.env.NODE_ENV || "development",
  });
}
