import postgres from "postgres";
import * as dotenv from "dotenv";
dotenv.config();

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  process.exit(1);
}

const sql = postgres(connectionString);

async function run() {
  try {
    const cols =
      await sql`SELECT column_name FROM information_schema.columns WHERE table_name = 'accounts'`;
    console.log("ACCOUNTS COLS:", cols.map((c) => c.column_name).join(", "));
  } catch (err) {
    console.error(err);
  } finally {
    await sql.end();
  }
}

run();
