import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SubmissionsController } from './submissions.controller';
import { SubmissionsService } from './submissions.service';
import { StorageService } from './services/storage.service';
import { Submission, SubmissionSchema } from '../database/schemas/submission.schema';
import { Task, TaskSchema } from '../database/schemas/task.schema';
import { User, UserSchema } from '../database/schemas/user.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Submission.name, schema: SubmissionSchema },
      { name: Task.name, schema: TaskSchema },
      { name: User.name, schema: UserSchema },
    ]),
  ],
  controllers: [SubmissionsController],
  providers: [SubmissionsService, StorageService],
  exports: [SubmissionsService, StorageService],
})
export class SubmissionsModule {}
