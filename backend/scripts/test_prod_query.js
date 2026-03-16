const postgres = require('postgres');

async function test() {
  const sql = postgres('postgresql://postgres:Zabnixsahakar123@db.jhaqdcstdxynrbsomadt.supabase.co:5432/postgres');
  
  try {
    console.log('Running query...');
    const result = await sql`
      select "accounts_manual_journals"."id", "accounts_manual_journals"."org_id", "accounts_manual_journals"."outlet_id", "accounts_manual_journals"."journal_number", "accounts_manual_journals"."fiscal_year_id", "accounts_manual_journals"."reference_number", "accounts_manual_journals"."journal_date", "accounts_manual_journals"."notes", "accounts_manual_journals"."is_13th_month_adjustment", "accounts_manual_journals"."reporting_method", "accounts_manual_journals"."currency_code", "accounts_manual_journals"."status", "accounts_manual_journals"."total_amount", "accounts_manual_journals"."recurring_journal_id", "accounts_manual_journals"."created_by", "accounts_manual_journals"."created_at", "accounts_manual_journals"."updated_at", "accounts_manual_journal_items"."id", "accounts_manual_journal_items"."manual_journal_id", "accounts_manual_journal_items"."account_id", "accounts_manual_journal_items"."description", "accounts_manual_journal_items"."contact_id", "accounts_manual_journal_items"."contact_type", "accounts_manual_journal_items"."contact_name", "accounts_manual_journal_items"."debit", "accounts_manual_journal_items"."credit", "accounts_manual_journal_items"."sort_order", "accounts_manual_journal_items"."created_at", "customers"."display_name", "vendors"."display_name", "accounts"."id", "accounts"."user_account_name", "accounts"."system_account_name" from "accounts_manual_journals" left join "accounts_manual_journal_items" on "accounts_manual_journals"."id" = "accounts_manual_journal_items"."manual_journal_id" left join "accounts" on "accounts_manual_journal_items"."account_id" = "accounts"."id" left join "customers" on ("accounts_manual_journal_items"."contact_id" = "customers"."id" and "accounts_manual_journal_items"."contact_type" = 'customer') left join "vendors" on ("accounts_manual_journal_items"."contact_id" = "vendors"."id" and "accounts_manual_journal_items"."contact_type" = 'vendor') where "accounts_manual_journals"."org_id" = '00000000-0000-0000-0000-000000000000' order by "accounts_manual_journals"."journal_date" desc, "accounts_manual_journals"."created_at" desc
    `;
    console.log('Query succeeded, rows returned:', result.length);
  } catch (err) {
    console.error('Query failed:', err);
  } finally {
    await sql.end();
  }
}

test();
