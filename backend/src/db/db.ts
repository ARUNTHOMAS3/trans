import * as dotenv from "dotenv";
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as schema from "./schema";

// Load default .env first, then allow optional .env.local overrides.
dotenv.config();
dotenv.config({ path: ".env.local", override: true });

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

// Safe startup DDL modification to persist canceled item quantities
client.unsafe(`
  ALTER TABLE purchase_order_items 
  ADD COLUMN IF NOT EXISTS cancelled_quantity numeric DEFAULT '0.00'
`).catch(err => {
  console.error("Failed to alter table purchase_order_items:", err);
});

export const db = drizzle(client, { schema });
