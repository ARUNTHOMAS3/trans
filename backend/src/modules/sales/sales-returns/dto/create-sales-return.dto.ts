import {
  IsString,
  IsDateString,
  IsOptional,
  IsUUID,
  IsBoolean,
  ValidateNested,
  IsNumber,
  ArrayMinSize,
} from 'class-validator';
import { Type } from 'class-transformer';

class CreateSalesReturnItemDto {
  @IsUUID()
  product_id: string;

  @IsUUID()
  @IsOptional()
  sales_invoice_item_id?: string;

  @IsNumber()
  @IsOptional()
  invoiced_qty?: number;

  @IsNumber()
  @IsOptional()
  already_returned_qty?: number;

  @IsNumber()
  return_qty: number;

  @IsNumber()
  @IsOptional()
  receivable_qty?: number;

  @IsNumber()
  @IsOptional()
  credit_only_qty?: number;

  @IsString()
  @IsOptional()
  remarks?: string;
}

export class CreateSalesReturnDto {
  @IsUUID()
  customer_id: string;

  @IsString()
  rma_number: string;

  @IsDateString()
  return_date: string;

  @IsUUID()
  @IsOptional()
  warehouse_id?: string;

  @IsString()
  @IsOptional()
  reason?: string;

  @IsString()
  @IsOptional()
  reference_number?: string;

  @IsBoolean()
  @IsOptional()
  contains_credit_only_goods?: boolean;

  @IsString()
  @IsOptional()
  status?: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @ValidateNested({ each: true })
  @Type(() => CreateSalesReturnItemDto)
  @ArrayMinSize(1)
  items: CreateSalesReturnItemDto[];
}
