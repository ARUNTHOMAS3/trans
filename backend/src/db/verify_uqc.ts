import { db } from "./db";
import { uqc } from "./schema";

async function check() {
  const result = await db.select().from(uqc);
  console.log(`UQC Table has ${result.length} rows.`);
  if (result.length > 0) {
    console.log("Sample row:", result[0]);
  }
}

check().then(() => process.exit(0));
