ALTER TABLE "organization" ADD COLUMN "attention" text;--> statement-breakpoint
ALTER TABLE "organization" ADD COLUMN "address_street_1" text;--> statement-breakpoint
ALTER TABLE "organization" ADD COLUMN "address_street_2" text;--> statement-breakpoint
ALTER TABLE "organization" ADD COLUMN "city" varchar(100);--> statement-breakpoint
ALTER TABLE "organization" ADD COLUMN "pincode" varchar(20);--> statement-breakpoint
ALTER TABLE "organization" ADD COLUMN "phone" varchar(50);--> statement-breakpoint
ALTER TABLE "organization" ADD COLUMN "assembly_id" uuid;--> statement-breakpoint
ALTER TABLE "organization" ADD COLUMN "payment_stub_assembly_id" uuid;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "assembly_id" uuid;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD COLUMN "payment_stub_assembly_id" uuid;--> statement-breakpoint
ALTER TABLE "warehouses" ADD COLUMN "district_id" uuid;--> statement-breakpoint
ALTER TABLE "warehouses" ADD COLUMN "local_body_id" uuid;--> statement-breakpoint
ALTER TABLE "warehouses" ADD COLUMN "ward_id" uuid;--> statement-breakpoint
ALTER TABLE "organization" ADD CONSTRAINT "organization_assembly_id_settings_assemblies_id_fk" FOREIGN KEY ("assembly_id") REFERENCES "public"."settings_assemblies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "organization" ADD CONSTRAINT "organization_payment_stub_assembly_id_settings_assemblies_id_fk" FOREIGN KEY ("payment_stub_assembly_id") REFERENCES "public"."settings_assemblies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD CONSTRAINT "settings_branches_assembly_id_settings_assemblies_id_fk" FOREIGN KEY ("assembly_id") REFERENCES "public"."settings_assemblies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "settings_branches" ADD CONSTRAINT "settings_branches_payment_stub_assembly_id_settings_assemblies_id_fk" FOREIGN KEY ("payment_stub_assembly_id") REFERENCES "public"."settings_assemblies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "warehouses" ADD CONSTRAINT "warehouses_district_id_settings_districts_id_fk" FOREIGN KEY ("district_id") REFERENCES "public"."settings_districts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "warehouses" ADD CONSTRAINT "warehouses_local_body_id_settings_local_bodies_id_fk" FOREIGN KEY ("local_body_id") REFERENCES "public"."settings_local_bodies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "warehouses" ADD CONSTRAINT "warehouses_ward_id_settings_wards_id_fk" FOREIGN KEY ("ward_id") REFERENCES "public"."settings_wards"("id") ON DELETE no action ON UPDATE no action;