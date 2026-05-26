import { Module } from "@nestjs/common";
import { VendorsController } from "./controllers/vendors.controller";
import { VendorsService } from "./services/vendors.service";
import { SupabaseModule } from "../../supabase/supabase.module";

@Module({
  imports: [SupabaseModule],
  controllers: [VendorsController],
  providers: [VendorsService],
  exports: [VendorsService],
})
export class VendorsModule {}
