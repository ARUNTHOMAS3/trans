import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  ValidateNested,
} from "class-validator";
import { Type } from "class-transformer";

export class CreateSalesReturnItemDto {
  @IsUUID()
  product_id!: string;

  @IsOptional()
  @IsUUID()
  sales_invoice_item_id?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  invoiced_qty?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  already_returned_qty?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  return_qty?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  receivable_qty?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  credit_only_qty?: number;

  @IsOptional()
  @IsString()
  remarks?: string;
}

export class CreateSalesReturnDto {
  @IsUUID()
  customer_id!: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  rma_number?: string;

  @IsDateString()
  return_date!: string;

  @IsUUID()
  warehouse_id!: string;

  @IsOptional()
  @IsString()
  reason?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  reference_number?: string;

  @IsOptional()
  @IsBoolean()
  contains_credit_only_goods?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  status?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateSalesReturnItemDto)
  items!: CreateSalesReturnItemDto[];
}
