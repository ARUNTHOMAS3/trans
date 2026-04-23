ALTER TABLE "outlet_inventory" RENAME TO "branch_inventory";--> statement-breakpoint
ALTER TABLE "product_outlet_inventory_settings" RENAME TO "product_branch_inventory_settings";--> statement-breakpoint
ALTER TABLE "branch_inventory" DROP CONSTRAINT "outlet_inventory_outlet_id_product_id_batch_no_key";--> statement-breakpoint
ALTER TABLE "branch_inventory" DROP CONSTRAINT "outlet_inventory_current_stock_check";--> statement-breakpoint
ALTER TABLE "branch_inventory" DROP CONSTRAINT "outlet_inventory_entity_id_organisation_branch_master_id_fk";
--> statement-breakpoint
ALTER TABLE "product_branch_inventory_settings" DROP CONSTRAINT "product_outlet_inventory_settings_entity_id_organisation_branch_master_id_fk";
--> statement-breakpoint
ALTER TABLE "product_branch_inventory_settings" DROP CONSTRAINT "product_outlet_inventory_settings_product_id_products_id_fk";
--> statement-breakpoint
ALTER TABLE "product_branch_inventory_settings" DROP CONSTRAINT "product_outlet_inventory_settings_reorder_term_id_reorder_terms_id_fk";
--> statement-breakpoint
ALTER TABLE "branch_inventory" ADD COLUMN "org_id" uuid DEFAULT '00000000-0000-0000-0000-000000000000' NOT NULL;--> statement-breakpoint
ALTER TABLE "branch_inventory" ADD CONSTRAINT "branch_inventory_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_branch_inventory_settings" ADD CONSTRAINT "product_branch_inventory_settings_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_branch_inventory_settings" ADD CONSTRAINT "product_branch_inventory_settings_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_branch_inventory_settings" ADD CONSTRAINT "product_branch_inventory_settings_reorder_term_id_reorder_terms_id_fk" FOREIGN KEY ("reorder_term_id") REFERENCES "public"."reorder_terms"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branch_inventory" ADD CONSTRAINT "branch_inventory_outlet_id_product_id_batch_no_key" UNIQUE("outlet_id","product_id","batch_no");--> statement-breakpoint
ALTER TABLE "branch_inventory" ADD CONSTRAINT "branch_inventory_current_stock_check" CHECK (current_stock >= 0);