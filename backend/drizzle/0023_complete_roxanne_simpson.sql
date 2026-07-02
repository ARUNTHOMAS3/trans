CREATE TABLE "shipment_preferences" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar NOT NULL,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "shipment_preferences_name_unique" UNIQUE("name")
);
--> statement-breakpoint
ALTER TABLE "accounts" ALTER COLUMN "org_id" DROP DEFAULT;--> statement-breakpoint
ALTER TABLE "audit_logs" ALTER COLUMN "user_id" DROP DEFAULT;--> statement-breakpoint
ALTER TABLE "audit_logs" ALTER COLUMN "org_id" DROP DEFAULT;--> statement-breakpoint
ALTER TABLE "audit_logs_archive" ALTER COLUMN "user_id" DROP DEFAULT;--> statement-breakpoint
ALTER TABLE "audit_logs_archive" ALTER COLUMN "org_id" DROP DEFAULT;--> statement-breakpoint
ALTER TABLE "products" ALTER COLUMN "type" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "products" ALTER COLUMN "product_name" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "products" ALTER COLUMN "item_code" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "products" ALTER COLUMN "unit_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_reps" ALTER COLUMN "org_id" DROP DEFAULT;--> statement-breakpoint
ALTER TABLE "transaction_locks" ALTER COLUMN "org_id" DROP DEFAULT;--> statement-breakpoint
ALTER TABLE "vendors" ALTER COLUMN "org_id" DROP DEFAULT;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "unit_pack_id" varchar(50);--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "product_type_id" uuid;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "how_it_works" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "drug_interactions" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "contraindications" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "side_effects_management" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "good_to_know" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "quick_tips" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "allergy_information" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "product_highlights" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "ingredients_list" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "safety_measures_warnings_pregnancy" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "safety_measures_warnings_breastfeeding" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "safety_measures_warnings_alcohol" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "safety_measures_warnings_liver" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "safety_measures_warnings_kidney" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "safety_measures_warnings_use_in_driving_and_operating_machinery" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "safety_measures_warnings_allergy" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "safety_measures_warnings_children" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "safety_measures_warnings_older_patients" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "interactions_drug_drug_interactions" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "interactions_drug_disease_interactions" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "dosage_daily_dose" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "dosage_over_dose" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "dosage_missed_dose" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "references_text" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "product_description" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "additional_info_allergy" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "additional_info_concerns" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "additional_info_good_to_know" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "additional_info_quick_tips" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "directions_for_use" text;--> statement-breakpoint
ALTER TABLE "batch_stock_layers" DROP COLUMN "updated_at";--> statement-breakpoint
ALTER TABLE "bill_items" DROP COLUMN "updated_at";--> statement-breakpoint
ALTER TABLE "bills" DROP COLUMN "updated_at";--> statement-breakpoint
ALTER TABLE "bin_master" DROP COLUMN "updated_at";--> statement-breakpoint
ALTER TABLE "rack_master" DROP COLUMN "updated_at";--> statement-breakpoint
ALTER TABLE "sales_reps" DROP COLUMN "updated_at";--> statement-breakpoint
ALTER TABLE "storage_location" DROP COLUMN "updated_at";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "updated_at";--> statement-breakpoint
ALTER TABLE "vendor_bank_accounts" DROP COLUMN "updated_at";--> statement-breakpoint
ALTER TABLE "vendor_contact_persons" DROP COLUMN "updated_at";