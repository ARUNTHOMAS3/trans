import { IsNotEmpty, IsString } from "class-validator";

export class DisableBinLocationsDto {
  @IsString()
  @IsNotEmpty()
  org_id!: string;

  @IsString()
  @IsNotEmpty()
  branch_id!: string;
}
