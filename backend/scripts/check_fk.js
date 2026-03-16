const postgres = require('postgres');
require('dotenv').config();

const DATABASE_URL = 'postgresql://postgres:Zabnixsahakar123@db.jhaqdcstdxynrbsomadt.supabase.co:5432/postgres';

async function run() {
  const sql = postgres(DATABASE_URL);
  try {
    const keys = await sql.unsafe(`
      SELECT 
        conname AS constraint_name,
        confrelid::regclass AS referenced_table
      FROM pg_catalog.pg_constraint 
      WHERE conrelid = 'accounts_manual_journal_items'::regclass;
    `);
    console.log(JSON.stringify(keys, null, 2));
  } catch (e) {
    console.error(e);
  } finally {
    await sql.end();
  }
}
run();
