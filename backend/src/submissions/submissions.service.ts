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
import { ReviewsService } from '../reviews/reviews.service';

@Injectable()
export class SubmissionsService {
  private readonly logger = new Logger(SubmissionsService.name);

  constructor(
    @InjectModel(Submission.name) private readonly submissionModel: Model<SubmissionDocument>,
    @InjectModel(Task.name) private readonly taskModel: Model<TaskDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    private readonly storageService: StorageService,
    private readonly reviewsService: ReviewsService,
  ) {}

  async createSubmission(
    userId: string,
    createDto: CreateSubmissionDto,
    file?: Express.Multer.File,
  ) {
    // 1. Resolve any expired submissions before evaluating queue
    await this.reviewsService.resolveExpiredSubmissions();

    // 2. Verify task exists
    const task = await this.taskModel.findById(createDto.taskId).exec();
    if (!task) {
      throw new NotFoundException('Task not found');
    }
    if (task.userId.toString() !== userId) {
      throw new ForbiddenException('You cannot submit evidence for someone else’s task');
    }

    // 3. Resolve image URL
    let imageUrl = createDto.imageUrl;
    if (file) {
      imageUrl = await this.storageService.uploadFile(file);
    }

    if (!imageUrl) {
      throw new BadRequestException('Either an image file or imageUrl must be provided');
    }

    // 4. Give-to-Get Quota & Low Queue Bypass Check
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

    // Count how many submissions by other peers are currently in queue waiting for reviews
    const availableToReviewCount = await this.submissionModel.countDocuments({
      status: SubmissionStatus.IN_QUEUE,
      userId: { $ne: user._id },
      reviewedByUserIds: { $ne: user._id },
    });

    // Anti-lock rule: If queue has < 5 submissions available to review,
    // bypass the 5-review requirement so the user isn't permanently blocked.
    const queueIsLow = availableToReviewCount < 5;
    const isUnlocked = dailyReviewsDone >= 5 || queueIsLow;
    const status = isUnlocked ? SubmissionStatus.IN_QUEUE : SubmissionStatus.PENDING_QUOTA;

    // If unlocked, also promote any older pending submissions of this user
    if (isUnlocked) {
      await this.submissionModel.updateMany(
        { userId: user._id, status: SubmissionStatus.PENDING_QUOTA },
        { $set: { status: SubmissionStatus.IN_QUEUE } },
      );
    }

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

    let message = '';
    if (status === SubmissionStatus.IN_QUEUE) {
      if (queueIsLow && dailyReviewsDone < 5) {
        message =
          'Hàng đợi hiện có ít hơn 5 bài đánh giá. Bằng chứng của bạn đã được bỏ qua điều kiện và đưa thẳng vào hàng đợi!';
      } else {
        message = 'Bằng chứng đã được đưa vào hàng đợi đánh giá cộng đồng!';
      }
    } else {
      message = `Đã nộp bằng chứng! Hãy đánh giá ${reviewsNeeded} bài của người khác để mở khóa bài của bạn vào hàng đợi.`;
    }

    return {
      submission: savedSubmission,
      quotaStatus: {
        dailyReviewsDone,
        reviewsNeededToQueue: reviewsNeeded,
        isUnlockedInQueue: status === SubmissionStatus.IN_QUEUE,
        bypassedDueToLowQueue: queueIsLow,
      },
      message,
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
