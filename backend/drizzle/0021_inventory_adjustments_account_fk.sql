ALTER TABLE "inventory_adjustments"
ADD CONSTRAINT "inventory_adjustments_account_id_fkey"
FOREIGN KEY ("account_id")
REFERENCES "public"."accounts"("id")
ON DELETE SET NULL
ON UPDATE NO ACTION;

