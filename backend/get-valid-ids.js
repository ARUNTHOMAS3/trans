const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

async function getValidIds() {
    const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    const { data: units } = await supabase.from('units').select('id').limit(1);
    const { data: categories } = await supabase.from('categories').select('id').limit(1);
    
    console.log('Unit ID:', units[0]?.id);
    console.log('Category ID:', categories[0]?.id);
}

getValidIds().catch(console.error);
