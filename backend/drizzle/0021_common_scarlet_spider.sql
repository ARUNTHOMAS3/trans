ALTER TYPE "public"."inventory_adjustment_status" ADD VALUE 'submitted' BEFORE 'approved';--> statement-breakpoint
CREATE TABLE "inventory_adjustment_account_entries" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"adjustment_id" uuid NOT NULL,
	"entity_id" uuid NOT NULL,
	"account_id" uuid NOT NULL,
	"debit" numeric(18, 2) DEFAULT '0.00' NOT NULL,
	"credit" numeric(18, 2) DEFAULT '0.00' NOT NULL,
	"description" text,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "inventory_adjustment_attachments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"adjustment_id" uuid NOT NULL,
	"entity_id" uuid NOT NULL,
	"file_name" varchar(255) NOT NULL,
	"file_url" text NOT NULL,
	"file_key" text,
	"mime_type" varchar(120),
	"file_size_bytes" bigint,
	"uploaded_by" uuid,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "inventory_adjustment_item_batches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"adjustment_id" uuid NOT NULL,
	"adjustment_item_id" uuid NOT NULL,
	"entity_id" uuid NOT NULL,
	"product_id" uuid NOT NULL,
	"warehouse_id" uuid,
	"bin_id" uuid,
	"batch_id" uuid,
	"batch_reference" varchar(150),
	"quantity_in" numeric(15, 2) DEFAULT '0.00' NOT NULL,
	"quantity_out" numeric(15, 2) DEFAULT '0.00' NOT NULL,
	"rate" numeric(15, 2),
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "inventory_adjustment_reasons" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entity_id" uuid,
	"name" varchar(200) NOT NULL,
	"code" varchar(60),
	"is_active" boolean DEFAULT true NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "inventory_adjustment_value_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"adjustment_id" uuid NOT NULL,
	"entity_id" uuid NOT NULL,
	"product_id" uuid NOT NULL,
	"batch_id" uuid,
	"batch_stock_layer_id" uuid,
	"current_value" numeric(18, 2) DEFAULT '0.00' NOT NULL,
	"changed_value" numeric(18, 2) DEFAULT '0.00' NOT NULL,
	"adjusted_value" numeric(18, 2) DEFAULT '0.00' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ADD COLUMN "purchase_rate" numeric(15, 2);--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ADD COLUMN "mrp" numeric(15, 2);--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ADD COLUMN "adjustment_value" numeric(15, 2) DEFAULT '0.00' NOT NULL;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ADD COLUMN "batch_reference" varchar(150);--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ADD COLUMN "batch_allocations" jsonb DEFAULT '[]'::jsonb;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ADD COLUMN "reporting_tags" jsonb DEFAULT '{}'::jsonb;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ADD COLUMN "mfd_month_year" varchar(7);--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ADD COLUMN "expiry_month_year" varchar(7);--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ADD COLUMN "reason_id" uuid;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ADD COLUMN "account_id" uuid;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ADD COLUMN "cost_price" numeric(15, 2);--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ADD COLUMN "adjustment_value" numeric(15, 2);--> statement-breakpoint
ALTER TABLE "inventory_adjustment_account_entries" ADD CONSTRAINT "inventory_adjustment_account_entries_adjustment_id_inventory_adjustments_id_fk" FOREIGN KEY ("adjustment_id") REFERENCES "public"."inventory_adjustments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_account_entries" ADD CONSTRAINT "inventory_adjustment_account_entries_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_account_entries" ADD CONSTRAINT "inventory_adjustment_account_entries_account_id_accounts_id_fk" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ADD CONSTRAINT "inventory_adjustment_attachments_adjustment_id_inventory_adjustments_id_fk" FOREIGN KEY ("adjustment_id") REFERENCES "public"."inventory_adjustments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ADD CONSTRAINT "inventory_adjustment_attachments_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_attachments" ADD CONSTRAINT "inventory_adjustment_attachments_uploaded_by_users_id_fk" FOREIGN KEY ("uploaded_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ADD CONSTRAINT "inventory_adjustment_item_batches_adjustment_id_inventory_adjustments_id_fk" FOREIGN KEY ("adjustment_id") REFERENCES "public"."inventory_adjustments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ADD CONSTRAINT "inventory_adjustment_item_batches_adjustment_item_id_inventory_adjustment_items_id_fk" FOREIGN KEY ("adjustment_item_id") REFERENCES "public"."inventory_adjustment_items"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ADD CONSTRAINT "inventory_adjustment_item_batches_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ADD CONSTRAINT "inventory_adjustment_item_batches_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ADD CONSTRAINT "inventory_adjustment_item_batches_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_item_batches" ADD CONSTRAINT "inventory_adjustment_item_batches_batch_id_batches_id_fk" FOREIGN KEY ("batch_id") REFERENCES "public"."batches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_reasons" ADD CONSTRAINT "inventory_adjustment_reasons_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ADD CONSTRAINT "inventory_adjustment_value_items_adjustment_id_inventory_adjustments_id_fk" FOREIGN KEY ("adjustment_id") REFERENCES "public"."inventory_adjustments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ADD CONSTRAINT "inventory_adjustment_value_items_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ADD CONSTRAINT "inventory_adjustment_value_items_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_value_items" ADD CONSTRAINT "inventory_adjustment_value_items_batch_id_batches_id_fk" FOREIGN KEY ("batch_id") REFERENCES "public"."batches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ADD CONSTRAINT "inventory_adjustments_account_id_accounts_id_fk" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE set null ON UPDATE no action;