
import { db } from './src/db/db';
import { sql } from 'drizzle-orm';

async function checkColumns() {
  try {
    const result = await db.execute(sql`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'accounts'
    `);
    console.log('Columns in accounts table:', result);
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkColumns();
