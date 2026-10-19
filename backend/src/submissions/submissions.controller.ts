import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { SubmissionsService } from './submissions.service';
import { CreateSubmissionDto } from './dto/create-submission.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('submissions')
export class SubmissionsController {
  constructor(private readonly submissionsService: SubmissionsService) {}

  @Post()
  @UseInterceptors(FileInterceptor('image'))
  async createSubmission(
    @CurrentUser('userId') userId: string,
    @Body() createDto: CreateSubmissionDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.submissionsService.createSubmission(userId, createDto, file);
  }

  @Get('me')
  async getMySubmissions(@CurrentUser('userId') userId: string) {
    return this.submissionsService.getMySubmissions(userId);
  }

  @Get(':id')
  async getSubmissionById(@Param('id') id: string) {
    return this.submissionsService.getSubmissionById(id);
  }
}
