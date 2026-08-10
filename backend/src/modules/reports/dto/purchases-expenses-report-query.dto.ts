import { Type } from "class-transformer";
import { IsOptional, IsString, Max, Min } from "class-validator";

export class PurchasesExpensesReportQueryDto {
  @IsOptional()
  @IsString()
  startDate?: string;

  @IsOptional()
  @IsString()
  endDate?: string;

  @IsOptional()
  @IsString()
  entityId?: string;

  @IsOptional()
  @IsString()
  vendorId?: string;

  @IsOptional()
  @IsString()
  warehouseId?: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  filterBy?: string;

  @IsOptional()
  @IsString()
  reportBy?: string;
  @IsOptional()
  @IsString()
  accountType?: string;

  @IsOptional()
  @IsString()
  categoryName?: string;

  @IsOptional()
  @IsString()
  customerName?: string;

  @IsOptional()
  @Type(() => Number)
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @Min(1)
  @Max(500)
  limit?: number = 100;

  @IsOptional()
  @Type(() => Number)
  @Min(1)
  @Max(500)
  pageSize?: number;

  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsString()
  sortBy?: string;

  @IsOptional()
  @IsString()
  sortDirection?: string;
}
