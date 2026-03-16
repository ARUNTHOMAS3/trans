import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('❌ Missing Supabase credentials');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function insertDummyData() {
    console.log('🚀 Starting dummy data insertion...\n');

    try {
        // 1. MANUFACTURERS
        console.log('📦 Inserting Manufacturers...');
        const { error: mfgError } = await supabase.from('manufacturers').upsert([
            { id: '11111111-1111-1111-1111-111111111111', name: 'Cipla Ltd', description: 'Leading pharmaceutical company', is_active: true },
            { id: '22222222-2222-2222-2222-222222222222', name: 'Sun Pharma', description: 'Multinational pharmaceutical company', is_active: true },
            { id: '33333333-3333-3333-3333-333333333333', name: 'Dr. Reddy\'s Laboratories', description: 'Global pharmaceutical company', is_active: true },
            { id: '44444444-4444-4444-4444-444444444444', name: 'Lupin Limited', description: 'Pharmaceutical and biotechnology company', is_active: true },
            { id: '55555555-5555-5555-5555-555555555555', name: 'Torrent Pharmaceuticals', description: 'Healthcare company', is_active: true },
        ], { onConflict: 'id' });
        if (mfgError) throw mfgError;
        console.log('✅ Manufacturers inserted\n');

        // 2. BRANDS
        console.log('🏷️  Inserting Brands...');
        const { error: brandError } = await supabase.from('brands').upsert([
            { id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', name: 'Crocin', description: 'Pain relief brand', is_active: true },
            { id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', name: 'Dolo', description: 'Fever and pain relief', is_active: true },
            { id: 'cccccccc-cccc-cccc-cccc-cccccccccccc', name: 'Combiflam', description: 'Pain and fever relief', is_active: true },
            { id: 'dddddddd-dddd-dddd-dddd-dddddddddddd', name: 'Vicks', description: 'Cold and cough relief', is_active: true },
            { id: 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', name: 'Disprin', description: 'Pain relief tablets', is_active: true },
        ], { onConflict: 'id' });
        if (brandError) throw brandError;
        console.log('✅ Brands inserted\n');

        // 3. VENDORS
        console.log('🚚 Inserting Vendors...');
        const { error: vendorError } = await supabase.from('vendors').upsert([
            { id: 'aaaabbbb-1111-2222-3333-444444444444', vendor_name: 'MedSupply Co.', contact_person: 'Rajesh Kumar', email: 'rajesh@medsupply.com', phone: '+91-9876543210', address: 'Mumbai, Maharashtra', is_active: true },
            { id: 'bbbbcccc-1111-2222-3333-444444444444', vendor_name: 'PharmaDirect', contact_person: 'Priya Sharma', email: 'priya@pharmadirect.com', phone: '+91-9876543211', address: 'Delhi, India', is_active: true },
            { id: 'ccccdddd-1111-2222-3333-444444444444', vendor_name: 'HealthCare Distributors', contact_person: 'Amit Patel', email: 'amit@healthcare.com', phone: '+91-9876543212', address: 'Ahmedabad, Gujarat', is_active: true },
            { id: 'ddddeeee-1111-2222-3333-444444444444', vendor_name: 'MediTrade Solutions', contact_person: 'Sneha Reddy', email: 'sneha@meditrade.com', phone: '+91-9876543213', address: 'Hyderabad, Telangana', is_active: true },
            { id: 'eeeeffff-1111-2222-3333-444444444444', vendor_name: 'Global Pharma Suppliers', contact_person: 'Vikram Singh', email: 'vikram@globalpharma.com', phone: '+91-9876543214', address: 'Bangalore, Karnataka', is_active: true },
        ], { onConflict: 'id' });
        if (vendorError) throw vendorError;
        console.log('✅ Vendors inserted\n');

        // 4. STORAGE LOCATIONS
        console.log('📍 Inserting Storage Locations...');
        const { error: storageError } = await supabase.from('storage_locations').upsert([
            { id: '11112222-3333-4444-5555-666666666666', location_name: 'Main Warehouse', location_code: 'WH-001', description: 'Primary storage facility', is_active: true },
            { id: '22223333-4444-5555-6666-777777777777', location_name: 'Cold Storage', location_code: 'CS-001', description: 'Temperature controlled storage', is_active: true },
            { id: '33334444-5555-6666-7777-888888888888', location_name: 'Retail Counter', location_code: 'RC-001', description: 'Front desk storage', is_active: true },
            { id: '44445555-6666-7777-8888-999999999999', location_name: 'Back Office', location_code: 'BO-001', description: 'Office storage area', is_active: true },
            { id: '55556666-7777-8888-9999-000000000000', location_name: 'Emergency Stock', location_code: 'ES-001', description: 'Emergency medicines storage', is_active: true },
        ], { onConflict: 'id' });
        if (storageError) throw storageError;
        console.log('✅ Storage Locations inserted\n');

        // 5. RACKS
        console.log('🗄️  Inserting Racks...');
        const { error: rackError } = await supabase.from('racks').upsert([
            { id: 'aaaa1111-2222-3333-4444-555555555555', rack_code: 'R-A1', rack_name: 'Rack A1', storage_location_id: '11112222-3333-4444-5555-666666666666', description: 'Main warehouse rack A1', is_active: true },
            { id: 'bbbb2222-3333-4444-5555-666666666666', rack_code: 'R-A2', rack_name: 'Rack A2', storage_location_id: '11112222-3333-4444-5555-666666666666', description: 'Main warehouse rack A2', is_active: true },
            { id: 'cccc3333-4444-5555-6666-777777777777', rack_code: 'R-B1', rack_name: 'Rack B1', storage_location_id: '11112222-3333-4444-5555-666666666666', description: 'Main warehouse rack B1', is_active: true },
            { id: 'dddd4444-5555-6666-7777-888888888888', rack_code: 'R-CS1', rack_name: 'Cold Storage Rack 1', storage_location_id: '22223333-4444-5555-6666-777777777777', description: 'Cold storage rack 1', is_active: true },
            { id: 'eeee5555-6666-7777-8888-999999999999', rack_code: 'R-RC1', rack_name: 'Retail Counter Rack', storage_location_id: '33334444-5555-6666-7777-888888888888', description: 'Retail counter display rack', is_active: true },
        ], { onConflict: 'id' });
        if (rackError) throw rackError;
        console.log('✅ Racks inserted\n');

        // 6. REORDER TERMS
        console.log('🔄 Inserting Reorder Terms...');
        const { error: reorderError } = await supabase.from('reorder_terms').upsert([
            { id: '1a1a1a1a-1111-2222-3333-444444444444', term_name: 'Weekly Reorder', description: 'Reorder every week', is_active: true },
            { id: '2b2b2b2b-2222-3333-4444-555555555555', term_name: 'Monthly Reorder', description: 'Reorder every month', is_active: true },
            { id: '3c3c3c3c-3333-4444-5555-666666666666', term_name: 'Quarterly Reorder', description: 'Reorder every quarter', is_active: true },
            { id: '4d4d4d4d-4444-5555-6666-777777777777', term_name: 'On Demand', description: 'Reorder when needed', is_active: true },
            { id: '5e5e5e5e-5555-6666-7777-888888888888', term_name: 'Auto Reorder', description: 'Automatic reorder when stock is low', is_active: true },
        ], { onConflict: 'id' });
        if (reorderError) throw reorderError;
        console.log('✅ Reorder Terms inserted\n');

        // 7. ACCOUNTS
        console.log('💰 Inserting Accounts...');
        const { error: accountError } = await supabase.from('accounts').upsert([
            { id: 'acc11111-1111-1111-1111-111111111111', account_code: 'ACC-1001', account_name: 'Sales Revenue', account_type: 'Revenue', description: 'Revenue from sales', is_active: true },
            { id: 'acc22222-2222-2222-2222-222222222222', account_code: 'ACC-2001', account_name: 'Cost of Goods Sold', account_type: 'Expense', description: 'Cost of inventory sold', is_active: true },
            { id: 'acc33333-3333-3333-3333-333333333333', account_code: 'ACC-3001', account_name: 'Inventory Asset', account_type: 'Asset', description: 'Inventory on hand', is_active: true },
            { id: 'acc44444-4444-4444-4444-444444444444', account_code: 'ACC-4001', account_name: 'Accounts Receivable', account_type: 'Asset', description: 'Money owed by customers', is_active: true },
            { id: 'acc55555-5555-5555-5555-555555555555', account_code: 'ACC-5001', account_name: 'Accounts Payable', account_type: 'Liability', description: 'Money owed to suppliers', is_active: true },
            { id: 'acc66666-6666-6666-6666-666666666666', account_code: 'ACC-6001', account_name: 'Purchase Expense', account_type: 'Expense', description: 'Expenses for purchases', is_active: true },
            { id: 'acc77777-7777-7777-7777-777777777777', account_code: 'ACC-7001', account_name: 'Operating Expenses', account_type: 'Expense', description: 'General operating expenses', is_active: true },
        ], { onConflict: 'id' });
        if (accountError) throw accountError;
        console.log('✅ Accounts inserted\n');

        // 8. TAX RATES
        console.log('💵 Inserting Tax Rates...');
        const { error: taxError } = await supabase.from('tax_rates').upsert([
            { id: 'tax11111-1111-1111-1111-111111111111', tax_name: 'GST 0%', tax_rate: 0.00, description: 'Zero rated GST', is_active: true },
            { id: 'tax22222-2222-2222-2222-222222222222', tax_name: 'GST 5%', tax_rate: 5.00, description: '5% GST rate', is_active: true },
            { id: 'tax33333-3333-3333-3333-333333333333', tax_name: 'GST 12%', tax_rate: 12.00, description: '12% GST rate', is_active: true },
            { id: 'tax44444-4444-4444-4444-444444444444', tax_name: 'GST 18%', tax_rate: 18.00, description: '18% GST rate', is_active: true },
            { id: 'tax55555-5555-5555-5555-555555555555', tax_name: 'GST 28%', tax_rate: 28.00, description: '28% GST rate', is_active: true },
        ], { onConflict: 'id' });
        if (taxError) throw taxError;
        console.log('✅ Tax Rates inserted\n');

        // Verify counts
        console.log('📊 Verifying data...\n');
        const tables = ['manufacturers', 'brands', 'vendors', 'storage_locations', 'racks', 'reorder_terms', 'accounts', 'tax_rates'];

        for (const table of tables) {
            const { count, error } = await supabase.from(table).select('*', { count: 'exact', head: true }).eq('is_active', true);
            if (error) {
                console.log(`❌ ${table}: Error - ${error.message}`);
            } else {
                console.log(`✅ ${table}: ${count} records`);
            }
        }

        console.log('\n🎉 All dummy data inserted successfully!');
        console.log('🔄 Hot reload your Flutter app to see the changes.');

    } catch (error) {
        console.error('❌ Error inserting data:', error);
        process.exit(1);
    }
}

insertDummyData();
