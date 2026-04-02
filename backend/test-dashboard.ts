import { db } from "./src/db/db";
import { sql } from "drizzle-orm";

async function main() {
  try {
    const rawQuery = sql`
      SELECT
        p.id as "id",
        p.product_name as "name",
        COALESCE(SUM(oi.current_stock), 0) as "stockOnHand"
      FROM outlet_inventory oi
      JOIN products p ON oi.product_id = p.id
      WHERE 1 = 1
      GROUP BY p.id, p.product_name
      HAVING COALESCE(SUM(oi.current_stock), 0) > 0
      ORDER BY "stockOnHand" DESC, p.product_name ASC
      LIMIT 5
    `;

    console.log("Running query...");
    const result = await db.execute(rawQuery);
    console.log("Success! Results:");
    console.log(result);
  } catch (err) {
    console.error("Query failed with error:");
    console.error(err);
  } finally {
    process.exit(0);
  }
}

main();
