import { Type } from "class-transformer";
import {
  IsBoolean,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
} from "class-validator";
import {
  EXPENSE_MODES,
  EXPENSE_STATUSES,
} from "../constants/expense.constants";

const EXPENSE_FAVORITE_FILTERS = [
  "all",
  "unbilled",
  "invoiced",
  "reimbursed",
  "billable",
  "non_billable",
  "with_receipts",
  "without_receipts",
] as const;

const EXPENSE_SORT_FIELDS = [
  "date",
  "expenseAccount",
  "reference",
  "vendorName",
  "customerName",
  "amount",
  "status",
] as const;

const SORT_DIRECTIONS = ["asc", "desc"] as const;

export class ListExpensesQueryDto {
  @IsOptional()
  @Type(() => Number)
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @Min(1)
  @Max(200)
  limit?: number = 100;

  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsIn(EXPENSE_STATUSES)
  status?: string;

  @IsOptional()
  @IsIn(EXPENSE_MODES)
  expense_mode?: string;

  @IsOptional()
  @IsUUID()
  vendor_id?: string;

  @IsOptional()
  @IsUUID()
  customer_id?: string;

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  is_itemized?: boolean;

  @IsOptional()
  @IsIn(EXPENSE_FAVORITE_FILTERS)
  favorite_filter?: string;

  @IsOptional()
  @IsIn(EXPENSE_SORT_FIELDS)
  sort_by?: string;

  @IsOptional()
  @IsIn(SORT_DIRECTIONS)
  sort_direction?: "asc" | "desc";
}
