import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/translations.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../review_controller.dart';
import '../widgets/swipe_card.dart';
import '../../domain/review_models.dart';

class ReviewFeedScreen extends ConsumerStatefulWidget {
  const ReviewFeedScreen({super.key});

  @override
  ConsumerState<ReviewFeedScreen> createState() => _ReviewFeedScreenState();
}

class _ReviewFeedScreenState extends ConsumerState<ReviewFeedScreen> {
  final GlobalKey<SwipeCardState> _currentCardKey = GlobalKey<SwipeCardState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewControllerProvider);
    final tr = ref.watch(translationsProvider);
    final quota = state.quota;

    // Listen for Give-to-Get unlocked celebration
    ref.listen<ReviewState>(reviewControllerProvider, (prev, next) {
      if (next.lastUnlockedCount > 0 && mounted) {
        _showUnlockedCelebration(next.lastUnlockedCount, tr);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.communityPeerReview),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: tr.antiCheatRulesTitle,
            onPressed: () => _showRulesDialog(context, tr),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: tr.refreshQueue,
            onPressed: () => ref.read(reviewControllerProvider.notifier).loadFeed(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Give-to-Get Engine Progress Bar
            _buildGiveToGetHeader(quota, tr),

            // Swipe Deck Area
            Expanded(
              child: state.isLoading && state.feed.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : state.feed.isEmpty
                      ? _buildEmptyFeedState(tr)
                      : _buildSwipeDeck(state),
            ),

            // Bottom Action Buttons
            if (state.feed.isNotEmpty) _buildBottomActionButtons(state),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildGiveToGetHeader(ReviewQuotaStatus? quota, Translations tr) {
    final reviewsDone = quota?.dailyReviewsDone ?? 0;
    final target = quota?.targetQuota ?? 5;
    final isQuotaMet = reviewsDone >= target;
    final progress = (reviewsDone / target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isQuotaMet ? AppColors.approve.withValues(alpha: 0.5) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isQuotaMet ? Icons.verified : Icons.lock_clock,
                size: 20,
                color: isQuotaMet ? AppColors.approve : AppColors.pending,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isQuotaMet ? tr.giveToGetUnlockedHeader : tr.giveToGetEngineTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isQuotaMet ? AppColors.approve : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                tr.reviewsTodayFormat
                    .replaceAll('{done}', '$reviewsDone')
                    .replaceAll('{target}', '$target'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                isQuotaMet ? AppColors.approve : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isQuotaMet ? tr.quotaUnlockedDesc : tr.quotaNeededDesc(target - reviewsDone),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeDeck(ReviewState state) {
    final cards = state.feed;
    final frontCard = cards.first;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background card (peeking through)
          if (cards.length > 1)
            Transform.scale(
              scale: 0.94,
              child: Opacity(
                opacity: 0.6,
                child: SwipeCard(
                  key: ValueKey(cards[1].submissionId),
                  card: cards[1],
                  isFront: false,
                  onSwiped: (_) {},
                ),
              ),
            ),

          // Front interactive card
          SwipeCard(
            key: _currentCardKey,
            card: frontCard,
            isFront: true,
            onSwiped: (isApproved) {
              ref.read(reviewControllerProvider.notifier).submitVote(
                    card: frontCard,
                    isApproved: isApproved,
                  );
              ref.read(authControllerProvider.notifier).refreshProfile();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButtons(ReviewState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reject Button (Swipe Left)
          InkWell(
            onTap: () {
              _currentCardKey.currentState?.swipeLeft();
            },
            borderRadius: BorderRadius.circular(36),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.reject, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.reject.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: AppColors.reject, size: 32),
            ),
          ),

          // Approve Button (Swipe Right)
          InkWell(
            onTap: () {
              _currentCardKey.currentState?.swipeRight();
            },
            borderRadius: BorderRadius.circular(36),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.approve, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.approve.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: AppColors.approve, size: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeedState(Translations tr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.all_inclusive, size: 54, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Text(
              tr.queueCaughtUpTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr.queueCaughtUpDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ref.read(reviewControllerProvider.notifier).loadFeed(),
              icon: const Icon(Icons.refresh),
              label: Text(tr.refreshQueue),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlockedCelebration(int count, Translations tr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.approve, width: 1.5),
        ),
        title: Row(
          children: [
            const Text('🎉 ', style: TextStyle(fontSize: 24)),
            Expanded(
              child: Text(
                tr.quotaMetCelebrationTitle,
                style: const TextStyle(color: AppColors.approve, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          tr.quotaMetCelebrationBody(count),
          style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.letsGo),
          ),
        ],
      ),
    );
  }

  void _showRulesDialog(BuildContext context, Translations tr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr.antiCheatRulesTitle),
        content: Text(
          tr.rulesContent,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.understood, style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
