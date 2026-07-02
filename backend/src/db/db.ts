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

// Safe startup DDL modification to persist canceled item quantities and address nullability
client.unsafe(`
  ALTER TABLE purchase_order_items 
  ADD COLUMN IF NOT EXISTS cancelled_quantity numeric DEFAULT '0.00';

  ALTER TABLE purchase_orders 
  ADD COLUMN IF NOT EXISTS shipping_address uuid,
  ADD COLUMN IF NOT EXISTS billing_address uuid;

  ALTER TABLE purchase_orders 
  ALTER COLUMN shipping_address DROP NOT NULL,
  ALTER COLUMN billing_address DROP NOT NULL;

  ALTER TABLE branch_price_list_assignments
  DROP CONSTRAINT IF EXISTS branch_price_list_assignments_branch_id_fkey;

  ALTER TABLE branch_price_list_assignments
  ADD CONSTRAINT branch_price_list_assignments_branch_id_fkey
  FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL;
`).catch(err => {
  console.error("Failed to execute safe DDL updates:", err);
});

export const db = drizzle(client, { schema });
