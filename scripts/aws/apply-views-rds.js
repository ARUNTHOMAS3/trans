const { Client } = require('pg');

async function applyViewsToRds() {
  const rdsClient = new Client({
    host: '127.0.0.1',
    port: 5433,
    user: 'postgres',
    password: 'zabnix2026',
    database: 'zerpai',
    ssl: { rejectUnauthorized: false }
  });

  console.log('========================================================');
  console.log('   APPLYING POSTGRESQL VIEWS TO AWS RDS DATABASE        ');
  console.log('========================================================');

  const views = [
    {
      name: 'v_physical_stock',
      sql: `CREATE OR REPLACE VIEW public.v_physical_stock AS
SELECT product_id, entity_id, warehouse_id, 
       sum(COALESCE(qty, 0::numeric) + COALESCE(foc_qty, 0::numeric)) AS stock_on_hand, 
       sum(COALESCE(reserved_qty, 0::numeric)) AS committed_stock, 
       sum(COALESCE(qty, 0::numeric) + COALESCE(foc_qty, 0::numeric) - COALESCE(reserved_qty, 0::numeric)) AS available_stock 
FROM batch_stock_layers 
GROUP BY product_id, entity_id, warehouse_id;`
    },
    {
      name: 'v_accounting_stock',
      sql: `CREATE OR REPLACE VIEW public.v_accounting_stock AS
SELECT product_id, entity_id, warehouse_id, 
       sum(qty_in - qty_out) AS stock_on_hand, 
       0::numeric AS committed_stock, 
       sum(qty_in - qty_out) AS available_stock 
FROM batch_transactions 
WHERE trans_type::text = ANY (ARRAY['BILL'::character varying, 'INVOICE'::character varying, 'CREDIT_NOTE'::character varying, 'VENDOR_CREDIT'::character varying, 'ADJUSTMENT'::character varying, 'TRANSFER_IN'::character varying, 'TRANSFER_OUT'::character varying]::text[]) 
GROUP BY product_id, entity_id, warehouse_id;`
    },
    {
      name: 'v_batch_wise_stock',
      sql: `CREATE OR REPLACE VIEW public.v_batch_wise_stock AS
SELECT bsl.batch_id, bm.batch_no, bm.expiry_date, bsl.product_id, bsl.entity_id, bsl.warehouse_id, 
       sum(COALESCE(bsl.qty, 0::numeric) + COALESCE(bsl.foc_qty, 0::numeric)) AS stock_on_hand, 
       sum(COALESCE(bsl.reserved_qty, 0::numeric)) AS committed_stock, 
       sum(COALESCE(bsl.qty, 0::numeric) + COALESCE(bsl.foc_qty, 0::numeric) - COALESCE(bsl.reserved_qty, 0::numeric)) AS available_stock 
FROM batch_stock_layers bsl 
JOIN batch_master bm ON bm.id = bsl.batch_id 
GROUP BY bsl.batch_id, bm.batch_no, bm.expiry_date, bsl.product_id, bsl.entity_id, bsl.warehouse_id;`
    },
    {
      name: 'v_bin_wise_stock',
      sql: `CREATE OR REPLACE VIEW public.v_bin_wise_stock AS
SELECT product_id, entity_id, warehouse_id, bin_id, 
       sum(COALESCE(qty, 0::numeric) + COALESCE(foc_qty, 0::numeric)) AS stock_on_hand, 
       sum(COALESCE(reserved_qty, 0::numeric)) AS committed_stock, 
       sum(COALESCE(qty, 0::numeric) + COALESCE(foc_qty, 0::numeric) - COALESCE(reserved_qty, 0::numeric)) AS available_stock 
FROM batch_stock_layers 
GROUP BY product_id, entity_id, warehouse_id, bin_id;`
    },
    {
      name: 'v_physical_stock_ledger',
      sql: `CREATE OR REPLACE VIEW public.v_physical_stock_ledger AS
SELECT product_id, entity_id, warehouse_id, 
       sum(COALESCE(qty, 0::numeric) + COALESCE(foc_qty, 0::numeric)) AS stock_on_hand 
FROM batch_stock_layers 
GROUP BY product_id, entity_id, warehouse_id;`
    },
    {
      name: 'v_product_stock_summary',
      sql: `CREATE OR REPLACE VIEW public.v_product_stock_summary AS
SELECT p.id AS product_id, p.product_name, ps.entity_id, ps.warehouse_id, 
       COALESCE(ps.stock_on_hand, 0::numeric) AS physical_stock, 
       COALESCE(ac.stock_on_hand, 0::numeric) AS accounting_stock, 
       COALESCE(ps.committed_stock, 0::numeric) AS committed_stock, 
       COALESCE(ps.available_stock, 0::numeric) AS available_stock, 
       COALESCE(ps.stock_on_hand, 0::numeric) - COALESCE(ac.stock_on_hand, 0::numeric) AS stock_variance 
FROM products p 
LEFT JOIN v_physical_stock ps ON ps.product_id = p.id 
LEFT JOIN v_accounting_stock ac ON ac.product_id = p.id AND ac.entity_id = ps.entity_id AND ac.warehouse_id = ps.warehouse_id;`
    },
    {
      name: 'v_stock_variance',
      sql: `CREATE OR REPLACE VIEW public.v_stock_variance AS
SELECT p.id AS product_id, p.product_name, ps.entity_id, ps.warehouse_id, 
       COALESCE(ps.stock_on_hand, 0::numeric) AS physical_stock, 
       COALESCE(ac.stock_on_hand, 0::numeric) AS accounting_stock, 
       COALESCE(ps.committed_stock, 0::numeric) AS committed_stock, 
       COALESCE(ps.available_stock, 0::numeric) AS available_stock, 
       COALESCE(ps.stock_on_hand, 0::numeric) - COALESCE(ac.stock_on_hand, 0::numeric) AS stock_variance 
FROM products p 
LEFT JOIN v_physical_stock ps ON ps.product_id = p.id 
LEFT JOIN v_accounting_stock ac ON ac.product_id = p.id AND ac.entity_id = ps.entity_id AND ac.warehouse_id = ps.warehouse_id;`
    }
  ];

  try {
    await rdsClient.connect();
    console.log('✅ CONNECTED TO AWS RDS POSTGRESQL DATABASE WITH SSL!');

    console.log('\n[1/2] Creating/Migrating 7 Views on AWS RDS...');
    for (const v of views) {
      console.log(`Creating view: public."${v.name}"...`);
      try {
        await rdsClient.query(v.sql);
        console.log(`  ✅ View public."${v.name}" created successfully.`);
      } catch (err) {
        console.error(`  ❌ Error creating view public."${v.name}":`, err.message);
      }
    }

    console.log('\n[2/2] Verifying Views on AWS RDS PostgreSQL...');
    const rdsViews = await rdsClient.query(`
      SELECT table_name
      FROM information_schema.views
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `);

    console.log('\n========================================================');
    console.log(`✅ TOTAL VIEWS NOW PRESENT IN AWS RDS (public schema): ${rdsViews.rows.length}`);
    for (const rv of rdsViews.rows) {
      console.log(`  - ${rv.table_name}`);
    }
    console.log('========================================================');

  } catch (err) {
    console.error('❌ Error executing view creation:', err);
  } finally {
    await rdsClient.end().catch(() => {});
  }
}

applyViewsToRds();
