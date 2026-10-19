import {
  BadRequestException,
  ConflictException,
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
import { Review, ReviewDocument } from '../database/schemas/review.schema';
import { User, UserDocument } from '../database/schemas/user.schema';
import { Task, TaskDocument } from '../database/schemas/task.schema';
import { Goal, GoalDocument } from '../database/schemas/goal.schema';
import { SubmitReviewDto } from './dto/submit-review.dto';
import { isSameUtcDay } from '../common/utils/date.utils';

export interface BlindReviewCard {
  submissionId: string;
  taskId: string;
  taskTitle: string;
  taskDescription: string;
  evidencePrompt: string;
  imageUrl: string;
  createdAt: Date;
}

@Injectable()
export class ReviewsService {
  private readonly logger = new Logger(ReviewsService.name);
  private static readonly DAILY_QUOTA_TARGET = 5;

  constructor(
    @InjectModel(Review.name) private readonly reviewModel: Model<ReviewDocument>,
    @InjectModel(Submission.name) private readonly submissionModel: Model<SubmissionDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(Task.name) private readonly taskModel: Model<TaskDocument>,
    @InjectModel(Goal.name) private readonly goalModel: Model<GoalDocument>,
  ) {}

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
   * Generates a random blind swipe feed for peer review.
   * Rules:
   * 1. Submission status must be 'in_queue'.
   * 2. Self-review prevention: userId != currentUserId.
   * 3. Idempotency: submissionId not already reviewed by current user (reviewedByUserIds != currentUserId).
   * 4. Blind review: NEVER expose author name, id, or avatar.
   */
  async getSwipeFeed(userId: string, limit: number = 10): Promise<BlindReviewCard[]> {
    const userObjectId = new Types.ObjectId(userId);

    const submissions = await this.submissionModel
      .find({
        status: SubmissionStatus.IN_QUEUE,
        userId: { $ne: userObjectId },
        reviewedByUserIds: { $ne: userObjectId },
      })
      .populate('taskId')
      .limit(limit)
      .exec();

    return submissions
      .filter((s) => s.taskId != null)
      .map((s) => {
        const task = s.taskId as unknown as TaskDocument;
        return {
          submissionId: s._id.toString(),
          taskId: task._id.toString(),
          taskTitle: task.title,
          taskDescription: task.description,
          evidencePrompt: task.evidencePrompt,
          imageUrl: s.imageUrl,
          createdAt: s.createdAt,
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

    const dailyReviewsDone = user.dailyReviewsDone || 0;
    const remainingToQuota = Math.max(0, ReviewsService.DAILY_QUOTA_TARGET - dailyReviewsDone);

    return {
      dailyReviewsDone,
      targetQuota: ReviewsService.DAILY_QUOTA_TARGET,
      quotaReached: dailyReviewsDone >= ReviewsService.DAILY_QUOTA_TARGET,
      remainingToQuota,
      pendingProofsLocked: pendingCount,
      inQueueProofsActive: inQueueCount,
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
