import * as dotenv from "dotenv";
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as schema from "./schema";

dotenv.config({ path: ".env.local" });

// Create PostgreSQL connection
const connectionString =
  process.env.DRIZZLE_DATABASE_URL || process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error(
    "Missing DRIZZLE_DATABASE_URL or DATABASE_URL for runtime DB connection.",
  );
}

// Disable prefetch/prepare for "Transaction" pool mode (PgBouncer)
export const client = postgres(connectionString, {
  prepare: false,
  ssl: "require",
});
export const db = drizzle(client, { schema });
