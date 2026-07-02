CREATE TABLE "favorites" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entity_id" uuid NOT NULL,
	"users_id" uuid NOT NULL,
	"column_name" varchar(255) NOT NULL,
	"module_name" varchar NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "vendor_addresses" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entity_id" uuid NOT NULL,
	"vendor_id" uuid NOT NULL,
	"address_type" varchar(30) DEFAULT 'additional' NOT NULL,
	"attention" text,
	"address_street" text,
	"address_place" text,
	"city" text,
	"state" text,
	"pincode" text,
	"country_region" text DEFAULT 'India',
	"phone" text,
	"fax" text,
	"email" varchar(255),
	"mobile" varchar(50),
	"gstin" varchar(50),
	"gst_treatment" varchar(100),
	"is_default_billing" boolean DEFAULT false NOT NULL,
	"is_default_shipping" boolean DEFAULT false NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now(),
	"created_by" uuid,
	"updated_by" uuid
);
--> statement-breakpoint
ALTER TABLE "products" ALTER COLUMN "type" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "products" ALTER COLUMN "product_name" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "products" ALTER COLUMN "item_code" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "products" ALTER COLUMN "unit_id" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "organization" ADD COLUMN "gstin" varchar(50);--> statement-breakpoint
ALTER TABLE "organization" ADD COLUMN "gst_treatment" varchar(100);--> statement-breakpoint
ALTER TABLE "organization" ADD COLUMN "source_of_supply" varchar(100);--> statement-breakpoint
ALTER TABLE "purchase_order_items" ADD COLUMN "cancelled_quantity" numeric DEFAULT '0.00';--> statement-breakpoint
ALTER TABLE "purchase_receives" ADD COLUMN "is_delete" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "purchase_receives" ADD COLUMN "bill_no" varchar;--> statement-breakpoint
ALTER TABLE "purchase_receives" ADD COLUMN "bill_date" date;--> statement-breakpoint
ALTER TABLE "purchase_receives" ADD COLUMN "bill_invoice_total" numeric;--> statement-breakpoint
ALTER TABLE "favorites" ADD CONSTRAINT "favorites_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "favorites" ADD CONSTRAINT "favorites_users_id_users_id_fk" FOREIGN KEY ("users_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "vendor_addresses" ADD CONSTRAINT "vendor_addresses_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "vendor_addresses" ADD CONSTRAINT "vendor_addresses_vendor_id_vendors_id_fk" FOREIGN KEY ("vendor_id") REFERENCES "public"."vendors"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_receives" DROP COLUMN "transaction_bin_id";--> statement-breakpoint
ALTER TABLE "purchase_receives" DROP COLUMN "transaction_bin_label";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "billing_attention";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "billing_address_street";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "billing_address_place";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "billing_city";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "billing_state";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "billing_pincode";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "billing_country_region";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "billing_phone";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "shipping_attention";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "shipping_address_street";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "shipping_address_place";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "shipping_city";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "shipping_state";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "shipping_pincode";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "shipping_country_region";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "shipping_phone";