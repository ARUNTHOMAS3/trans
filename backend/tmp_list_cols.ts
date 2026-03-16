import postgres from "postgres";
import * as dotenv from "dotenv";
dotenv.config();

const sql = postgres(process.env.DATABASE_URL!);

async function main() {
  try {
    const res =
      await sql`SELECT column_name FROM information_schema.columns WHERE table_name = 'products'`;
    console.log(res.map((r) => r.column_name).join(", "));
  } finally {
    await sql.end();
  }
}

main();
