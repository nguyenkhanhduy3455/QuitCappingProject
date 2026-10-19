import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/translations.dart';
import '../../../tasks_today/presentation/today_tasks_controller.dart';
import '../goals_controller.dart';
import '../roadmap_controller.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  final List<String> _categories = [
    'Coding',
    'Fitness',
    'Academics',
    'Productivity',
    'Career',
  ];
  late String _selectedCategory;

  final List<String> _skillLevels = ['Beginner', 'Intermediate', 'Advanced'];
  late String _selectedSkillLevel;

  int _selectedDuration = 14;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
    _selectedSkillLevel = _skillLevels.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(roadmapControllerProvider.notifier).createGoal(
          title: _titleController.text.trim(),
          category: _selectedCategory,
          currentSkillLevel: _selectedSkillLevel,
          durationDays: _selectedDuration,
        );

    if (success && mounted) {
      ref.read(todayTasksControllerProvider.notifier).loadTodayTasks();
      ref.read(goalsControllerProvider.notifier).loadGoals();
      Navigator.pop(context);
    } else if (mounted) {
      final error = ref.read(roadmapControllerProvider).errorMessage ?? 'Failed to generate goal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.reject,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roadmapState = ref.watch(roadmapControllerProvider);
    final tr = ref.watch(translationsProvider);
    final isGenerating = roadmapState.isGenerating;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.newAiGoalTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.poweredByGemini,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tr.geminiDesc,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Target Goal Input
                Text(
                  tr.targetGoalQuestion,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: tr.targetGoalHint,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return tr.targetGoalQuestion;
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category Selection
                Text(
                  tr.category,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = cat == _selectedCategory;
                    return ChoiceChip(
                      label: Text(tr.categoryName(cat)),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Current Skill Level
                Text(
                  tr.currentSkillLevel,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: _skillLevels
                      .map((lvl) => ButtonSegment(value: lvl, label: Text(tr.skillLevelName(lvl))))
                      .toList(),
                  selected: {_selectedSkillLevel},
                  onSelectionChanged: (set) {
                    setState(() => _selectedSkillLevel = set.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary.withValues(alpha: 0.25);
                      }
                      return AppColors.surfaceVariant;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      return AppColors.textSecondary;
                    }),
                  ),
                ),
                const SizedBox(height: 20),

                // Target Duration (Days)
                Text(
                  tr.targetDuration,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [7, 14, 30].map((days) {
                    final isSelected = days == _selectedDuration;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceVariant,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.cardBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => setState(() => _selectedDuration = days),
                          child: Text(
                            '$days ${tr.daysSuffix}',
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isGenerating ? null : _submit,
                    child: isGenerating
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Text(tr.generatingText),
                            ],
                          )
                        : Text(
                            tr.generateBtn,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
