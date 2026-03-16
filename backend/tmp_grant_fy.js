require('dotenv').config();
const postgres = require('postgres');

const sql = postgres(process.env.DATABASE_URL, { ssl: 'require' });

(async () => {
  try {
    await sql`GRANT USAGE ON SCHEMA public TO service_role, authenticated, anon`;
    await sql`GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.accounts_fiscal_years TO service_role`;
    await sql`GRANT SELECT ON TABLE public.accounts_fiscal_years TO authenticated, anon`;

    const rows = await sql`
      SELECT id, name, start_date, end_date, is_active
      FROM public.accounts_fiscal_years
      ORDER BY start_date DESC
    `;

    console.log('fiscal_year_rows=', rows.length);
    console.log(rows.slice(0, 5));
  } catch (e) {
    console.error(e);
    process.exit(1);
  } finally {
    await sql.end({ timeout: 5 });
  }
})();
