import { Type } from "class-transformer";
import { IsOptional, IsString, Max, Min } from "class-validator";

export class InventoryReportQueryDto {
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
  warehouseId?: string;

  @IsOptional()
  @IsString()
  productId?: string;

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
  status?: string;

  @IsOptional()
  @IsString()
  hideEmptyBatches?: string;

  @IsOptional()
  @IsString()
  stockAvailability?: string;
  @IsOptional()
  @IsString()
  sortBy?: string;

  @IsOptional()
  @IsString()
  sortDirection?: string;

  @IsOptional()
  @Type(() => Number)
  @Min(1)
  @Max(12)
  intervalCount?: number = 6;

  @IsOptional()
  @Type(() => Number)
  @Min(1)
  @Max(365)
  intervalDays?: number = 3;
}
