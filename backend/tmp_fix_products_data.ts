import postgres from "postgres";
import * as dotenv from "dotenv";
dotenv.config();

const sql = postgres(process.env.DATABASE_URL!);

async function main() {
  try {
    const invalidProducts = await sql`
      SELECT id, product_name, unit_id FROM products 
      WHERE unit_id NOT IN (SELECT id FROM units)
    `;
    console.log("Products with invalid unit IDs:");
    console.table(invalidProducts);

    // Find a valid unit ID from the units table to use as a fallback
    const validUnitRes =
      await sql`SELECT id FROM units WHERE is_active = true LIMIT 1;`;
    if (validUnitRes.length > 0) {
      const fallbackId = validUnitRes[0].id;
      console.log(
        `Setting unit_id to ${fallbackId} for ${invalidProducts.length} invalid products...`,
      );
      await sql`UPDATE products SET unit_id = ${fallbackId} WHERE unit_id NOT IN (SELECT id FROM units);`;
      console.log("✅ Updated products");

      // Now re-try adding the FK
      console.log("Adding foreign key: products.unit_id -> units.id");
      await sql`ALTER TABLE products ADD CONSTRAINT products_unit_id_units_id_fk FOREIGN KEY (unit_id) REFERENCES units(id);`;
      console.log("✅ Added product -> unit foreign key");

      // Reload schema cache
      await sql`NOTIFY pgrst, 'reload schema';`;
      console.log("✅ Reloaded PostgREST schema cache");
    }
  } catch (e) {
    console.error("❌ Error:", e.message);
  } finally {
    await sql.end();
  }
}

main();
