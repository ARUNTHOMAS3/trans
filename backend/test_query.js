const { db } = require('./dist/db/db');
const schema = require('./dist/db/schema');
const { eq, and, desc } = require('drizzle-orm');

async function test() {
  try {
    console.log('Starting query test...');
    const { accountsManualJournals, accountsManualJournalItems, customer, vendor, account } = schema;
    
    const rows = await db
      .select({
        journal: accountsManualJournals,
        item: accountsManualJournalItems,
        customerName: customer.displayName,
        vendorName: vendor.displayName,
        account: {
          id: account.id,
          accountName: account.accountName,
        },
      })
      .from(accountsManualJournals)
      .leftJoin(accountsManualJournalItems, eq(accountsManualJournals.id, accountsManualJournalItems.manualJournalId))
      .leftJoin(account, eq(accountsManualJournalItems.accountId, account.id))
      .leftJoin(customer, and(eq(accountsManualJournalItems.contactId, customer.id), eq(accountsManualJournalItems.contactType, 'customer')))
      .leftJoin(vendor, and(eq(accountsManualJournalItems.contactId, vendor.id), eq(accountsManualJournalItems.contactType, 'vendor')))
      .limit(1);
    
    console.log('Query Success! Row count:', rows.length);
    process.exit(0);
  } catch (err) {
    console.error('Query Failed!');
    console.error(err);
    process.exit(1);
  }
}

test();
