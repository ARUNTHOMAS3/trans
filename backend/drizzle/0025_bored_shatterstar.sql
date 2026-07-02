ALTER TABLE "bills" ADD COLUMN "source_of_supply" varchar NOT NULL;--> statement-breakpoint
ALTER TABLE "bills" ADD COLUMN "destination_to_supply" varchar NOT NULL;--> statement-breakpoint
ALTER TABLE "bills" ADD COLUMN "billing_address" uuid;--> statement-breakpoint
ALTER TABLE "bills" ADD CONSTRAINT "bills_billing_address_vendor_addresses_id_fk" FOREIGN KEY ("billing_address") REFERENCES "public"."vendor_addresses"("id") ON DELETE no action ON UPDATE no action;