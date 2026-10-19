import { IsInt, IsNotEmpty, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateGoalDto {
  @IsString()
  @IsNotEmpty({ message: 'Target goal title is required' })
  title: string;

  @IsString()
  @IsNotEmpty({ message: 'Goal category is required' })
  category: string;

  @IsString()
  @IsNotEmpty({ message: 'Current skill level is required' })
  currentSkillLevel: string;

  @IsInt({ message: 'Duration must be an integer number of days' })
  @Min(1, { message: 'Duration must be at least 1 day' })
  @Max(60, { message: 'Duration cannot exceed 60 days' })
  @IsOptional()
  durationDays?: number = 30;
}
