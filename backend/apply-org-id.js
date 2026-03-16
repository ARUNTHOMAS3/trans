
const dotenv = require('dotenv');
const postgres = require('postgres');

dotenv.config();

async function applyChanges() {
  const connectionString = process.env.DATABASE_URL;
  const sql = postgres(connectionString, { ssl: 'require' });

  try {
    console.log('Adding org_id and outlet_id to accounts...');
    await sql`ALTER TABLE accounts ADD COLUMN IF NOT EXISTS org_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'`;
    await sql`ALTER TABLE accounts ADD COLUMN IF NOT EXISTS outlet_id UUID`;

    console.log('Adding org_id and outlet_id to account_transactions...');
    await sql`ALTER TABLE account_transactions ADD COLUMN IF NOT EXISTS org_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'`;
    await sql`ALTER TABLE account_transactions ADD COLUMN IF NOT EXISTS outlet_id UUID`;

    console.log('Refreshing PostgREST schema cache...');
    await sql`NOTIFY pgrst, 'reload schema'`;

    console.log('All changes applied successfully.');
    process.exit(0);
  } catch (error) {
    console.error('Fatal Error:', error);
    process.exit(1);
  }
}

applyChanges();
