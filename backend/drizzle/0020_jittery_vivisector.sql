CREATE TYPE "public"."inventory_adjustment_status" AS ENUM('draft', 'approved', 'rejected', 'cancelled');--> statement-breakpoint
CREATE TYPE "public"."inventory_adjustment_type" AS ENUM('quantity', 'value');--> statement-breakpoint
CREATE TABLE "inventory_adjustment_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"adjustment_id" uuid NOT NULL,
	"product_id" uuid NOT NULL,
	"entity_id" uuid NOT NULL,
	"quantity_before" numeric(15, 2) DEFAULT '0.00' NOT NULL,
	"quantity_adjusted" numeric(15, 2) DEFAULT '0.00' NOT NULL,
	"quantity_after" numeric(15, 2) DEFAULT '0.00' NOT NULL,
	"cost_price" numeric(15, 2),
	"batch_id" uuid,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "inventory_adjustments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entity_id" uuid NOT NULL,
	"adjustment_number" varchar(100),
	"adjustment_date" timestamp with time zone DEFAULT now(),
	"warehouse_id" uuid,
	"adjustment_type" "inventory_adjustment_type" DEFAULT 'quantity',
	"reason" varchar(255),
	"reference_number" varchar(100),
	"notes" text,
	"status" "inventory_adjustment_status" DEFAULT 'draft',
	"adjusted_by" uuid,
	"approved_by" uuid,
	"approved_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now(),
	"updated_at" timestamp with time zone DEFAULT now(),
	"product_id" uuid,
	"quantity_before" numeric(15, 2),
	"quantity_adjusted" numeric(15, 2),
	"quantity_after" numeric(15, 2),
	CONSTRAINT "inventory_adjustments_adjustment_number_unique" UNIQUE("adjustment_number")
);
--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "associated_branch_id" uuid;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ADD CONSTRAINT "inventory_adjustment_items_adjustment_id_inventory_adjustments_id_fk" FOREIGN KEY ("adjustment_id") REFERENCES "public"."inventory_adjustments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ADD CONSTRAINT "inventory_adjustment_items_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ADD CONSTRAINT "inventory_adjustment_items_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustment_items" ADD CONSTRAINT "inventory_adjustment_items_batch_id_batches_id_fk" FOREIGN KEY ("batch_id") REFERENCES "public"."batches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ADD CONSTRAINT "inventory_adjustments_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ADD CONSTRAINT "inventory_adjustments_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ADD CONSTRAINT "inventory_adjustments_adjusted_by_users_id_fk" FOREIGN KEY ("adjusted_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ADD CONSTRAINT "inventory_adjustments_approved_by_users_id_fk" FOREIGN KEY ("approved_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_adjustments" ADD CONSTRAINT "inventory_adjustments_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customers" ADD CONSTRAINT "customers_associated_branch_id_branches_id_fk" FOREIGN KEY ("associated_branch_id") REFERENCES "public"."branches"("id") ON DELETE set null ON UPDATE no action;