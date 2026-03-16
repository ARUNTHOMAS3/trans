import postgres from "postgres";
import * as dotenv from "dotenv";
dotenv.config();

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error("DATABASE_URL is not set");
  process.exit(1);
}

const sql = postgres(connectionString);

async function run() {
  try {
    console.log("Adding columns to accounts table...");
    await sql`ALTER TABLE accounts ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE`;
    await sql`ALTER TABLE accounts ADD COLUMN IF NOT EXISTS modified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()`;
    await sql`ALTER TABLE accounts ADD COLUMN IF NOT EXISTS modified_by UUID`;

    console.log("Adding column to countries table...");
    await sql`ALTER TABLE countries ADD COLUMN IF NOT EXISTS currency_code CHARACTER VARYING(10)`;

    console.log("Schema updated successfully!");
  } catch (err) {
    console.error("Migration failed:", err);
  } finally {
    await sql.end();
  }
}

run();
