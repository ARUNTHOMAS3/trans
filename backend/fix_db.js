const { db } = require('./dist/db/db');
const { sql } = require('drizzle-orm');

async function fix() {
  try {
    console.log('Adding column contact_name...');
    await db.execute(sql`ALTER TABLE accounts_manual_journal_items ADD COLUMN IF NOT EXISTS contact_name VARCHAR(255)`);
    console.log('Adding column contact_name to recurring...');
    await db.execute(sql`ALTER TABLE accounts_recurring_journal_items ADD COLUMN IF NOT EXISTS contact_name VARCHAR(255)`);
    console.log('Fix complete.');
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

fix();
