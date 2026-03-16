
const dotenv = require('dotenv');
const postgres = require('postgres');

dotenv.config();

async function checkColumns() {
  const connectionString = process.env.DATABASE_URL;
  const sql = postgres(connectionString, { ssl: 'require' });
  try {
    const tables = ['accounts', 'account_transactions'];
    for (const table of tables) {
      const result = await sql`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = ${table}
      `;
      console.log(`Columns in ${table} table:`);
      result.forEach(row => console.log(`- ${row.column_name}`));
      console.log('---');
    }
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkColumns();
