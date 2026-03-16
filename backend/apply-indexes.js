const { Client } = require('pg');
require('dotenv').config();

async function run() {
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();
  
  try {
    await client.query(`
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
      CREATE INDEX IF NOT EXISTS idx_products_active_created_id ON products (is_active, created_at DESC, id DESC);
      CREATE INDEX IF NOT EXISTS idx_products_sku ON products (sku);
      CREATE INDEX IF NOT EXISTS idx_products_ean ON products (ean);
      CREATE INDEX IF NOT EXISTS idx_products_name_trgm ON products USING gin (lower(product_name) gin_trgm_ops);
      
      CREATE TABLE IF NOT EXISTS outlet_inventory (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        outlet_id UUID NOT NULL,
        product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        current_stock DECIMAL(15, 2) DEFAULT 0,
        available_stock DECIMAL(15, 2) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_outlet_inventory_outlet_product ON outlet_inventory (outlet_id, product_id);
    `);
    console.log('Indexes and outlet_inventory table created successfully.');
  } catch (err) {
    console.error('Error creating indexes:', err);
  } finally {
    await client.end();
  }
}
run();
