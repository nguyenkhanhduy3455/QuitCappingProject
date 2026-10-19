import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Goal, GoalDocument, GoalStatus } from '../database/schemas/goal.schema';
import { Task, TaskDocument } from '../database/schemas/task.schema';
import { Submission, SubmissionDocument } from '../database/schemas/submission.schema';
import { User, UserDocument } from '../database/schemas/user.schema';
import { GeminiAiService } from './services/gemini-ai.service';
import { CreateGoalDto } from './dto/create-goal.dto';

@Injectable()
export class GoalsService {
  private readonly logger = new Logger(GoalsService.name);

  constructor(
    @InjectModel(Goal.name) private readonly goalModel: Model<GoalDocument>,
    @InjectModel(Task.name) private readonly taskModel: Model<TaskDocument>,
    @InjectModel(Submission.name) private readonly submissionModel: Model<SubmissionDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    private readonly geminiAiService: GeminiAiService,
  ) {}

  async createGoal(userId: string, createGoalDto: CreateGoalDto) {
    const durationDays = createGoalDto.durationDays || 30;

    // 0. Point cost rule: Creating a goal costs 500 points
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new NotFoundException('User not found');
    }
    const currentPoints = user.points ?? 1000;
    if (currentPoints < 500) {
      throw new BadRequestException(
        `Bạn không đủ điểm để tạo mục tiêu (cần 500 điểm, hiện có ${currentPoints} điểm). Hãy hoàn thành các nhiệm vụ hoặc tham gia đánh giá chéo để tích lũy thêm điểm!`,
      );
    }
    user.points = currentPoints - 500;
    await user.save();

    // 1. Create Goal entity
    const goal = new this.goalModel({
      userId: new Types.ObjectId(userId),
      title: createGoalDto.title,
      category: createGoalDto.category,
      durationDays,
      currentDay: 1,
      status: GoalStatus.ACTIVE,
    });
    const savedGoal = await goal.save();

    // 2. Call Gemini AI with strict JSON schema to generate micro-tasks
    this.logger.log(`Generating AI roadmap for goal "${savedGoal.title}" (${durationDays} days)...`);
    const generatedTasks = await this.geminiAiService.generateRoadmapTasks(
      createGoalDto.title,
      createGoalDto.currentSkillLevel,
      durationDays,
    );

    // 3. Persist micro-tasks in database
    const taskDocs = generatedTasks.map((t) => ({
      goalId: savedGoal._id,
      userId: savedGoal.userId,
      dayNumber: t.dayNumber,
      title: t.title,
      description: t.description,
      evidencePrompt: t.evidencePrompt,
      isCompleted: false,
    }));

    const insertedTasks = await this.taskModel.insertMany(taskDocs);
    this.logger.log(`Generated and saved ${insertedTasks.length} micro-tasks for goal ${savedGoal._id}`);

    return {
      goal: savedGoal,
      taskCount: insertedTasks.length,
      sampleTasks: insertedTasks.slice(0, 3),
    };
  }

  async getActiveGoal(userId: string) {
    const goal = await this.goalModel
      .findOne({ userId: new Types.ObjectId(userId), status: GoalStatus.ACTIVE })
      .sort({ createdAt: -1 })
      .exec();

    if (!goal) {
      return null;
    }

    const totalTasks = await this.taskModel.countDocuments({ goalId: goal._id }).exec();
    const completedTasks = await this.taskModel
      .countDocuments({ goalId: goal._id, isCompleted: true })
      .exec();

    return {
      goal,
      totalTasks,
      completedTasks,
      progressPercentage: totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0,
    };
  }

  async getGoalRoadmap(goalId: string, userId: string) {
    const goal = await this.goalModel.findById(goalId).exec();
    if (!goal) {
      throw new NotFoundException('Goal not found');
    }
    if (goal.userId.toString() !== userId) {
      throw new ForbiddenException('You do not have access to this goal');
    }

    // Fetch all tasks for this goal
    const tasks = await this.taskModel.find({ goalId: goal._id }).sort({ dayNumber: 1, _id: 1 }).exec();

    // Fetch latest submissions for each task to display proof status
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

    const tasksWithSubmissions = tasks.map((t) => {
      const latestSub = submissionMap.get(t._id.toString());
      return {
        id: t._id.toString(),
        goalId: t.goalId.toString(),
        dayNumber: t.dayNumber,
        title: t.title,
        description: t.description,
        evidencePrompt: t.evidencePrompt,
        isCompleted: t.isCompleted,
        latestSubmission: latestSub
          ? {
              id: latestSub._id.toString(),
              imageUrl: latestSub.imageUrl,
              status: latestSub.status,
              upvotes: latestSub.upvotes,
              downvotes: latestSub.downvotes,
              createdAt: latestSub.createdAt,
            }
          : null,
      };
    });

    return {
      goal,
      tasks: tasksWithSubmissions,
    };
  }

  async listUserGoals(userId: string) {
    return this.goalModel
      .find({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 })
      .exec();
  }
}
