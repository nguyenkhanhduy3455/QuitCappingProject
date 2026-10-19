import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TasksController } from './tasks.controller';
import { TasksService } from './tasks.service';
import { Task, TaskSchema } from '../database/schemas/task.schema';
import { Goal, GoalSchema } from '../database/schemas/goal.schema';
import { Submission, SubmissionSchema } from '../database/schemas/submission.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Task.name, schema: TaskSchema },
      { name: Goal.name, schema: GoalSchema },
      { name: Submission.name, schema: SubmissionSchema },
    ]),
  ],
  controllers: [TasksController],
  providers: [TasksService],
  exports: [TasksService],
})
export class TasksModule {}
