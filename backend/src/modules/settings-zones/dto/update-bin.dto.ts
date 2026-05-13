import { IsIn, IsNotEmpty, IsOptional, IsString } from "class-validator";

export class UpdateBinDto {
  @IsString()
  @IsNotEmpty()
  org_id!: string;

  @IsString()
  @IsNotEmpty()
  branch_id!: string;

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  @IsIn(["Active", "Inactive"])
  status?: "Active" | "Inactive";
}
