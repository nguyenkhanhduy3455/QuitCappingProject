import { IsOptional, IsString } from 'class-validator';
import { Type } from 'class-transformer';

export class QueryTasksDto {
  @IsOptional()
  @IsString()
  goalId?: string;

  @IsOptional()
  @Type(() => Number)
  dayNumber?: number;
}
