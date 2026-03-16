
const postgres = require('postgres');

async function check() {
  const sql = postgres('postgresql://postgres:Zabnixsahakar123@db.jhaqdcstdxynrbsomadt.supabase.co:5432/postgres');
  
  try {
    const required = {
      accounts: ['id', 'user_account_name', 'system_account_name'],
      customers: ['id', 'display_name'],
      vendors: ['id', 'display_name'],
      accounts_manual_journals: ['id', 'org_id', 'outlet_id', 'journal_number', 'fiscal_year_id', 'reference_number', 'journal_date', 'notes', 'is_13th_month_adjustment', 'reporting_method', 'currency_code', 'status', 'total_amount', 'recurring_journal_id', 'created_by', 'created_at', 'updated_at'],
      accounts_manual_journal_items: ['id', 'manual_journal_id', 'account_id', 'description', 'contact_id', 'contact_type', 'contact_name', 'debit', 'credit', 'sort_order', 'created_at']
    };

    for (const [table, cols] of Object.entries(required)) {
      console.log(`\nChecking ${table}...`);
      const columns = await sql`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = ${table}
      `;
      const existingCols = columns.map(c => c.column_name);
      
      const missing = cols.filter(c => !existingCols.includes(c));
      if (missing.length > 0) {
        console.log(`ERROR: Missing columns in ${table}:`, missing);
      } else {
        console.log(`OK: ${table} has all required columns.`);
      }
    }

  } catch (err) {
    console.error('Error:', err);
  } finally {
    await sql.end();
  }
}

check();
