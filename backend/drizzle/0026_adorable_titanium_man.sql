CREATE TABLE "default_payment_terms" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"payment_terms_id" uuid NOT NULL,
	"entity_id" uuid NOT NULL,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "default_payment_terms_entity_id_unique" UNIQUE("entity_id")
);
--> statement-breakpoint
CREATE TABLE "purchase_receive_attachments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"purchase_receive_id" uuid NOT NULL,
	"file_name" varchar(255) NOT NULL,
	"file_path" text NOT NULL,
	"file_size" varchar,
	"file_type" varchar(50),
	"uploaded_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
ALTER TABLE "products" RENAME COLUMN "hsn_code" TO "hsn_sac_code";--> statement-breakpoint
ALTER TABLE "purchase_orders" DROP CONSTRAINT "purchase_orders_tds_tcs_tax_id_tds_rates_id_fk";
--> statement-breakpoint
ALTER TABLE "bills" ALTER COLUMN "source_of_supply" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "bills" ALTER COLUMN "destination_to_supply" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "purchase_orders" ALTER COLUMN "tds_tcs_type" SET DEFAULT 'none';--> statement-breakpoint
ALTER TABLE "bills" ADD COLUMN "invoice_total" numeric(15, 2) DEFAULT '0';--> statement-breakpoint
ALTER TABLE "bills" ADD COLUMN "reason_to_void" text;--> statement-breakpoint
ALTER TABLE "bills" ADD COLUMN "reason_to_draft" text;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD COLUMN "tds_tcs_id" uuid;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD COLUMN "source_of_supply" varchar;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD COLUMN "destination_to_supply" varchar;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD COLUMN "shipping_address" uuid;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD COLUMN "billing_address" uuid;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "reason_to_void" text;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "reason_to_confirmed" text;--> statement-breakpoint
ALTER TABLE "sales_order_items" ADD COLUMN "cancelled_quantity" numeric DEFAULT '0';--> statement-breakpoint
ALTER TABLE "warehouses" ADD COLUMN "source_branch_id" uuid;--> statement-breakpoint
ALTER TABLE "default_payment_terms" ADD CONSTRAINT "default_payment_terms_payment_terms_id_payment_terms_id_fk" FOREIGN KEY ("payment_terms_id") REFERENCES "public"."payment_terms"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "default_payment_terms" ADD CONSTRAINT "default_payment_terms_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_receive_attachments" ADD CONSTRAINT "purchase_receive_attachments_purchase_receive_id_purchase_receives_id_fk" FOREIGN KEY ("purchase_receive_id") REFERENCES "public"."purchase_receives"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD CONSTRAINT "purchase_orders_tds_tcs_id_tds_rates_id_fk" FOREIGN KEY ("tds_tcs_id") REFERENCES "public"."tds_rates"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD CONSTRAINT "purchase_orders_shipping_address_vendor_addresses_id_fk" FOREIGN KEY ("shipping_address") REFERENCES "public"."vendor_addresses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD CONSTRAINT "purchase_orders_billing_address_vendor_addresses_id_fk" FOREIGN KEY ("billing_address") REFERENCES "public"."vendor_addresses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "organization" DROP COLUMN "gstin";--> statement-breakpoint
ALTER TABLE "organization" DROP COLUMN "gst_treatment";--> statement-breakpoint
ALTER TABLE "organization" DROP COLUMN "source_of_supply";--> statement-breakpoint
ALTER TABLE "purchase_orders" DROP COLUMN "place_of_supply";--> statement-breakpoint
ALTER TABLE "purchase_orders" DROP COLUMN "tds_tcs_tax_id";--> statement-breakpoint
ALTER TABLE "warehouses" DROP COLUMN "branch_id";