import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary } from 'cloudinary';
import * as fs from 'fs';
import * as path from 'path';
import { promisify } from 'util';

const writeFileAsync = promisify(fs.writeFile);

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private readonly isCloudinaryConfigured: boolean = false;
  private readonly uploadDir: string;

  constructor(private readonly configService: ConfigService) {
    const cloudName = this.configService.get<string>('CLOUDINARY_CLOUD_NAME');
    const apiKey = this.configService.get<string>('CLOUDINARY_API_KEY');
    const apiSecret = this.configService.get<string>('CLOUDINARY_API_SECRET');

    if (cloudName && apiKey && apiSecret) {
      cloudinary.config({
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
        secure: true,
      });
      this.isCloudinaryConfigured = true;
      this.logger.log('Cloudinary storage initialized successfully.');
    } else {
      this.logger.warn(
        'Cloudinary credentials not provided. Using local disk storage fallback in ./uploads directory.',
      );
    }

    this.uploadDir = path.resolve(process.cwd(), 'uploads');
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  async uploadFile(file: Express.Multer.File): Promise<string> {
    if (this.isCloudinaryConfigured) {
      return new Promise<string>((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
          {
            folder: 'quitcapping_evidence',
            transformation: [{ width: 1200, crop: 'limit', quality: 'auto:eco' }],
          },
          (error, result) => {
            if (error) {
              this.logger.error('Cloudinary upload error:', error);
              return reject(error);
            }
            if (!result || !result.secure_url) {
              return reject(new Error('Cloudinary response missing secure_url'));
            }
            resolve(result.secure_url);
          },
        );
        uploadStream.end(file.buffer);
      });
    }

    // Local disk fallback
    const ext = path.extname(file.originalname) || '.jpg';
    const filename = `proof_${Date.now()}_${Math.random().toString(36).substring(2, 9)}${ext}`;
    const filePath = path.join(this.uploadDir, filename);

    await writeFileAsync(filePath, file.buffer);
    this.logger.log(`Saved proof file locally: ${filename}`);

    return `/uploads/${filename}`;
  }
}
