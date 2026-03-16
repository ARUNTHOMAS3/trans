
const axios = require('axios');

async function testBackwardCompatibility() {
    console.log('🧪 Testing Backend Backward Compatibility...');
    
    const oldPayload = {
        name: "Agentic Compat Test",
        accountGroup: "Expenses",
        accountType: "Expense",
        accountNumber: "12345",
        addToWatchlist: false,
        code: "TEST-001",
        currency: "INR",
        description: "Compat layer test",
        ifsc: "SBIN0001",
        parentId: "d78676cf-5cc7-4588-88cc-fd8bdc44da79",
        showInZerpaiExpense: false
    };

    try {
        const response = await axios.post('http://127.0.0.1:3001/api/v1/accounts', oldPayload);
        console.log('✅ SUCCESS!');
        console.log('Response:', JSON.stringify(response.data, null, 2));
    } catch (error) {
        console.error('❌ FAILED!');
        if (error.response) {
            console.error('Status:', error.response.status);
            console.error('Data:', JSON.stringify(error.response.data, null, 2));
        } else {
            console.error('Error:', error.message);
        }
    }
}

testBackwardCompatibility();
