import { defineConfig } from "drizzle-kit";
import * as dotenv from "dotenv";

dotenv.config();
dotenv.config({ path: ".env.local", override: true });

const drizzleDatabaseUrl = process.env.DRIZZLE_DATABASE_URL || process.env.DATABASE_URL;

if (!drizzleDatabaseUrl) {
  throw new Error(
    "Missing DRIZZLE_DATABASE_URL or DATABASE_URL for drizzle-kit.",
  );
}

export default defineConfig({
  dialect: "postgresql",
  schema: "./src/db/schema.ts",
  out: "./drizzle",
  dbCredentials: {
    url: drizzleDatabaseUrl,
  },
  verbose: true,
  strict: true,
});
