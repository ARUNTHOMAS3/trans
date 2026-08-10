import { Type } from "class-transformer";
import { IsIn, IsOptional, IsString, Max, Min } from "class-validator";

const SORT_DIRECTIONS = ["asc", "desc"] as const;

export class SalesReportQueryDto {
  @IsOptional()
  @IsString()
  startDate?: string;

  @IsOptional()
  @IsString()
  endDate?: string;

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
  @IsIn(SORT_DIRECTIONS)
  sortDirection?: "asc" | "desc";

  @IsOptional()
  @IsString()
  groupBy?: string;

  @IsOptional()
  @IsString()
  compareWith?: string;

  @IsOptional()
  @IsString()
  reportBy?: string;

  @IsOptional()
  @IsString()
  transactionType?: string;

  @IsOptional()
  @IsString()
  entities?: string;

  @IsOptional()
  @IsString()
  moreFilters?: string;

  @IsOptional()
  @IsString()
  exportFormat?: string;
}
