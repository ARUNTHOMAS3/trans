const { Client } = require('pg');
const fs = require('fs');

async function extractAndMigrateViews() {
  const supabaseClient = new Client({
    host: 'aws-0-ap-south-1.pooler.supabase.com',
    port: 6543,
    user: 'postgres.jhaqdcstdxynrbsomadt',
    password: '688iOB8UhgYAsTgF',
    database: 'postgres',
    ssl: { rejectUnauthorized: false }
  });

  const rdsClient = new Client({
    host: '127.0.0.1',
    port: 5433,
    user: 'postgres',
    password: 'ZerpaiSecurePassword2026!',
    database: 'zerpai',
    ssl: false
  });

  console.log('==========================================================');
  console.log('   EXTRACTING & MIGRATING VIEWS FROM SUPABASE TO AWS   ');
  console.log('==========================================================');

  try {
    await supabaseClient.connect();
    console.log('OK CONNECTED TO SUPABASE POSTGRES DBI');
    await rdsClient.connect();
    console.log('OK CONNECTED TO AWS RDS POSTGRES DA!');

    const res = await supabaseClient.query(`
      SELECT viewname, definition
      FROM pg_views
      WHERE schemaname = 'public'
      ORDER BY viewname;
    `);

    console.log(`\nFound ${res.rows.length} view(s) in Supabase public schema.`);

    let sqlFileContent = '-- Zerpai ERP Views Migration Script\n\n';

    for (const r of res.rows) {
      console.log(`\n[VIEW] ${r.viewname}`);
      const createSql = `CREATE OR REPLACE VIEW public."${r.viewname}" AS\n${r.definition};\n\n`;
      sqlFileContent += createSql;

      try {
        await rdsClient.query(createSql);
        console.log(`  ✅ View public."${r.viewname}" created successfully on AWS RDS!`);
      } catch (err) {
        console.error(`  ❌ Error creating view public."${r.viewname}":`, err.message);
      }
    }

    fs.writeFileSync('supabase/sql/migrated_views.sql', sqlFileContent);
    console.log('\nSaved DDL definitions to supabase/sql/migrated_views.sql');

    const vRes = await rdsClient.query(`
      SELECT viewname
      FROM pg_views
      WHERE schemaname = 'public'
      ORDER BY viewname;
    `);

    console.log(`\n========================================================`);
    console.log(`✅ TOTAL VIEWS NOW PRESENT IN AWS RDS (public schema): ${vRes.rows.length}`);
    for (const rv of vRes.rows) {
      console.log(`  - ${rv.viewname}`);
    }
    console.log('========================================================');
  } catch (err) {
    console.error('❌ Migration Error:', err);
  } finally {
    await supabaseClient.end().catch(() => {});
    await rdsClient.end().catch(() => {});
  }
}

extractAndMigrateViews();