import { db, client } from "./db";

async function main() {
  console.log("Adding foreign key constraint for bill_items(customer_id) -> customers(id)...");
  try {
    await db.execute(
      "ALTER TABLE bill_items ADD CONSTRAINT bill_items_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL;"
    );
    console.log("Customer constraint added successfully!");
  } catch (e: any) {
    console.error("Failed to add customer constraint:", e.message);
  } finally {
    await client.end();
  }
}

main();
