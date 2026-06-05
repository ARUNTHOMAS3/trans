CREATE TABLE "batch_stock_layers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entity_id" uuid NOT NULL,
	"warehouse_id" uuid NOT NULL,
	"bin_id" uuid,
	"product_id" uuid NOT NULL,
	"batch_id" uuid NOT NULL,
	"qty" numeric(15, 3) DEFAULT '0',
	"purchase_rate" numeric(15, 2) DEFAULT '0',
	"mrp" numeric(15, 2) DEFAULT '0',
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "batch_transactions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"batch_id" uuid NOT NULL,
	"layer_id" uuid,
	"product_id" uuid NOT NULL,
	"entity_id" uuid NOT NULL,
	"warehouse_id" uuid NOT NULL,
	"bin_id" uuid,
	"trans_type" varchar NOT NULL,
	"ref_id" uuid,
	"ref_no" varchar,
	"qty_in" numeric DEFAULT '0',
	"qty_out" numeric DEFAULT '0',
	"rate" numeric,
	"trans_date" timestamp DEFAULT now() NOT NULL,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "batch_master" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid,
	"batch_no" varchar(100) NOT NULL,
	"entity_id" uuid NOT NULL,
	"expiry_date" date NOT NULL,
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
CREATE TABLE "bill_item_batches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"bill_item_id" uuid NOT NULL,
	"batch_id" uuid NOT NULL,
	"layer_id" uuid,
	"warehouse_id" uuid,
	"bin_id" uuid,
	"quantity" numeric(15, 3) DEFAULT '0' NOT NULL,
	"foc_quantity" numeric(15, 3) DEFAULT '0',
	"damage_quantity" numeric(15, 3) DEFAULT '0',
	"purchase_rate" numeric(15, 2),
	"mrp" numeric(15, 2),
	"expiry_date" date,
	"manufacture_date" date,
	"manufacture_batch_no" varchar(100),
	"is_direct_bill" boolean DEFAULT false,
	"created_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "bill_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"bill_id" uuid NOT NULL,
	"product_id" uuid NOT NULL,
	"purchase_receive_item_id" uuid,
	"account_id" uuid,
	"customer_id" uuid,
	"hsn_code" varchar(50),
	"description" text,
	"quantity" numeric(15, 3) DEFAULT '0' NOT NULL,
	"rate" numeric(15, 2) DEFAULT '0' NOT NULL,
	"discount_type" varchar(20),
	"discount_value" numeric(15, 2) DEFAULT '0',
	"discount_amount" numeric(15, 2) DEFAULT '0',
	"tax_id" uuid,
	"tax_percentage" numeric(8, 2) DEFAULT '0',
	"tax_amount" numeric(15, 2) DEFAULT '0',
	"line_total" numeric(15, 2) DEFAULT '0',
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "bill_landed_costs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"bill_id" uuid NOT NULL,
	"expense_account_id" uuid NOT NULL,
	"amount" numeric(15, 2) NOT NULL,
	"allocation_method" varchar(30),
	"description" text,
	"created_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "bills" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entity_id" uuid NOT NULL,
	"vendor_id" uuid NOT NULL,
	"bill_number" varchar(50) NOT NULL,
	"order_number" varchar(100),
	"bill_date" date NOT NULL,
	"due_date" date,
	"payment_term_id" uuid,
	"reverse_charge_applicable" boolean DEFAULT false,
	"warehouse_id" uuid,
	"price_list_id" uuid,
	"landed_cost_allocation_type" varchar(30),
	"subject" text,
	"notes" text,
	"subtotal" numeric(15, 2) DEFAULT '0',
	"discount_total" numeric(15, 2) DEFAULT '0',
	"tax_total" numeric(15, 2) DEFAULT '0',
	"shipping_charges" numeric(15, 2) DEFAULT '0',
	"tds_total" numeric(15, 2) DEFAULT '0',
	"tcs_total" numeric(15, 2) DEFAULT '0',
	"adjustment_amount" numeric(15, 2) DEFAULT '0',
	"round_off" numeric(15, 2) DEFAULT '0',
	"grand_total" numeric(15, 2) DEFAULT '0',
	"source_type" varchar(30),
	"source_id" uuid,
	"status" varchar(30) DEFAULT 'draft',
	"is_delete" boolean DEFAULT false NOT NULL,
	"created_by" uuid,
	"approved_by" uuid,
	"approved_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "bin_master" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entity_id" uuid NOT NULL,
	"warehouse_id" uuid NOT NULL,
	"rack_id" uuid NOT NULL,
	"bin_code" varchar(255) NOT NULL,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "branch_user_access" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"role_id" uuid,
	"is_default_branch" boolean DEFAULT false,
	"permissions" jsonb DEFAULT '{}'::jsonb,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"entity_id" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "inventory_package_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"package_id" uuid NOT NULL,
	"entity_id" uuid NOT NULL,
	"product_id" uuid NOT NULL,
	"quantity" numeric(15, 3) DEFAULT '0' NOT NULL,
	"sales_order_id" uuid,
	"picklist_id" uuid,
	"batch_no" varchar,
	"bin_location" varchar,
	"foc" smallint
);
--> statement-breakpoint
CREATE TABLE "inventory_package_sales_orders" (
	"package_id" uuid NOT NULL,
	"sales_order_id" uuid NOT NULL,
	"entity_id" uuid NOT NULL,
	"bin_location" text,
	"batch_no" varchar(100),
	CONSTRAINT "inventory_package_sales_orders_pkey" UNIQUE("package_id","sales_order_id")
);
--> statement-breakpoint
CREATE TABLE "inventory_packages" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entity_id" uuid NOT NULL,
	"customer_id" uuid NOT NULL,
	"package_number" varchar NOT NULL,
	"package_date" date DEFAULT CURRENT_DATE NOT NULL,
	"dimension_length" numeric(15, 2) DEFAULT '0',
	"dimension_width" numeric(15, 2) DEFAULT '0',
	"dimension_height" numeric(15, 2) DEFAULT '0',
	"dimension_unit" varchar(10) DEFAULT 'cm',
	"weight" numeric(15, 2) DEFAULT '0',
	"weight_unit" varchar(10) DEFAULT 'kg',
	"is_manual_mode" boolean DEFAULT false,
	"notes" text,
	"status" varchar(50) DEFAULT 'Not Shipped',
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now(),
	"is_delete" boolean DEFAULT false NOT NULL,
	"created_by" uuid,
	CONSTRAINT "inventory_packages_package_number_unique" UNIQUE("package_number")
);
--> statement-breakpoint
CREATE TABLE "picklist_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"picklist_id" uuid NOT NULL,
	"product_id" uuid NOT NULL,
	"sales_order_id" uuid,
	"sales_order_line_id" uuid,
	"qty_ordered" numeric,
	"qty_to_pick" numeric,
	"qty_picked" numeric DEFAULT '0',
	"status" text,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "picklist_master" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"picklist_no" varchar NOT NULL,
	"entity_id" uuid NOT NULL,
	"picklist_date" date NOT NULL,
	"status" text,
	"assignee_id" uuid,
	"warehouse_id" uuid NOT NULL,
	"notes" text,
	"is_delete" boolean DEFAULT false NOT NULL,
	"is_entrypass" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "picklist_master_picklist_no_unique" UNIQUE("picklist_no")
);
--> statement-breakpoint
CREATE TABLE "picklist_batch_allocation" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"picklist_item_id" uuid NOT NULL,
	"batch_id" uuid NOT NULL,
	"layer_id" varchar NOT NULL,
	"warehouse_id" uuid NOT NULL,
	"bin_id" uuid NOT NULL,
	"qty" numeric NOT NULL,
	"foc_qty" numeric DEFAULT '0',
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "purchase_order_attachments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"purchase_order_id" uuid NOT NULL,
	"file_name" varchar NOT NULL,
	"file_path" text NOT NULL,
	"file_size" integer,
	"file_type" varchar,
	"uploaded_at" timestamp DEFAULT now(),
	"entity_id" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "purchase_order_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"purchase_order_id" uuid NOT NULL,
	"sort_order" integer,
	"is_header" boolean DEFAULT false,
	"header_text" text,
	"product_id" uuid,
	"description" text,
	"account_id" uuid,
	"accounts" uuid,
	"quantity" numeric DEFAULT '0.00',
	"rate" numeric DEFAULT '0.00',
	"tax_id" uuid,
	"item_tax_rate" numeric DEFAULT '0.00',
	"tax_amount" numeric DEFAULT '0.00',
	"discount" numeric DEFAULT '0.00',
	"discount_type" varchar DEFAULT 'percentage',
	"amount" numeric DEFAULT '0.00',
	"hsn_code" varchar(50),
	"pricelist" varchar(255),
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	"entity_id" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "purchase_orders" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"vendor_id" uuid NOT NULL,
	"transaction_series" varchar,
	"purchase_number" varchar,
	"reference" varchar,
	"purchase_date" timestamp DEFAULT now(),
	"expected_delivery_date" timestamp,
	"payment_terms" varchar,
	"payment_term_id" uuid,
	"warehouse_id" uuid,
	"warehouse_name" varchar,
	"price_list_id" uuid,
	"place_of_supply" varchar,
	"document_type" varchar(50) NOT NULL,
	"status" varchar(50) DEFAULT 'Draft',
	"sub_total" numeric DEFAULT '0.00' NOT NULL,
	"tax_total" numeric DEFAULT '0.00' NOT NULL,
	"discount_total" numeric DEFAULT '0.00' NOT NULL,
	"tds_tcs_type" varchar DEFAULT 'TDS',
	"tds_tcs_tax_id" uuid,
	"tds_tcs_amount" numeric DEFAULT '0.00' NOT NULL,
	"adjustment" numeric DEFAULT '0.00' NOT NULL,
	"round_off" numeric DEFAULT '0.00' NOT NULL,
	"total_quantity" numeric DEFAULT '0.000' NOT NULL,
	"total" numeric DEFAULT '0.00' NOT NULL,
	"currency" varchar(20) DEFAULT 'INR',
	"vendor_notes" text,
	"terms_and_conditions" text,
	"is_delete" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	"entity_id" uuid NOT NULL,
	CONSTRAINT "purchase_orders_purchase_number_unique" UNIQUE("purchase_number")
);
--> statement-breakpoint
CREATE TABLE "purchase_receive_item_batches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"purchase_receive_item_id" uuid NOT NULL,
	"product_id" uuid NOT NULL,
	"warehouse_id" uuid,
	"bin_id" uuid,
	"batch_no" varchar NOT NULL,
	"unit_pack" varchar,
	"mrp" numeric,
	"ptr" numeric,
	"quantity" numeric DEFAULT '0' NOT NULL,
	"foc_qty" numeric DEFAULT '0' NOT NULL,
	"manufacture_batch_number" varchar,
	"manufacture_date" date,
	"expiry_date" date NOT NULL,
	"is_damaged" boolean DEFAULT false NOT NULL,
	"damaged_qty" numeric DEFAULT '0' NOT NULL,
	"entity_id" uuid NOT NULL,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "purchase_receive_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"purchase_receive_id" uuid NOT NULL,
	"item_id" uuid,
	"item_name" varchar NOT NULL,
	"description" text,
	"ordered" numeric DEFAULT '0' NOT NULL,
	"received" numeric DEFAULT '0' NOT NULL,
	"in_transit" numeric DEFAULT '0' NOT NULL,
	"quantity_to_receive" numeric DEFAULT '0' NOT NULL,
	"warehouse_id" uuid,
	"bin_id" uuid,
	"bin_label" varchar,
	"entity_id" uuid NOT NULL,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "purchase_receives" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"purchase_receive_number" varchar NOT NULL,
	"received_date" date NOT NULL,
	"vendor_name" varchar,
	"purchase_order_id" uuid,
	"purchase_order_number" varchar,
	"warehouse_id" uuid,
	"transaction_bin_id" uuid,
	"transaction_bin_label" varchar,
	"status" varchar(50) DEFAULT 'draft' NOT NULL,
	"notes" text,
	"entity_id" uuid NOT NULL,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "rack_master" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entity_id" uuid NOT NULL,
	"warehouse_id" uuid NOT NULL,
	"rack_name" varchar(255) NOT NULL,
	"rack_code" varchar(50),
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "sales_order_attachments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"sales_order_id" uuid NOT NULL,
	"file_name" varchar NOT NULL,
	"file_path" text NOT NULL,
	"file_size" integer,
	"file_type" varchar,
	"uploaded_at" timestamp DEFAULT now(),
	"entity_id" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "sales_order_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"sales_order_id" uuid NOT NULL,
	"line_no" integer DEFAULT 1 NOT NULL,
	"product_id" uuid NOT NULL,
	"description" text,
	"quantity" numeric DEFAULT '0.000' NOT NULL,
	"free_quantity" numeric DEFAULT '0.000' NOT NULL,
	"rate" numeric DEFAULT '0.00' NOT NULL,
	"discount_type" varchar DEFAULT '%',
	"discount_value" numeric DEFAULT '0.00' NOT NULL,
	"discount_amount" numeric DEFAULT '0.00' NOT NULL,
	"tax_id" uuid,
	"tax_rate" numeric DEFAULT '0.0000' NOT NULL,
	"tax_amount" numeric DEFAULT '0.00' NOT NULL,
	"amount" numeric DEFAULT '0.00' NOT NULL,
	"mrp" numeric DEFAULT '0.00' NOT NULL,
	"batch_id" uuid,
	"warehouse_id" uuid,
	"line_meta" jsonb,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	"entity_id" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "sales_reps" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"org_id" uuid DEFAULT '00000000-0000-0000-0000-000000000000' NOT NULL,
	"entity_id" uuid,
	"name" varchar(255) NOT NULL,
	"number" varchar(100),
	"brand_id" uuid,
	"division" varchar(255),
	"area" varchar(255),
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "roles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"label" varchar NOT NULL,
	"description" text DEFAULT '' NOT NULL,
	"permissions" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"entity_id" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "storage_location" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entity_id" uuid NOT NULL,
	"location_name" varchar(255) NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
