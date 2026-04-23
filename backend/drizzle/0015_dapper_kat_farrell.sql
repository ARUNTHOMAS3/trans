ALTER TABLE "customers" RENAME COLUMN "billing_address_street1" TO "billing_address_street";--> statement-breakpoint
ALTER TABLE "customers" RENAME COLUMN "billing_address_street2" TO "billing_address_place";--> statement-breakpoint
ALTER TABLE "customers" RENAME COLUMN "shipping_address_street1" TO "shipping_address_street";--> statement-breakpoint
ALTER TABLE "customers" RENAME COLUMN "shipping_address_street2" TO "shipping_address_place";--> statement-breakpoint
ALTER TABLE "organization" RENAME COLUMN "address_street_1" TO "street";--> statement-breakpoint
ALTER TABLE "organization" RENAME COLUMN "address_street_2" TO "place";--> statement-breakpoint
ALTER TABLE "branches" RENAME COLUMN "address_street_1" TO "street";--> statement-breakpoint
ALTER TABLE "branches" RENAME COLUMN "address_street_2" TO "place";--> statement-breakpoint
ALTER TABLE "vendors" RENAME COLUMN "billing_address_street_1" TO "billing_address_street";--> statement-breakpoint
ALTER TABLE "vendors" RENAME COLUMN "billing_address_street_2" TO "billing_address_place";--> statement-breakpoint
ALTER TABLE "vendors" RENAME COLUMN "shipping_address_street_1" TO "shipping_address_street";--> statement-breakpoint
ALTER TABLE "vendors" RENAME COLUMN "shipping_address_street_2" TO "shipping_address_place";--> statement-breakpoint
ALTER TABLE "warehouses" RENAME COLUMN "address_street_1" TO "street";--> statement-breakpoint
ALTER TABLE "warehouses" RENAME COLUMN "address_street_2" TO "place";--> statement-breakpoint
ALTER TABLE "organization" ADD COLUMN "additional_fields" jsonb;