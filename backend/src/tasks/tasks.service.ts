import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Task, TaskDocument } from '../database/schemas/task.schema';
import { Goal, GoalDocument, GoalStatus } from '../database/schemas/goal.schema';
import { Submission, SubmissionDocument } from '../database/schemas/submission.schema';
import { QueryTasksDto } from './dto/query-tasks.dto';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';

@Injectable()
export class TasksService {
  constructor(
    @InjectModel(Task.name) private readonly taskModel: Model<TaskDocument>,
    @InjectModel(Goal.name) private readonly goalModel: Model<GoalDocument>,
    @InjectModel(Submission.name) private readonly submissionModel: Model<SubmissionDocument>,
  ) {}

  async getDailyTasks(userId: string, query: QueryTasksDto) {
    let goal: GoalDocument | null = null;

    if (query.goalId) {
      goal = await this.goalModel.findById(query.goalId).exec();
      if (!goal || goal.userId.toString() !== userId) {
        throw new NotFoundException('Goal not found');
      }
    } else {
      goal = await this.goalModel
        .findOne({ userId: new Types.ObjectId(userId), status: GoalStatus.ACTIVE })
        .sort({ createdAt: -1 })
        .exec();
      if (!goal) {
        return {
          goal: null,
          dayNumber: 1,
          tasks: [],
        };
      }
    }

    const dayNumber = query.dayNumber || goal.currentDay || 1;

    const tasks = await this.taskModel
      .find({ goalId: goal._id, dayNumber })
      .sort({ _id: 1 })
      .exec();

    const taskIds = tasks.map((t) => t._id);
    const submissions = await this.submissionModel
      .find({ taskId: { $in: taskIds } })
      .sort({ createdAt: -1 })
      .exec();

    const submissionMap = new Map<string, any>();
    for (const sub of submissions) {
      const taskIdStr = sub.taskId.toString();
      if (!submissionMap.has(taskIdStr)) {
        submissionMap.set(taskIdStr, sub);
      }
    }

    const enrichedTasks = tasks.map((t) => {
      const sub = submissionMap.get(t._id.toString());
      return {
        id: t._id.toString(),
        goalId: t.goalId.toString(),
        dayNumber: t.dayNumber,
        title: t.title,
        description: t.description,
        evidencePrompt: t.evidencePrompt,
        isCompleted: t.isCompleted,
        latestSubmission: sub
          ? {
              id: sub._id.toString(),
              imageUrl: sub.imageUrl,
              status: sub.status,
              upvotes: sub.upvotes,
              downvotes: sub.downvotes,
              createdAt: sub.createdAt,
            }
          : null,
      };
    });

    return {
      goal: {
        id: goal._id.toString(),
        title: goal.title,
        category: goal.category,
        durationDays: goal.durationDays,
        currentDay: goal.currentDay,
      },
      dayNumber,
      tasks: enrichedTasks,
    };
  }

  async getTaskById(taskId: string, userId: string) {
    const task = await this.taskModel.findById(taskId).exec();
    if (!task) {
      throw new NotFoundException('Task not found');
    }
    if (task.userId.toString() !== userId) {
      throw new ForbiddenException('You do not have access to this task');
    }

    const latestSubmission = await this.submissionModel
      .findOne({ taskId: task._id })
      .sort({ createdAt: -1 })
      .exec();

    return {
      id: task._id.toString(),
      goalId: task.goalId.toString(),
      dayNumber: task.dayNumber,
      title: task.title,
      description: task.description,
      evidencePrompt: task.evidencePrompt,
      isCompleted: task.isCompleted,
      latestSubmission: latestSubmission
        ? {
            id: latestSubmission._id.toString(),
            imageUrl: latestSubmission.imageUrl,
            status: latestSubmission.status,
            upvotes: latestSubmission.upvotes,
            downvotes: latestSubmission.downvotes,
            createdAt: latestSubmission.createdAt,
          }
        : null,
    };
  }

  async createTask(userId: string, dto: CreateTaskDto) {
    let goal: GoalDocument | null = null;
    if (dto.goalId) {
      goal = await this.goalModel.findById(dto.goalId).exec();
      if (!goal || goal.userId.toString() !== userId) {
        throw new NotFoundException('Goal not found');
      }
    } else {
      goal = await this.goalModel
        .findOne({ userId: new Types.ObjectId(userId), status: GoalStatus.ACTIVE })
        .sort({ createdAt: -1 })
        .exec();
      if (!goal) {
        throw new BadRequestException('Bạn chưa có mục tiêu nào đang hoạt động để thêm nhiệm vụ');
      }
    }

    const dayNumber = dto.dayNumber || goal.currentDay || 1;

    const task = new this.taskModel({
      goalId: goal._id,
      userId: new Types.ObjectId(userId),
      dayNumber,
      title: dto.title.trim(),
      description: dto.description?.trim() || '',
      evidencePrompt: dto.evidencePrompt?.trim() || 'Chụp ảnh xác nhận hoàn thành nhiệm vụ này',
      isCompleted: false,
    });

    const saved = await task.save();

    return {
      id: saved._id.toString(),
      goalId: saved.goalId.toString(),
      dayNumber: saved.dayNumber,
      title: saved.title,
      description: saved.description,
      evidencePrompt: saved.evidencePrompt,
      isCompleted: saved.isCompleted,
      latestSubmission: null,
    };
  }

  async updateTask(taskId: string, userId: string, dto: UpdateTaskDto) {
    const task = await this.taskModel.findById(taskId).exec();
    if (!task) {
      throw new NotFoundException('Task not found');
    }
    if (task.userId.toString() !== userId) {
      throw new ForbiddenException('You do not have access to modify this task');
    }

    if (dto.title !== undefined && dto.title.trim().length > 0) {
      task.title = dto.title.trim();
    }
    if (dto.description !== undefined) {
      task.description = dto.description.trim();
    }
    if (dto.evidencePrompt !== undefined && dto.evidencePrompt.trim().length > 0) {
      task.evidencePrompt = dto.evidencePrompt.trim();
    }

    const saved = await task.save();

    const latestSubmission = await this.submissionModel
      .findOne({ taskId: saved._id })
      .sort({ createdAt: -1 })
      .exec();

    return {
      id: saved._id.toString(),
      goalId: saved.goalId.toString(),
      dayNumber: saved.dayNumber,
      title: saved.title,
      description: saved.description,
      evidencePrompt: saved.evidencePrompt,
      isCompleted: saved.isCompleted,
      latestSubmission: latestSubmission
        ? {
            id: latestSubmission._id.toString(),
            imageUrl: latestSubmission.imageUrl,
            status: latestSubmission.status,
            upvotes: latestSubmission.upvotes,
            downvotes: latestSubmission.downvotes,
            createdAt: latestSubmission.createdAt,
          }
        : null,
    };
  }
}
