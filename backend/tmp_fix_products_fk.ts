import postgres from "postgres";
import * as dotenv from "dotenv";
dotenv.config();

const sql = postgres(process.env.DATABASE_URL!);

async function main() {
  try {
    console.log("Adding foreign key: products.unit_id -> units.id");
    await sql`ALTER TABLE products ADD CONSTRAINT products_unit_id_units_id_fk FOREIGN KEY (unit_id) REFERENCES units(id);`;
    console.log("✅ Added product -> unit foreign key");

    // Also notify PostgREST to reload
    await sql`NOTIFY pgrst, 'reload schema';`;
    console.log("✅ Reloaded PostgREST schema cache");
  } catch (e) {
    console.error("❌ Error:", e.message);
  } finally {
    await sql.end();
  }
}

main();
