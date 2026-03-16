import postgres from "postgres";

const connUrl =
  process.env.DATABASE_URL ||
  "postgresql://postgres.rqrdrkffuovpntkwhlct:zerpai-erp-master-key@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1";
const sql = postgres(connUrl);

async function main() {
  try {
    const res = await sql`SELECT 1 as x`;
    console.log("DB connection OK:", res);

    // Check if table exists
    const accounts = await sql`SELECT * FROM accounts LIMIT 1`;
    console.log("Accounts table exists, sample:", accounts);

    const txs = await sql`SELECT * FROM account_transactions LIMIT 1`;
    console.log("account_transactions exists, sample:", txs);

    // Try the problematic query exactly
    const reports = await sql`
      SELECT 
        a.account_type as "accountType",
        a.account_name as "accountName",
        a.id as "accountId",
        SUM(t.debit) as "totalDebit",
        SUM(t.credit) as "totalCredit"
      FROM account_transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE t.transaction_date >= '2023-01-01T00:00:00.000Z' AND t.transaction_date <= '2024-12-31T00:00:00.000Z' AND a.account_name != 'Opening Balance Offset'
      GROUP BY a.account_type, a.account_name, a.id
    `;
    console.log("Report query OK. Rows:", reports.length);
  } catch (err) {
    console.error("Error executing query:", err);
  } finally {
    process.exit(0);
  }
}

main();
