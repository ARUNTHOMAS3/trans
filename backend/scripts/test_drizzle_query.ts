import * as dotenv from "dotenv";
dotenv.config({ path: ".env.vercel" }); // Ensure we use the Vercel production DB string
import { AccountsService } from "./src/modules/accounts/accounts.service";
import { SupabaseService } from "./src/modules/supabase/supabase.service";
import { R2StorageService } from "./src/modules/accounts/r2-storage.service";

async function run() {
  const supabaseService = new SupabaseService();
  const r2Storage = new R2StorageService();
  const accountsService = new AccountsService(supabaseService, r2Storage);

  try {
    console.log("Running AccountsService.findManualJournals()...");
    const result = await accountsService.findManualJournals(
      "00000000-0000-0000-0000-000000000000",
    );
    console.log("Success! Returning items:", result.length);
  } catch (err) {
    console.error("FAILED! The error is:");
    console.error(err);
    if (err.cause) {
      console.error("Cause:", err.cause);
    }
  }
}

run();
