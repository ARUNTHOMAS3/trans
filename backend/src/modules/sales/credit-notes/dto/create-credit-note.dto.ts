import { Type } from "class-transformer";
import {
  IsArray,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from "class-validator";

export class CreateCreditNoteItemDto {
  @IsOptional()
  @IsString()
  accountId?: string;

  @IsString()
  productId!: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsNumber()
  @Min(0)
  quantity!: number;

  @IsNumber()
  @Min(0)
  rate!: number;

  @IsOptional()
  @IsIn(["PERCENTAGE", "FIXED"])
  discountType?: "PERCENTAGE" | "FIXED";

  @IsOptional()
  @IsNumber()
  discountValue?: number;

  @IsOptional()
  @IsNumber()
  discountAmount?: number;

  @IsOptional()
  @IsNumber()
  taxableAmount?: number;

  @IsOptional()
  @IsNumber()
  taxPercentage?: number;

  @IsOptional()
  @IsNumber()
  taxAmount?: number;

  @IsNumber()
  @Min(0)
  lineTotal!: number;

  /// Batch this line credits. Supplied when the credit note is raised from a
  /// sales return; otherwise the batches are resolved from that return's
  /// receive. `batch_transactions.batch_id` is NOT NULL, so a line with no
  /// batch cannot post to the accounting ledger.
  @IsOptional()
  @IsString()
  batchId?: string;
}

export class CreateCreditNoteDto {
  @IsString()
  customerId!: string;

  @IsString()
  creditNoteNumber!: string;

  @IsOptional()
  @IsString()
  referenceNumber?: string;

  @IsOptional()
  @IsString()
  creditNoteDate?: string;

  @IsIn(["DRAFT", "OPEN", "APPROVED"])
  status!: "DRAFT" | "OPEN" | "APPROVED";

  @IsOptional()
  @IsString()
  salespersonId?: string;

  @IsNumber()
  grandTotal!: number;

  @IsOptional()
  @IsNumber()
  subTotal?: number;

  @IsOptional()
  @IsNumber()
  taxTotal?: number;

  @IsOptional()
  @IsNumber()
  shippingAmount?: number;

  @IsOptional()
  @IsNumber()
  adjustmentAmount?: number;

  /** TDS withheld on the note, from the selected `tax_groups` rate. */
  @IsOptional()
  @IsNumber()
  tdsTotal?: number;

  /** TCS collected on the note, from the selected `tax_groups` rate. */
  @IsOptional()
  @IsNumber()
  tcsTotal?: number;

  @IsOptional()
  @IsString()
  customerNotes?: string;

  @IsOptional()
  @IsString()
  termsAndConditions?: string;

  /// Warehouse the credited goods sit in. Required to post the accounting
  /// ledger (`batch_transactions.warehouse_id` is NOT NULL); falls back to the
  /// source sales return's receive when omitted.
  @IsOptional()
  @IsString()
  warehouseId?: string;

  /// RMA# of the sales return this credit note settles.
  ///
  /// Used to resolve which batches the credited quantities came from — a credit
  /// note carries no batch detail of its own, but the return's receive does.
  @IsOptional()
  @IsString()
  fromRmaNumber?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateCreditNoteItemDto)
  items!: CreateCreditNoteItemDto[];
}
