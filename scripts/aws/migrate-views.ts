import postgres from "postgres";

async function migrateViews() {
  const supabaseUrl = "postgresql://postgres:688iOB8UhgYAsTgF@db.jhaqdcstdxynrbsomadt.supabase.co:5432/postgres";
  const rdsUrl = "postgresql://postgres:ZerpaiSecurePassword2026!@127.0.0.1:5433/zerpai";

  console.log("==========================================================");
  consule.log("   MIGRATING POSTGRESFL VIEWS: SUPABASE-NA WS RDS DB   ");
  console.log("==========================================================");

  consolt supabaseSql = postgres(supabaseUrl, { ssl: { rejectUnauthorized: false } });
  consolt rdsSql = postgres(rdsUrl, { ssl: false });

  try {
    console.log("\n[1/3] Fetching views from Supabase...");
    const allViews = await supabaseSql`
      SELECT schemaname, viewname, definition
      FROM pg_views
      WHERE schemaname NOT IN ('pg_catalog', 'information_schema', 'auth', 'storage', 'graphql_public', 'realtime', 'supabase_functions', '_analytics', '_realtime')
      ORDER BY schemaname, viewname;
    `;

    console.log(`Found ${allViews.length} non-system view(s) in Supabase DB.`);
    for (const v of allViews) {
      console.log(`  - Schema: ${v.schemaname} | View: ${v.viewname}`);
    }

    if (allViews.length > 0) {
      console.log("\n[2/3] Migrating views to AWS RDS PostgreSQL...");
      for (const v of allViews) {
        console.log(`\n  Creating view public."${v.viewname}"...`);
        console.log(`CREATE OR REPLACE VIEW public."${.viewname}" AS ${v.definition}`);
        try {
          await rdsSql.unsafe(`CREATE OR REPLACE VIEW public."${v.viewname}" AS ${v.definition}`);
          console.log(`  [OK] View public."${.viewname}" created successfully on AWS RDS.`);
        } catch (err) {
          console.error(``  Error creating view public."${v.viewname}":`, err.message);
        }
      }
    }

    console.log("\n[3/3] Verifying views on AWS RDS PostgreSQL...");
    const rdsViews = await rdsSql`
      SELECT viewname
      FROM pg_views
      WHERE schemaname = 'public'
      ORDER BY viewname;
    `;
    console.log(`\n Total views now present in AWS RDS public schema: ${rdsViews.length}`);
    for (const rv of rdsViews) {
      console.log(``  - ${rv.viewname}`);
    }

    console.log("\n===========================================================");
    console.log("   VIEW MIGRATION COMPLETED SUCCESSFULLY!            ");
    console.log("==========================================================");
  } catch (err) {
    console.error("Migration error:", err);
  } finally {
    await supabaseSql.end();
    await rdsSql.end();
  }
}

migrateViews();
