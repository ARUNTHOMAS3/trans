
const postgres = require('postgres');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '.env') });

const sql = postgres(process.env.DATABASE_URL);

async function renameColumn() {
    try {
        console.log('🚀 Renaming "account_name" to "system_account_name" in database...');
        
        await sql`ALTER TABLE accounts RENAME COLUMN account_name TO system_account_name`;
        console.log('✅ Column renamed successfully.');
        
        // Verify columns
        const data = await sql`SELECT * FROM accounts LIMIT 1`;
        if (data.length > 0) {
            console.log('Current Columns:', Object.keys(data[0]));
        }

        process.exit(0);
    } catch (e) {
        console.error('❌ Rename failed:', e);
        process.exit(1);
    }
}

renameColumn();
