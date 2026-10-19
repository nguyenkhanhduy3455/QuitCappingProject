import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/translations.dart';
import '../../domain/review_models.dart';

class SwipeCard extends ConsumerStatefulWidget {
  final BlindReviewCard card;
  final bool isFront;
  final Function(bool isApproved) onSwiped;

  const SwipeCard({
    super.key,
    required this.card,
    required this.isFront,
    required this.onSwiped,
  });

  @override
  ConsumerState<SwipeCard> createState() => SwipeCardState();
}

class SwipeCardState extends ConsumerState<SwipeCard> with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  double _angle = 0.0;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void swipeRight() {
    _animateAndTrigger(const Offset(500, 0), true);
  }

  void swipeLeft() {
    _animateAndTrigger(const Offset(-500, 0), false);
  }

  void _animateAndTrigger(Offset targetOffset, bool isApproved) {
    _offsetAnim = Tween<Offset>(begin: _position, end: targetOffset).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _position = _offsetAnim.value;
          _angle = (_position.dx / 400) * (math.pi / 12);
        });
      });

    _animController.forward(from: 0).then((_) {
      widget.onSwiped(isApproved);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isFront) return;
    setState(() {
      _position += details.delta;
      _angle = (_position.dx / 400) * (math.pi / 12);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isFront) return;
    final threshold = MediaQuery.of(context).size.width * 0.35;

    if (_position.dx > threshold) {
      swipeRight();
    } else if (_position.dx < -threshold) {
      swipeLeft();
    } else {
      // Spring back to center
      _offsetAnim = Tween<Offset>(begin: _position, end: Offset.zero).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
      )..addListener(() {
          setState(() {
            _position = _offsetAnim.value;
            _angle = (_position.dx / 400) * (math.pi / 12);
          });
        });
      _animController.forward(from: 0);
    }
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Relative upload url from local backend
    final baseUrl = ApiEndpoints.baseUrl;
    return '$baseUrl$url';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final tr = ref.watch(translationsProvider);
    final approveOpacity = (_position.dx / 120).clamp(0.0, 1.0);
    final rejectOpacity = (-_position.dx / 120).clamp(0.0, 1.0);

    final resolvedImageUrl = _resolveImageUrl(widget.card.imageUrl);

    return Transform.translate(
      offset: _position,
      child: Transform.rotate(
        angle: _angle,
        child: GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Container(
            width: screenSize.width * 0.9,
            height: screenSize.height * 0.62,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo Evidence Display
                    Expanded(
                      flex: 6,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            resolvedImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 48, color: AppColors.textSecondary),
                              ),
                            ),
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: AppColors.surfaceVariant,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Blind Review Watermark Tag
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.visibility_off, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr.blindReviewWatermark,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Task & Evidence Prompt Description
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: AppColors.surface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.card.taskTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.card.taskDescription,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            // Concrete Proof Criteria
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.checklist, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${tr.verifyCriteriaPrefix}${widget.card.evidencePrompt}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Approve Stamp Overlay (Green)
                if (approveOpacity > 0)
                  Positioned(
                    top: 30,
                    left: 20,
                    child: Opacity(
                      opacity: approveOpacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.approve.withValues(alpha: 0.2),
                          border: Border.all(color: AppColors.approve, width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tr.approveStamp,
                          style: const TextStyle(
                            color: AppColors.approve,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Reject Stamp Overlay (Red)
                if (rejectOpacity > 0)
                  Positioned(
                    top: 30,
                    right: 20,
                    child: Opacity(
                      opacity: rejectOpacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.reject.withValues(alpha: 0.2),
                          border: Border.all(color: AppColors.reject, width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tr.rejectStamp,
                          style: const TextStyle(
                            color: AppColors.reject,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
