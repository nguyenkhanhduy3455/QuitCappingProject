import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { ReviewsService } from './reviews.service';
import { Review } from '../database/schemas/review.schema';
import { Submission, SubmissionStatus } from '../database/schemas/submission.schema';
import { User } from '../database/schemas/user.schema';
import { Task } from '../database/schemas/task.schema';
import { Goal } from '../database/schemas/goal.schema';
import { ForbiddenException, ConflictException, BadRequestException } from '@nestjs/common';
import { Types } from 'mongoose';

describe('ReviewsService & Give-to-Get Anti-Cheat Engine', () => {
  let service: ReviewsService;

  const mockReviewModel: any = jest.fn().mockImplementation((dto) => ({
    ...dto,
    save: jest.fn().mockResolvedValue({ _id: new Types.ObjectId(), ...dto }),
  }));
  mockReviewModel.findOne = jest.fn();

  const mockSubmissionModel: any = {
    find: jest.fn(),
    findById: jest.fn(),
    countDocuments: jest.fn(),
    updateMany: jest.fn(),
  };

  const mockUserModel: any = {
    findById: jest.fn(),
  };

  const mockTaskModel: any = {
    findById: jest.fn(),
    countDocuments: jest.fn(),
  };

  const mockGoalModel: any = {
    findById: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReviewsService,
        { provide: getModelToken(Review.name), useValue: mockReviewModel },
        { provide: getModelToken(Submission.name), useValue: mockSubmissionModel },
        { provide: getModelToken(User.name), useValue: mockUserModel },
        { provide: getModelToken(Task.name), useValue: mockTaskModel },
        { provide: getModelToken(Goal.name), useValue: mockGoalModel },
      ],
    }).compile();

    service = module.get<ReviewsService>(ReviewsService);
  });

  describe('Anti-Cheat: Self-Review Prevention', () => {
    it('should throw ForbiddenException if user attempts to review their own submission', async () => {
      const currentUserId = new Types.ObjectId().toString();
      const submissionId = new Types.ObjectId().toString();

      mockSubmissionModel.findById.mockReturnValue({
        exec: jest.fn().mockResolvedValue({
          _id: new Types.ObjectId(submissionId),
          userId: new Types.ObjectId(currentUserId), // Same user
          status: SubmissionStatus.IN_QUEUE,
        }),
      });

      await expect(
        service.submitReview(currentUserId, {
          submissionId,
          isApproved: true,
        }),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('Anti-Cheat: Review Idempotency', () => {
    it('should throw ConflictException if user already reviewed this submission', async () => {
      const currentUserId = new Types.ObjectId().toString();
      const authorId = new Types.ObjectId().toString();
      const submissionId = new Types.ObjectId().toString();

      mockSubmissionModel.findById.mockReturnValue({
        exec: jest.fn().mockResolvedValue({
          _id: new Types.ObjectId(submissionId),
          userId: new Types.ObjectId(authorId),
          status: SubmissionStatus.IN_QUEUE,
        }),
      });

      mockReviewModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue({
          _id: new Types.ObjectId(),
          submissionId: new Types.ObjectId(submissionId),
          reviewerId: new Types.ObjectId(currentUserId),
        }),
      });

      await expect(
        service.submitReview(currentUserId, {
          submissionId,
          isApproved: true,
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('Peer Review Vote Resolution (>= 3 upvotes -> APPROVED)', () => {
    it('should mark submission as APPROVED and task isCompleted=true when reaching 3 upvotes', async () => {
      const currentUserId = new Types.ObjectId().toString();
      const authorId = new Types.ObjectId().toString();
      const submissionId = new Types.ObjectId().toString();
      const taskId = new Types.ObjectId().toString();

      const mockSubmission: any = {
        _id: new Types.ObjectId(submissionId),
        taskId: new Types.ObjectId(taskId),
        userId: new Types.ObjectId(authorId),
        status: SubmissionStatus.IN_QUEUE,
        upvotes: 2, // currently 2 upvotes, this vote makes it 3
        downvotes: 0,
        reviewedByUserIds: [],
        save: jest.fn().mockResolvedValue(true),
      };

      const mockReviewer: any = {
        _id: new Types.ObjectId(currentUserId),
        dailyReviewsDone: 1,
        lastReviewDate: new Date(),
        save: jest.fn().mockResolvedValue(true),
      };

      const mockTask: any = {
        _id: new Types.ObjectId(taskId),
        isCompleted: false,
        goalId: new Types.ObjectId(),
        dayNumber: 1,
        save: jest.fn().mockResolvedValue(true),
      };

      mockSubmissionModel.findById.mockReturnValue({ exec: jest.fn().mockResolvedValue(mockSubmission) });
      mockReviewModel.findOne.mockReturnValue({ exec: jest.fn().mockResolvedValue(null) });
      mockUserModel.findById.mockReturnValue({ exec: jest.fn().mockResolvedValue(mockReviewer) });
      mockTaskModel.findById.mockReturnValue({ exec: jest.fn().mockResolvedValue(mockTask) });
      mockTaskModel.countDocuments.mockReturnValue({ exec: jest.fn().mockResolvedValue(0) });
      mockGoalModel.findById.mockReturnValue({ exec: jest.fn().mockResolvedValue(null) });

      const result = await service.submitReview(currentUserId, {
        submissionId,
        isApproved: true,
      });

      expect(mockSubmission.upvotes).toBe(3);
      expect(mockSubmission.status).toBe(SubmissionStatus.APPROVED);
      expect(mockTask.isCompleted).toBe(true);
      expect(result.submissionStatus).toBe(SubmissionStatus.APPROVED);
    });
  });

  describe('Peer Review Vote Resolution (>= 3 downvotes -> REJECTED)', () => {
    it('should mark submission as REJECTED and keep task isCompleted=false when reaching 3 downvotes', async () => {
      const currentUserId = new Types.ObjectId().toString();
      const authorId = new Types.ObjectId().toString();
      const submissionId = new Types.ObjectId().toString();
      const taskId = new Types.ObjectId().toString();

      const mockSubmission: any = {
        _id: new Types.ObjectId(submissionId),
        taskId: new Types.ObjectId(taskId),
        userId: new Types.ObjectId(authorId),
        status: SubmissionStatus.IN_QUEUE,
        upvotes: 0,
        downvotes: 2, // currently 2 downvotes, this vote makes it 3
        reviewedByUserIds: [],
        save: jest.fn().mockResolvedValue(true),
      };

      const mockReviewer: any = {
        _id: new Types.ObjectId(currentUserId),
        dailyReviewsDone: 2,
        lastReviewDate: new Date(),
        save: jest.fn().mockResolvedValue(true),
      };

      const mockTask: any = {
        _id: new Types.ObjectId(taskId),
        isCompleted: false,
        save: jest.fn().mockResolvedValue(true),
      };

      mockSubmissionModel.findById.mockReturnValue({ exec: jest.fn().mockResolvedValue(mockSubmission) });
      mockReviewModel.findOne.mockReturnValue({ exec: jest.fn().mockResolvedValue(null) });
      mockUserModel.findById.mockReturnValue({ exec: jest.fn().mockResolvedValue(mockReviewer) });
      mockTaskModel.findById.mockReturnValue({ exec: jest.fn().mockResolvedValue(mockTask) });

      const result = await service.submitReview(currentUserId, {
        submissionId,
        isApproved: false,
      });

      expect(mockSubmission.downvotes).toBe(3);
      expect(mockSubmission.status).toBe(SubmissionStatus.REJECTED);
      expect(mockTask.isCompleted).toBe(false);
      expect(result.submissionStatus).toBe(SubmissionStatus.REJECTED);
    });
  });

  describe('Give-to-Get Quota Engine: Unlock on 5th Review', () => {
    it('should promote pending_quota submissions to in_queue when user completes their 5th review today', async () => {
      const currentUserId = new Types.ObjectId().toString();
      const authorId = new Types.ObjectId().toString();
      const submissionId = new Types.ObjectId().toString();

      const mockSubmission: any = {
        _id: new Types.ObjectId(submissionId),
        taskId: new Types.ObjectId(),
        userId: new Types.ObjectId(authorId),
        status: SubmissionStatus.IN_QUEUE,
        upvotes: 0,
        downvotes: 0,
        reviewedByUserIds: [],
        save: jest.fn().mockResolvedValue(true),
      };

      // Reviewer has done 4 reviews today; this review is #5
      const mockReviewer: any = {
        _id: new Types.ObjectId(currentUserId),
        dailyReviewsDone: 4,
        lastReviewDate: new Date(),
        save: jest.fn().mockResolvedValue(true),
      };

      mockSubmissionModel.findById.mockReturnValue({ exec: jest.fn().mockResolvedValue(mockSubmission) });
      mockReviewModel.findOne.mockReturnValue({ exec: jest.fn().mockResolvedValue(null) });
      mockUserModel.findById.mockReturnValue({ exec: jest.fn().mockResolvedValue(mockReviewer) });
      mockSubmissionModel.updateMany.mockResolvedValue({ modifiedCount: 2 });

      const result = await service.submitReview(currentUserId, {
        submissionId,
        isApproved: true,
      });

      expect(mockReviewer.dailyReviewsDone).toBe(5);
      expect(mockSubmissionModel.updateMany).toHaveBeenCalledWith(
        {
          userId: new Types.ObjectId(currentUserId),
          status: SubmissionStatus.PENDING_QUOTA,
        },
        {
          $set: { status: SubmissionStatus.IN_QUEUE },
        },
      );
      expect(result.reviewerQuota.quotaReached).toBe(true);
      expect(result.reviewerQuota.unlockedSubmissionsCount).toBe(2);
    });
  });
});
