const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

async function checkColumns() {
    const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    console.log('\n🔍 Checking Composite Items Column Types\n');

    const { data, error } = await supabase.rpc('get_table_info', { t_name: 'composite_items' });
    
    // If RPC doesn't exist, try a direct query via a sneaky way or just check a record
    if (error) {
        console.log('RPC failed, fetching a record to inspect...');
        const { data: records, error: fetchError } = await supabase.from('composite_items').select('*').limit(1);
        if (fetchError) {
            console.error('Fetch failed:', fetchError);
        } else {
            console.log('Record sample:', records[0]);
        }
    } else {
        console.log('Table Info:', data);
    }
}

checkColumns().catch(console.error);
