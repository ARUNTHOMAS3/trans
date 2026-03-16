const { db } = require('./dist/db/db');
const { sql } = require('drizzle-orm');

async function inspect() {
  try {
    console.log('Inspecting accounts table columns...');
    const columns = await db.execute(sql`SELECT column_name FROM information_schema.columns WHERE table_name = 'accounts'`);
    console.log('Columns in accounts table:', JSON.stringify(columns.map(c => c.column_name)));
    
    console.log('Inspecting manual journal items columns...');
    const itemsColumns = await db.execute(sql`SELECT column_name FROM information_schema.columns WHERE table_name = 'accounts_manual_journal_items'`);
    console.log('Columns in manual_journal_items:', JSON.stringify(itemsColumns.map(c => c.column_name)));
    
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

inspect();
