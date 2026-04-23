import { ArrayMinSize, IsArray, IsIn, IsNotEmpty, IsString } from "class-validator";

export class BulkZoneActionDto {
  @IsString()
  @IsNotEmpty()
  org_id!: string;

  @IsString()
  @IsNotEmpty()
  branch_id!: string;

  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  zone_ids!: string[];

  @IsString()
  @IsIn(["mark_active", "mark_inactive"])
  action!: "mark_active" | "mark_inactive";
}
