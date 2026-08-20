import { migrate } from "drizzle-orm/postgres-js/migrator";
import { db } from "./db";

async function runMigration() {
  console.log("🚀 Starting Drizzle database schema migration to AWS RDS...");
  const startTime = Date.now();
  try {
    await migrate(db, { migrationsFolder: "./drizzle" });
    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    console.log(`✅ All Drizzle migrations executed successfully in ${duration}s!`);
    process.exit(0);
  } catch (error) {
    console.error("❌ Migration failed:", error);
    process.exit(1);
  }
}

runMigration();
