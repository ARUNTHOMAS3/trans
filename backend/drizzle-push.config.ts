import { defineConfig } from "drizzle-kit";
import * as dotenv from "dotenv";

const cliTargetUrl = process.env.TARGET_DB_URL;

dotenv.config();

const drizzleDatabaseUrl =
  cliTargetUrl ||
  process.env.DRIZZLE_DATABASE_URL ||
  process.env.DATABASE_URL;

if (!drizzleDatabaseUrl) {
  throw new Error(
    "Missing TARGET_DB_URL, DRIZZLE_DATABASE_URL or DATABASE_URL for drizzle-kit.",
  );
}

console.log(`Connecting Drizzle Kit to: ${drizzleDatabaseUrl.replace(/:[^:@]+@/, ":****@")}`);

export default defineConfig({
  dialect: "postgresql",
  schema: "./src/db/schema.ts",

  dbCredentials: {
    url: drizzleDatabaseUrl,
    ssl: {
      rejectUnauthorized: false,
    },
  },

  verbose: true,
  strict: false,
});