ALTER TABLE "batches" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "inventory_picklist_items" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "inventory_picklists" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "racks" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "storage_conditions" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
DROP TABLE "batches" CASCADE;--> statement-breakpoint
DROP TABLE "inventory_picklist_items" CASCADE;--> statement-breakpoint
DROP TABLE "inventory_picklists" CASCADE;--> statement-breakpoint
DROP TABLE "racks" CASCADE;--> statement-breakpoint
DROP TABLE "storage_conditions" CASCADE;--> statement-breakpoint
ALTER TABLE "customers" DROP CONSTRAINT "customers_associated_branch_id_branches_id_fk";
--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" DROP CONSTRAINT "inventory_adjustment_attachments_uploaded_by_users_id_fk";
--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" DROP CONSTRAINT "inventory_adjustment_item_batches_batch_id_batches_id_fk";
--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" DROP CONSTRAINT "inventory_adjustment_items_batch_id_batches_id_fk";
--> statement-breakpoint
ALTER TABLE "inventory_adjustment_reasons" DROP CONSTRAINT "inventory_adjustment_reasons_entity_id_organisation_branch_master_id_fk";
--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" DROP CONSTRAINT "inventory_adjustment_value_items_batch_id_batches_id_fk";
--> statement-breakpoint
ALTER TABLE "inventory_adjustments" DROP CONSTRAINT "inventory_adjustments_account_id_accounts_id_fk";
--> statement-breakpoint
ALTER TABLE "products" DROP CONSTRAINT "products_storage_id_storage_conditions_id_fk";
--> statement-breakpoint
ALTER TABLE "products" DROP CONSTRAINT "products_rack_id_racks_id_fk";
--> statement-breakpoint
ALTER TABLE "inventory_adjustment_account_entries" ALTER COLUMN "debit" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_account_entries" ALTER COLUMN "debit" SET DEFAULT '0';--> statement-breakpoint
ALTER TABLE "inventory_adjustment_account_entries" ALTER COLUMN "credit" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_account_entries" ALTER COLUMN "credit" SET DEFAULT '0';--> statement-breakpoint
ALTER TABLE "inventory_adjustment_account_entries" ALTER COLUMN "created_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_account_entries" ALTER COLUMN "created_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustment_account_entries" ALTER COLUMN "updated_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_account_entries" ALTER COLUMN "updated_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ALTER COLUMN "file_name" SET DATA TYPE text;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ALTER COLUMN "file_url" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ALTER COLUMN "mime_type" SET DATA TYPE text;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ALTER COLUMN "created_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ALTER COLUMN "created_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ALTER COLUMN "updated_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ALTER COLUMN "updated_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ALTER COLUMN "batch_reference" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ALTER COLUMN "quantity_in" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ALTER COLUMN "quantity_in" SET DEFAULT '0';--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ALTER COLUMN "quantity_out" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ALTER COLUMN "quantity_out" SET DEFAULT '0';--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ALTER COLUMN "rate" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ALTER COLUMN "created_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ALTER COLUMN "created_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ALTER COLUMN "updated_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ALTER COLUMN "updated_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "quantity_before" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "quantity_before" SET DEFAULT '0';--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "quantity_adjusted" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "quantity_adjusted" SET DEFAULT '0';--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "quantity_after" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "quantity_after" SET DEFAULT '0';--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "cost_price" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "purchase_rate" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "mrp" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "adjustment_value" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "adjustment_value" SET DEFAULT '0';--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "batch_reference" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "batch_allocations" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "reporting_tags" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "mfd_month_year" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "expiry_month_year" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "created_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "created_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "updated_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ALTER COLUMN "updated_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustment_reasons" ALTER COLUMN "name" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_reasons" ALTER COLUMN "code" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_reasons" ALTER COLUMN "created_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_reasons" ALTER COLUMN "created_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustment_reasons" ALTER COLUMN "updated_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_reasons" ALTER COLUMN "updated_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ALTER COLUMN "current_value" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ALTER COLUMN "current_value" SET DEFAULT '0';--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ALTER COLUMN "changed_value" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ALTER COLUMN "changed_value" SET DEFAULT '0';--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ALTER COLUMN "adjusted_value" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ALTER COLUMN "adjusted_value" SET DEFAULT '0';--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ALTER COLUMN "created_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ALTER COLUMN "created_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ALTER COLUMN "updated_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ALTER COLUMN "updated_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "adjustment_number" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "adjustment_date" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "adjustment_date" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "adjustment_date" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "adjustment_type" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "adjustment_type" SET DEFAULT 'quantity';--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "adjustment_type" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "reason" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "reference_number" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "status" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "status" SET DEFAULT 'draft';--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "status" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "approved_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "created_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "created_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "updated_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "updated_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "quantity_before" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "quantity_adjusted" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "quantity_after" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "cost_price" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ALTER COLUMN "adjustment_value" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "organisation_branch_master" ALTER COLUMN "name" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "organisation_branch_master" ALTER COLUMN "type" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "organisation_branch_master" ALTER COLUMN "created_at" SET DATA TYPE timestamp;--> statement-breakpoint
ALTER TABLE "organisation_branch_master" ALTER COLUMN "created_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "sales_orders" ALTER COLUMN "sale_number" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "sales_orders" ALTER COLUMN "reference" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "sales_orders" ALTER COLUMN "delivery_method" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "sales_orders" ALTER COLUMN "payment_terms" SET DATA TYPE varchar;--> statement-breakpoint
ALTER TABLE "sales_orders" ALTER COLUMN "total" SET DATA TYPE numeric;--> statement-breakpoint
ALTER TABLE "sales_orders" ALTER COLUMN "total" SET DEFAULT '0.00';--> statement-breakpoint
ALTER TABLE "warehouses" ALTER COLUMN "entity_id" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ADD COLUMN "storage_bucket" text;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ADD COLUMN "storage_path" text;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ADD COLUMN "file_hash" text;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ADD COLUMN "batch_stock_layer_id" uuid;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_reasons" ADD COLUMN "reason_type" varchar DEFAULT 'both';--> statement-breakpoint
ALTER TABLE "products" ADD COLUMN "rep_id" uuid;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "transaction_series" varchar;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "payment_term_id" uuid;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "salesperson_id" varchar;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "salesperson_name" varchar;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "warehouse_id" uuid;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "warehouse_name" varchar;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "price_list_id" uuid;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "place_of_supply" varchar;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "sub_total" numeric DEFAULT '0.00' NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "tax_total" numeric DEFAULT '0.00' NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "discount_total" numeric DEFAULT '0.00' NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "shipping_charges" numeric DEFAULT '0.00' NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "tds_tcs_type" varchar DEFAULT 'TDS';--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "tds_tcs_tax_id" uuid;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "tds_tcs_amount" numeric DEFAULT '0.00' NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "adjustment" numeric DEFAULT '0.00' NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "round_off" numeric DEFAULT '0.00' NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "total_quantity" numeric DEFAULT '0.000' NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "is_delete" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "updated_at" timestamp DEFAULT now();--> statement-breakpoint
ALTER TABLE "sales_payment_links" ADD COLUMN "entity_id" uuid NOT NULL;--> statement-breakpoint
ALTER TABLE "batch_stock_layers" ADD CONSTRAINT "batch_stock_layers_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batch_stock_layers" ADD CONSTRAINT "batch_stock_layers_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batch_stock_layers" ADD CONSTRAINT "batch_stock_layers_bin_id_bin_master_id_fk" FOREIGN KEY ("bin_id") REFERENCES "public"."bin_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batch_stock_layers" ADD CONSTRAINT "batch_stock_layers_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batch_stock_layers" ADD CONSTRAINT "batch_stock_layers_batch_id_batch_master_id_fk" FOREIGN KEY ("batch_id") REFERENCES "public"."batch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batch_transactions" ADD CONSTRAINT "batch_transactions_batch_id_batch_master_id_fk" FOREIGN KEY ("batch_id") REFERENCES "public"."batch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batch_transactions" ADD CONSTRAINT "batch_transactions_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batch_transactions" ADD CONSTRAINT "batch_transactions_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batch_transactions" ADD CONSTRAINT "batch_transactions_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batch_master" ADD CONSTRAINT "batch_master_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batch_master" ADD CONSTRAINT "batch_master_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bill_item_batches" ADD CONSTRAINT "bill_item_batches_bill_item_id_bill_items_id_fk" FOREIGN KEY ("bill_item_id") REFERENCES "public"."bill_items"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bill_item_batches" ADD CONSTRAINT "bill_item_batches_layer_id_batch_stock_layers_id_fk" FOREIGN KEY ("layer_id") REFERENCES "public"."batch_stock_layers"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bill_item_batches" ADD CONSTRAINT "bill_item_batches_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bill_item_batches" ADD CONSTRAINT "bill_item_batches_bin_id_bin_master_id_fk" FOREIGN KEY ("bin_id") REFERENCES "public"."bin_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bill_items" ADD CONSTRAINT "bill_items_bill_id_bills_id_fk" FOREIGN KEY ("bill_id") REFERENCES "public"."bills"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bill_items" ADD CONSTRAINT "bill_items_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bill_items" ADD CONSTRAINT "bill_items_account_id_accounts_id_fk" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bill_items" ADD CONSTRAINT "bill_items_customer_id_customers_id_fk" FOREIGN KEY ("customer_id") REFERENCES "public"."customers"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bill_landed_costs" ADD CONSTRAINT "bill_landed_costs_bill_id_bills_id_fk" FOREIGN KEY ("bill_id") REFERENCES "public"."bills"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bill_landed_costs" ADD CONSTRAINT "bill_landed_costs_expense_account_id_accounts_id_fk" FOREIGN KEY ("expense_account_id") REFERENCES "public"."accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bills" ADD CONSTRAINT "bills_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bills" ADD CONSTRAINT "bills_vendor_id_vendors_id_fk" FOREIGN KEY ("vendor_id") REFERENCES "public"."vendors"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bills" ADD CONSTRAINT "bills_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bin_master" ADD CONSTRAINT "bin_master_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bin_master" ADD CONSTRAINT "bin_master_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bin_master" ADD CONSTRAINT "bin_master_rack_id_rack_master_id_fk" FOREIGN KEY ("rack_id") REFERENCES "public"."rack_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branch_user_access" ADD CONSTRAINT "branch_user_access_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branch_user_access" ADD CONSTRAINT "branch_user_access_role_id_roles_id_fk" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branch_user_access" ADD CONSTRAINT "branch_user_access_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_package_items" ADD CONSTRAINT "inventory_package_items_package_id_inventory_packages_id_fk" FOREIGN KEY ("package_id") REFERENCES "public"."inventory_packages"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_package_items" ADD CONSTRAINT "inventory_package_items_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_package_items" ADD CONSTRAINT "inventory_package_items_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_package_items" ADD CONSTRAINT "inventory_package_items_sales_order_id_sales_orders_id_fk" FOREIGN KEY ("sales_order_id") REFERENCES "public"."sales_orders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_package_items" ADD CONSTRAINT "inventory_package_items_picklist_id_picklist_master_id_fk" FOREIGN KEY ("picklist_id") REFERENCES "public"."picklist_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_package_sales_orders" ADD CONSTRAINT "inventory_package_sales_orders_package_id_inventory_packages_id_fk" FOREIGN KEY ("package_id") REFERENCES "public"."inventory_packages"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_package_sales_orders" ADD CONSTRAINT "inventory_package_sales_orders_sales_order_id_sales_orders_id_fk" FOREIGN KEY ("sales_order_id") REFERENCES "public"."sales_orders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_package_sales_orders" ADD CONSTRAINT "inventory_package_sales_orders_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_packages" ADD CONSTRAINT "inventory_packages_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_packages" ADD CONSTRAINT "inventory_packages_customer_id_customers_id_fk" FOREIGN KEY ("customer_id") REFERENCES "public"."customers"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "picklist_items" ADD CONSTRAINT "picklist_items_picklist_id_picklist_master_id_fk" FOREIGN KEY ("picklist_id") REFERENCES "public"."picklist_master"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "picklist_items" ADD CONSTRAINT "picklist_items_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "picklist_items" ADD CONSTRAINT "picklist_items_sales_order_id_sales_orders_id_fk" FOREIGN KEY ("sales_order_id") REFERENCES "public"."sales_orders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "picklist_master" ADD CONSTRAINT "picklist_master_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "picklist_master" ADD CONSTRAINT "picklist_master_assignee_id_users_id_fk" FOREIGN KEY ("assignee_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "picklist_master" ADD CONSTRAINT "picklist_master_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "picklist_batch_allocation" ADD CONSTRAINT "picklist_batch_allocation_picklist_item_id_picklist_items_id_fk" FOREIGN KEY ("picklist_item_id") REFERENCES "public"."picklist_items"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "picklist_batch_allocation" ADD CONSTRAINT "picklist_batch_allocation_batch_id_batch_master_id_fk" FOREIGN KEY ("batch_id") REFERENCES "public"."batch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "picklist_batch_allocation" ADD CONSTRAINT "picklist_batch_allocation_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "picklist_batch_allocation" ADD CONSTRAINT "picklist_batch_allocation_bin_id_bin_master_id_fk" FOREIGN KEY ("bin_id") REFERENCES "public"."bin_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_order_attachments" ADD CONSTRAINT "purchase_order_attachments_purchase_order_id_purchase_orders_id_fk" FOREIGN KEY ("purchase_order_id") REFERENCES "public"."purchase_orders"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_order_attachments" ADD CONSTRAINT "purchase_order_attachments_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_order_items" ADD CONSTRAINT "purchase_order_items_purchase_order_id_purchase_orders_id_fk" FOREIGN KEY ("purchase_order_id") REFERENCES "public"."purchase_orders"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_order_items" ADD CONSTRAINT "purchase_order_items_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_order_items" ADD CONSTRAINT "purchase_order_items_account_id_accounts_id_fk" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_order_items" ADD CONSTRAINT "purchase_order_items_accounts_accounts_id_fk" FOREIGN KEY ("accounts") REFERENCES "public"."accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_order_items" ADD CONSTRAINT "purchase_order_items_tax_id_tax_rates_id_fk" FOREIGN KEY ("tax_id") REFERENCES "public"."tax_rates"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_order_items" ADD CONSTRAINT "purchase_order_items_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD CONSTRAINT "purchase_orders_vendor_id_vendors_id_fk" FOREIGN KEY ("vendor_id") REFERENCES "public"."vendors"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD CONSTRAINT "purchase_orders_payment_term_id_payment_terms_id_fk" FOREIGN KEY ("payment_term_id") REFERENCES "public"."payment_terms"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD CONSTRAINT "purchase_orders_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD CONSTRAINT "purchase_orders_price_list_id_price_lists_id_fk" FOREIGN KEY ("price_list_id") REFERENCES "public"."price_lists"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD CONSTRAINT "purchase_orders_tds_tcs_tax_id_tds_rates_id_fk" FOREIGN KEY ("tds_tcs_tax_id") REFERENCES "public"."tds_rates"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_orders" ADD CONSTRAINT "purchase_orders_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_receive_item_batches" ADD CONSTRAINT "purchase_receive_item_batches_purchase_receive_item_id_purchase_receive_items_id_fk" FOREIGN KEY ("purchase_receive_item_id") REFERENCES "public"."purchase_receive_items"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_receive_item_batches" ADD CONSTRAINT "purchase_receive_item_batches_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_receive_item_batches" ADD CONSTRAINT "purchase_receive_item_batches_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_receive_item_batches" ADD CONSTRAINT "purchase_receive_item_batches_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_receive_items" ADD CONSTRAINT "purchase_receive_items_purchase_receive_id_purchase_receives_id_fk" FOREIGN KEY ("purchase_receive_id") REFERENCES "public"."purchase_receives"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_receive_items" ADD CONSTRAINT "purchase_receive_items_item_id_products_id_fk" FOREIGN KEY ("item_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_receive_items" ADD CONSTRAINT "purchase_receive_items_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_receive_items" ADD CONSTRAINT "purchase_receive_items_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_receives" ADD CONSTRAINT "purchase_receives_purchase_order_id_purchase_orders_id_fk" FOREIGN KEY ("purchase_order_id") REFERENCES "public"."purchase_orders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_receives" ADD CONSTRAINT "purchase_receives_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "purchase_receives" ADD CONSTRAINT "purchase_receives_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rack_master" ADD CONSTRAINT "rack_master_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rack_master" ADD CONSTRAINT "rack_master_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_order_attachments" ADD CONSTRAINT "sales_order_attachments_sales_order_id_sales_orders_id_fk" FOREIGN KEY ("sales_order_id") REFERENCES "public"."sales_orders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_order_attachments" ADD CONSTRAINT "sales_order_attachments_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_order_items" ADD CONSTRAINT "sales_order_items_sales_order_id_sales_orders_id_fk" FOREIGN KEY ("sales_order_id") REFERENCES "public"."sales_orders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_order_items" ADD CONSTRAINT "sales_order_items_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_order_items" ADD CONSTRAINT "sales_order_items_tax_id_tax_rates_id_fk" FOREIGN KEY ("tax_id") REFERENCES "public"."tax_rates"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_order_items" ADD CONSTRAINT "sales_order_items_batch_id_batch_master_id_fk" FOREIGN KEY ("batch_id") REFERENCES "public"."batch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_order_items" ADD CONSTRAINT "sales_order_items_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_order_items" ADD CONSTRAINT "sales_order_items_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_reps" ADD CONSTRAINT "sales_reps_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_reps" ADD CONSTRAINT "sales_reps_brand_id_brands_id_fk" FOREIGN KEY ("brand_id") REFERENCES "public"."brands"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "roles" ADD CONSTRAINT "roles_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "storage_location" ADD CONSTRAINT "storage_location_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ADD CONSTRAINT "inventory_adjustment_attachments_uploaded_by_users_id_fk" FOREIGN KEY ("uploaded_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ADD CONSTRAINT "inventory_adjustment_item_batches_batch_id_batch_master_id_fk" FOREIGN KEY ("batch_id") REFERENCES "public"."batch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ADD CONSTRAINT "inventory_adjustment_item_batches_batch_stock_layer_id_batch_stock_layers_id_fk" FOREIGN KEY ("batch_stock_layer_id") REFERENCES "public"."batch_stock_layers"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ADD CONSTRAINT "inventory_adjustment_items_batch_id_batch_master_id_fk" FOREIGN KEY ("batch_id") REFERENCES "public"."batch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_reasons" ADD CONSTRAINT "inventory_adjustment_reasons_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ADD CONSTRAINT "inventory_adjustment_value_items_batch_id_batch_master_id_fk" FOREIGN KEY ("batch_id") REFERENCES "public"."batch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ADD CONSTRAINT "inventory_adjustment_value_items_batch_stock_layer_id_batch_stock_layers_id_fk" FOREIGN KEY ("batch_stock_layer_id") REFERENCES "public"."batch_stock_layers"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ADD CONSTRAINT "inventory_adjustments_reason_id_inventory_adjustment_reasons_id_fk" FOREIGN KEY ("reason_id") REFERENCES "public"."inventory_adjustment_reasons"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ADD CONSTRAINT "inventory_adjustments_account_id_accounts_id_fk" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "products" ADD CONSTRAINT "products_rep_id_sales_reps_id_fk" FOREIGN KEY ("rep_id") REFERENCES "public"."sales_reps"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "products" ADD CONSTRAINT "products_storage_id_storage_location_id_fk" FOREIGN KEY ("storage_id") REFERENCES "public"."storage_location"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "products" ADD CONSTRAINT "products_rack_id_rack_master_id_fk" FOREIGN KEY ("rack_id") REFERENCES "public"."rack_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD CONSTRAINT "sales_orders_payment_term_id_payment_terms_id_fk" FOREIGN KEY ("payment_term_id") REFERENCES "public"."payment_terms"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD CONSTRAINT "sales_orders_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD CONSTRAINT "sales_orders_price_list_id_price_lists_id_fk" FOREIGN KEY ("price_list_id") REFERENCES "public"."price_lists"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD CONSTRAINT "sales_orders_tds_tcs_tax_id_tds_rates_id_fk" FOREIGN KEY ("tds_tcs_tax_id") REFERENCES "public"."tds_rates"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_payment_links" ADD CONSTRAINT "sales_payment_links_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customers" DROP COLUMN "associated_branch_id";--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" DROP COLUMN "file_key";--> statement-breakpoint
DROP TYPE "public"."inventory_adjustment_status";--> statement-breakpoint
DROP TYPE "public"."inventory_adjustment_type";