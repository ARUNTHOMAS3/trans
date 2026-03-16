import postgres from "postgres";
import * as dotenv from "dotenv";
dotenv.config();

const connectionString = process.env.DATABASE_URL!;
const sql = postgres(connectionString);

async function check() {
  try {
    const rows = await sql`SELECT * FROM uqc LIMIT 10;`;
    console.log("ROWS:", JSON.stringify(rows, null, 2));
    const count = await sql`SELECT count(*) FROM uqc;`;
    console.log("COUNT:", count[0].count);
  } catch (e) {
    console.error("ERROR:", e);
  } finally {
    await sql.end();
  }
}

check();
