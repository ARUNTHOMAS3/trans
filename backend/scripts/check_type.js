const postgres = require('postgres');

async function checkType() {
  const sql = postgres('postgresql://postgres:Zabnixsahakar123@db.jhaqdcstdxynrbsomadt.supabase.co:5432/postgres');
  
  try {
    const res = await sql`
      SELECT data_type, udt_name 
      FROM information_schema.columns 
      WHERE table_name = 'accounts_manual_journal_items' AND column_name = 'contact_type'
    `;
    console.log(res);

    // Test the exact parametrized query to see if it throws a type mismatch error
    try {
        await sql`
        select "accounts_manual_journals"."id" from "accounts_manual_journals" 
        left join "accounts_manual_journal_items" on "accounts_manual_journals"."id" = "accounts_manual_journal_items"."manual_journal_id" 
        left join "customers" on ("accounts_manual_journal_items"."contact_id" = "customers"."id" and "accounts_manual_journal_items"."contact_type" = ${'customer'}) 
        left join "vendors" on ("accounts_manual_journal_items"."contact_id" = "vendors"."id" and "accounts_manual_journal_items"."contact_type" = ${'vendor'}) 
        where "accounts_manual_journals"."org_id" = ${'00000000-0000-0000-0000-000000000000'} limit 1
        `;
        console.log("Parametrized query successful");
    } catch (e) {
        console.log("Parametrized query error:", e.message);
    }
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await sql.end();
  }
}

checkType();
