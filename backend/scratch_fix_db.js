const postgres = require('postgres');

const sql = postgres('postgresql://postgres:688iOB8UhgYAsTgF@db.jhaqdcstdxynrbsomadt.supabase.co:5432/postgres');

async function run() {
  try {
    console.log('Running SQL...');
    await sql`ALTER TABLE sales_orders ALTER COLUMN is_delete SET DEFAULT false;`;
    console.log('SQL ran successfully!');
  } catch (e) {
    console.error('Error running SQL:', e);
  } finally {
    await sql.end();
  }
}

run();
