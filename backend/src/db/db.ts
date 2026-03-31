import * as dotenv from "dotenv";
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as schema from "./schema";

dotenv.config({ path: ".env.local" });

// Create PostgreSQL connection
const connectionString = process.env.DATABASE_URL!;

// Disable prefetch/prepare for "Transaction" pool mode (PgBouncer)
export const client = postgres(connectionString, {
  prepare: false,
  ssl: "require",
});
export const db = drizzle(client, { schema });
