const { Client } = require('pg');
require('dotenv').config();

async function checkStrengths() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
  });
  try {
    await client.connect();
    const cols = await client.query(`SELECT column_name FROM information_schema.columns WHERE table_name = 'strengths'`);
    console.log('Columns in strengths:', cols.rows.map(r => r.column_name).join(', '));
    
    console.log('Searching for strengths...');
    const res = await client.query(`
      SELECT * FROM strengths 
      WHERE strength_name ILIKE '%2%'
      LIMIT 100
    `);
    console.log('Results:');
    res.rows.forEach(row => {
      console.log(JSON.stringify(row));
    });
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await client.end();
  }
}

checkStrengths();
