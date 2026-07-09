import { Type } from "class-transformer";
import {
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
} from "class-validator";

const SORT_DIRECTIONS = ["asc", "desc"] as const;

export class ListRecurringExpensesQueryDto {
  @IsOptional()
  @Type(() => Number)
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @Min(1)
  @Max(200)
  limit?: number = 100;

  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsString()
  profile_name?: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsUUID()
  vendor_id?: string;

  @IsOptional()
  @IsUUID()
  vendorId?: string;

  @IsOptional()
  @IsUUID()
  customer_id?: string;

  @IsOptional()
  @IsUUID()
  expense_account_id?: string;

  @IsOptional()
  @IsUUID()
  tax_id?: string;

  @IsOptional()
  @IsString()
  gst_treatment?: string;

  @IsOptional()
  @IsString()
  source_of_supply?: string;

  @IsOptional()
  @IsString()
  destination_of_supply?: string;

  @IsOptional()
  @IsString()
  start_date_from?: string;

  @IsOptional()
  @IsString()
  start_date_to?: string;

  @IsOptional()
  @IsString()
  end_date_from?: string;

  @IsOptional()
  @IsString()
  end_date_to?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  amount_from?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  amount_to?: number;

  @IsOptional()
  @IsString()
  sort_field?: string;

  @IsOptional()
  @IsIn(SORT_DIRECTIONS)
  sort_direction?: (typeof SORT_DIRECTIONS)[number];
}
