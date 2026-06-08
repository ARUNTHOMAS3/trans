import { Type } from "class-transformer";
import {
  IsArray,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from "class-validator";

export class CreateCreditNoteItemDto {
  @IsString()
  productId!: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsNumber()
  @Min(0)
  quantity!: number;

  @IsNumber()
  @Min(0)
  rate!: number;

  @IsOptional()
  @IsIn(["PERCENTAGE", "FIXED"])
  discountType?: "PERCENTAGE" | "FIXED";

  @IsOptional()
  @IsNumber()
  discountValue?: number;

  @IsOptional()
  @IsNumber()
  discountAmount?: number;

  @IsOptional()
  @IsNumber()
  taxableAmount?: number;

  @IsOptional()
  @IsNumber()
  taxPercentage?: number;

  @IsOptional()
  @IsNumber()
  taxAmount?: number;

  @IsNumber()
  @Min(0)
  lineTotal!: number;
}

export class CreateCreditNoteDto {
  @IsString()
  customerId!: string;

  @IsString()
  creditNoteNumber!: string;

  @IsOptional()
  @IsString()
  referenceNumber?: string;

  @IsOptional()
  @IsString()
  creditNoteDate?: string;

  @IsIn(["DRAFT", "APPROVED"])
  status!: "DRAFT" | "APPROVED";

  @IsNumber()
  grandTotal!: number;

  @IsOptional()
  @IsNumber()
  subTotal?: number;

  @IsOptional()
  @IsNumber()
  taxTotal?: number;

  @IsOptional()
  @IsNumber()
  shippingAmount?: number;

  @IsOptional()
  @IsNumber()
  adjustmentAmount?: number;

  @IsOptional()
  @IsString()
  customerNotes?: string;

  @IsOptional()
  @IsString()
  termsAndConditions?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateCreditNoteItemDto)
  items!: CreateCreditNoteItemDto[];
}
