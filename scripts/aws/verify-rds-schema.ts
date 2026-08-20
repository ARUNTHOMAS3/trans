import postgres from "postgres";

async function verifyRdsSchema() {
  const dbUrl = "postgresql://postgres:ZerpaiSecurePassword2026!@zerpai-db.cziuqia28x6a.ap-south-2.rds.amazonaws.com:5432/zerpai";
  console.log("Verifying Amazon RDS PostgreSQL Schema...");
  const sql = postgres(dbUrl, { ssl: false });

  try {
    const tables = await sql`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `;

    console.log(`✅ Total Public Tables Found: ${tables.length}`);
    console.log("Sample Tables:", tables.slice(0, 15).map(t => t.table_name).join(", "));
  } catch (err) {
    console.error("❌ Database schema check error:", err);
  } finally {
    await sql.end();
  }
}

verifyRdsSchema();
