import {
  IsString,
  IsNumber,
  IsDateString,
  IsOptional,
  IsUUID,
  ValidateNested,
  ArrayMinSize,
  IsBoolean,
} from "class-validator";
import { Type } from "class-transformer";

class PurchaseOrderItemDto {
  @IsString()
  @IsOptional()
  product_id?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  account_id?: string;

  @IsString()
  @IsOptional()
  accounts?: string;

  @IsNumber()
  @IsOptional()
  quantity?: number;

  @IsNumber()
  @IsOptional()
  rate?: number;

  @IsString()
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
  @IsOptional()
  amount?: number;

  @IsOptional()
  hsn_code?: string | number;

  @IsString()
  @IsOptional()
  pricelist?: string;

  @IsString()
  @IsOptional()
  warehouse_id?: string;

  @IsString()
  @IsOptional()
  warehouse_name?: string;

  @IsBoolean()
  @IsOptional()
  is_header?: boolean;

  @IsString()
  @IsOptional()
  header_text?: string;

  @IsString()
  @IsOptional()
  id?: string;

  @IsNumber()
  @IsOptional()
  cancelled_quantity?: number;

  @IsNumber()
  @IsOptional()
  sort_order?: number;

  @IsBoolean()
  @IsOptional()
  track_batches?: boolean;

  @IsBoolean()
  @IsOptional()
  track_serial_number?: boolean;

  @IsBoolean()
  @IsOptional()
  track_bin_location?: boolean;
}

export class CreatePurchaseOrderDto {
  @IsString()
  @IsOptional()
  org_id?: string;

  @IsString()
  @IsOptional()
  branch_id?: string;

  @IsString()
  @IsOptional()
  warehouse_name?: string;

  @IsString()
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
  payment_terms_id?: string;

  @IsString()
  @IsOptional()
  shipment_preference_id?: string;

  @IsString()
  @IsOptional()
  delivery_type?: string;

  @IsString()
  @IsOptional()
  delivery_warehouse_id?: string;

  @IsString()
  @IsOptional()
  delivery_customer_id?: string;

  @IsString()
  @IsOptional()
  warehouse_id?: string;

  @IsString()
  @IsOptional()
  discount_level?: string;

  @IsString()
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

  @IsString()
  @IsOptional()
  tds_id?: string;

  @IsString()
  @IsOptional()
  tds_tcs_id?: string;

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

  @IsString()
  @IsOptional()
  source_of_supply?: string;

  @IsString()
  @IsOptional()
  destination_to_supply?: string;

  @IsString()
  @IsOptional()
  shipping_address?: string;

  @IsString()
  @IsOptional()
  billing_address?: string;

  @ValidateNested({ each: true })
  @Type(() => PurchaseOrderItemDto)
  @ArrayMinSize(1)
  items: PurchaseOrderItemDto[];
}
