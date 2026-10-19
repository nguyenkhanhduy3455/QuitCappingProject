import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_data_storage.dart';
import '../domain/review_models.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final localData = ref.watch(localDataStorageProvider);
  return ReviewRepository(dio, localData);
});

class SubmitReviewResult {
  final String message;
  final int currentUpvotes;
  final int currentDownvotes;
  final String submissionStatus;
  final int dailyReviewsDone;
  final bool quotaReached;
  final int unlockedSubmissionsCount;

  SubmitReviewResult({
    required this.message,
    required this.currentUpvotes,
    required this.currentDownvotes,
    required this.submissionStatus,
    required this.dailyReviewsDone,
    required this.quotaReached,
    required this.unlockedSubmissionsCount,
  });
}

class ReviewRepository {
  final Dio _dio;
  final LocalDataStorage _localData;

  ReviewRepository(this._dio, this._localData);

  Future<List<BlindReviewCard>> getSwipeFeed({int limit = 10}) async {
    if (_localData.isGuestMode()) {
      return _localData.getDemoReviewFeed();
    }

    try {
      final response = await _dio.get(
        ApiEndpoints.reviewFeed,
        queryParameters: {'limit': limit},
      );
      final list = response.data as List<dynamic>? ?? [];
      return list.map((json) => BlindReviewCard.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(e.message ?? 'Failed to fetch review feed');
    }
  }

  Future<SubmitReviewResult> submitReview({
    required String submissionId,
    required bool isApproved,
  }) async {
    if (_localData.isGuestMode()) {
      return await _localData.submitReviewVote(
        submissionId: submissionId,
        isApproved: isApproved,
      );
    }

    try {
      final response = await _dio.post(
        ApiEndpoints.submitReview,
        data: {
          'submissionId': submissionId,
          'isApproved': isApproved,
        },
      );
      final data = response.data;
      final quota = data['reviewerQuota'] as Map<String, dynamic>? ?? {};

      return SubmitReviewResult(
        message: data['message'] ?? 'Vote recorded',
        currentUpvotes: data['currentUpvotes'] ?? 0,
        currentDownvotes: data['currentDownvotes'] ?? 0,
        submissionStatus: data['submissionStatus'] ?? 'in_queue',
        dailyReviewsDone: quota['dailyReviewsDone'] ?? 0,
        quotaReached: quota['quotaReached'] ?? false,
        unlockedSubmissionsCount: quota['unlockedSubmissionsCount'] ?? 0,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(e.message ?? 'Failed to submit review');
    }
  }

  Future<ReviewQuotaStatus> getQuotaStatus() async {
    if (_localData.isGuestMode()) {
      final guest = _localData.getGuestUser();
      return ReviewQuotaStatus(
        dailyReviewsDone: 5,
        targetQuota: 5,
        quotaReached: true,
        remainingToQuota: 0,
        pendingProofsLocked: 0,
        inQueueProofsActive: 1,
        streakCount: guest.streakCount,
      );
    }

    try {
      final response = await _dio.get(ApiEndpoints.reviewQuota);
      return ReviewQuotaStatus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(e.message ?? 'Failed to fetch quota status');
    }
  }
}
