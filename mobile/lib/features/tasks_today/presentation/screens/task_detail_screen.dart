import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/translations.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../proof/data/submission_repository.dart';
import '../../../roadmap/data/goal_repository.dart';
import '../../../roadmap/domain/task_model.dart';
import '../../../roadmap/presentation/roadmap_controller.dart';
import '../today_tasks_controller.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late TaskModel _task;
  final _picker = ImagePicker();
  File? _selectedFile;
  String? _sampleImageUrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

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
      _sampleImageUrl =
          'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&auto=format&fit=crop&q=80';
    });
  }

  void _submitProof(Translations tr) async {
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
        taskId: _task.id,
        imageFile: _selectedFile,
        imageUrl: _sampleImageUrl,
      );

      // Refresh providers
      await ref.read(todayTasksControllerProvider.notifier).refresh();
      await ref.read(roadmapControllerProvider.notifier).refreshCurrentTasks();
      await ref.read(authControllerProvider.notifier).refreshProfile();

      // Update local task state
      setState(() {
        _isSubmitting = false;
        _task = TaskModel(
          id: _task.id,
          goalId: _task.goalId,
          dayNumber: _task.dayNumber,
          title: _task.title,
          description: _task.description,
          evidencePrompt: _task.evidencePrompt,
          isCompleted: false,
          latestSubmission: TaskSubmissionSummary(
            id: result.submission.id,
            imageUrl: result.submission.imageUrl,
            status: result.submission.status,
            upvotes: result.submission.upvotes,
            downvotes: result.submission.downvotes,
            createdAt: result.submission.createdAt,
          ),
        );
        _selectedFile = null;
        _sampleImageUrl = null;
      });

      if (mounted) {
        _showSuccessDialog(result, tr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(tr.taskCompletedSuccessMessage)),
              ],
            ),
            backgroundColor: AppColors.approve,
            duration: const Duration(seconds: 4),
          ),
        );
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
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        title: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.approve.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.celebration, color: AppColors.approve, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              tr.taskCompletedCelebrationTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙 ', style: TextStyle(fontSize: 16)),
                  Text(
                    tr.bonusPointsBadge,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tr.taskPointsEarnedNotice,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        result.isUnlockedInQueue ? Icons.check_circle : Icons.lock_clock,
                        size: 16,
                        color: result.isUnlockedInQueue ? AppColors.approve : AppColors.pending,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          result.isUnlockedInQueue ? tr.proofInQueueTitle : tr.giveToGetLockedTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.message,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.rate_review, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tr.reviewsTodayFormat
                        .replaceAll('{done}', '${result.dailyReviewsDone}')
                        .replaceAll('{target}', '5'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr.gotIt, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(Translations tr) {
    final titleController = TextEditingController(text: _task.cleanTitle);
    final descController = TextEditingController(text: _task.description);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(tr.editTask, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.taskTitle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: titleController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(hintText: tr.taskTitleHint),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return tr.taskTitleHint;
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tr.taskDescription,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    maxLines: 3,
                    decoration: InputDecoration(hintText: tr.taskDescHint),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: Text(tr.cancel, style: const TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      try {
                        final updated = await ref.read(goalRepositoryProvider).updateTask(
                              _task.id,
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                            );
                        if (!mounted) return;
                        setState(() {
                          _task = _task.copyWith(
                            title: updated.title,
                            description: updated.description,
                            evidencePrompt: updated.evidencePrompt,
                          );
                        });
                        ref.read(todayTasksControllerProvider.notifier).refresh();
                        ref.read(roadmapControllerProvider.notifier).refreshCurrentTasks();
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr.taskUpdatedSuccess), backgroundColor: AppColors.approve),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.reject),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(tr.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationsProvider);
    final submission = _task.latestSubmission;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.taskDetail),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: tr.editTask,
            onPressed: () => _showEditTaskDialog(tr),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Task Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _task.cleanTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _task.hasSubmittedEvidence ? AppColors.textSecondary : AppColors.textPrimary,
                              decoration: _task.hasSubmittedEvidence ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(_task, tr),
                      ],
                    ),
                    if (_task.hasSubmittedEvidence) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.approve.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.approve.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: AppColors.approve),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                tr.taskCompletedSuccessMessage,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.approve,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr.dailyTasksTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _showEditTaskDialog(tr),
                          icon: const Icon(Icons.edit, size: 14, color: AppColors.primary),
                          label: Text(
                            tr.editTask,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    if (_task.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _task.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Concrete Evidence Prompt Box
            Container(
              padding: const EdgeInsets.all(16),
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
                      const Icon(Icons.camera_alt, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        tr.proofRequirementHeader,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _task.evidencePrompt,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submitted Evidence Section
            if (submission != null) ...[
              Text(
                tr.submittedEvidence,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                  color: AppColors.surfaceVariant,
                ),
                clipBehavior: Clip.antiAlias,
                child: submission.imageUrl.isNotEmpty
                    ? Image.network(
                        submission.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image, size: 48, color: AppColors.textSecondary),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 48, color: AppColors.textSecondary),
                      ),
              ),
              const SizedBox(height: 12),
              _buildSubmissionStatusNotice(submission, tr),
              const SizedBox(height: 20),
            ],

            // Submit / Retry Proof Section
            if (!_task.isCompleted && (submission == null || submission.status == 'rejected')) ...[
              Text(
                tr.submitEvidenceNow,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

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
                                const Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.textSecondary),
                                const SizedBox(height: 8),
                                Text(
                                  tr.noPhotoSelected,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
              ),
              const SizedBox(height: 14),

              // Image Source Selection Buttons
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
              const SizedBox(height: 6),
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
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: submission?.status == 'rejected' ? AppColors.reject : AppColors.primary,
                  ),
                  onPressed: _isSubmitting ? null : () => _submitProof(tr),
                  icon: _isSubmitting
                      ? const SizedBox.shrink()
                      : Icon(
                          submission?.status == 'rejected' ? Icons.replay : Icons.upload_file,
                          size: 18,
                        ),
                  label: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          submission?.status == 'rejected' ? tr.retryProof : tr.submitProof,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionStatusNotice(TaskSubmissionSummary submission, Translations tr) {
    if (submission.status == 'pending_quota') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.pending.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.pending.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_clock, size: 20, color: AppColors.pending),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr.lockedNotice,
                style: const TextStyle(fontSize: 13, color: AppColors.pending, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (submission.status == 'in_queue') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inQueue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.inQueue.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.how_to_vote, size: 20, color: AppColors.inQueue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr.inQueueNotice(submission.upvotes, submission.downvotes),
                style: const TextStyle(fontSize: 13, color: AppColors.inQueue, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (submission.status == 'rejected') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.reject.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.reject.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 20, color: AppColors.reject),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr.rejectedBadge,
                style: const TextStyle(fontSize: 13, color: AppColors.reject, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (submission.status == 'approved') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.approve.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.approve.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 20, color: AppColors.approve),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr.approvedBadge,
                style: const TextStyle(fontSize: 13, color: AppColors.approve, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatusBadge(TaskModel task, Translations tr) {
    if (task.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.approve.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: AppColors.approve),
            const SizedBox(width: 4),
            Text(
              tr.approvedBadge,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.approve),
            ),
          ],
        ),
      );
    }

    final sub = task.latestSubmission;
    if (sub == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          tr.pendingProofBadge,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
      );
    }

    switch (sub.status) {
      case 'pending_quota':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.pending.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tr.lockedBadge,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.pending),
          ),
        );
      case 'in_queue':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.inQueue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tr.inQueueBadge,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.inQueue),
          ),
        );
      case 'rejected':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.reject.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tr.rejectedBadge,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.reject),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
