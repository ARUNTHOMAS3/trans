import postgres from "postgres";
import * as dotenv from "dotenv";
dotenv.config();

const sql = postgres(process.env.DATABASE_URL!);

async function main() {
  try {
    await sql`GRANT ALL ON TABLE uqc TO anon, authenticated, service_role, postgres;`;
    console.log("✅ Permissions granted for uqc");

    // Also ensuring units table has correct FK reference
    // Drizzle should have done it, but let's be sure
    try {
      await sql`ALTER TABLE units ADD CONSTRAINT units_uqc_id_fkey FOREIGN KEY (uqc_id) REFERENCES uqc(id) ON DELETE RESTRICT;`;
      console.log("✅ Added FK constraint to units");
    } catch (e) {
      console.log("ℹ️ FK might already exist:", e.message);
    }
  } catch (e) {
    console.error("❌ Error:", e);
  } finally {
    await sql.end();
  }
}

main();
