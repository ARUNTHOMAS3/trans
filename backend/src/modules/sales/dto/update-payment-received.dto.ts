import { PartialType } from "@nestjs/mapped-types";
import { CreatePaymentReceivedDto } from "./create-payment-received.dto";
import { IsBoolean, IsOptional } from "class-validator";

export class UpdatePaymentReceivedDto extends PartialType(
  CreatePaymentReceivedDto,
) {
  @IsOptional()
  @IsBoolean()
  is_delete?: boolean;
}
