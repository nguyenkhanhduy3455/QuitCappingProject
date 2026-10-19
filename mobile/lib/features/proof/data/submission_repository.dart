import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_data_storage.dart';
import '../domain/submission_model.dart';

final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final localData = ref.watch(localDataStorageProvider);
  return SubmissionRepository(dio, localData);
});

class SubmissionResult {
  final SubmissionModel submission;
  final int dailyReviewsDone;
  final int reviewsNeededToQueue;
  final bool isUnlockedInQueue;
  final String message;

  SubmissionResult({
    required this.submission,
    required this.dailyReviewsDone,
    required this.reviewsNeededToQueue,
    required this.isUnlockedInQueue,
    required this.message,
  });
}

class SubmissionRepository {
  final Dio _dio;
  final LocalDataStorage _localData;

  SubmissionRepository(this._dio, this._localData);

  Future<SubmissionResult> submitProof({
    required String taskId,
    File? imageFile,
    String? imageUrl,
  }) async {
    if (_localData.isGuestMode()) {
      final path = imageFile?.path ?? imageUrl;
      return await _localData.submitProof(taskId: taskId, imageUrl: path);
    }

    try {
      dynamic data;

      if (imageFile != null) {
        final fileName = imageFile.path.split('/').last;
        final ext = fileName.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

        data = FormData.fromMap({
          'taskId': taskId,
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        });
      } else {
        data = {
          'taskId': taskId,
          'imageUrl': imageUrl,
        };
      }

      final response = await _dio.post(
        ApiEndpoints.submissions,
        data: data,
      );

      final resData = response.data;
      final submission = SubmissionModel.fromJson(resData['submission'] as Map<String, dynamic>);
      final quota = resData['quotaStatus'] as Map<String, dynamic>? ?? {};

      return SubmissionResult(
        submission: submission,
        dailyReviewsDone: quota['dailyReviewsDone'] ?? 0,
        reviewsNeededToQueue: quota['reviewsNeededToQueue'] ?? 5,
        isUnlockedInQueue: quota['isUnlockedInQueue'] ?? false,
        message: resData['message'] ?? 'Proof submitted successfully',
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(e.message ?? 'Failed to submit proof');
    }
  }
}
