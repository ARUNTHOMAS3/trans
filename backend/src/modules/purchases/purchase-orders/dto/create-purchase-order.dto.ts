import {
  IsString,
  IsNumber,
  IsDateString,
  IsOptional,
  IsUUID,
  ValidateNested,
  ArrayMinSize,
} from "class-validator";
import { Type } from "class-transformer";

class PurchaseOrderItemDto {
  @IsUUID()
  @IsOptional()
  item_id?: string;

  @IsString()
  item_name: string;

  @IsNumber()
  quantity: number;

  @IsNumber()
  rate: number;

  @IsNumber()
  @IsOptional()
  discount_percent?: number;

  @IsNumber()
  amount: number;
}

export class CreatePurchaseOrderDto {
  @IsUUID()
  vendor_id: string;

  @IsString()
  order_number: string;

  @IsDateString()
  @IsOptional()
  order_date?: string;

  @IsDateString()
  @IsOptional()
  expected_delivery_date?: string;

  @IsString()
  @IsOptional()
  reference_number?: string;

  @IsString()
  @IsOptional()
  terms?: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @ValidateNested({ each: true })
  @Type(() => PurchaseOrderItemDto)
  @ArrayMinSize(1)
  items: PurchaseOrderItemDto[];

  @IsNumber()
  subtotal: number;

  @IsNumber()
  @IsOptional()
  tax_amount?: number;

  @IsNumber()
  total_amount: number;

  @IsString()
  @IsOptional()
  status?: string = "draft";
}
