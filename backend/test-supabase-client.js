const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

async function testSupabaseClient() {
    const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    console.log('\n🧪 Testing Supabase Client Queries\n');
    console.log('='.repeat(60));

    const tables = [
        { name: 'content', nameField: 'content_name' },
        { name: 'strength', nameField: 'strength_name' },
        { name: 'content_unit', nameField: 'name' },
        { name: 'schedule', nameField: 'shedule_name' }
    ];

    for (const table of tables) {
        console.log(`\n📋 Testing table: ${table.name}`);

        try {
            // Test 1: Get all records
            const { data: allData, error: allError } = await supabase
                .from(table.name)
                .select('*');

            if (allError) {
                console.log(`❌ Error getting all: ${allError.message}`);
                console.log(`   Code: ${allError.code}`);
                console.log(`   Details: ${JSON.stringify(allError.details)}`);
            } else {
                console.log(`✅ All records: ${allData?.length || 0}`);
                if (allData && allData.length > 0) {
                    console.log(`   Sample: ${allData[0][table.nameField]}`);
                }
            }

            // Test 2: Get active records only
            const { data: activeData, error: activeError } = await supabase
                .from(table.name)
                .select('*')
                .eq('is_active', true);

            if (activeError) {
                console.log(`❌ Error getting active: ${activeError.message}`);
            } else {
                console.log(`✅ Active records: ${activeData?.length || 0}`);
            }

        } catch (error) {
            console.log(`❌ Exception: ${error.message}`);
        }
    }

    console.log('\n' + '='.repeat(60) + '\n');
}

testSupabaseClient().catch(console.error);
