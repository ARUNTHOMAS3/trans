ALTER TABLE "branches" RENAME COLUMN "drug_license_20" TO "drug_licence_20";--> statement-breakpoint
ALTER TABLE "branches" RENAME COLUMN "drug_license_21" TO "drug_licence_21";--> statement-breakpoint
ALTER TABLE "branches" RENAME COLUMN "drug_license_20b" TO "drug_licence_20b";--> statement-breakpoint
ALTER TABLE "branches" RENAME COLUMN "drug_license_21b" TO "drug_licence_21b";--> statement-breakpoint
ALTER TABLE "branch_transaction_series" DROP CONSTRAINT "branch_transaction_series_org_id_organization_id_fk";
--> statement-breakpoint
ALTER TABLE "branch_transaction_series" DROP CONSTRAINT "branch_transaction_series_branch_id_branches_id_fk";
--> statement-breakpoint
ALTER TABLE "transaction_series" ALTER COLUMN "org_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "branch_transaction_series" ADD COLUMN "entity_id" uuid NOT NULL;--> statement-breakpoint
ALTER TABLE "branches" ADD COLUMN "msme_type" varchar(50);--> statement-breakpoint
ALTER TABLE "transaction_series" ADD COLUMN "entity_id" uuid NOT NULL;--> statement-breakpoint
ALTER TABLE "branch_transaction_series" ADD CONSTRAINT "branch_transaction_series_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_series" ADD CONSTRAINT "transaction_series_entity_id_organisation_branch_master_id_fk" FOREIGN KEY ("entity_id") REFERENCES "public"."organisation_branch_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branch_transaction_series" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "branch_transaction_series" DROP COLUMN "branch_id";