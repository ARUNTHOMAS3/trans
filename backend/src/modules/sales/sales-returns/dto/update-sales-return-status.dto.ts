import { Transform } from 'class-transformer';
import { IsIn, IsString } from 'class-validator';

/**
 * Statuses the sales return workflow actually writes. `sales_returns.status`
 * has no CHECK constraint, so the allow-list is enforced here.
 */
export const SALES_RETURN_STATUSES = [
  'draft',
  'approved',
  'declined',
  'received',
] as const;

export class UpdateSalesReturnStatusDto {
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsString()
  @IsIn(SALES_RETURN_STATUSES as unknown as string[])
  status!: string;
}
