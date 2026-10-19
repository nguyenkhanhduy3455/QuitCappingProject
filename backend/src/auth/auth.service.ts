import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { User, UserDocument } from '../database/schemas/user.schema';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { isSameUtcDay } from '../common/utils/date.utils';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    private readonly jwtService: JwtService,
  ) {}

  async register(registerDto: RegisterDto) {
    const existing = await this.userModel.findOne({ email: registerDto.email.toLowerCase() }).exec();
    if (existing) {
      throw new ConflictException('Email is already registered');
    }

    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(registerDto.password, saltRounds);

    const createdUser = new this.userModel({
      email: registerDto.email.toLowerCase(),
      passwordHash,
      displayName: registerDto.displayName,
      avatarUrl: registerDto.avatarUrl || '',
      dailyReviewsDone: 0,
      lastReviewDate: null,
      streakCount: 0,
    });

    const savedUser = await createdUser.save();
    const token = this.generateToken(savedUser._id.toString(), savedUser.email);

    return {
      token,
      user: this.sanitizeUser(savedUser),
    };
  }

  async login(loginDto: LoginDto) {
    const user = await this.userModel.findOne({ email: loginDto.email.toLowerCase() }).exec();
    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const isMatch = await bcrypt.compare(loginDto.password, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('Invalid email or password');
    }

    // Daily reset check
    if (!isSameUtcDay(user.lastReviewDate)) {
      user.dailyReviewsDone = 0;
      await user.save();
    }

    const token = this.generateToken(user._id.toString(), user.email);
    return {
      token,
      user: this.sanitizeUser(user),
    };
  }

  async getProfile(userId: string) {
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    if (!isSameUtcDay(user.lastReviewDate)) {
      user.dailyReviewsDone = 0;
      await user.save();
    }

    return this.sanitizeUser(user);
  }

  private generateToken(userId: string, email: string): string {
    return this.jwtService.sign({ sub: userId, email });
  }

  private sanitizeUser(user: UserDocument) {
    return {
      id: user._id.toString(),
      email: user.email,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      dailyReviewsDone: user.dailyReviewsDone,
      lastReviewDate: user.lastReviewDate,
      streakCount: user.streakCount,
      quotaReached: (user.dailyReviewsDone || 0) >= 5,
    };
  }
}
