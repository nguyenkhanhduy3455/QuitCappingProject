import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Logger,
  OnModuleInit,
  OnModuleDestroy,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  Submission,
  SubmissionDocument,
  SubmissionStatus,
} from '../database/schemas/submission.schema';
import { Review, ReviewDocument } from '../database/schemas/review.schema';
import { User, UserDocument } from '../database/schemas/user.schema';
import { Task, TaskDocument } from '../database/schemas/task.schema';
import { Goal, GoalDocument } from '../database/schemas/goal.schema';
import { SubmitReviewDto } from './dto/submit-review.dto';
import { isSameUtcDay, startOfUtcDay } from '../common/utils/date.utils';

export interface BlindReviewCard {
  submissionId: string;
  taskId: string;
  taskTitle: string;
  taskDescription: string;
  evidencePrompt: string;
  imageUrl: string;
  createdAt: Date;
  isOwnSubmission: boolean;
  upvotes: number;
  downvotes: number;
  totalReviews: number;
  status: string;
}

@Injectable()
export class ReviewsService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ReviewsService.name);
  private static readonly DAILY_QUOTA_TARGET = 5;
  private cleanupInterval?: NodeJS.Timeout;

  constructor(
    @InjectModel(Review.name) private readonly reviewModel: Model<ReviewDocument>,
    @InjectModel(Submission.name) private readonly submissionModel: Model<SubmissionDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(Task.name) private readonly taskModel: Model<TaskDocument>,
    @InjectModel(Goal.name) private readonly goalModel: Model<GoalDocument>,
  ) {}

  async onModuleInit() {
    await this.resolveExpiredSubmissions();
    this.cleanupInterval = setInterval(() => {
      this.resolveExpiredSubmissions().catch((err) => {
        this.logger.error(`Error in resolveExpiredSubmissions interval: ${err.message}`);
      });
    }, 10 * 60 * 1000);
  }

  onModuleDestroy() {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
    }
  }

  /**
   * Automatically passes submissions created before today's 00:00:00 (quá 12h đêm)
   * that have not reached 5 reviews and haven't been rejected.
   * Gives them 3/5 approval and marks task complete (+10 points for author).
   */
  async resolveExpiredSubmissions(): Promise<number> {
    try {
      const now = new Date();
      const localMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
      const utcMidnight = startOfUtcDay(now);
      const cutoff = localMidnight > utcMidnight ? localMidnight : utcMidnight;

      const expiredSubmissions = await this.submissionModel
        .find({
          status: { $in: [SubmissionStatus.IN_QUEUE, SubmissionStatus.PENDING_QUOTA] },
          createdAt: { $lt: cutoff },
          downvotes: { $lt: 3 },
        })
        .exec();

      if (!expiredSubmissions || expiredSubmissions.length === 0) {
        return 0;
      }

      let resolvedCount = 0;
      for (const sub of expiredSubmissions) {
        sub.status = SubmissionStatus.APPROVED;
        sub.upvotes = Math.max(sub.upvotes || 0, 3);
        await sub.save();

        const task = await this.taskModel.findById(sub.taskId).exec();
        if (task) {
          task.isCompleted = true;
          await task.save();
          await this.checkAndUpdateStreak(task);
        }

        const author = await this.userModel.findById(sub.userId).exec();
        if (author) {
          author.points = (author.points ?? 1000) + 10;
          await author.save();
        }

        resolvedCount++;
      }

      if (resolvedCount > 0) {
        this.logger.log(`Auto-passed ${resolvedCount} submissions past midnight with 3/5 score.`);
      }

      return resolvedCount;
    } catch (err: any) {
      this.logger.error(`Failed to resolve expired submissions: ${err.message}`);
      return 0;
    }
  }

  /**
   * Resets quota if a new UTC day has arrived.
   */
  private checkAndResetQuota(user: UserDocument): boolean {
    if (!isSameUtcDay(user.lastReviewDate)) {
      user.dailyReviewsDone = 0;
      return true;
    }
    return false;
  }

  /**
   * Generates a random swipe feed for peer review.
   * Rules:
   * 1. Submission status must be 'in_queue'.
   * 2. Self submissions ARE included in feed so user sees their own submissions in queue,
   *    but user cannot review them.
   * 3. Idempotency: submissionId not already reviewed by current user (reviewedByUserIds != currentUserId).
   * 4. Blind review: NEVER expose author name, id, or avatar for peer cards.
   */
  async getSwipeFeed(userId: string, limit: number = 15): Promise<BlindReviewCard[]> {
    await this.resolveExpiredSubmissions();

    const userObjectId = new Types.ObjectId(userId);

    const submissions = await this.submissionModel
      .find({
        status: SubmissionStatus.IN_QUEUE,
        reviewedByUserIds: { $ne: userObjectId },
      })
      .populate('taskId')
      .sort({ createdAt: -1 })
      .limit(limit)
      .exec();

    return submissions
      .filter((s) => s.taskId != null)
      .map((s) => {
        const task = s.taskId as unknown as TaskDocument;
        const isOwn = s.userId.toString() === userId;
        const totalReviews =
          s.reviewedByUserIds?.length ?? ((s.upvotes || 0) + (s.downvotes || 0));
        return {
          submissionId: s._id.toString(),
          taskId: task._id.toString(),
          taskTitle: task.title,
          taskDescription: task.description,
          evidencePrompt: task.evidencePrompt,
          imageUrl: s.imageUrl,
          createdAt: s.createdAt,
          isOwnSubmission: isOwn,
          upvotes: s.upvotes || 0,
          downvotes: s.downvotes || 0,
          totalReviews,
          status: s.status,
        };
      });
  }

  /**
   * Submits a peer review (Swipe right = Approve, Swipe left = Reject).
   */
  async submitReview(userId: string, dto: SubmitReviewDto) {
    const reviewerObjectId = new Types.ObjectId(userId);
    const submissionObjectId = new Types.ObjectId(dto.submissionId);

    // 1. Fetch submission
    const submission = await this.submissionModel.findById(submissionObjectId).exec();
    if (!submission) {
      throw new NotFoundException('Submission not found');
    }

    // 2. Anti-cheat Rule: Self-review prevention
    if (submission.userId.toString() === userId) {
      throw new ForbiddenException('Anti-cheat violation: You cannot review your own submission');
    }

    // 3. Status check: submission must be currently in queue
    if (submission.status !== SubmissionStatus.IN_QUEUE) {
      throw new BadRequestException(
        `This submission is no longer open for peer review (status: ${submission.status})`,
      );
    }

    // 4. Anti-cheat Rule: Idempotency check (prevent duplicate review by same user)
    const existingReview = await this.reviewModel
      .findOne({ submissionId: submissionObjectId, reviewerId: reviewerObjectId })
      .exec();

    if (existingReview) {
      throw new ConflictException('You have already reviewed this submission');
    }

    // 5. Create Review Record
    const review = new this.reviewModel({
      submissionId: submissionObjectId,
      reviewerId: reviewerObjectId,
      isApproved: dto.isApproved,
    });
    await review.save();

    // 6. Update reviewer daily reviews quota
    const reviewer = await this.userModel.findById(reviewerObjectId).exec();
    if (!reviewer) {
      throw new NotFoundException('Reviewer account not found');
    }

    this.checkAndResetQuota(reviewer);
    reviewer.dailyReviewsDone = (reviewer.dailyReviewsDone || 0) + 1;
    reviewer.lastReviewDate = new Date();
    // Reward: +5 points for reviewing another peer's submission
    reviewer.points = (reviewer.points ?? 1000) + 5;
    await reviewer.save();

    // 7. Update Submission votes and reviewed list
    submission.reviewedByUserIds.push(reviewerObjectId);
    if (dto.isApproved) {
      submission.upvotes = (submission.upvotes || 0) + 1;
    } else {
      submission.downvotes = (submission.downvotes || 0) + 1;
    }

    let resolutionStatus: SubmissionStatus = submission.status;

    // 8. Peer Review Resolution:
    // If upvotes >= 3 -> APPROVED, task marked complete
    // If downvotes >= 3 -> REJECTED, task must be retried
    if (submission.upvotes >= 3) {
      submission.status = SubmissionStatus.APPROVED;
      resolutionStatus = SubmissionStatus.APPROVED;

      // Reward: +10 points for submission owner when approved by community
      const author = await this.userModel.findById(submission.userId).exec();
      if (author) {
        author.points = (author.points ?? 1000) + 10;
        await author.save();
      }

      // Mark associated task as complete
      const task = await this.taskModel.findById(submission.taskId).exec();
      if (task) {
        task.isCompleted = true;
        await task.save();

        // Check if all tasks for this day are completed to update streak
        await this.checkAndUpdateStreak(task);
      }
    } else if (submission.downvotes >= 3) {
      submission.status = SubmissionStatus.REJECTED;
      resolutionStatus = SubmissionStatus.REJECTED;

      const task = await this.taskModel.findById(submission.taskId).exec();
      if (task) {
        task.isCompleted = false;
        await task.save();
      }
    }

    await submission.save();

    // 9. Give-to-Get Engine: If reviewer reached >= 5 reviews today, unlock their pending proofs!
    let unlockedSubmissionsCount = 0;
    if (reviewer.dailyReviewsDone >= ReviewsService.DAILY_QUOTA_TARGET) {
      const promoteResult = await this.submissionModel.updateMany(
        {
          userId: reviewerObjectId,
          status: SubmissionStatus.PENDING_QUOTA,
        },
        {
          $set: { status: SubmissionStatus.IN_QUEUE },
        },
      );
      unlockedSubmissionsCount = promoteResult.modifiedCount;
      if (unlockedSubmissionsCount > 0) {
        this.logger.log(
          `User ${userId} reached daily quota (${reviewer.dailyReviewsDone}/5). Unlocked ${unlockedSubmissionsCount} submissions into the global queue.`,
        );
      }
    }

    return {
      message: dto.isApproved ? 'Approved vote recorded' : 'Rejected vote recorded',
      currentUpvotes: submission.upvotes,
      currentDownvotes: submission.downvotes,
      submissionStatus: resolutionStatus,
      reviewerQuota: {
        dailyReviewsDone: reviewer.dailyReviewsDone,
        targetQuota: ReviewsService.DAILY_QUOTA_TARGET,
        quotaReached: reviewer.dailyReviewsDone >= ReviewsService.DAILY_QUOTA_TARGET,
        unlockedSubmissionsCount,
      },
    };
  }

  /**
   * Retrieves reviewer's Give-to-Get quota status and pending proofs count.
   */
  async getQuotaStatus(userId: string) {
    await this.resolveExpiredSubmissions();

    const reviewerObjectId = new Types.ObjectId(userId);
    const user = await this.userModel.findById(reviewerObjectId).exec();
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const wasReset = this.checkAndResetQuota(user);
    if (wasReset) {
      await user.save();
    }

    const pendingCount = await this.submissionModel.countDocuments({
      userId: reviewerObjectId,
      status: SubmissionStatus.PENDING_QUOTA,
    });

    const inQueueCount = await this.submissionModel.countDocuments({
      userId: reviewerObjectId,
      status: SubmissionStatus.IN_QUEUE,
    });

    // Count how many submissions by other users are in queue waiting to be reviewed
    const availableToReviewCount = await this.submissionModel.countDocuments({
      status: SubmissionStatus.IN_QUEUE,
      userId: { $ne: reviewerObjectId },
      reviewedByUserIds: { $ne: reviewerObjectId },
    });

    const dailyReviewsDone = user.dailyReviewsDone || 0;
    const remainingToQuota = Math.max(0, ReviewsService.DAILY_QUOTA_TARGET - dailyReviewsDone);
    const bypassQuotaActive = availableToReviewCount < ReviewsService.DAILY_QUOTA_TARGET;

    return {
      dailyReviewsDone,
      targetQuota: ReviewsService.DAILY_QUOTA_TARGET,
      quotaReached: dailyReviewsDone >= ReviewsService.DAILY_QUOTA_TARGET || bypassQuotaActive,
      remainingToQuota,
      pendingProofsLocked: pendingCount,
      inQueueProofsActive: inQueueCount,
      availableToReviewCount,
      bypassQuotaActive,
      streakCount: user.streakCount || 0,
    };
  }

  private async checkAndUpdateStreak(task: TaskDocument) {
    // Check if all tasks for task.goalId and task.dayNumber are completed
    const incompleteTasksCount = await this.taskModel.countDocuments({
      goalId: task.goalId,
      dayNumber: task.dayNumber,
      isCompleted: false,
    });

    if (incompleteTasksCount === 0) {
      // All day's tasks are completed!
      const user = await this.userModel.findById(task.userId).exec();
      if (user) {
        user.streakCount = (user.streakCount || 0) + 1;
        await user.save();
      }

      // Advance goal currentDay if not already past
      const goal = await this.goalModel.findById(task.goalId).exec();
      if (goal && goal.currentDay <= task.dayNumber && goal.currentDay < goal.durationDays) {
        goal.currentDay = task.dayNumber + 1;
        await goal.save();
      }
    }
  }
}
