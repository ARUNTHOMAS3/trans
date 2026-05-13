ALTER TABLE "fiscal_years" DROP CONSTRAINT "fiscal_years_org_id_organization_id_fk";
--> statement-breakpoint
ALTER TABLE "fiscal_years" DROP CONSTRAINT "fiscal_years_branch_id_branches_id_fk";
--> statement-breakpoint
ALTER TABLE "account_transactions" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "account_transactions" DROP COLUMN "branch_id";--> statement-breakpoint
ALTER TABLE "fiscal_years" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "fiscal_years" DROP COLUMN "branch_id";--> statement-breakpoint
ALTER TABLE "journal_number_settings" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "journal_number_settings" DROP COLUMN "outlet_id";--> statement-breakpoint
ALTER TABLE "journal_template_items" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "journal_template_items" DROP COLUMN "outlet_id";--> statement-breakpoint
ALTER TABLE "journal_templates" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "journal_templates" DROP COLUMN "outlet_id";--> statement-breakpoint
ALTER TABLE "manual_journal_attachments" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "manual_journal_attachments" DROP COLUMN "outlet_id";--> statement-breakpoint
ALTER TABLE "manual_journals" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "manual_journals" DROP COLUMN "outlet_id";--> statement-breakpoint
ALTER TABLE "recurring_journals" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "recurring_journals" DROP COLUMN "outlet_id";--> statement-breakpoint
ALTER TABLE "reorder_terms" DROP COLUMN "org_id";--> statement-breakpoint
ALTER TABLE "reorder_terms" DROP COLUMN "outlet_id";