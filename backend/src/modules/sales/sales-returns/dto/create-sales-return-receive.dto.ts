import {
  IsString,
  IsOptional,
  IsArray,
  ValidateNested,
  IsNumber,
  IsUUID,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

class CreateReceiveItemDto {
  @IsUUID()
  product_id: string;

  @IsUUID()
  @IsOptional()
  sales_return_item_id?: string;

  @IsNumber()
  @Min(0)
  receiving_qty: number;

  @IsNumber()
  @IsOptional()
  return_qty?: number;

  @IsNumber()
  @IsOptional()
  already_received_qty?: number;

  @IsString()
  @IsOptional()
  remarks?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateReceiveBatchDto)
  @IsOptional()
  batches?: CreateReceiveBatchDto[];
}

class CreateReceiveBatchDto {
  @IsUUID()
  batch_id: string;

  @IsUUID()
  @IsOptional()
  layer_id?: string;

  @IsUUID()
  @IsOptional()
  warehouse_id?: string;

  @IsUUID()
  bin_id: string;

  @IsNumber()
  @Min(0)
  quantity: number;

  @IsNumber()
  @IsOptional()
  @Min(0)
  foc_quantity?: number;

  @IsNumber()
  @IsOptional()
  @Min(0)
  purchase_rate?: number;

  @IsNumber()
  @IsOptional()
  @Min(0)
  mrp?: number;

  @IsString()
  @IsOptional()
  expiry_date?: string;

  @IsString()
  @IsOptional()
  manufacture_date?: string;

  @IsString()
  @IsOptional()
  manufacture_batch_no?: string;
}

export class CreateSalesReturnReceiveDto {
  @IsString()
  receive_date: string;

  @IsUUID()
  @IsOptional()
  warehouse_id?: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateReceiveItemDto)
  items: CreateReceiveItemDto[];
}
