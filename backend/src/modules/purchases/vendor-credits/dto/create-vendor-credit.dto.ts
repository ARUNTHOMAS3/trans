import { IsString, IsNotEmpty, IsOptional, IsNumber, IsBoolean, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class VendorCreditBatchDto {
  @IsOptional()
  @IsString()
  binId?: string;

  @IsOptional()
  @IsString()
  batchId?: string;

  @IsOptional()
  @IsString()
  layerId?: string;

  @IsOptional()
  @IsString()
  batchNo?: string;

  @IsOptional()
  @IsNumber()
  quantity?: number;
}

export class VendorCreditItemDto {
  @IsOptional()
  @IsString()
  productId?: string;

  @IsOptional()
  @IsString()
  itemDescription?: string;

  @IsOptional()
  @IsNumber()
  quantity?: number;

  @IsOptional()
  @IsNumber()
  unitPrice?: number;

  @IsOptional()
  @IsNumber()
  discountAmount?: number;

  @IsOptional()
  @IsString()
  taxId?: string;

  @IsOptional()
  @IsNumber()
  taxAmount?: number;

  @IsOptional()
  @IsNumber()
  lineTotal?: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => VendorCreditBatchDto)
  batches?: VendorCreditBatchDto[];
}

export class CreateVendorCreditDto {
  @IsNotEmpty()
  @IsString()
  vendorId: string;

  @IsNotEmpty()
  @IsString()
  vendorCreditNumber: string;

  @IsNotEmpty()
  @IsString()
  vendorCreditDate: string;

  @IsOptional()
  @IsString()
  billId?: string;

  @IsOptional()
  @IsString()
  referenceNumber?: string;

  @IsOptional()
  @IsString()
  subject?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsBoolean()
  reverseChargeApplicable?: boolean;

  @IsOptional()
  @IsNumber()
  subtotal?: number;

  @IsOptional()
  @IsNumber()
  discountAmount?: number;

  @IsOptional()
  @IsNumber()
  taxAmount?: number;

  @IsOptional()
  @IsNumber()
  adjustmentAmount?: number;

  @IsOptional()
  @IsNumber()
  totalAmount?: number;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => VendorCreditItemDto)
  items?: VendorCreditItemDto[];
}
