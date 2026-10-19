import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { SubmitReviewDto } from './dto/submit-review.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Get('feed')
  async getSwipeFeed(
    @CurrentUser('userId') userId: string,
    @Query('limit') limit?: number,
  ) {
    return this.reviewsService.getSwipeFeed(userId, limit ? Number(limit) : 10);
  }

  @Post()
  async submitReview(
    @CurrentUser('userId') userId: string,
    @Body() dto: SubmitReviewDto,
  ) {
    return this.reviewsService.submitReview(userId, dto);
  }

  @Get('quota')
  async getQuotaStatus(@CurrentUser('userId') userId: string) {
    return this.reviewsService.getQuotaStatus(userId);
  }
}
