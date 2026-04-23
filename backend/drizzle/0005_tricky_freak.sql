CREATE TABLE "settings_assemblies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"district_id" uuid NOT NULL,
	"name" varchar(150) NOT NULL,
	"code" varchar(50),
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
ALTER TABLE "settings_assemblies" ADD CONSTRAINT "settings_assemblies_district_id_settings_districts_id_fk" FOREIGN KEY ("district_id") REFERENCES "public"."settings_districts"("id") ON DELETE no action ON UPDATE no action;