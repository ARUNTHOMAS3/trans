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
