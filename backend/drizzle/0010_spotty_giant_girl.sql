ALTER TABLE "warehouses" DROP CONSTRAINT "warehouses_org_id_organization_id_fk";
--> statement-breakpoint
ALTER TABLE "warehouses" DROP CONSTRAINT "warehouses_district_id_lsgd_districts_id_fk";
--> statement-breakpoint
ALTER TABLE "warehouses" DROP CONSTRAINT "warehouses_local_body_id_lsgd_local_bodies_id_fk";
--> statement-breakpoint
ALTER TABLE "warehouses" DROP CONSTRAINT "warehouses_ward_id_lsgd_wards_id_fk";
--> statement-breakpoint
ALTER TABLE "warehouses" DROP CONSTRAINT "warehouses_branch_id_branches_id_fk";
--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "account_transactions" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "fiscal_years" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "journal_number_settings" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "journal_template_items" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "journal_templates" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "manual_journal_attachments" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "manual_journal_items" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "manual_journals" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "recurring_journal_items" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "recurring_journals" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "audit_logs" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "audit_logs_archive" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "batches" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "inventory_picklists" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "outlet_inventory" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "price_lists" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "product_outlet_inventory_settings" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "sales_eway_bills" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "org_id" uuid NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "outlet_id" uuid;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "sales_payments" ADD COLUMN "org_id" uuid NOT NULL;--> statement-breakpoint
ALTER TABLE "sales_payments" ADD COLUMN "outlet_id" uuid;--> statement-breakpoint
ALTER TABLE "sales_payments" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "transaction_locks" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "transaction_locks" ADD COLUMN "branch_id" uuid;--> statement-breakpoint
ALTER TABLE "transactional_sequences" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "vendors" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "warehouses" ADD COLUMN "entity_id" uuid;--> statement-breakpoint
ALTER TABLE "warehouses" ADD COLUMN "assembly_id" uuid;--> statement-breakpoint
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "account_transactions" ADD CONSTRAINT "account_transactions_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fiscal_years" ADD CONSTRAINT "fiscal_years_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journal_number_settings" ADD CONSTRAINT "journal_number_settings_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journal_template_items" ADD CONSTRAINT "journal_template_items_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journal_templates" ADD CONSTRAINT "journal_templates_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "manual_journal_attachments" ADD CONSTRAINT "manual_journal_attachments_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "manual_journal_items" ADD CONSTRAINT "manual_journal_items_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "manual_journals" ADD CONSTRAINT "manual_journals_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recurring_journal_items" ADD CONSTRAINT "recurring_journal_items_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recurring_journals" ADD CONSTRAINT "recurring_journals_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "audit_logs_archive" ADD CONSTRAINT "audit_logs_archive_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "batches" ADD CONSTRAINT "batches_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_picklists" ADD CONSTRAINT "inventory_picklists_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "outlet_inventory" ADD CONSTRAINT "outlet_inventory_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "price_lists" ADD CONSTRAINT "price_lists_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_outlet_inventory_settings" ADD CONSTRAINT "product_outlet_inventory_settings_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_eway_bills" ADD CONSTRAINT "sales_eway_bills_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_orders" ADD CONSTRAINT "sales_orders_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sales_payments" ADD CONSTRAINT "sales_payments_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_locks" ADD CONSTRAINT "transaction_locks_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactional_sequences" ADD CONSTRAINT "transactional_sequences_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "users" ADD CONSTRAINT "users_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "vendors" ADD CONSTRAINT "vendors_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "warehouses" ADD CONSTRAINT "warehouses_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "warehouses" DROP COLUMN "zip_code";--> statement-breakpoint
ALTER TABLE "warehouses" DROP COLUMN "country_region";