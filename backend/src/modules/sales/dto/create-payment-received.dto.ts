import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  ValidateNested,
} from "class-validator";
import { Type } from "class-transformer";

export class CreatePaymentAllocationDto {
  @IsUUID()
  invoice_id!: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  invoice_amount?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  amount_due?: number;

  @Type(() => Number)
  @IsNumber()
  @Min(0)
  allocated_amount!: number;

  @IsDateString()
  payment_received_on!: string;

  @IsOptional()
  @IsString()
  remarks?: string;
}

export class PaymentAttachmentDto {
  /// Original file name as chosen by the user (e.g. "receipt.pdf").
  @IsString()
  @MaxLength(255)
  file_name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  file_type?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  file_size?: number;

  /// Base64-encoded file contents (no `data:` URI prefix). Decoded server-side
  /// and uploaded to Cloudflare R2; only the returned key is persisted.
  @IsString()
  data_base64!: string;

  @IsOptional()
  @IsString()
  remarks?: string;
}

export class CreatePaymentReceivedDto {
  @IsUUID()
  customer_id!: string;

  @IsString()
  @MaxLength(100)
  payment_number!: string;

  @IsOptional()
  @IsIn(["INVOICE_PAYMENT", "CUSTOMER_ADVANCE"])
  payment_type?: string;

  @IsDateString()
  payment_date!: string;

  @IsUUID()
  deposit_account_id!: string;

  @IsOptional()
  @IsUUID()
  location_id?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  place_of_supply?: string;

  @IsOptional()
  @IsString()
  description_of_supply?: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  payment_mode?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  reference_number?: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0)
  amount_received!: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  bank_charges?: number;

  @IsOptional()
  @IsBoolean()
  is_tds_deducted?: boolean;

  @IsOptional()
  @IsUUID()
  tds_tax_id?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  tds_amount?: number;

  @IsOptional()
  @IsUUID()
  tax_id?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  tax_amount?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  excess_amount?: number;

  @IsOptional()
  @IsIn(["draft", "paid"])
  status?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  /// Invoice allocations (saved to `payment_received_allocations`). Only sent for
  /// INVOICE_PAYMENT; each entry maps to one unpaid invoice the payment covers.
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreatePaymentAllocationDto)
  allocations?: CreatePaymentAllocationDto[];

  /// File attachments (saved to `payment_received_attachments`). Each carries the
  /// file bytes as base64; uploaded to R2 and linked to the created payment.
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PaymentAttachmentDto)
  attachments?: PaymentAttachmentDto[];
}
