import postgres from "postgres";
import * as dotenv from "dotenv";

dotenv.config();

const connectionString = process.env.DATABASE_URL!;
const sql = postgres(connectionString);

async function createTable() {
  console.log("Creating UQC table...");
  try {
    await sql`
      CREATE TABLE IF NOT EXISTS uqc (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        uqc_code VARCHAR(50) NOT NULL UNIQUE,
        description VARCHAR(255) NOT NULL,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT now()
      );
    `;
    console.log("UQC table created or already exists.");
  } catch (error) {
    console.error("Error creating UQC table:", error);
  } finally {
    await sql.end();
  }
}

createTable();
