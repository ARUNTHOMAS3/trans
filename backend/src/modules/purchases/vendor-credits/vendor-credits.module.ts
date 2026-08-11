import { Module } from '@nestjs/common';
import { VendorCreditsController } from './controllers/vendor-credits.controller';
import { VendorCreditsService } from './services/vendor-credits.service';
import { SupabaseModule } from '../../supabase/supabase.module';

@Module({
  imports: [SupabaseModule],
  controllers: [VendorCreditsController],
  providers: [VendorCreditsService],
  exports: [VendorCreditsService],
})
export class VendorCreditsModule {}
