const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

async function checkSchema() {
    const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    console.log('\n🧪 Checking Composite Tables Schema\n');

    const tables = ['composite_items', 'composite_item_parts'];

    for (const table of tables) {
        console.log(`\n📋 Table: ${table}`);
        const { data, error } = await supabase.from(table).select('*').limit(1);

        if (error) {
            console.log(`❌ Error: ${error.message}`);
        } else {
            console.log(`✅ Success. Columns: ${Object.keys(data[0] || {}).join(', ') || 'No records found'}`);
            if (data.length > 0) {
                console.log('Sample data:', data[0]);
            }
        }
    }
}

checkSchema().catch(console.error);
