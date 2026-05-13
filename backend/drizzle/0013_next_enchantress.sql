ALTER TABLE "branch_inventory" DROP CONSTRAINT "branch_inventory_outlet_id_product_id_batch_no_key";--> statement-breakpoint
DROP INDEX "idx_inventory_expiry";--> statement-breakpoint
DROP INDEX "idx_inventory_outlet";--> statement-breakpoint
DROP INDEX "idx_inventory_outlet_product";--> statement-breakpoint
DROP INDEX "idx_inventory_product";--> statement-breakpoint
ALTER TABLE "branch_inventory" ALTER COLUMN "entity_id" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "customers" ALTER COLUMN "entity_id" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "product_branch_inventory_settings" ALTER COLUMN "entity_id" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_orders" ALTER COLUMN "entity_id" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_payments" ALTER COLUMN "entity_id" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "transactional_sequences" ALTER COLUMN "entity_id" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "branch_inventory" ADD COLUMN "created_at" timestamp with time zone DEFAULT now();--> statement-breakpoint
ALTER TABLE "branch_inventory" ADD COLUMN "updated_at" timestamp with time zone DEFAULT now();--> statement-breakpoint
ALTER TABLE "transactional_sequences" ADD COLUMN "created_at" timestamp DEFAULT now();--> statement-breakpoint
CREATE INDEX "idx_branch_inventory_expiry" ON "branch_inventory" USING btree ("expiry_date" date_ops);--> statement-breakpoint
CREATE INDEX "idx_branch_inventory_entity" ON "branch_inventory" USING btree ("entity_id" uuid_ops);--> statement-breakpoint
CREATE INDEX "idx_branch_inventory_entity_product" ON "branch_inventory" USING btree ("entity_id" uuid_ops,"product_id" uuid_ops);--> statement-breakpoint
CREATE INDEX "idx_branch_inventory_product" ON "branch_inventory" USING btree ("product_id" uuid_ops);--> statement-breakpoint
ALTER TABLE "branch_inventory" DROP COLUMN "outlet_id";--> statement-breakpoint
ALTER TABLE "branch_inventory" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "customers" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "customers" DROP COLUMN "outlet_id";--> statement-breakpoint
ALTER TABLE "product_branch_inventory_settings" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "product_branch_inventory_settings" DROP COLUMN "outlet_id";--> statement-breakpoint
ALTER TABLE "sales_orders" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "sales_orders" DROP COLUMN "outlet_id";--> statement-breakpoint
ALTER TABLE "sales_payments" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "sales_payments" DROP COLUMN "outlet_id";--> statement-breakpoint
ALTER TABLE "transactional_sequences" DROP COLUMN "outlet_id";--> statement-breakpoint
ALTER TABLE "branch_inventory" ADD CONSTRAINT "branch_inventory_entity_id_product_id_batch_no_key" UNIQUE("entity_id","product_id","batch_no");