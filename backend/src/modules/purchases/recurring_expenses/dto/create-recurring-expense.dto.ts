import {
  IsString,
  IsNumber,
  IsDateString,
  IsOptional,
  IsUUID,
  IsBoolean,
} from "class-validator";

export class CreateRecurringExpenseDto {
  @IsString()
  profile_name: string;

  @IsUUID()
  @IsOptional()
  entity_id?: string;

  @IsNumber()
  @IsOptional()
  repeat_every?: number = 1;

  @IsString()
  repeat_type: string;

  @IsDateString()
  start_date: string;

  @IsDateString()
  @IsOptional()
  end_date?: string;

  @IsBoolean()
  never_expires: boolean;

  @IsDateString()
  @IsOptional()
  next_run_date?: string;

  @IsDateString()
  @IsOptional()
  last_run_date?: string;

  @IsString()
  @IsOptional()
  status?: string = "ACTIVE";

  @IsUUID()
  expense_account_id: string;

  @IsNumber()
  amount: number;

  @IsString()
  @IsOptional()
  currency_code?: string = "INR";

  @IsUUID()
  paid_through_account_id: string;

  @IsString()
  expense_type: string;

  @IsString()
  @IsOptional()
  hsn_sac_code?: string;

  @IsUUID()
  @IsOptional()
  vendor_id?: string;

  @IsString()
  @IsOptional()
  gst_treatment?: string;

  @IsString()
  @IsOptional()
  source_of_supply?: string;

  @IsString()
  @IsOptional()
  destination_of_supply?: string;

  @IsBoolean()
  @IsOptional()
  reverse_charge?: boolean = false;

  @IsUUID()
  @IsOptional()
  tax_id?: string;

  @IsString()
  @IsOptional()
  amount_tax_mode?: string = "EXCLUSIVE";

  @IsString()
  @IsOptional()
  invoice_number?: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsUUID()
  @IsOptional()
  customer_id?: string;

  @IsBoolean()
  @IsOptional()
  is_billable?: boolean = false;

  @IsBoolean()
  @IsOptional()
  auto_create?: boolean = true;
}
