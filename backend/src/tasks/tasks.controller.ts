import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { TasksService } from './tasks.service';
import { QueryTasksDto } from './dto/query-tasks.dto';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
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

  @Post()
  async createTask(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateTaskDto,
  ) {
    return this.tasksService.createTask(userId, dto);
  }

  @Get(':id')
  async getTaskById(
    @Param('id') taskId: string,
    @CurrentUser('userId') userId: string,
  ) {
    return this.tasksService.getTaskById(taskId, userId);
  }

  @Patch(':id')
  async updateTask(
    @Param('id') taskId: string,
    @CurrentUser('userId') userId: string,
    @Body() dto: UpdateTaskDto,
  ) {
    return this.tasksService.updateTask(taskId, userId, dto);
  }
}
