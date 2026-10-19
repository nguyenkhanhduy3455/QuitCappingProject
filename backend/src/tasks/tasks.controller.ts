import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { TasksService } from './tasks.service';
import { QueryTasksDto } from './dto/query-tasks.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('tasks')
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Get('daily')
  async getDailyTasks(
    @CurrentUser('userId') userId: string,
    @Query() query: QueryTasksDto,
  ) {
    return this.tasksService.getDailyTasks(userId, query);
  }

  @Get(':id')
  async getTaskById(
    @Param('id') taskId: string,
    @CurrentUser('userId') userId: string,
  ) {
    return this.tasksService.getTaskById(taskId, userId);
  }
}
