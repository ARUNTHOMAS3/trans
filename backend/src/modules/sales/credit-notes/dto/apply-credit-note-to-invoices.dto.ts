import { Type } from "class-transformer";
import {
  ArrayNotEmpty,
  IsArray,
  IsDateString,
  IsNumber,
  IsOptional,
  IsUUID,
  Min,
  ValidateNested,
} from "class-validator";

export class CreditNoteInvoiceAllocationDto {
  @IsUUID()
  invoiceId!: string;

  @IsNumber()
  @Min(0.01)
  amount!: number;
}

export class ApplyCreditNoteToInvoicesDto {
  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => CreditNoteInvoiceAllocationDto)
  allocations!: CreditNoteInvoiceAllocationDto[];

  @IsOptional()
  @IsDateString()
  appliedOn?: string;
}
