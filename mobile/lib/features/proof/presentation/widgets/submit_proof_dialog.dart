import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/translations.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../roadmap/domain/task_model.dart';
import '../../../roadmap/presentation/roadmap_controller.dart';
import '../../../tasks_today/presentation/today_tasks_controller.dart';
import '../../data/submission_repository.dart';

class SubmitProofDialog extends ConsumerStatefulWidget {
  final TaskModel task;

  const SubmitProofDialog({super.key, required this.task});

  @override
  ConsumerState<SubmitProofDialog> createState() => _SubmitProofDialogState();
}

class _SubmitProofDialogState extends ConsumerState<SubmitProofDialog> {
  final _picker = ImagePicker();
  File? _selectedFile;
  String? _sampleImageUrl;
  bool _isSubmitting = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() {
          _selectedFile = File(picked.path);
          _sampleImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open camera/gallery: $e')),
        );
      }
    }
  }

  void _useSampleProof() {
    setState(() {
      _selectedFile = null;
      _sampleImageUrl = 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&auto=format&fit=crop&q=80';
    });
  }

  void _submit(Translations tr) async {
    if (_selectedFile == null && _sampleImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.noPhotoSelected)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(submissionRepositoryProvider);
      final result = await repo.submitProof(
        taskId: widget.task.id,
        imageFile: _selectedFile,
        imageUrl: _sampleImageUrl,
      );

      // Refresh tasks and auth profile state
      await ref.read(roadmapControllerProvider.notifier).refreshCurrentTasks();
      await ref.read(todayTasksControllerProvider.notifier).refresh();
      await ref.read(authControllerProvider.notifier).refreshProfile();

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(result, tr);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.reject,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(SubmissionResult result, Translations tr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Row(
          children: [
            Icon(
              result.isUnlockedInQueue ? Icons.check_circle : Icons.lock_clock,
              color: result.isUnlockedInQueue ? AppColors.approve : AppColors.pending,
            ),
            const SizedBox(width: 8),
            Text(
              result.isUnlockedInQueue ? tr.proofInQueueTitle : tr.giveToGetLockedTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.rate_review, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr.reviewsTodayFormat
                          .replaceAll('{done}', '${result.dailyReviewsDone}')
                          .replaceAll('{target}', '5'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.gotIt, style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationsProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.add_a_photo, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.task.cleanTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppColors.cardBorder),
            const SizedBox(height: 8),

            // Concrete Evidence Prompt Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.visibility, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        tr.proofRequirementHeader,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.task.evidencePrompt,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Image Preview Area
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedFile != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_selectedFile!, fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                              onPressed: () => setState(() => _selectedFile = null),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _sampleImageUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(_sampleImageUrl!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                                  onPressed: () => setState(() => _sampleImageUrl = null),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              Text(
                                tr.noPhotoSelected,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
            ),
            const SizedBox(height: 16),

            // Image Source Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text(tr.camera, style: const TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: Text(tr.gallery, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Emulator / Demo shortcut button
            Center(
              child: TextButton.icon(
                onPressed: _useSampleProof,
                icon: const Icon(Icons.image, size: 16, color: AppColors.textSecondary),
                label: Text(
                  tr.demoPhoto,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Submit Proof Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submit(tr),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        tr.submitEvidenceBtn,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
