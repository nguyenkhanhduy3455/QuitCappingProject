import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { GoalsController } from './goals.controller';
import { GoalsService } from './goals.service';
import { GeminiAiService } from './services/gemini-ai.service';
import { Goal, GoalSchema } from '../database/schemas/goal.schema';
import { Task, TaskSchema } from '../database/schemas/task.schema';
import { Submission, SubmissionSchema } from '../database/schemas/submission.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Goal.name, schema: GoalSchema },
      { name: Task.name, schema: TaskSchema },
      { name: Submission.name, schema: SubmissionSchema },
    ]),
  ],
  controllers: [GoalsController],
  providers: [GoalsService, GeminiAiService],
  exports: [GoalsService, GeminiAiService],
})
export class GoalsModule {}
