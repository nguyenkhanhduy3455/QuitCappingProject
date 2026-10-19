import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  Submission,
  SubmissionDocument,
  SubmissionStatus,
} from '../database/schemas/submission.schema';
import { Task, TaskDocument } from '../database/schemas/task.schema';
import { User, UserDocument } from '../database/schemas/user.schema';
import { StorageService } from './services/storage.service';
import { CreateSubmissionDto } from './dto/create-submission.dto';
import { isSameUtcDay } from '../common/utils/date.utils';

@Injectable()
export class SubmissionsService {
  private readonly logger = new Logger(SubmissionsService.name);

  constructor(
    @InjectModel(Submission.name) private readonly submissionModel: Model<SubmissionDocument>,
    @InjectModel(Task.name) private readonly taskModel: Model<TaskDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    private readonly storageService: StorageService,
  ) {}

  async createSubmission(
    userId: string,
    createDto: CreateSubmissionDto,
    file?: Express.Multer.File,
  ) {
    // 1. Verify task exists
    const task = await this.taskModel.findById(createDto.taskId).exec();
    if (!task) {
      throw new NotFoundException('Task not found');
    }
    if (task.userId.toString() !== userId) {
      throw new ForbiddenException('You cannot submit evidence for someone else’s task');
    }

    // 2. Resolve image URL
    let imageUrl = createDto.imageUrl;
    if (file) {
      imageUrl = await this.storageService.uploadFile(file);
    }

    if (!imageUrl) {
      throw new BadRequestException('Either an image file or imageUrl must be provided');
    }

    // 3. Give-to-Get Quota Check
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new NotFoundException('User not found');
    }

    let dailyReviewsDone = user.dailyReviewsDone || 0;
    if (!isSameUtcDay(user.lastReviewDate)) {
      dailyReviewsDone = 0;
      user.dailyReviewsDone = 0;
      await user.save();
    }

    // If user has already reviewed >= 5 submissions today, it goes straight to IN_QUEUE
    const status =
      dailyReviewsDone >= 5 ? SubmissionStatus.IN_QUEUE : SubmissionStatus.PENDING_QUOTA;

    const submission = new this.submissionModel({
      taskId: task._id,
      userId: user._id,
      imageUrl,
      status,
      upvotes: 0,
      downvotes: 0,
      reviewedByUserIds: [],
    });

    const savedSubmission = await submission.save();

    // Reward: +10 points for completing a task with photo evidence
    user.points = (user.points ?? 1000) + 10;
    await user.save();

    const reviewsNeeded = Math.max(0, 5 - dailyReviewsDone);

    return {
      submission: savedSubmission,
      quotaStatus: {
        dailyReviewsDone,
        reviewsNeededToQueue: reviewsNeeded,
        isUnlockedInQueue: status === SubmissionStatus.IN_QUEUE,
      },
      message:
        status === SubmissionStatus.IN_QUEUE
          ? 'Proof submitted directly to the global peer-review queue!'
          : `Proof submitted! Complete ${reviewsNeeded} peer review${reviewsNeeded > 1 ? 's' : ''} today to release your proof to the community.`,
    };
  }

  async getMySubmissions(userId: string) {
    return this.submissionModel
      .find({ userId: new Types.ObjectId(userId) })
      .populate('taskId')
      .sort({ createdAt: -1 })
      .exec();
  }

  async getSubmissionById(submissionId: string) {
    const submission = await this.submissionModel.findById(submissionId).populate('taskId').exec();
    if (!submission) {
      throw new NotFoundException('Submission not found');
    }
    return submission;
  }
}
