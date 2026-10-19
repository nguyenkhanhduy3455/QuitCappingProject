import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { GoalsService } from './goals.service';
import { CreateGoalDto } from './dto/create-goal.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('goals')
export class GoalsController {
  constructor(private readonly goalsService: GoalsService) {}

  @Post()
  async createGoal(
    @CurrentUser('userId') userId: string,
    @Body() createGoalDto: CreateGoalDto,
  ) {
    return this.goalsService.createGoal(userId, createGoalDto);
  }

  @Get('active')
  async getActiveGoal(@CurrentUser('userId') userId: string) {
    return this.goalsService.getActiveGoal(userId);
  }

  @Get(':id/roadmap')
  async getGoalRoadmap(
    @Param('id') goalId: string,
    @CurrentUser('userId') userId: string,
  ) {
    return this.goalsService.getGoalRoadmap(goalId, userId);
  }

  @Get()
  async listGoals(@CurrentUser('userId') userId: string) {
    return this.goalsService.listUserGoals(userId);
  }
}
