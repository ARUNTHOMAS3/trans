import * as dotenv from "dotenv";
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as schema from "./schema";
import { createHash } from "crypto";
import { ObservabilityService } from "../common/observability/observability.service";

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
const observability = new ObservabilityService();
const isSslDisabled =
  connectionString.includes("sslmode=disable") ||
  process.env.DB_SSL === "false";
const isSslNoVerify = connectionString.includes("sslmode=no-verify");

const rawClient = postgres(connectionString, {
  prepare: false,
  ssl: isSslDisabled ? false : isSslNoVerify ? { rejectUnauthorized: false } : "prefer",
  connect_timeout: 10,
  idle_timeout: 20,
  max: 10,
  debug: observability.isEnabled
    ? (_connection, query) => {
        observability.record("database_query_submitted", "database", {
          metrics: { query_fingerprint: fingerprint(query) },
        });
      }
    : undefined,
});

function fingerprint(query: string): string {
  return createHash("sha256").update(query).digest("hex").slice(0, 16);
}

function instrumentResult<T>(result: T, query: string): T {
  if (!observability.isEnabled || !result || typeof (result as any).then !== "function") {
    return result;
  }
  const startedAt = process.hrtime.bigint();
  return Promise.resolve(result as any).then(
    (rows: any) => {
      observability.recordDatabase({
        queryFingerprint: fingerprint(query),
        durationMs: Number(process.hrtime.bigint() - startedAt) / 1e6,
        rows: Array.isArray(rows) ? rows.length : Number(rows?.count ?? 0),
      });
      return rows;
    },
    (error: unknown) => {
      observability.recordDatabase({
        queryFingerprint: fingerprint(query),
        durationMs: Number(process.hrtime.bigint() - startedAt) / 1e6,
        rows: 0,
        error: true,
      });
      throw error;
    },
  ) as T;
}

export const client = observability.isEnabled
  ? (new Proxy(rawClient as any, {
      apply(target, thisArg, args) {
        const query = typeof args[0] === "string" ? args[0] : "tagged_query";
        return instrumentResult(Reflect.apply(target, thisArg, args), query);
      },
      get(target, property, receiver) {
        const value = Reflect.get(target, property, receiver);
        if (property === "unsafe" && typeof value === "function") {
          return (...args: any[]) =>
            instrumentResult(
              value.apply(target, args),
              typeof args[0] === "string" ? args[0] : "unsafe_query",
            );
        }
        return value;
      },
    }) as typeof rawClient)
  : rawClient;

// Safe startup DDL modification to persist canceled item quantities
client.unsafe(`
  ALTER TABLE purchase_order_items 
  ADD COLUMN IF NOT EXISTS cancelled_quantity numeric DEFAULT '0.00'
`).catch(err => {
  console.error("Failed to alter table purchase_order_items:", err);
});

export const db = drizzle(client, { schema });
