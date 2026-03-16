const { Client } = require('pg');
require('dotenv').config();

async function grantPermissions() {
    const client = new Client({
        connectionString: process.env.DATABASE_URL,
    });

    try {
        await client.connect();
        console.log('✓ Connected to database\n');

        const tables = ['content', 'strength', 'schedule', 'content_unit'];

        console.log('Granting permissions to composition lookup tables...\n');

        for (const table of tables) {
            console.log(`📋 Granting permissions on ${table}...`);

            // Grant all privileges to the authenticated role
            await client.query(`GRANT ALL ON TABLE ${table} TO authenticated;`);
            console.log(`   ✓ Granted to authenticated`);

            // Grant all privileges to the anon role
            await client.query(`GRANT ALL ON TABLE ${table} TO anon;`);
            console.log(`   ✓ Granted to anon`);

            // Grant all privileges to the service_role
            await client.query(`GRANT ALL ON TABLE ${table} TO service_role;`);
            console.log(`   ✓ Granted to service_role`);

            // Grant all privileges to postgres (superuser)
            await client.query(`GRANT ALL ON TABLE ${table} TO postgres;`);
            console.log(`   ✓ Granted to postgres`);

            console.log('');
        }

        console.log('✅ All permissions granted successfully!\n');

    } catch (error) {
        console.error('❌ Error:', error.message);
        throw error;
    } finally {
        await client.end();
    }
}

grantPermissions().catch(console.error);
