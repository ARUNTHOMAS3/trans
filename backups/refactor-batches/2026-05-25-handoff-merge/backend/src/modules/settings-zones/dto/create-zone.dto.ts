import {
  ArrayMinSize,
  IsArray,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from "class-validator";
import { Type } from "class-transformer";

class CreateZoneLevelDto {
  @IsInt()
  @Min(1)
  level!: number;

  @IsString()
  @IsNotEmpty()
  location!: string;

  @IsOptional()
  @IsString()
  delimiter?: string;

  @IsString()
  @IsNotEmpty()
  alias_name!: string;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  total!: number;
}

export class CreateZoneDto {
  @IsString()
  @IsNotEmpty()
  org_id!: string;

  @IsString()
  @IsNotEmpty()
  branch_id!: string;

  @IsOptional()
  @IsString()
  branch_name?: string;

  @IsString()
  @IsNotEmpty()
  zone_name!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateZoneLevelDto)
  levels!: CreateZoneLevelDto[];
}

export type ZoneLevelInput = CreateZoneLevelDto;
