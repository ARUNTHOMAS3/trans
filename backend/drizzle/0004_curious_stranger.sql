ALTER TABLE "organization" ADD COLUMN "report_basis" varchar(50) DEFAULT 'accrual';--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "has_separate_payment_stub_address" boolean DEFAULT false;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "payment_stub_address" text;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "payment_stub_district_id" uuid;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "payment_stub_local_body_id" uuid;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "payment_stub_ward_id" uuid;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD CONSTRAINT "settings_branches_payment_stub_district_id_settings_districts_id_fk" FOREIGN KEY ("payment_stub_district_id") REFERENCES "public"."settings_districts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD CONSTRAINT "settings_branches_payment_stub_local_body_id_settings_local_bodies_id_fk" FOREIGN KEY ("payment_stub_local_body_id") REFERENCES "public"."settings_local_bodies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD CONSTRAINT "settings_branches_payment_stub_ward_id_settings_wards_id_fk" FOREIGN KEY ("payment_stub_ward_id") REFERENCES "public"."settings_wards"("id") ON DELETE no action ON UPDATE no action;