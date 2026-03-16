import postgres from "postgres";
import * as dotenv from "dotenv";
dotenv.config();

const sql = postgres(process.env.DATABASE_URL!);

async function main() {
  try {
    const result = await sql`
      SELECT 
          column_name, 
          data_type, 
          is_nullable
      FROM 
          information_schema.columns 
      WHERE 
          table_name = 'products';
    `;
    console.log("Columns for products:");
    console.table(result);
  } catch (e) {
    console.error("❌ Error:", e);
  } finally {
    await sql.end();
  }
}

main();
