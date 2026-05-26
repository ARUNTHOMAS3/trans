import { IsString, MaxLength } from "class-validator";

export class UpdateSalesReturnStatusDto {
  @IsString()
  @MaxLength(30)
  status!: string;
}

