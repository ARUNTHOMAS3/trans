import postgres from "postgres";
import * as dotenv from "dotenv";
import * as path from "path";

dotenv.config({ path: path.join(__dirname, "../../.env") });

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  console.error("❌ Missing DATABASE_URL in .env");
  process.exit(1);
}

const sql = postgres(databaseUrl);

async function applySchema() {
  console.log("🚀 Applying TDS schema...");

  try {
    await sql`
      CREATE TABLE IF NOT EXISTS "tds_groups" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
        "group_name" varchar(255) NOT NULL,
        "applicable_from" timestamp,
        "applicable_to" timestamp,
        "is_active" boolean DEFAULT true,
        "created_at" timestamp DEFAULT now(),
        CONSTRAINT "tds_groups_group_name_unique" UNIQUE("group_name")
      );
    `;
    console.log("✅ Table tds_groups created or exists.");

    await sql`
      CREATE TABLE IF NOT EXISTS "tds_sections" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
        "section_name" varchar(100) NOT NULL,
        "description" text,
        "is_active" boolean DEFAULT true,
        "created_at" timestamp DEFAULT now(),
        CONSTRAINT "tds_sections_section_name_unique" UNIQUE("section_name")
      );
    `;
    console.log("✅ Table tds_sections created or exists.");

    await sql`
      CREATE TABLE IF NOT EXISTS "tds_rates" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
        "tax_name" varchar(255) NOT NULL,
        "section_id" uuid REFERENCES "tds_sections"("id"),
        "base_rate" numeric(5, 2) NOT NULL,
        "surcharge_rate" numeric(5, 2) DEFAULT '0.00',
        "cess_rate" numeric(5, 2) DEFAULT '0.00',
        "payable_account_id" uuid REFERENCES "accounts"("id"),
        "receivable_account_id" uuid REFERENCES "accounts"("id"),
        "is_higher_rate" boolean DEFAULT false,
        "reason_higher_rate" text,
        "applicable_from" timestamp,
        "applicable_to" timestamp,
        "is_active" boolean DEFAULT true,
        "created_at" timestamp DEFAULT now(),
        CONSTRAINT "tds_rates_tax_name_unique" UNIQUE("tax_name")
      );
    `;
    console.log("✅ Table tds_rates created or exists.");

    await sql`
      CREATE TABLE IF NOT EXISTS "tds_group_items" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
        "tds_group_id" uuid REFERENCES "tds_groups"("id") ON DELETE cascade,
        "tds_rate_id" uuid REFERENCES "tds_rates"("id") ON DELETE cascade,
        "created_at" timestamp DEFAULT now()
      );
    `;
    console.log("✅ Table tds_group_items created or exists.");

    console.log("🚀 Updating vendors table with TDS and MSME columns...");
    await sql`
      ALTER TABLE "vendors" 
      ADD COLUMN IF NOT EXISTS "is_msme_registered" boolean DEFAULT false,
      ADD COLUMN IF NOT EXISTS "tds_rate_id" uuid REFERENCES "tds_rates"("id");
    `;
    console.log("✅ Vendors table updated.");

    console.log("🚀 Enabling RLS and adding policies (Allow All for now)...");

    const tables = [
      "tds_sections",
      "tds_rates",
      "tds_groups",
      "tds_group_items",
    ];
    for (const table of tables) {
      await sql.unsafe(`ALTER TABLE "${table}" ENABLE ROW LEVEL SECURITY;`);
      await sql.unsafe(`
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_policy WHERE polname = 'Allow all operations on ${table}'
            ) THEN
                CREATE POLICY "Allow all operations on ${table}" ON "${table}" FOR ALL USING (true) WITH CHECK (true);
            END IF;
        END
        $$;
      `);
    }
    console.log("✅ RLS policies applied.");

    console.log(
      "🚀 Granting permissions to anon, authenticated, and service_role...",
    );
    for (const table of tables) {
      await sql.unsafe(`GRANT ALL ON TABLE "${table}" TO service_role;`);
      await sql.unsafe(
        `GRANT SELECT ON TABLE "${table}" TO anon, authenticated;`,
      );
    }
    console.log("✅ Permissions granted.");
  } catch (error) {
    console.error("❌ Error applying schema:", error);
  } finally {
    await sql.end();
  }
}

applySchema().catch(console.error);
