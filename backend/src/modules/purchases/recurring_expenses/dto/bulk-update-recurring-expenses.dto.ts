import {
  ArrayNotEmpty,
  IsArray,
  IsBoolean,
  IsDateString,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  ValidateNested,
} from "class-validator";
import { Type } from "class-transformer";

export class BulkUpdateRecurringExpensesDataDto {
  @IsUUID()
  @IsOptional()
  expense_account_id?: string;

  @IsUUID()
  @IsOptional()
  paid_through_account_id?: string;

  @IsDateString()
  @IsOptional()
  end_date?: string;

  @IsNumber()
  @IsOptional()
  repeat_every?: number;

  @IsString()
  @IsOptional()
  repeat_type?: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsUUID()
  @IsOptional()
  vendor_id?: string;

  @IsUUID()
  @IsOptional()
  customer_id?: string;

  @IsString()
  @IsOptional()
  expense_type?: string;

  @IsBoolean()
  @IsOptional()
  is_billable?: boolean;
}

export class BulkUpdateRecurringExpensesDto {
  @IsArray()
  @ArrayNotEmpty()
  @IsUUID("4", { each: true })
  ids: string[];

  @ValidateNested()
  @Type(() => BulkUpdateRecurringExpensesDataDto)
  updateData: BulkUpdateRecurringExpensesDataDto;
}
