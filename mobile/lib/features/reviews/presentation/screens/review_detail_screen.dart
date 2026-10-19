import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/translations.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../domain/review_models.dart';
import '../review_controller.dart';

class ReviewDetailScreen extends ConsumerStatefulWidget {
  final BlindReviewCard card;

  const ReviewDetailScreen({super.key, required this.card});

  @override
  ConsumerState<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends ConsumerState<ReviewDetailScreen> {
  bool _isSubmitting = false;

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final baseUrl = ApiEndpoints.baseUrl;
    return '$baseUrl$url';
  }

  Future<void> _handleVote(bool isApproved) async {
    setState(() => _isSubmitting = true);
    final tr = ref.read(translationsProvider);

    try {
      final result = await ref.read(reviewControllerProvider.notifier).submitVote(
            card: widget.card,
            isApproved: isApproved,
          );

      if (mounted) {
        ref.read(authControllerProvider.notifier).refreshProfile();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result != null ? tr.voteSubmittedSuccess : tr.taskUpdatedSuccess),
            backgroundColor: isApproved ? AppColors.approve : AppColors.reject,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.reject,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationsProvider);
    final card = widget.card;
    final resolvedImageUrl = _resolveImageUrl(card.imageUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.reviewTaskDetailTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Evidence Card
              Container(
                height: 320,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      resolvedImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 54, color: AppColors.textSecondary),
                        ),
                      ),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                          ),
                        );
                      },
                    ),

                    // Badge in top-left
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: card.isOwnSubmission ? AppColors.primary : Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              card.isOwnSubmission ? Icons.person : Icons.visibility_off,
                              size: 14,
                              color: card.isOwnSubmission ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              card.isOwnSubmission ? tr.yourSubmissionTag : tr.blindReviewWatermark,
                              style: TextStyle(
                                color: card.isOwnSubmission ? Colors.white : AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Task Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Reviewers Count Badges
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: card.isOwnSubmission
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.inQueue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: card.isOwnSubmission
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.inQueue.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            card.isOwnSubmission ? tr.ownSubmissionShort : tr.inQueueBadge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: card.isOwnSubmission ? AppColors.primary : AppColors.inQueue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.how_to_reg, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                tr.reviewedCount(card.totalReviews),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (card.upvotes > 0 || card.downvotes > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '👍 ${card.upvotes}   👎 ${card.downvotes}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Task Title
                    Text(
                      card.cleanTaskTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    if (card.taskDescription.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        card.taskDescription,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Criteria Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.checklist, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${tr.verifyCriteriaPrefix}${card.evidencePrompt}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Voting Section
              if (card.isOwnSubmission)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr.cannotReviewOwnDetail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr.reviewActionTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr.isVietnamese
                          ? 'Đánh giá công tâm giúp cộng đồng không bốc phét (+5 điểm thưởng)'
                          : 'Fair review keeps the community honest (+5 pts reward)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Reject Button
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.reject,
                              side: const BorderSide(color: AppColors.reject, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isSubmitting ? null : () => _handleVote(false),
                            icon: const Icon(Icons.close, size: 20),
                            label: Text(
                              tr.rejectButtonLabel,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Approve Button
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.approve,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            onPressed: _isSubmitting ? null : () => _handleVote(true),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check, size: 20),
                            label: Text(
                              tr.approveButtonLabel,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
