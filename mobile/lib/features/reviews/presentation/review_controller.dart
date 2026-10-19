import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../data/review_repository.dart';
import '../domain/review_models.dart';

class ReviewState {
  final bool isLoading;
  final bool isVoting;
  final List<BlindReviewCard> feed;
  final ReviewQuotaStatus? quota;
  final int lastUnlockedCount;
  final String? errorMessage;

  const ReviewState({
    required this.isLoading,
    required this.isVoting,
    required this.feed,
    this.quota,
    this.lastUnlockedCount = 0,
    this.errorMessage,
  });

  factory ReviewState.initial() => const ReviewState(
        isLoading: false,
        isVoting: false,
        feed: [],
        quota: null,
      );

  ReviewState copyWith({
    bool? isLoading,
    bool? isVoting,
    List<BlindReviewCard>? feed,
    ReviewQuotaStatus? quota,
    int? lastUnlockedCount,
    String? errorMessage,
  }) {
    return ReviewState(
      isLoading: isLoading ?? this.isLoading,
      isVoting: isVoting ?? this.isVoting,
      feed: feed ?? this.feed,
      quota: quota ?? this.quota,
      lastUnlockedCount: lastUnlockedCount ?? this.lastUnlockedCount,
      errorMessage: errorMessage,
    );
  }
}

final reviewControllerProvider =
    StateNotifierProvider<ReviewController, ReviewState>((ref) {
  final reviewRepo = ref.watch(reviewRepositoryProvider);
  return ReviewController(reviewRepo);
});

class ReviewController extends StateNotifier<ReviewState> {
  final ReviewRepository _reviewRepo;

  ReviewController(this._reviewRepo) : super(ReviewState.initial()) {
    init();
  }

  Future<void> init() async {
    await refreshQuota();
    await loadFeed();
  }

  Future<void> refreshQuota() async {
    try {
      final quota = await _reviewRepo.getQuotaStatus();
      state = state.copyWith(quota: quota);
    } catch (_) {}
  }

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cards = await _reviewRepo.getSwipeFeed(limit: 15);
      state = state.copyWith(isLoading: false, feed: cards);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load swipe feed');
    }
  }

  Future<SubmitReviewResult?> submitVote({
    required BlindReviewCard card,
    required bool isApproved,
  }) async {
    // Optimistically remove card from feed for instant UI feedback
    final updatedFeed = List<BlindReviewCard>.from(state.feed)
      ..removeWhere((c) => c.submissionId == card.submissionId);

    state = state.copyWith(feed: updatedFeed, isVoting: true, lastUnlockedCount: 0);

    try {
      final result = await _reviewRepo.submitReview(
        submissionId: card.submissionId,
        isApproved: isApproved,
      );

      // Refresh quota status after vote
      final updatedQuota = await _reviewRepo.getQuotaStatus();

      state = state.copyWith(
        isVoting: false,
        quota: updatedQuota,
        lastUnlockedCount: result.unlockedSubmissionsCount,
      );

      // If feed is low, pre-fetch more cards
      if (state.feed.length <= 2) {
        final more = await _reviewRepo.getSwipeFeed(limit: 10);
        state = state.copyWith(feed: [...state.feed, ...more]);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isVoting: false, errorMessage: e.toString());
      return null;
    }
  }
}
