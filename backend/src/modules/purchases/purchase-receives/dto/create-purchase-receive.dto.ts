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

class PurchaseReceiveBatchDto {
  @IsString()
  batch_no!: string;

  @IsString()
  @IsOptional()
  unit_pack?: string;

  @IsNumber()
  @IsOptional()
  mrp?: number;

  @IsNumber()
  @IsOptional()
  ptr?: number;

  @IsNumber()
  quantity!: number;

  @IsNumber()
  @IsOptional()
  foc?: number;

  @IsString()
  @IsOptional()
  manufacture_batch?: string;

  @IsDateString()
  @IsOptional()
  manufacture_date?: string;

  @IsDateString()
  @IsOptional()
  expiry_date?: string;

  @IsUUID()
  @IsOptional()
  warehouse_id?: string;

  @IsUUID()
  @IsOptional()
  bin_id?: string;

  @IsString()
  @IsOptional()
  bin_label?: string;

  @IsBoolean()
  @IsOptional()
  is_damaged?: boolean;

  @IsNumber()
  @IsOptional()
  damaged_qty?: number;
}

class PurchaseReceiveItemDto {
  @IsUUID()
  @IsOptional()
  item_id?: string;

  @IsString()
  item_name: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsNumber()
  ordered: number;

  @IsNumber()
  received: number;

  @IsNumber()
  in_transit: number;

  @IsNumber()
  quantity_to_receive: number;

  @IsUUID()
  @IsOptional()
  warehouse_id?: string;

  @IsUUID()
  @IsOptional()
  bin_id?: string;

  @IsString()
  @IsOptional()
  bin_label?: string;

  @ValidateNested({ each: true })
  @Type(() => PurchaseReceiveBatchDto)
  @IsOptional()
  batches?: PurchaseReceiveBatchDto[];
}

export class CreatePurchaseReceiveDto {
  @IsString()
  @IsOptional()
  vendor_name?: string;

  @IsString()
  purchase_receive_number: string;

  @IsDateString()
  received_date: string;

  @IsUUID()
  @IsOptional()
  purchase_order_id?: string;

  @IsString()
  @IsOptional()
  purchase_order_number?: string;

  @IsUUID()
  @IsOptional()
  warehouse_id?: string;

  @IsUUID()
  @IsOptional()
  transaction_bin_id?: string;

  @IsString()
  @IsOptional()
  transaction_bin_label?: string;

  @IsString()
  @IsOptional()
  status?: string = "draft";

  @IsString()
  @IsOptional()
  notes?: string;

  @ValidateNested({ each: true })
  @Type(() => PurchaseReceiveItemDto)
  @ArrayMinSize(1)
  items: PurchaseReceiveItemDto[];
}
