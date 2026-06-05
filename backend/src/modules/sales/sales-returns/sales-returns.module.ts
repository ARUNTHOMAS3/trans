import { Module } from '@nestjs/common';
import { SupabaseModule } from '../../supabase/supabase.module';
import { SalesReturnsController } from './controllers/sales-returns.controller';
import { SalesReturnsService } from './services/sales-returns.service';

@Module({
  imports: [SupabaseModule],
  controllers: [SalesReturnsController],
  providers: [SalesReturnsService],
  exports: [SalesReturnsService],
})
export class SalesReturnsModule {}
