import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateSubmissionDto {
  @IsString()
  @IsNotEmpty({ message: 'taskId is required' })
  taskId: string;

  @IsOptional()
  @IsString()
  imageUrl?: string;
}
