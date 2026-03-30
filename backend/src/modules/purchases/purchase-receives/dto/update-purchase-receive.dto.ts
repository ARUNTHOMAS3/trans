import { PartialType } from "@nestjs/mapped-types";
import { CreatePurchaseReceiveDto } from "./create-purchase-receive.dto";

export class UpdatePurchaseReceiveDto extends PartialType(
  CreatePurchaseReceiveDto,
) {}
