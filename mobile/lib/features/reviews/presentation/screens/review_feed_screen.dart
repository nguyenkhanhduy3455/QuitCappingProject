import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/translations.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../domain/review_models.dart';
import '../review_controller.dart';
import 'review_detail_screen.dart';

class ReviewFeedScreen extends ConsumerStatefulWidget {
  const ReviewFeedScreen({super.key});

  @override
  ConsumerState<ReviewFeedScreen> createState() => _ReviewFeedScreenState();
}

class _ReviewFeedScreenState extends ConsumerState<ReviewFeedScreen> {
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
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(reviewControllerProvider.notifier).loadFeed();
            await ref.read(reviewControllerProvider.notifier).refreshQuota();
          },
          color: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Give-to-Get Engine Progress Bar
              _buildGiveToGetHeader(quota, tr),

              // Queue Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${tr.reviewQueueTitle} (${state.feed.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () => ref.read(reviewControllerProvider.notifier).loadFeed(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              tr.refreshQueue,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Compact Queue List Area
              Expanded(
                child: state.isLoading && state.feed.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : state.feed.isEmpty
                        ? _buildEmptyFeedState(tr)
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24, top: 4),
                            itemCount: state.feed.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final card = state.feed[index];
                              return _buildQueueRowItem(card, tr);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGiveToGetHeader(ReviewQuotaStatus? quota, Translations tr) {
    final reviewsDone = quota?.dailyReviewsDone ?? 0;
    final target = quota?.targetQuota ?? 5;
    final isBypass = quota?.bypassQuotaActive ?? false;
    final isQuotaMet = (reviewsDone >= target) || isBypass;
    final progress = isBypass ? 1.0 : (reviewsDone / target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            isBypass
                ? tr.lowQueueBypassNotice
                : isQuotaMet
                    ? tr.quotaUnlockedDesc
                    : tr.quotaNeededDesc(target - reviewsDone),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueRowItem(BlindReviewCard card, Translations tr) {
    final resolvedImageUrl = _resolveImageUrl(card.imageUrl);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: card.isOwnSubmission
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.cardBorder,
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openReviewDetail(card),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Small Thumbnail Image (hình nhỏ)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 52,
                  height: 52,
                  color: AppColors.surfaceVariant,
                  child: Image.network(
                    resolvedImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Center(
                      child: Icon(Icons.broken_image, size: 24, color: AppColors.textSecondary),
                    ),
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Status & Reviewers Count (tên, trạng thái, số người duyệt)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.cleanTaskTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Status Badge (trạng thái)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: card.isOwnSubmission
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.inQueue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            card.isOwnSubmission ? tr.ownSubmissionShort : tr.inQueueBadge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: card.isOwnSubmission ? AppColors.primary : AppColors.inQueue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Number of Reviewers (số người duyệt)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.how_to_reg, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              tr.reviewedCount(card.totalReviews),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Open Button (Nút Mở / Xem)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: card.isOwnSubmission ? AppColors.surfaceVariant : AppColors.primary,
                  foregroundColor: card.isOwnSubmission ? AppColors.textPrimary : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () => _openReviewDetail(card),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: Text(
                  tr.openTask,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openReviewDetail(BlindReviewCard card) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReviewDetailScreen(card: card)),
    );
    if (updated == true && mounted) {
      await ref.read(reviewControllerProvider.notifier).loadFeed();
      await ref.read(reviewControllerProvider.notifier).refreshQuota();
      ref.read(authControllerProvider.notifier).refreshProfile();
    }
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final baseUrl = ApiEndpoints.baseUrl;
    return '$baseUrl$url';
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
