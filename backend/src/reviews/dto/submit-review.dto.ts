import { IsBoolean, IsNotEmpty, IsString } from 'class-validator';

export class SubmitReviewDto {
  @IsString()
  @IsNotEmpty({ message: 'submissionId is required' })
  submissionId: string;

  @IsBoolean({ message: 'isApproved must be a boolean (true for swipe right, false for swipe left)' })
  isApproved: boolean;
}
