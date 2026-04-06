ALTER TABLE "accounts" RENAME COLUMN "outlet_id" TO "branch_id";--> statement-breakpoint
ALTER TABLE "settings_branches" ALTER COLUMN "gstin" SET DATA TYPE varchar(15);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "website" varchar(255);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "attention" text;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "address_street_1" text;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "address_street_2" text;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "is_child_location" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "parent_branch_id" uuid;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "primary_contact_id" uuid;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "industry" varchar(255);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "pan" varchar(10);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "gst_treatment" varchar(50);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "gstin_registration_type" varchar(50);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "gstin_legal_name" varchar(255);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "gstin_trade_name" varchar(255);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "gstin_registered_on" date;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "gstin_reverse_charge" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "gstin_import_export" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "gstin_import_export_account_id" uuid;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "gstin_digital_services" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "is_drug_registered" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "drug_licence_type" varchar(50);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "drug_license_20" varchar(255);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "drug_license_21" varchar(255);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "drug_license_20b" varchar(255);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "drug_license_21b" varchar(255);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "is_fssai_registered" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "fssai_number" varchar(255);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "is_msme_registered" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "msme_registration_type" varchar(50);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "msme_number" varchar(255);--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "logo_url" text;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "subscription_from" date;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "subscription_to" date;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "default_transaction_series_id" uuid;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "has_separate_payment_stub_address" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "payment_stub_address" text;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "payment_stub_district_id" uuid;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "payment_stub_local_body_id" uuid;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "payment_stub_ward_id" uuid;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD CONSTRAINT "settings_branches_payment_stub_district_id_settings_districts_id_fk" FOREIGN KEY ("payment_stub_district_id") REFERENCES "public"."settings_districts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD CONSTRAINT "settings_branches_payment_stub_local_body_id_settings_local_bodies_id_fk" FOREIGN KEY ("payment_stub_local_body_id") REFERENCES "public"."settings_local_bodies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD CONSTRAINT "settings_branches_payment_stub_ward_id_settings_wards_id_fk" FOREIGN KEY ("payment_stub_ward_id") REFERENCES "public"."settings_wards"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD CONSTRAINT "settings_branches_primary_contact_id_users_id_fk" FOREIGN KEY ("primary_contact_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branches" DROP COLUMN IF EXISTS "address";--> statement-breakpoint
ALTER TABLE "settings_branches" DROP COLUMN IF EXISTS "fax";--> statement-breakpoint
ALTER TABLE "organization" DROP COLUMN IF EXISTS "fax";--> statement-breakpoint
ALTER TABLE "organization" DROP COLUMN IF EXISTS "payment_stub_fax";