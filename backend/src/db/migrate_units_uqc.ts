import postgres from "postgres";
import * as dotenv from "dotenv";

dotenv.config();

const connectionString = process.env.DATABASE_URL!;
const sql = postgres(connectionString);

async function migrate() {
  console.log("Starting migration for units table...");
  try {
    // 1. Add uqc_id column as nullable initially
    console.log("Adding uqc_id column...");
    await sql`ALTER TABLE units ADD COLUMN IF NOT EXISTS uqc_id UUID;`;

    // 2. Map existing unit_symbol to uqc_id
    console.log("Mapping unit_symbol to uqc_id...");
    await sql`
      UPDATE units
      SET uqc_id = uqc.id
      FROM uqc
      WHERE TRIM(UPPER(units.unit_symbol)) = TRIM(UPPER(uqc.uqc_code));
    `;

    // 3. Handle cases where mapping failed (set to 'OTH' if available, or just use a fallback)
    // First, let's find the ID for 'OTH'
    const othResponse =
      await sql`SELECT id FROM uqc WHERE uqc_code = 'OTH' LIMIT 1;`;
    if (othResponse.length > 0) {
      const othId = othResponse[0].id;
      console.log(`Setting default UQC ID (${othId}) for remaining units...`);
      await sql`UPDATE units SET uqc_id = ${othId} WHERE uqc_id IS NULL;`;
    }

    // 4. If there are still NULLs (unlikely if 'OTH' exists), we might have an issue making it NOT NULL.
    // Ensure no NULLs remain.
    const nullCount =
      await sql`SELECT count(*) FROM units WHERE uqc_id IS NULL;`;
    if (parseInt(nullCount[0].count) > 0) {
      throw new Error(
        `Migration failed: ${nullCount[0].count} units still have null uqc_id. Cannot set to NOT NULL.`,
      );
    }

    // 5. Set uqc_id to NOT NULL and add foreign key if needed (Drizzle usually handles FK later or we do it now)
    console.log("Setting uqc_id to NOT NULL...");
    await sql`ALTER TABLE units ALTER COLUMN uqc_id SET NOT NULL;`;

    // Add foreign key constraint if it doesn't exist
    console.log("Adding foreign key constraint...");
    try {
      await sql`ALTER TABLE units ADD CONSTRAINT units_uqc_id_fkey FOREIGN KEY (uqc_id) REFERENCES uqc(id);`;
    } catch (e) {
      console.log("Foreign key might already exist, skipping...");
    }

    // 6. Drop unit_symbol column
    console.log("Dropping unit_symbol column...");
    await sql`ALTER TABLE units DROP COLUMN IF EXISTS unit_symbol;`;

    console.log("Migration completed successfully!");
  } catch (error) {
    console.error("Migration failed:", error);
  } finally {
    await sql.end();
    process.exit(0);
  }
}

migrate();
