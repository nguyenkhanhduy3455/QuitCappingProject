import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { SubmissionsService } from './submissions.service';
import { Submission, SubmissionStatus } from '../database/schemas/submission.schema';
import { Task } from '../database/schemas/task.schema';
import { User } from '../database/schemas/user.schema';
import { StorageService } from './services/storage.service';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Types } from 'mongoose';

describe('SubmissionsService - Give-to-Get Ingestion', () => {
  let service: SubmissionsService;

  const mockSubmissionModel: any = jest.fn().mockImplementation((dto) => ({
    ...dto,
    _id: new Types.ObjectId(),
    save: jest.fn().mockResolvedValue({ _id: new Types.ObjectId(), ...dto }),
  }));
  mockSubmissionModel.find = jest.fn();
  mockSubmissionModel.findById = jest.fn();

  const mockTaskModel: any = {
    findById: jest.fn(),
  };

  const mockUserModel: any = {
    findById: jest.fn(),
  };

  const mockStorageService: any = {
    uploadFile: jest.fn().mockResolvedValue('https://res.cloudinary.com/demo/image/upload/sample.jpg'),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SubmissionsService,
        { provide: getModelToken(Submission.name), useValue: mockSubmissionModel },
        { provide: getModelToken(Task.name), useValue: mockTaskModel },
        { provide: getModelToken(User.name), useValue: mockUserModel },
        { provide: StorageService, useValue: mockStorageService },
      ],
    }).compile();

    service = module.get<SubmissionsService>(SubmissionsService);
  });

  it('should create submission with status PENDING_QUOTA if dailyReviewsDone < 5', async () => {
    const userId = new Types.ObjectId().toString();
    const taskId = new Types.ObjectId().toString();

    mockTaskModel.findById.mockReturnValue({
      exec: jest.fn().mockResolvedValue({
        _id: new Types.ObjectId(taskId),
        userId: new Types.ObjectId(userId),
      }),
    });

    mockUserModel.findById.mockReturnValue({
      exec: jest.fn().mockResolvedValue({
        _id: new Types.ObjectId(userId),
        dailyReviewsDone: 2, // < 5
        lastReviewDate: new Date(),
        save: jest.fn().mockResolvedValue(true),
      }),
    });

    const result = await service.createSubmission(userId, {
      taskId,
      imageUrl: 'https://cdn.quitcapping.app/proofs/123.jpg',
    });

    expect(result.submission.status).toBe(SubmissionStatus.PENDING_QUOTA);
    expect(result.quotaStatus.isUnlockedInQueue).toBe(false);
    expect(result.quotaStatus.reviewsNeededToQueue).toBe(3);
  });

  it('should create submission directly with status IN_QUEUE if dailyReviewsDone >= 5', async () => {
    const userId = new Types.ObjectId().toString();
    const taskId = new Types.ObjectId().toString();

    mockTaskModel.findById.mockReturnValue({
      exec: jest.fn().mockResolvedValue({
        _id: new Types.ObjectId(taskId),
        userId: new Types.ObjectId(userId),
      }),
    });

    mockUserModel.findById.mockReturnValue({
      exec: jest.fn().mockResolvedValue({
        _id: new Types.ObjectId(userId),
        dailyReviewsDone: 5, // >= 5 quota met!
        lastReviewDate: new Date(),
        save: jest.fn().mockResolvedValue(true),
      }),
    });

    const result = await service.createSubmission(userId, {
      taskId,
      imageUrl: 'https://cdn.quitcapping.app/proofs/123.jpg',
    });

    expect(result.submission.status).toBe(SubmissionStatus.IN_QUEUE);
    expect(result.quotaStatus.isUnlockedInQueue).toBe(true);
    expect(result.quotaStatus.reviewsNeededToQueue).toBe(0);
  });

  it('should reject submission if task belongs to another user', async () => {
    const userId = new Types.ObjectId().toString();
    const otherUserId = new Types.ObjectId().toString();
    const taskId = new Types.ObjectId().toString();

    mockTaskModel.findById.mockReturnValue({
      exec: jest.fn().mockResolvedValue({
        _id: new Types.ObjectId(taskId),
        userId: new Types.ObjectId(otherUserId), // other user
      }),
    });

    await expect(
      service.createSubmission(userId, {
        taskId,
        imageUrl: 'https://cdn.quitcapping.app/proofs/123.jpg',
      }),
    ).rejects.toThrow(ForbiddenException);
  });
});
