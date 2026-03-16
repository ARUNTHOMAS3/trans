
const dotenv = require('dotenv');
const postgres = require('postgres');

dotenv.config();

async function checkTypes() {
  const sql = postgres(process.env.DATABASE_URL, { ssl: 'require' });
  try {
    const result = await sql`SELECT DISTINCT account_type FROM accounts`;
    console.log('Account types in DB:');
    result.forEach(row => console.log(`- ${row.account_type}`));
    
    const names = await sql`SELECT user_account_name, account_type FROM accounts WHERE user_account_name ILIKE '%Contract Asset%'`;
    console.log('\nAccounts matching "Contract Asset":');
    names.forEach(row => console.log(`- ${row.user_account_name} (${row.account_type})`));
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkTypes();
