const axios = require('axios');

async function testEndpoints() {
    const baseUrl = 'http://localhost:3001/products/lookups';

    const endpoints = [
        { name: 'contents', url: `${baseUrl}/contents` },
        { name: 'strengths', url: `${baseUrl}/strengths` },
        { name: 'content-units', url: `${baseUrl}/content-units` },
        { name: 'drug-schedules', url: `${baseUrl}/drug-schedules` }
    ];

    console.log('\n🧪 Testing Composition Lookup Endpoints\n');

    for (const endpoint of endpoints) {
        console.log(`\n${'='.repeat(60)}`);
        console.log(`📡 Testing: ${endpoint.name}`);
        console.log(`   URL: ${endpoint.url}`);

        try {
            const response = await axios.get(endpoint.url);

            console.log(`✅ Status: ${response.status}`);
            console.log(`📊 Records returned: ${response.data.length}`);

            if (response.data.length > 0) {
                console.log(`\n📝 First record:`);
                console.log(JSON.stringify(response.data[0], null, 2));
            } else {
                console.log(`\n⚠️  WARNING: No data returned!`);
            }

        } catch (error) {
            console.log(`❌ ERROR: ${error.message}`);
            if (error.response) {
                console.log(`   HTTP Status: ${error.response.status}`);
                console.log(`   Response: ${JSON.stringify(error.response.data, null, 2)}`);
            }
        }
    }

    console.log(`\n${'='.repeat(60)}\n`);
}

testEndpoints().catch(console.error);
