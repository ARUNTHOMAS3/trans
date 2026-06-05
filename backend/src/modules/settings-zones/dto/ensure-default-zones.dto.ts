import { IsNotEmpty, IsOptional, IsString } from "class-validator";

export class EnsureDefaultZonesDto {
  @IsString()
  @IsNotEmpty()
  org_id!: string;

  @IsString()
  @IsNotEmpty()
  branch_id!: string;

  @IsOptional()
  @IsString()
  branch_name?: string;
}
