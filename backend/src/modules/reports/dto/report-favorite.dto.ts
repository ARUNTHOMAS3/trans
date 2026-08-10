import { IsString, MaxLength } from "class-validator";

export class ReportFavoriteDto {
  @IsString()
  @MaxLength(255)
  report!: string;
}
