CREATE TYPE "public"."branch_type" AS ENUM('FOFO', 'COCO', 'FRANCHISE', 'WAREHOUSE');--> statement-breakpoint
CREATE TYPE "public"."hsn_sac_type" AS ENUM('HSN', 'SAC');--> statement-breakpoint
ALTER TYPE "public"."inventory_valuation_method" ADD VALUE 'FEFO' BEFORE 'Weighted Average';--> statement-breakpoint
CREATE TABLE "accounts_fiscal_years" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"org_id" uuid NOT NULL,
	"branch_id" uuid,
	"name" varchar(100) NOT NULL,
	"start_date" date NOT NULL,
	"end_date" date NOT NULL,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "accounts_journal_number_settings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"org_id" uuid NOT NULL,
	"branch_id" uuid,
	"user_id" uuid,
	"auto_generate" boolean DEFAULT true,
	"prefix" varchar(20) DEFAULT 'MJ',
	"next_number" integer DEFAULT 1,
	"is_manual_override_allowed" boolean DEFAULT false,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "accounts_journal_template_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"template_id" uuid NOT NULL,
	"org_id" uuid NOT NULL,
	"branch_id" uuid,
	"account_id" uuid NOT NULL,
	"description" text,
	"contact_id" uuid,
	"contact_type" varchar(50),
	"type" varchar(50),
	"debit" numeric(15, 2) DEFAULT '0.00',
	"credit" numeric(15, 2) DEFAULT '0.00',
	"sort_order" integer DEFAULT 0
);
--> statement-breakpoint
CREATE TABLE "accounts_journal_templates" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"org_id" uuid NOT NULL,
	"branch_id" uuid,
	"template_name" varchar(255) NOT NULL,
	"reference_number" varchar(255),
	"notes" text,
	"reporting_method" varchar(50) DEFAULT 'accrual_and_cash',
	"currency_code" varchar(10) DEFAULT 'INR',
	"enter_amount" boolean DEFAULT false,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "accounts_manual_journal_attachments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"manual_journal_id" uuid NOT NULL,
	"org_id" uuid NOT NULL,
	"branch_id" uuid,
	"file_name" varchar(255) NOT NULL,
	"file_path" text NOT NULL,
	"file_size" integer,
	"uploaded_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "accounts_manual_journal_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"manual_journal_id" uuid NOT NULL,
	"account_id" uuid NOT NULL,
	"description" text,
	"contact_id" uuid,
	"contact_type" varchar(50),
	"contact_name" varchar(255),
	"debit" numeric(15, 2) DEFAULT '0.00',
	"credit" numeric(15, 2) DEFAULT '0.00',
	"sort_order" integer DEFAULT 0,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "accounts_manual_journals" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"org_id" uuid NOT NULL,
	"branch_id" uuid,
	"journal_number" varchar(255) NOT NULL,
	"fiscal_year_id" uuid,
	"reference_number" varchar(255),
	"journal_date" date NOT NULL,
	"notes" text,
	"is_13th_month_adjustment" boolean DEFAULT false,
	"reporting_method" varchar(50) DEFAULT 'accrual_and_cash',
	"currency_code" varchar(10) DEFAULT 'INR',
	"status" varchar(50) DEFAULT 'draft',
	"total_amount" numeric(15, 2) DEFAULT '0.00',
	"is_deleted" boolean DEFAULT false,
	"recurring_journal_id" uuid,
	"created_by" uuid,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "accounts_manual_journals_journal_number_unique" UNIQUE("journal_number")
);
--> statement-breakpoint
CREATE TABLE "accounts_recurring_journal_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"recurring_journal_id" uuid NOT NULL,
	"account_id" uuid NOT NULL,
	"description" text,
	"contact_id" uuid,
	"contact_type" varchar(50),
	"contact_name" varchar(255),
	"debit" numeric(15, 2) DEFAULT '0.00',
	"credit" numeric(15, 2) DEFAULT '0.00',
	"sort_order" integer DEFAULT 0
);
--> statement-breakpoint
CREATE TABLE "accounts_recurring_journals" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"org_id" uuid NOT NULL,
	"branch_id" uuid,
	"profile_name" varchar(255) NOT NULL,
	"repeat_every" varchar(50) NOT NULL,
	"interval" integer DEFAULT 1,
	"start_date" date NOT NULL,
	"end_date" date,
	"never_expires" boolean DEFAULT true,
	"reference_number" varchar(255),
	"notes" text,
	"currency_code" varchar(10) DEFAULT 'INR',
	"reporting_method" varchar(50) DEFAULT 'accrual_and_cash',
	"created_by" uuid,
	"status" varchar(50) DEFAULT 'active',
	"last_generated_date" date,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "audit_logs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"table_name" varchar(255) NOT NULL,
	"record_id" uuid NOT NULL,
	"action" varchar(50) NOT NULL,
	"old_values" jsonb,
	"new_values" jsonb,
	"user_id" uuid DEFAULT '00000000-0000-0000-0000-000000000000' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now(),
	"org_id" uuid DEFAULT '00000000-0000-0000-0000-000000000000' NOT NULL,
	"branch_id" uuid,
	"actor_name" text DEFAULT 'system' NOT NULL,
	"schema_name" text DEFAULT 'public' NOT NULL,
	"record_pk" text,
	"changed_columns" text[],
	"txid" bigint NOT NULL,
	"source" text DEFAULT 'system' NOT NULL,
	"module_name" text,
	"request_id" text
);
--> statement-breakpoint
CREATE TABLE "audit_logs_archive" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"table_name" varchar(255) NOT NULL,
	"record_id" uuid NOT NULL,
	"action" varchar(50) NOT NULL,
	"old_values" jsonb,
	"new_values" jsonb,
	"user_id" uuid DEFAULT '00000000-0000-0000-0000-000000000000' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now(),
	"org_id" uuid DEFAULT '00000000-0000-0000-0000-000000000000' NOT NULL,
	"branch_id" uuid,
	"actor_name" text DEFAULT 'system' NOT NULL,
	"schema_name" text DEFAULT 'public' NOT NULL,
	"record_pk" text,
	"changed_columns" text[],
	"txid" bigint NOT NULL,
	"source" text DEFAULT 'system' NOT NULL,
	"module_name" text,
	"request_id" text,
	"archived_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "batches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid,
	"batch" varchar(100) NOT NULL,
	"exp" date NOT NULL,
	"mrp" numeric(15, 2) NOT NULL,
	"ptr" numeric(15, 2) NOT NULL,
	"unit_pack" varchar(50),
	"is_manufacture_details" boolean DEFAULT false,
	"manufacture_batch_number" varchar(100),
	"manufacture_exp" date,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "cities" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(255) NOT NULL,
	"state_id" uuid NOT NULL,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "customer_contact_persons" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"customer_id" uuid NOT NULL,
	"salutation" varchar(255),
	"first_name" varchar(255),
	"last_name" varchar(255),
	"email" varchar(255),
	"work_phone" varchar(50),
	"mobile_phone" varchar(50),
	"display_order" integer DEFAULT 0,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "hsn_sac_codes" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"type" varchar(15) NOT NULL,
	"code" varchar(20) NOT NULL,
	"description" text NOT NULL,
	CONSTRAINT "hsn_sac_codes_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "inventory_picklist_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"picklist_id" uuid NOT NULL,
	"product_id" uuid NOT NULL,
	"sales_order_id" uuid,
	"batch_no" varchar(100),
	"quantity_ordered" numeric(15, 2) DEFAULT '0',
	"quantity_to_pick" numeric(15, 2) DEFAULT '0.00' NOT NULL,
	"quantity_picked" numeric(15, 2) DEFAULT '0.00' NOT NULL,
	"location_bin" varchar(255),
	"status" varchar(50) DEFAULT 'Pending',
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "inventory_picklists" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"picklist_number" varchar(100) NOT NULL,
	"date" timestamp with time zone DEFAULT now(),
	"status" varchar(50) DEFAULT 'Yet to Start' NOT NULL,
	"assignee" uuid,
	"location" uuid,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "inventory_picklists_picklist_number_unique" UNIQUE("picklist_number")
);
--> statement-breakpoint
CREATE TABLE "organization" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"system_id" varchar(20) NOT NULL,
	"name" varchar(255) NOT NULL,
	"slug" varchar(255) NOT NULL,
	"state_id" uuid,
	"industry" varchar(255),
	"logo_url" text,
	"base_currency" varchar(10),
	"base_currency_decimals" smallint,
	"base_currency_format" varchar(50),
	"fiscal_year" varchar(50),
	"organization_language" varchar(50),
	"communication_languages" text[],
	"timezone" varchar(100),
	"date_format" varchar(50),
	"date_separator" varchar(5),
	"company_id_label" varchar(50),
	"company_id_value" varchar(100),
	"is_drug_registered" boolean DEFAULT false,
	"drug_license_20" varchar(255),
	"drug_license_21" varchar(255),
	"drug_license_20b" varchar(255),
	"drug_license_21b" varchar(255),
	"is_fssai_registered" boolean DEFAULT false,
	"fssai_number" varchar(255),
	"is_msme_registered" boolean DEFAULT false,
	"msme_number" varchar(255),
	"payment_stub_address" text,
	"has_separate_payment_stub_address" boolean DEFAULT false,
	"district_id" uuid,
	"local_body_id" uuid,
	"ward_id" uuid,
	"payment_stub_district_id" uuid,
	"payment_stub_local_body_id" uuid,
	"payment_stub_ward_id" uuid,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "organization_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "outlet_inventory" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"outlet_id" uuid NOT NULL,
	"product_id" uuid NOT NULL,
	"current_stock" integer DEFAULT 0 NOT NULL,
	"reserved_stock" integer DEFAULT 0,
	"available_stock" integer GENERATED ALWAYS AS ((current_stock - reserved_stock)) STORED,
	"batch_no" varchar(100),
	"expiry_date" date,
	"min_stock_level" integer DEFAULT 0,
	"max_stock_level" integer DEFAULT 0,
	"last_stock_update" timestamp with time zone DEFAULT now(),
	CONSTRAINT "outlet_inventory_outlet_id_product_id_batch_no_key" UNIQUE("outlet_id","product_id","batch_no"),
	CONSTRAINT "outlet_inventory_current_stock_check" CHECK (current_stock >= 0)
);
--> statement-breakpoint
CREATE TABLE "payment_terms" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"term_name" varchar(255) NOT NULL,
	"number_of_days" integer NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "payment_terms_term_name_unique" UNIQUE("term_name")
);
--> statement-breakpoint
CREATE TABLE "product_contents" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid NOT NULL,
	"content_id" uuid,
	"strength_id" uuid,
	"content_unit_id" uuid,
	"shedule_id" uuid,
	"display_order" integer DEFAULT 0,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "product_outlet_inventory_settings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"org_id" uuid DEFAULT '00000000-0000-0000-0000-000000000000' NOT NULL,
	"outlet_id" uuid,
	"product_id" uuid NOT NULL,
	"reorder_point" integer DEFAULT 0 NOT NULL,
	"reorder_term_id" uuid,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_by_id" uuid,
	"updated_by_id" uuid,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "settings_branch_transaction_series" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"org_id" uuid NOT NULL,
	"branch_id" uuid NOT NULL,
	"transaction_series_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "settings_branches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"org_id" uuid NOT NULL,
	"name" varchar(255) NOT NULL,
	"branch_code" varchar(50) NOT NULL,
	"system_id" varchar(50),
	"branch_type" "branch_type" DEFAULT 'FOFO',
	"gstin" varchar(50),
	"email" varchar(255),
	"phone" varchar(50),
	"address" text,
	"city" varchar(100),
	"state" varchar(100),
	"country" varchar(100) DEFAULT 'India',
	"pincode" varchar(20),
	"district_id" uuid,
	"local_body_id" uuid,
	"ward_id" uuid,
	"landmark" text,
	"is_primary" boolean DEFAULT false NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "settings_districts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(255) NOT NULL,
	"state_id" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "settings_lsgd_seed_stage" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"data" jsonb,
	"processed" boolean DEFAULT false
);
--> statement-breakpoint
CREATE TABLE "settings_local_bodies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(255) NOT NULL,
	"district_id" uuid NOT NULL,
	"body_type" varchar(50)
);
--> statement-breakpoint
CREATE TABLE "settings_transaction_series" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"org_id" uuid NOT NULL,
	"name" varchar(255) NOT NULL,
	"modules" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "settings_wards" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"ward_number" integer NOT NULL,
	"ward_name" varchar(255),
	"local_body_id" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "states" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(255) NOT NULL,
	"code" varchar(10),
	"country_id" uuid NOT NULL,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "states_name_country_id_unique" UNIQUE("name","country_id")
);
--> statement-breakpoint
CREATE TABLE "tds_rates" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tds_name" varchar(100) NOT NULL,
	"tds_rate" numeric(5, 2) NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "tds_rates_tds_name_unique" UNIQUE("tds_name")
);
--> statement-breakpoint
CREATE TABLE "transaction_locks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"org_id" uuid DEFAULT '00000000-0000-0000-0000-000000000000' NOT NULL,
	"module_name" varchar(100) NOT NULL,
	"lock_date" timestamp NOT NULL,
	"reason" text,
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "idx_org_module_lock" UNIQUE("org_id","module_name")
);
--> statement-breakpoint
CREATE TABLE "transactional_sequences" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"module" varchar(50) NOT NULL,
	"prefix" varchar(20) DEFAULT '' NOT NULL,
	"next_number" integer DEFAULT 1 NOT NULL,
	"suffix" varchar(20) DEFAULT '' NOT NULL,
	"padding" integer DEFAULT 6 NOT NULL,
	"outlet_id" uuid,
	"is_active" boolean DEFAULT true,
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "uqc" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"uqc_code" varchar(20) NOT NULL,
	"description" varchar(255) NOT NULL,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "uqc_uqc_code_unique" UNIQUE("uqc_code")
);
--> statement-breakpoint
CREATE TABLE "vendor_bank_accounts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"vendor_id" uuid,
	"holder_name" text,
	"bank_name" text,
	"account_number" text,
	"ifsc" text,
	"is_primary" boolean DEFAULT false,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "vendor_contact_persons" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"vendor_id" uuid,
	"salutation" text,
	"first_name" text,
	"last_name" text,
	"email" text,
	"work_phone" text,
	"mobile_phone" text,
	"designation" text,
	"department" text,
	"is_primary" boolean DEFAULT false,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "warehouses" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"org_id" uuid,
	"name" varchar(255) NOT NULL,
	"attention" text,
	"address_street_1" text,
	"address_street_2" text,
	"city" text,
	"state" text,
	"zip_code" varchar(20),
	"country_region" text NOT NULL,
	"phone" varchar(50),
	"email" varchar(255),
	"is_active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	"branch_id" uuid,
	"warehouse_code" varchar(50),
	"pincode" varchar(20),
	"country" varchar(100) DEFAULT 'India' NOT NULL,
	"customer_id" uuid,
	"vendor_id" uuid
);
--> statement-breakpoint
ALTER TABLE "customer_contacts" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "organizations" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "outlets" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "product_compositions" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
DROP TABLE "customer_contacts" CASCADE;--> statement-breakpoint
DROP TABLE "organizations" CASCADE;--> statement-breakpoint
DROP TABLE "outlets" CASCADE;--> statement-breakpoint
DROP TABLE "product_compositions" CASCADE;--> statement-breakpoint
ALTER TABLE "accounts" DROP CONSTRAINT "accounts_account_name_unique";--> statement-breakpoint
ALTER TABLE "reorder_terms" DROP CONSTRAINT "reorder_terms_term_name_unique";--> statement-breakpoint
ALTER TABLE "vendors" DROP CONSTRAINT "vendors_vendor_name_unique";--> statement-breakpoint
ALTER TABLE "accounts" DROP CONSTRAINT "accounts_parent_id_accounts_id_fk";
--> statement-breakpoint
ALTER TABLE "users" DROP CONSTRAINT "users_org_id_organizations_id_fk";
--> statement-breakpoint
ALTER TABLE "accounts" ALTER COLUMN "ifsc" SET DATA TYPE varchar(50);--> statement-breakpoint
ALTER TABLE "customers" ALTER COLUMN "org_id" SET DEFAULT '00000000-0000-0000-0000-000000000000';--> statement-breakpoint
ALTER TABLE "customers" ALTER COLUMN "salutation" SET DATA TYPE varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ALTER COLUMN "exemption_reason" SET DATA TYPE text;--> statement-breakpoint
ALTER TABLE "customers" ALTER COLUMN "billing_address_street1" SET DATA TYPE varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ALTER COLUMN "billing_address_street2" SET DATA TYPE varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ALTER COLUMN "shipping_address_street1" SET DATA TYPE varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ALTER COLUMN "shipping_address_street2" SET DATA TYPE varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ALTER COLUMN "created_at" SET DATA TYPE timestamp with time zone;--> statement-breakpoint
ALTER TABLE "vendors" ALTER COLUMN "created_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "org_id" uuid DEFAULT '00000000-0000-0000-0000-000000000000' NOT NULL;--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "outlet_id" uuid;--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "user_account_name" varchar(255);--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "system_account_name" varchar(255);--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "account_type" varchar(50) NOT NULL;--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "account_group" varchar(50);--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "is_deletable" boolean DEFAULT true;--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "is_deleted" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "created_by" uuid;--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "modified_by" uuid;--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "modified_at" timestamp DEFAULT now();--> statement-breakpoint
ALTER TABLE "account_transactions" ADD COLUMN "org_id" uuid DEFAULT '00000000-0000-0000-0000-000000000000' NOT NULL;--> statement-breakpoint
ALTER TABLE "account_transactions" ADD COLUMN "branch_id" uuid;--> statement-breakpoint
ALTER TABLE "account_transactions" ADD COLUMN "source_id" uuid;--> statement-breakpoint
ALTER TABLE "account_transactions" ADD COLUMN "source_type" varchar(50);--> statement-breakpoint
ALTER TABLE "account_transactions" ADD COLUMN "contact_id" uuid;--> statement-breakpoint
ALTER TABLE "account_transactions" ADD COLUMN "contact_type" varchar(50);--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "business_type" varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "customer_language" varchar(255) DEFAULT 'English';--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "date_of_birth" timestamp;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "age" integer;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "gender" varchar(50);--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "Is_drug_registered" boolean;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "drug_licence_type" varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "drug_license_20" varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "drug_license_21" varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "drug_license_20b" varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "drug_license_21b" varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "drug_license_20_doc_url" text;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "drug_license_21_doc_url" text;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "drug_license_20b_doc_url" text;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "drug_license_21b_doc_url" text;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "Is_fssai_registered" boolean;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "fssai" varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "fssai_doc_url" text;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "Is_msme_registered" boolean;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "msme_registration_type" varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "msme_number" varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "msme_doc_url" text;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "receivable_balance" numeric(15, 2) DEFAULT '0.00';--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "place_of_customer" varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "privilege_card_number" varchar(255);--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "is_recurring" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "remarks" text;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "status" varchar(50) DEFAULT 'active';--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "document_urls" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "lock_unit_pack" integer DEFAULT 1;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "storage_description" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "about" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "uses_description" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "how_to_use" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "dosage_description" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "missed_dose_description" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "safety_advice" text;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "side_effects" jsonb;--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "faq_text" jsonb;--> statement-breakpoint
ALTER TABLE "reorder_terms" ADD COLUMN "org_id" uuid DEFAULT '00000000-0000-0000-0000-000000000000' NOT NULL;--> statement-breakpoint
ALTER TABLE "reorder_terms" ADD COLUMN "outlet_id" uuid;--> statement-breakpoint
ALTER TABLE "reorder_terms" ADD COLUMN "quantity" integer DEFAULT 1 NOT NULL;--> statement-breakpoint
ALTER TABLE "reorder_terms" ADD COLUMN "updated_at" timestamp DEFAULT now();--> statement-breakpoint
ALTER TABLE "units" ADD COLUMN "uqc_id" uuid;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "org_id" uuid DEFAULT '00000000-0000-0000-0000-000000000000' NOT NULL;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "branch_id" uuid;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "vendor_number" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "display_name" varchar(255) NOT NULL;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "salutation" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "first_name" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "last_name" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "company_name" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "mobile_phone" varchar(50);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "designation" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "department" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "website" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "vendor_language" varchar(255) DEFAULT 'English';--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "gst_treatment" varchar(100);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "source_of_supply" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "pan" varchar(50);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "currency" varchar(20) DEFAULT 'INR';--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "payment_terms" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "is_msme_registered" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "msme_registration_type" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "msme_registration_number" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "is_drug_registered" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "drug_licence_type" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "drug_license_20" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "drug_license_21" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "drug_license_20b" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "drug_license_21b" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "is_fssai_registered" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "fssai_number" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "tds_rate_id" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "price_list_id" uuid;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "enable_portal" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "remarks" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "x_handle" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "facebook_handle" varchar(255);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "whatsapp_number" varchar(50);--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "source" varchar(255) DEFAULT 'User';--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "updated_at" timestamp with time zone DEFAULT now();--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "billing_attention" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "billing_address_street_1" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "billing_address_street_2" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "billing_city" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "billing_state" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "billing_pincode" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "billing_country_region" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "billing_phone" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "billing_fax" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "shipping_attention" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "shipping_address_street_1" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "shipping_address_street_2" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "shipping_city" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "shipping_state" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "shipping_pincode" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "shipping_country_region" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "shipping_phone" text;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "shipping_fax" text;--> statement-breakpoint
ALTER TABLE "accounts_fiscal_years" ADD CONSTRAINT "accounts_fiscal_years_org_id_organization_id_fk" FOREIGN KEY ("org_id") REFERENCES "public"."organization"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "accounts_fiscal_years" ADD CONSTRAINT "accounts_fiscal_years_branch_id_settings_branches_id_fk" FOREIGN KEY ("branch_id") REFERENCES "public"."settings_branches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "accounts_journal_template_items" ADD CONSTRAINT "accounts_journal_template_items_template_id_accounts_journal_templates_id_fk" FOREIGN KEY ("template_id") REFERENCES "public"."accounts_journal_templates"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "accounts_manual_journal_attachments" ADD CONSTRAINT "accounts_manual_journal_attachments_manual_journal_id_accounts_manual_journals_id_fk" FOREIGN KEY ("manual_journal_id") REFERENCES "public"."accounts_manual_journals"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "accounts_manual_journal_items" ADD CONSTRAINT "accounts_manual_journal_items_manual_journal_id_accounts_manual_journals_id_fk" FOREIGN KEY ("manual_journal_id") REFERENCES "public"."accounts_manual_journals"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "accounts_recurring_journal_items" ADD CONSTRAINT "accounts_recurring_journal_items_recurring_journal_id_accounts_recurring_journals_id_fk" FOREIGN KEY ("recurring_journal_id") REFERENCES "public"."accounts_recurring_journals"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batches" ADD CONSTRAINT "batches_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "cities" ADD CONSTRAINT "cities_state_id_states_id_fk" FOREIGN KEY ("state_id") REFERENCES "public"."states"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customer_contact_persons" ADD CONSTRAINT "customer_contact_persons_customer_id_customers_id_fk" FOREIGN KEY ("customer_id") REFERENCES "public"."customers"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_picklist_items" ADD CONSTRAINT "inventory_picklist_items_picklist_id_inventory_picklists_id_fk" FOREIGN KEY ("picklist_id") REFERENCES "public"."inventory_picklists"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_picklist_items" ADD CONSTRAINT "inventory_picklist_items_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_picklist_items" ADD CONSTRAINT "inventory_picklist_items_sales_order_id_sales_orders_id_fk" FOREIGN KEY ("sales_order_id") REFERENCES "public"."sales_orders"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_picklists" ADD CONSTRAINT "inventory_picklists_assignee_users_id_fk" FOREIGN KEY ("assignee") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_picklists" ADD CONSTRAINT "inventory_picklists_location_storage_locations_id_fk" FOREIGN KEY ("location") REFERENCES "public"."storage_locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_contents" ADD CONSTRAINT "product_contents_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_contents" ADD CONSTRAINT "product_contents_content_id_contents_id_fk" FOREIGN KEY ("content_id") REFERENCES "public"."contents"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_contents" ADD CONSTRAINT "product_contents_strength_id_strengths_id_fk" FOREIGN KEY ("strength_id") REFERENCES "public"."strengths"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_contents" ADD CONSTRAINT "product_contents_content_unit_id_content_unit_id_fk" FOREIGN KEY ("content_unit_id") REFERENCES "public"."content_unit"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_contents" ADD CONSTRAINT "product_contents_shedule_id_schedules_id_fk" FOREIGN KEY ("shedule_id") REFERENCES "public"."schedules"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_outlet_inventory_settings" ADD CONSTRAINT "product_outlet_inventory_settings_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_outlet_inventory_settings" ADD CONSTRAINT "product_outlet_inventory_settings_reorder_term_id_reorder_terms_id_fk" FOREIGN KEY ("reorder_term_id") REFERENCES "public"."reorder_terms"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branch_transaction_series" ADD CONSTRAINT "settings_branch_transaction_series_org_id_organization_id_fk" FOREIGN KEY ("org_id") REFERENCES "public"."organization"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branch_transaction_series" ADD CONSTRAINT "settings_branch_transaction_series_branch_id_settings_branches_id_fk" FOREIGN KEY ("branch_id") REFERENCES "public"."settings_branches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branch_transaction_series" ADD CONSTRAINT "settings_branch_transaction_series_transaction_series_id_settings_transaction_series_id_fk" FOREIGN KEY ("transaction_series_id") REFERENCES "public"."settings_transaction_series"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD CONSTRAINT "settings_branches_org_id_organization_id_fk" FOREIGN KEY ("org_id") REFERENCES "public"."organization"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD CONSTRAINT "settings_branches_district_id_settings_districts_id_fk" FOREIGN KEY ("district_id") REFERENCES "public"."settings_districts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD CONSTRAINT "settings_branches_local_body_id_settings_local_bodies_id_fk" FOREIGN KEY ("local_body_id") REFERENCES "public"."settings_local_bodies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD CONSTRAINT "settings_branches_ward_id_settings_wards_id_fk" FOREIGN KEY ("ward_id") REFERENCES "public"."settings_wards"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_local_bodies" ADD CONSTRAINT "settings_local_bodies_district_id_settings_districts_id_fk" FOREIGN KEY ("district_id") REFERENCES "public"."settings_districts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_wards" ADD CONSTRAINT "settings_wards_local_body_id_settings_local_bodies_id_fk" FOREIGN KEY ("local_body_id") REFERENCES "public"."settings_local_bodies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "vendor_bank_accounts" ADD CONSTRAINT "vendor_bank_accounts_vendor_id_vendors_id_fk" FOREIGN KEY ("vendor_id") REFERENCES "public"."vendors"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "vendor_contact_persons" ADD CONSTRAINT "vendor_contact_persons_vendor_id_vendors_id_fk" FOREIGN KEY ("vendor_id") REFERENCES "public"."vendors"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "warehouses" ADD CONSTRAINT "warehouses_org_id_organization_id_fk" FOREIGN KEY ("org_id") REFERENCES "public"."organization"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "warehouses" ADD CONSTRAINT "warehouses_branch_id_settings_branches_id_fk" FOREIGN KEY ("branch_id") REFERENCES "public"."settings_branches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "warehouses" ADD CONSTRAINT "warehouses_customer_id_customers_id_fk" FOREIGN KEY ("customer_id") REFERENCES "public"."customers"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "warehouses" ADD CONSTRAINT "warehouses_vendor_id_vendors_id_fk" FOREIGN KEY ("vendor_id") REFERENCES "public"."vendors"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "idx_hsn_sac_code" ON "hsn_sac_codes" USING btree ("code");--> statement-breakpoint
CREATE INDEX "idx_hsn_sac_type" ON "hsn_sac_codes" USING btree ("type");--> statement-breakpoint
CREATE INDEX "idx_inventory_expiry" ON "outlet_inventory" USING btree ("expiry_date" date_ops);--> statement-breakpoint
CREATE INDEX "idx_inventory_outlet" ON "outlet_inventory" USING btree ("outlet_id" uuid_ops);--> statement-breakpoint
CREATE INDEX "idx_inventory_outlet_product" ON "outlet_inventory" USING btree ("outlet_id" uuid_ops,"product_id" uuid_ops);--> statement-breakpoint
CREATE INDEX "idx_inventory_product" ON "outlet_inventory" USING btree ("product_id" uuid_ops);--> statement-breakpoint
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_parent_id_accounts_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "units" ADD CONSTRAINT "units_uqc_id_uqc_id_fk" FOREIGN KEY ("uqc_id") REFERENCES "public"."uqc"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "users" ADD CONSTRAINT "users_org_id_organization_id_fk" FOREIGN KEY ("org_id") REFERENCES "public"."organization"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "vendors" ADD CONSTRAINT "vendors_branch_id_settings_branches_id_fk" FOREIGN KEY ("branch_id") REFERENCES "public"."settings_branches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "accounts" DROP COLUMN "account_name";--> statement-breakpoint
ALTER TABLE "accounts" DROP COLUMN "group_type";--> statement-breakpoint
ALTER TABLE "accounts" DROP COLUMN "detailed_type";--> statement-breakpoint
ALTER TABLE "reorder_terms" DROP COLUMN "preset_formula";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "vendor_name";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "vendor_type";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "contact_person";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "address";--> statement-breakpoint
ALTER TABLE "vendors" DROP COLUMN "drug_license_no";--> statement-breakpoint
ALTER TABLE "customers" ADD CONSTRAINT "customers_customer_number_unique" UNIQUE("customer_number");--> statement-breakpoint
ALTER TABLE "vendors" ADD CONSTRAINT "vendors_vendor_number_unique" UNIQUE("vendor_number");--> statement-breakpoint
DROP TYPE "public"."account_group_enum";