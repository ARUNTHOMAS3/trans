import { Module } from '@nestjs/common';
import { TransactionSeriesController } from './transaction-series.controller';
import { TransactionSeriesService } from './transaction-series.service';
import { SupabaseModule } from '../supabase/supabase.module';

@Module({
  imports: [SupabaseModule],
  controllers: [TransactionSeriesController],
  providers: [TransactionSeriesService],
  exports: [TransactionSeriesService],
})
export class TransactionSeriesModule {}
