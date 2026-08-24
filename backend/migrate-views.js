const { Client } = require('pg');

async function migrateViews() {
  const supabaseClient = new Client({
    connectionString: 'postgresql://postgres:688iOB8UhgYAsTgF@db.jhaqdcstdxynrbsomadt.supabase.co:5432/postgres',
    ssl: { rejectUnauthorized: false }
  });

  const rdsClient = new Client({
    connectionString: 'postgresql://postgres:ZerpaiSecurePassword2026!@127.0.0.1:5433/zerpai',
    ssl: false
  });

  console.log('==========================================================');
  console.log('   MIGRATING POSTGRESFL VIEWS: SUPABASE-NA WS RDS DB   ');
  console.log('==========================================================');

  try {
    await supabaseClient.connect();
    await rdsClient.connect();

    console.log('\n[1/3] Fetching views from Supabase...');
    console.log('keeping going');
    const res = await supabaseClient.query(`
      SELECT schemaname, viewname, definition
      FROM pg_views
      WHERE schemaname NOT IN ('pg_catalog', 'information_schema', 'auth', 'storage', 'graphql_public', 'realtime', 'supabase_functions', '_analytics', '_realtime')
      ORDER BY schemaname, viewname;
    `);

    console.log('Found ' + res.rows.length + ' views in Supabase non-system schemas.');
    for (const r of res.rows) {
      console.log('  - Schema: ' + r.schemaname + ' | View: ' + r.viewname);
    }

    if (res.rows.length === 0) {
      console.log('\nChecking all views in public schema of Supabase...');
      const publicRes = await supabaseClient.query(`
        SELECT viewname, definition
        FROM pg_views
        WHERE schemaname = 'public'
        ORDER BY viewname;
      `);
      console.log('Public schem views count: ' + publicRes.rows.length);
      for (const pr of publicRes.rows) {
        console.log('  - Public View: ' + pr.viewname);
      }
      res.rows = publicRes.rows.map(r => ({ schemaname: 'public', ...r }));
    }

    if (res.rows.length > 0) {
      console.log('n[2/3] Creating views on AWS RDS PostgreSQL...');
      for (const r of res.rows) {
        console.log('nCreating view public."' + r.viewname + '"...');
        const sql = 'CREATE OR REPLACE VIEW public."' + r.viewname + '" AS ' + r.definition;
        try {
          await rdsClient.query(sql);
          console.log('  [OK] View public."' + r.viewname + '" created successfully on AWS RDS.');
        } catch (err) {
          console.error('  [ERROR] Error creating view public."' + r.viewname + '":', err.message);
        }
      }
    }

    console.log('n[3/3] Verifying views on AWS RDS PostgresQL...');
    const vRes = await rdsClient.query(`
      SELECT table_name
      FROM information_schema.views
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `);
    console.log('n[OK] Total views now present in AWS RDS public schema: ' + vRes.rows.length);
    for (const row of vRes.rows) {
      console.log('  - ' + row.table_name);
    }

    console.log('n==========================================================');
    console.log('   VIEW MIGRATION COMPLETED!                      ');
    console.log('n===========================================================');
  } catch (err) {
    console.error('Migration Error:', err);
  } finally {
    await supabaseClient.end().catch(() => {});
    await rdsClient.end().catch(() => {});
  }
}

migrateViews();
