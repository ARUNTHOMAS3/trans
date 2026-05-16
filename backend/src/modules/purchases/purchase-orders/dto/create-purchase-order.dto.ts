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
  product_id?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsUUID()
  @IsOptional()
  account_id?: string;

  @IsNumber()
  quantity: number;

  @IsNumber()
  rate: number;

  @IsUUID()
  @IsOptional()
  tax_id?: string;

  @IsNumber()
  @IsOptional()
  item_tax_rate?: number;

  @IsNumber()
  @IsOptional()
  tax_amount?: number;

  @IsNumber()
  @IsOptional()
  discount?: number;

  @IsString()
  @IsOptional()
  discount_type?: string;

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

  @IsUUID()
  @IsOptional()
  payment_terms_id?: string;

  @IsUUID()
  @IsOptional()
  shipment_preference_id?: string;

  @IsString()
  @IsOptional()
  delivery_type?: string;

  @IsUUID()
  @IsOptional()
  delivery_warehouse_id?: string;

  @IsUUID()
  @IsOptional()
  delivery_customer_id?: string;

  @IsUUID()
  @IsOptional()
  warehouse_id?: string;

  @IsString()
  @IsOptional()
  discount_level?: string;

  @IsUUID()
  @IsOptional()
  discount_account_id?: string;

  @IsNumber()
  @IsOptional()
  discount?: number;

  @IsString()
  @IsOptional()
  discount_type?: string;

  @IsNumber()
  @IsOptional()
  total_quantity?: number;

  @IsString()
  @IsOptional()
  currency?: string;

  @IsNumber()
  @IsOptional()
  subtotal?: number;

  @IsNumber()
  @IsOptional()
  tax_amount?: number;

  @IsString()
  @IsOptional()
  tax_type?: string;

  @IsString()
  @IsOptional()
  tds_tcs_type?: string;

  @IsUUID()
  @IsOptional()
  tds_id?: string;

  @IsNumber()
  @IsOptional()
  tds_tcs_amount?: number;

  @IsNumber()
  @IsOptional()
  adjustment?: number;

  @IsNumber()
  total: number;

  @IsString()
  @IsOptional()
  status?: string = "draft";

  @IsString()
  @IsOptional()
  notes?: string;

  @IsString()
  @IsOptional()
  terms_and_conditions?: string;

  @ValidateNested({ each: true })
  @Type(() => PurchaseOrderItemDto)
  @ArrayMinSize(1)
  items: PurchaseOrderItemDto[];
}
