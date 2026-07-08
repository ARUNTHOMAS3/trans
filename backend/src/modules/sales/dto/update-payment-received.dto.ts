import { PartialType } from "@nestjs/mapped-types";
import { CreatePaymentReceivedDto } from "./create-payment-received.dto";

export class UpdatePaymentReceivedDto extends PartialType(
  CreatePaymentReceivedDto,
) {}
