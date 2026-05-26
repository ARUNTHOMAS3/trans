import {
  ArrayNotEmpty,
  IsArray,
  IsObject,
  IsUUID,
} from "class-validator";
import { UpdateCustomerDto } from "./update-customer.dto";

export class BulkUpdateCustomersDto {
  @IsArray()
  @ArrayNotEmpty()
  @IsUUID("4", { each: true })
  customerIds: string[];

  @IsObject()
  updateData: UpdateCustomerDto;
}

