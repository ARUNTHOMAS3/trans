import { Type } from "class-transformer";
import { IsString, IsOptional, IsNumber, IsBoolean, IsArray, ValidateNested, IsDateString } from "class-validator";

export class CreateBillItemBatchDto {
  @IsString()
  batchId: string;
  
  @IsOptional()
  @IsString()
  layerId?: string;

  @IsOptional()
  @IsString()
  warehouseId?: string;

  @IsOptional()
  @IsString()
  binId?: string;

  @IsNumber()
  quantity: number;

  @IsOptional()
  @IsNumber()
  focQuantity?: number;

  @IsOptional()
  @IsNumber()
  damageQuantity?: number;

  @IsOptional()
  @IsNumber()
  purchaseRate?: number;

  @IsOptional()
  @IsNumber()
  mrp?: number;

  @IsOptional()
  @IsDateString()
  expiryDate?: string;

  @IsOptional()
  @IsDateString()
  manufactureDate?: string;

  @IsOptional()
  @IsString()
  manufactureBatchNo?: string;

  @IsOptional()
  @IsBoolean()
  isDirectBill?: boolean;
}

export class CreateBillItemDto {
  @IsString()
  productId: string;

  @IsOptional()
  @IsString()
  purchaseReceiveItemId?: string;

  @IsOptional()
  @IsString()
  accountId?: string;

  @IsOptional()
  @IsString()
  customerId?: string;

  @IsOptional()
  @IsString()
  hsnCode?: string;

  @IsOptional()
  @IsString()
  hsn_code?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsNumber()
  quantity: number;

  @IsNumber()
  rate: number;

  @IsOptional()
  @IsString()
  discountType?: string;

  @IsOptional()
  @IsNumber()
  discountValue?: number;

  @IsOptional()
  @IsNumber()
  discountAmount?: number;

  @IsOptional()
  @IsString()
  taxId?: string;

  @IsOptional()
  @IsNumber()
  taxPercentage?: number;

  @IsOptional()
  @IsNumber()
  taxAmount?: number;

  @IsOptional()
  @IsNumber()
  lineTotal?: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateBillItemBatchDto)
  batches?: CreateBillItemBatchDto[];
}

export class CreateBillDto {
  @IsString()
  vendorId: string;

  @IsString()
  billNumber: string;

  @IsOptional()
  @IsString()
  orderNumber?: string;

  @IsDateString()
  billDate: string;

  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @IsOptional()
  @IsString()
  paymentTermId?: string;

  @IsOptional()
  @IsBoolean()
  reverseChargeApplicable?: boolean;

  @IsOptional()
  @IsString()
  warehouseId?: string;

  @IsOptional()
  @IsString()
  priceListId?: string;

  @IsOptional()
  @IsString()
  landedCostAllocationType?: string;

  @IsOptional()
  @IsString()
  subject?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsNumber()
  subtotal?: number;

  @IsOptional()
  @IsNumber()
  discountTotal?: number;

  @IsOptional()
  @IsNumber()
  taxTotal?: number;

  @IsOptional()
  @IsNumber()
  shippingCharges?: number;

  @IsOptional()
  @IsNumber()
  tdsTotal?: number;

  @IsOptional()
  @IsNumber()
  tcsTotal?: number;

  @IsOptional()
  @IsNumber()
  adjustmentAmount?: number;

  @IsOptional()
  @IsNumber()
  roundOff?: number;

  @IsOptional()
  @IsNumber()
  grandTotal?: number;

  @IsOptional()
  @IsString()
  sourceType?: string;

  @IsOptional()
  @IsString()
  sourceId?: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  sourceOfSupply?: string;

  @IsOptional()
  @IsString()
  destinationToSupply?: string;

  @IsOptional()
  @IsString()
  billingAddress?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateBillItemDto)
  items: CreateBillItemDto[];
}
