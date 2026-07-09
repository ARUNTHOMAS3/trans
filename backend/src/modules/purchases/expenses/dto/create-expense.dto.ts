import { Transform, Type } from "class-transformer";
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from "class-validator";
import {
  AMOUNT_TAX_MODES,
  EXPENSE_MODES,
  EXPENSE_STATUSES,
  EXPENSE_TYPES,
  MILEAGE_CALCULATION_METHODS,
  MILEAGE_UNITS,
} from "../constants/expense.constants";

export class CreateExpenseItemDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  line_no?: number;

  @IsOptional()
  @IsUUID()
  expense_account_id?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsUUID()
  tax_id?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  tax_amount?: number;

  @Type(() => Number)
  @IsNumber()
  @Min(0)
  amount: number;
}

export class CreateExpenseAttachmentDto {
  @IsString()
  file_name: string;

  @IsOptional()
  @IsString()
  original_file_name?: string;

  @IsString()
  file_url: string;

  @IsOptional()
  @IsString()
  file_type?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  file_size?: number;

  @IsOptional()
  @IsString()
  remarks?: string;
}

export class CreateExpenseMileageDto {
  @IsOptional()
  @IsUUID()
  employee_id?: string;

  @IsIn(MILEAGE_CALCULATION_METHODS)
  calculation_type: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0)
  distance: number;

  @IsIn(MILEAGE_UNITS)
  distance_unit: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  rate_per_km?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  odometer_start?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  odometer_end?: number;
}

export class CreateExpenseDto {
  @IsOptional()
  @IsString()
  expense_number?: string;

  @IsDateString()
  expense_date: string;

  @IsIn(EXPENSE_MODES)
  expense_mode: string;

  @IsOptional()
  @IsIn(EXPENSE_STATUSES)
  status?: string;

  @IsOptional()
  @IsBoolean()
  is_itemized?: boolean;

  @IsOptional()
  @IsUUID()
  expense_account_id?: string;

  @IsUUID()
  paid_through_account_id: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0)
  amount: number;

  @IsOptional()
  @IsString()
  currency_code?: string;

  @IsIn(EXPENSE_TYPES)
  expense_type: string;

  @IsOptional()
  @IsString()
  hsn_sac_code?: string;

  @IsOptional()
  @IsUUID()
  vendor_id?: string;

  @IsOptional()
  @IsUUID()
  customer_id?: string;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === null || value === undefined || value === "") {
      return null;
    }
    return Number(value);
  })
  @IsNumber()
  @Min(0)
  mark_up_by?: number | null;

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
  @IsBoolean()
  reverse_charge?: boolean;

  @IsOptional()
  @IsUUID()
  tax_id?: string;

  @IsOptional()
  @IsIn(AMOUNT_TAX_MODES)
  amount_tax_mode?: string;

  @IsOptional()
  @IsString()
  invoice_number?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsBoolean()
  is_billable?: boolean;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  subtotal?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  tax_amount?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  total_amount?: number;

  @IsOptional()
  @IsUUID()
  recurring_expense_id?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateExpenseItemDto)
  items?: CreateExpenseItemDto[];

  @IsOptional()
  @ValidateNested()
  @Type(() => CreateExpenseMileageDto)
  mileage?: CreateExpenseMileageDto;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => CreateExpenseAttachmentDto)
  attachments?: CreateExpenseAttachmentDto[];
}
