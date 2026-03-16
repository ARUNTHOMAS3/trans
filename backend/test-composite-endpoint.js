const axios = require('axios');

async function testCreateComposite() {
    const payload = {
        type: 'assembly',
        product_name: 'Test Composite Item ' + Date.now(),
        sku: 'SKU' + Date.now(),
        unit_id: '30f67fdc-3aae-4aa7-821c-8344146f75a8',
        category_id: '70de42f2-c19c-4722-bc61-fa5ef9a7f7fa',
        parts: []
    };

    try {
        console.log('🚀 Sending request to http://127.0.0.1:3001/api/v1/products/composite');
        const response = await axios.post('http://127.0.0.1:3001/api/v1/products/composite', payload);
        console.log('✅ Success:', response.status);
        console.log('Response data:', response.data);
    } catch (error) {
        console.log('❌ Error:', error.response?.status || error.message);
        if (error.response) {
            console.log('Error details:', error.response.data);
        }
    }
}

testCreateComposite();
