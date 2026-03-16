import postgres from "postgres";
import * as dotenv from "dotenv";
dotenv.config();

const sql = postgres(process.env.DATABASE_URL!);

async function main() {
  try {
    await sql`NOTIFY pgrst, 'reload schema';`;
    console.log("✅ PostgREST cache reloaded");

    // Also try granting permissions just in case
    await sql`GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;`;
    console.log("✅ Permissions granted on all tables");
  } catch (e) {
    console.error("❌ Error:", e);
  } finally {
    await sql.end();
  }
}

main();
