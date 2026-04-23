CREATE TABLE "organisation_branch_master" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(150) NOT NULL,
	"type" varchar(20) NOT NULL,
	"ref_id" uuid NOT NULL,
	"parent_id" uuid,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
ALTER TABLE "accounts_fiscal_years" RENAME TO "fiscal_years";--> statement-breakpoint
ALTER TABLE "accounts_journal_number_settings" RENAME TO "journal_number_settings";--> statement-breakpoint
ALTER TABLE "accounts_journal_template_items" RENAME TO "journal_template_items";--> statement-breakpoint
ALTER TABLE "accounts_journal_templates" RENAME TO "journal_templates";--> statement-breakpoint
ALTER TABLE "accounts_manual_journal_attachments" RENAME TO "manual_journal_attachments";--> statement-breakpoint
ALTER TABLE "accounts_manual_journal_items" RENAME TO "manual_journal_items";--> statement-breakpoint
ALTER TABLE "accounts_manual_journals" RENAME TO "manual_journals";--> statement-breakpoint
ALTER TABLE "accounts_recurring_journal_items" RENAME TO "recurring_journal_items";--> statement-breakpoint
ALTER TABLE "accounts_recurring_journals" RENAME TO "recurring_journals";--> statement-breakpoint
ALTER TABLE "schedules" RENAME TO "drug_schedules";--> statement-breakpoint
ALTER TABLE "settings_assemblies" RENAME TO "assemblies_constituencies";--> statement-breakpoint
ALTER TABLE "settings_branch_transaction_series" RENAME TO "branch_transaction_series";--> statement-breakpoint
ALTER TABLE "settings_branches" RENAME TO "branches";--> statement-breakpoint
ALTER TABLE "settings_districts" RENAME TO "lsgd_districts";--> statement-breakpoint
ALTER TABLE "settings_local_bodies" RENAME TO "lsgd_local_bodies";--> statement-breakpoint
ALTER TABLE "settings_transaction_series" RENAME TO "transaction_series";--> statement-breakpoint
ALTER TABLE "settings_wards" RENAME TO "lsgd_wards";--> statement-breakpoint
ALTER TABLE "storage_locations" RENAME TO "storage_conditions";--> statement-breakpoint
ALTER TABLE "strengths" RENAME TO "drug_strengths";--> statement-breakpoint
ALTER TABLE "journal_number_settings" RENAME COLUMN "branch_id" TO "outlet_id";--> statement-breakpoint
ALTER TABLE "journal_template_items" RENAME COLUMN "branch_id" TO "outlet_id";--> statement-breakpoint
ALTER TABLE "journal_templates" RENAME COLUMN "branch_id" TO "outlet_id";--> statement-breakpoint
ALTER TABLE "manual_journal_attachments" RENAME COLUMN "branch_id" TO "outlet_id";--> statement-breakpoint
ALTER TABLE "manual_journals" RENAME COLUMN "branch_id" TO "outlet_id";--> statement-breakpoint
ALTER TABLE "recurring_journals" RENAME COLUMN "branch_id" TO "outlet_id";--> statement-breakpoint
ALTER TABLE "manual_journals" DROP CONSTRAINT "accounts_manual_journals_journal_number_unique";--> statement-breakpoint
ALTER TABLE "drug_schedules" DROP CONSTRAINT "schedules_shedule_name_unique";--> statement-breakpoint
ALTER TABLE "storage_conditions" DROP CONSTRAINT "storage_locations_location_name_unique";--> statement-breakpoint
ALTER TABLE "drug_strengths" DROP CONSTRAINT "strengths_strength_name_unique";--> statement-breakpoint
ALTER TABLE "fiscal_years" DROP CONSTRAINT "accounts_fiscal_years_org_id_organization_id_fk";
--> statement-breakpoint
ALTER TABLE "fiscal_years" DROP CONSTRAINT "accounts_fiscal_years_branch_id_settings_branches_id_fk";
--> statement-breakpoint
ALTER TABLE "journal_template_items" DROP CONSTRAINT "accounts_journal_template_items_template_id_accounts_journal_templates_id_fk";
--> statement-breakpoint
ALTER TABLE "manual_journal_attachments" DROP CONSTRAINT "accounts_manual_journal_attachments_manual_journal_id_accounts_manual_journals_id_fk";
--> statement-breakpoint
ALTER TABLE "manual_journal_items" DROP CONSTRAINT "accounts_manual_journal_items_manual_journal_id_accounts_manual_journals_id_fk";
--> statement-breakpoint
ALTER TABLE "recurring_journal_items" DROP CONSTRAINT "accounts_recurring_journal_items_recurring_journal_id_accounts_recurring_journals_id_fk";
--> statement-breakpoint
ALTER TABLE "inventory_picklists" DROP CONSTRAINT "inventory_picklists_location_storage_locations_id_fk";
--> statement-breakpoint
ALTER TABLE "organization" DROP CONSTRAINT "organization_assembly_id_settings_assemblies_id_fk";
--> statement-breakpoint
ALTER TABLE "organization" DROP CONSTRAINT "organization_payment_stub_assembly_id_settings_assemblies_id_fk";
--> statement-breakpoint
ALTER TABLE "products" DROP CONSTRAINT "products_schedule_of_drug_id_schedules_id_fk";
--> statement-breakpoint
ALTER TABLE "products" DROP CONSTRAINT "products_storage_id_storage_locations_id_fk";
--> statement-breakpoint
ALTER TABLE "product_contents" DROP CONSTRAINT "product_contents_strength_id_strengths_id_fk";
--> statement-breakpoint
ALTER TABLE "product_contents" DROP CONSTRAINT "product_contents_shedule_id_schedules_id_fk";
--> statement-breakpoint
ALTER TABLE "racks" DROP CONSTRAINT "racks_storage_id_storage_locations_id_fk";
--> statement-breakpoint
ALTER TABLE "assemblies_constituencies" DROP CONSTRAINT "settings_assemblies_district_id_settings_districts_id_fk";
--> statement-breakpoint
ALTER TABLE "branch_transaction_series" DROP CONSTRAINT "settings_branch_transaction_series_org_id_organization_id_fk";
--> statement-breakpoint
ALTER TABLE "branch_transaction_series" DROP CONSTRAINT "settings_branch_transaction_series_branch_id_settings_branches_id_fk";
--> statement-breakpoint
ALTER TABLE "branch_transaction_series" DROP CONSTRAINT "settings_branch_transaction_series_transaction_series_id_settings_transaction_series_id_fk";
--> statement-breakpoint
ALTER TABLE "branches" DROP CONSTRAINT "settings_branches_org_id_organization_id_fk";
--> statement-breakpoint
ALTER TABLE "branches" DROP CONSTRAINT "settings_branches_district_id_settings_districts_id_fk";
--> statement-breakpoint
ALTER TABLE "branches" DROP CONSTRAINT "settings_branches_local_body_id_settings_local_bodies_id_fk";
--> statement-breakpoint
ALTER TABLE "branches" DROP CONSTRAINT "settings_branches_assembly_id_settings_assemblies_id_fk";
--> statement-breakpoint
ALTER TABLE "branches" DROP CONSTRAINT "settings_branches_ward_id_settings_wards_id_fk";
--> statement-breakpoint
ALTER TABLE "branches" DROP CONSTRAINT "settings_branches_primary_contact_id_users_id_fk";
--> statement-breakpoint
ALTER TABLE "branches" DROP CONSTRAINT "settings_branches_payment_stub_district_id_settings_districts_id_fk";
--> statement-breakpoint
ALTER TABLE "branches" DROP CONSTRAINT "settings_branches_payment_stub_local_body_id_settings_local_bodies_id_fk";
--> statement-breakpoint
ALTER TABLE "branches" DROP CONSTRAINT "settings_branches_payment_stub_ward_id_settings_wards_id_fk";
--> statement-breakpoint
ALTER TABLE "branches" DROP CONSTRAINT "settings_branches_payment_stub_assembly_id_settings_assemblies_id_fk";
--> statement-breakpoint
ALTER TABLE "lsgd_local_bodies" DROP CONSTRAINT "settings_local_bodies_district_id_settings_districts_id_fk";
--> statement-breakpoint
ALTER TABLE "lsgd_wards" DROP CONSTRAINT "settings_wards_local_body_id_settings_local_bodies_id_fk";
--> statement-breakpoint
ALTER TABLE "vendors" DROP CONSTRAINT "vendors_branch_id_settings_branches_id_fk";
--> statement-breakpoint
ALTER TABLE "warehouses" DROP CONSTRAINT "warehouses_district_id_settings_districts_id_fk";
--> statement-breakpoint
ALTER TABLE "warehouses" DROP CONSTRAINT "warehouses_local_body_id_settings_local_bodies_id_fk";
--> statement-breakpoint
ALTER TABLE "warehouses" DROP CONSTRAINT "warehouses_ward_id_settings_wards_id_fk";
--> statement-breakpoint
ALTER TABLE "warehouses" DROP CONSTRAINT "warehouses_branch_id_settings_branches_id_fk";
--> statement-breakpoint
ALTER TABLE "fiscal_years" ADD CONSTRAINT "fiscal_years_org_id_organization_id_fk" FOREIGN KEY ("org_id") REFERENCES "public"."organization"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fiscal_years" ADD CONSTRAINT "fiscal_years_branch_id_branches_id_fk" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journal_template_items" ADD CONSTRAINT "journal_template_items_template_id_journal_templates_id_fk" FOREIGN KEY ("template_id") REFERENCES "public"."journal_templates"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "manual_journal_attachments" ADD CONSTRAINT "manual_journal_attachments_manual_journal_id_manual_journals_id_fk" FOREIGN KEY ("manual_journal_id") REFERENCES "public"."manual_journals"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "manual_journal_items" ADD CONSTRAINT "manual_journal_items_manual_journal_id_manual_journals_id_fk" FOREIGN KEY ("manual_journal_id") REFERENCES "public"."manual_journals"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recurring_journal_items" ADD CONSTRAINT "recurring_journal_items_recurring_journal_id_recurring_journals_id_fk" FOREIGN KEY ("recurring_journal_id") REFERENCES "public"."recurring_journals"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "inventory_picklists" ADD CONSTRAINT "inventory_picklists_location_storage_conditions_id_fk" FOREIGN KEY ("location") REFERENCES "public"."storage_conditions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "organization" ADD CONSTRAINT "organization_assembly_id_assemblies_constituencies_id_fk" FOREIGN KEY ("assembly_id") REFERENCES "public"."assemblies_constituencies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "organization" ADD CONSTRAINT "organization_payment_stub_assembly_id_assemblies_constituencies_id_fk" FOREIGN KEY ("payment_stub_assembly_id") REFERENCES "public"."assemblies_constituencies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "products" ADD CONSTRAINT "products_schedule_of_drug_id_drug_schedules_id_fk" FOREIGN KEY ("schedule_of_drug_id") REFERENCES "public"."drug_schedules"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "products" ADD CONSTRAINT "products_storage_id_storage_conditions_id_fk" FOREIGN KEY ("storage_id") REFERENCES "public"."storage_conditions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_contents" ADD CONSTRAINT "product_contents_strength_id_drug_strengths_id_fk" FOREIGN KEY ("strength_id") REFERENCES "public"."drug_strengths"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_contents" ADD CONSTRAINT "product_contents_shedule_id_drug_schedules_id_fk" FOREIGN KEY ("shedule_id") REFERENCES "public"."drug_schedules"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "racks" ADD CONSTRAINT "racks_storage_id_storage_conditions_id_fk" FOREIGN KEY ("storage_id") REFERENCES "public"."storage_conditions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "assemblies_constituencies" ADD CONSTRAINT "assemblies_constituencies_district_id_lsgd_districts_id_fk" FOREIGN KEY ("district_id") REFERENCES "public"."lsgd_districts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branch_transaction_series" ADD CONSTRAINT "branch_transaction_series_org_id_organization_id_fk" FOREIGN KEY ("org_id") REFERENCES "public"."organization"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branch_transaction_series" ADD CONSTRAINT "branch_transaction_series_branch_id_branches_id_fk" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branch_transaction_series" ADD CONSTRAINT "branch_transaction_series_transaction_series_id_transaction_series_id_fk" FOREIGN KEY ("transaction_series_id") REFERENCES "public"."transaction_series"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branches" ADD CONSTRAINT "branches_org_id_organization_id_fk" FOREIGN KEY ("org_id") REFERENCES "public"."organization"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branches" ADD CONSTRAINT "branches_district_id_lsgd_districts_id_fk" FOREIGN KEY ("district_id") REFERENCES "public"."lsgd_districts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branches" ADD CONSTRAINT "branches_local_body_id_lsgd_local_bodies_id_fk" FOREIGN KEY ("local_body_id") REFERENCES "public"."lsgd_local_bodies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branches" ADD CONSTRAINT "branches_assembly_id_assemblies_constituencies_id_fk" FOREIGN KEY ("assembly_id") REFERENCES "public"."assemblies_constituencies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branches" ADD CONSTRAINT "branches_ward_id_lsgd_wards_id_fk" FOREIGN KEY ("ward_id") REFERENCES "public"."lsgd_wards"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branches" ADD CONSTRAINT "branches_primary_contact_id_users_id_fk" FOREIGN KEY ("primary_contact_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branches" ADD CONSTRAINT "branches_payment_stub_district_id_lsgd_districts_id_fk" FOREIGN KEY ("payment_stub_district_id") REFERENCES "public"."lsgd_districts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branches" ADD CONSTRAINT "branches_payment_stub_local_body_id_lsgd_local_bodies_id_fk" FOREIGN KEY ("payment_stub_local_body_id") REFERENCES "public"."lsgd_local_bodies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branches" ADD CONSTRAINT "branches_payment_stub_ward_id_lsgd_wards_id_fk" FOREIGN KEY ("payment_stub_ward_id") REFERENCES "public"."lsgd_wards"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branches" ADD CONSTRAINT "branches_payment_stub_assembly_id_assemblies_constituencies_id_fk" FOREIGN KEY ("payment_stub_assembly_id") REFERENCES "public"."assemblies_constituencies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "lsgd_local_bodies" ADD CONSTRAINT "lsgd_local_bodies_district_id_lsgd_districts_id_fk" FOREIGN KEY ("district_id") REFERENCES "public"."lsgd_districts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "lsgd_wards" ADD CONSTRAINT "lsgd_wards_local_body_id_lsgd_local_bodies_id_fk" FOREIGN KEY ("local_body_id") REFERENCES "public"."lsgd_local_bodies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "vendors" ADD CONSTRAINT "vendors_branch_id_branches_id_fk" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "warehouses" ADD CONSTRAINT "warehouses_district_id_lsgd_districts_id_fk" FOREIGN KEY ("district_id") REFERENCES "public"."lsgd_districts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "warehouses" ADD CONSTRAINT "warehouses_local_body_id_lsgd_local_bodies_id_fk" FOREIGN KEY ("local_body_id") REFERENCES "public"."lsgd_local_bodies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "warehouses" ADD CONSTRAINT "warehouses_ward_id_lsgd_wards_id_fk" FOREIGN KEY ("ward_id") REFERENCES "public"."lsgd_wards"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "warehouses" ADD CONSTRAINT "warehouses_branch_id_branches_id_fk" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "manual_journals" ADD CONSTRAINT "manual_journals_journal_number_unique" UNIQUE("journal_number");--> statement-breakpoint
ALTER TABLE "drug_schedules" ADD CONSTRAINT "drug_schedules_shedule_name_unique" UNIQUE("shedule_name");--> statement-breakpoint
ALTER TABLE "storage_conditions" ADD CONSTRAINT "storage_conditions_location_name_unique" UNIQUE("location_name");--> statement-breakpoint
ALTER TABLE "drug_strengths" ADD CONSTRAINT "drug_strengths_strength_name_unique" UNIQUE("strength_name");