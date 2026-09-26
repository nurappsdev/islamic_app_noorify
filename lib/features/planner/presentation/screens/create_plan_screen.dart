import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/presentation/bloc/create_quiz_plan_bloc.dart';
import 'package:islami_app_noorify/features/planner/presentation/quiz_plan_failure_message.dart';
import 'package:islami_app_noorify/features/planner/presentation/widgets/quiz_plan_widgets.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_category.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_failure_message.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_status_view.dart';

/// How many quizzes of one category can be added at once.
const _quizCountChoices = [1, 2, 3, 4, 5];

/// Questions per quiz on offer, limited to what the category holds.
const _questionCountChoices = [5, 10, 15, 20, 25, 30];

/// Create-plan form (`POST /quizzes/plans`). Pops with the server's plan once
/// created. Expects a [CreateQuizPlanBloc] above it.
class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _planNameController = TextEditingController();
  DateTime? _schedule;
  QuizCategory? _category;
  int? _quizCount;
  int? _questionCount;

  /// The added quizzes are shown instead of the form, as designed; Add More
  /// returns to the form.
  bool _showingAdded = false;

  @override
  void dispose() {
    _planNameController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// The quiz filled in on the form, or `null` while it is incomplete.
  QuizPlanPortionDraft? get _selection {
    final category = _category;
    final quizCount = _quizCount;
    final questionCount = _questionCount;
    if (category == null || quizCount == null || questionCount == null) {
      return null;
    }
    return QuizPlanPortionDraft(
      categoryId: category.id,
      categoryName: category.name,
      quizCount: quizCount,
      questionCount: questionCount,
    );
  }

  /// What the form still needs before its quiz can be added.
  String _missingMessage(AppText appText) => _category == null
      ? appText.selectCategoryFirst
      : (_quizCount == null
            ? appText.numberOfQuizzes
            : appText.questionsPerQuiz);

  void _add() {
    final appText = AppText.readOf(context);
    final selection = _selection;
    if (selection == null) {
      _snack(_missingMessage(appText));
      return;
    }
    context.read<CreateQuizPlanBloc>().add(AddQuizPlanPortion(selection));
    setState(() {
      _category = null;
      _quizCount = null;
      _questionCount = null;
      _showingAdded = true;
    });
  }

  void _create() {
    final appText = AppText.readOf(context);
    final state = context.read<CreateQuizPlanBloc>().state;
    if (_planNameController.text.trim().isEmpty) {
      _snack(appText.planNameRequired);
      return;
    }
    // A quiz filled in but not added yet goes with the plan.
    final pending = _selection;
    if (state.portions.isEmpty && pending == null) {
      _snack(
        _category == null
            ? appText.addAtLeastOneQuiz
            : _missingMessage(appText),
      );
      return;
    }
    context.read<CreateQuizPlanBloc>().add(
      SubmitQuizPlan(
        name: _planNameController.text,
        scheduledAt: _schedule,
        pending: pending,
      ),
    );
  }

  Future<void> _pickCategory(List<QuizCategory> categories) async {
    final picked = await _pick<QuizCategory>(
      categories,
      (c) =>
          '${context.localized(c.name)} '
          '(${context.localized(c.totalQuestions.text)})',
    );
    if (picked == null) return;
    setState(() {
      _category = picked;
      // Sensible defaults, so a category alone makes a complete quiz.
      _quizCount ??= _quizCountChoices.first;
      final available = _questionCountChoices
          .where((n) => n <= picked.totalQuestions.value)
          .toList();
      // A count the new category cannot supply is replaced.
      if (_questionCount == null ||
          _questionCount! > picked.totalQuestions.value) {
        _questionCount = available.contains(10)
            ? 10
            : (available.isEmpty ? null : available.last);
      }
    });
  }

  Future<T?> _pick<T>(List<T> items, String Function(T) label) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: context.surfaceColor(Colors.white),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final item in items)
              ListTile(
                title: Text(label(item)),
                onTap: () => Navigator.pop(sheetContext, item),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocConsumer<CreateQuizPlanBloc, CreateQuizPlanState>(
      listenWhen: (a, b) =>
          a.submitSerial != b.submitSerial || a.created != b.created,
      listener: (context, state) {
        final created = state.created;
        if (created != null) {
          Navigator.of(context).pop(created);
        } else if (state.submitFailure != null) {
          _snack(
            quizPlanFailureMessage(
              AppText.readOf(context),
              state.submitFailure,
              QuizPlanAction.create,
            ),
          );
        }
      },
      builder: (context, state) {
        final Widget body;
        if (_showingAdded && state.portions.isNotEmpty) {
          body = _AddedQuizView(
            planName: _planNameController.text.trim(),
            portions: state.portions,
            onRemove: (i) => context.read<CreateQuizPlanBloc>().add(
              RemoveQuizPlanPortion(i),
            ),
            onAddMore: () => setState(() => _showingAdded = false),
          );
        } else {
          switch (state.categoriesStatus) {
            case CreateQuizPlanCategoriesStatus.loading:
              body = const Center(child: CircularProgressIndicator());
            case CreateQuizPlanCategoriesStatus.failure:
              body = QuizStatusView(
                message: quizFailureMessage(appText, state.categoriesFailure),
                onRetry: () => context.read<CreateQuizPlanBloc>().add(
                  const LoadQuizPlanCategories(),
                ),
              );
            case CreateQuizPlanCategoriesStatus.success:
              final questionChoices = _questionCountChoices
                  .where(
                    (n) =>
                        _category == null ||
                        n <= _category!.totalQuestions.value,
                  )
                  .toList();
              body = _PlanForm(
                controller: _planNameController,
                schedule: _schedule,
                onPickSchedule: () async {
                  final picked = await pickQuizPlanSchedule(context, _schedule);
                  if (picked != null) setState(() => _schedule = picked);
                },
                onClearSchedule: () => setState(() => _schedule = null),
                category: _category == null
                    ? null
                    : context.localized(_category!.name),
                quizCount: _quizCount,
                questionCount: _questionCount,
                onPickCategory: () => _pickCategory(state.categories),
                onPickQuizCount: () async {
                  final n = await _pick<int>(
                    _quizCountChoices,
                    (n) => context.localizedDigits('$n'),
                  );
                  if (n != null) setState(() => _quizCount = n);
                },
                onPickQuestionCount: questionChoices.isEmpty
                    ? null
                    : () async {
                        final n = await _pick<int>(
                          questionChoices,
                          (n) => context.localizedDigits('$n'),
                        );
                        if (n != null) setState(() => _questionCount = n);
                      },
                onAdd: _add,
                addedCount: state.portions.length,
                onShowAdded: () => setState(() => _showingAdded = true),
              );
          }
        }
        return Scaffold(
          backgroundColor: context.pageColor(Colors.white),
          body: SafeArea(
            child: Column(
              children: [
                _CreatePlanHeader(onBack: () => Navigator.of(context).pop()),
                Expanded(child: body),
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 9.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: FilledButton(
                      onPressed: state.isSubmitting ? null : _create,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFA1AD59),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                      ),
                      child: state.isSubmitting
                          ? SizedBox(
                              width: 20.r,
                              height: 20.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              appText.create,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CreatePlanHeader extends StatelessWidget {
  const _CreatePlanHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 19.w,
            top: 6.h,
            child: IconButton(
              onPressed: onBack,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFDFDE68),
                foregroundColor: Color(0xFF303629),
                minimumSize: Size(33.w, 33.w),
                padding: EdgeInsets.zero,
              ),
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 15.sp),
            ),
          ),
          Text(
            AppText.of(context).createPlanHeader,
            style: TextStyle(
              color: context.inkColor(Color(0xFF84945F)),
              fontSize: 18.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanForm extends StatelessWidget {
  const _PlanForm({
    required this.controller,
    required this.schedule,
    required this.onPickSchedule,
    required this.onClearSchedule,
    required this.category,
    required this.quizCount,
    required this.questionCount,
    required this.onPickCategory,
    required this.onPickQuizCount,
    required this.onPickQuestionCount,
    required this.onAdd,
    required this.addedCount,
    required this.onShowAdded,
  });

  final TextEditingController controller;
  final DateTime? schedule;
  final VoidCallback onPickSchedule;
  final VoidCallback onClearSchedule;
  final String? category;
  final int? quizCount;
  final int? questionCount;
  final VoidCallback onPickCategory;
  final VoidCallback onPickQuizCount;
  final VoidCallback? onPickQuestionCount;
  final VoidCallback onAdd;
  final int addedCount;
  final VoidCallback onShowAdded;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(15.w, 5.h, 15.w, 20.h),
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(appText.planNameLabel, style: TextStyle(fontSize: 14.sp)),
        ),
        SizedBox(height: 9.h),
        TextField(
          controller: controller,
          maxLength: 120,
          style: TextStyle(fontSize: 13.sp),
          decoration: _fieldDecoration(context, appText.writeHereHint),
        ),
        SizedBox(height: 6.h),
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(appText.scheduleLabel, style: TextStyle(fontSize: 14.sp)),
        ),
        SizedBox(height: 9.h),
        _SelectionField(
          hint: appText.notScheduled,
          value: schedule == null
              ? null
              : context.localizedDigits(
                  quizPlanScheduleLabel(appText, schedule),
                ),
          onTap: onPickSchedule,
          onClear: schedule == null ? null : onClearSchedule,
        ),
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.fromLTRB(23.w, 24.h, 23.w, 22.h),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFA1AD59)),
            borderRadius: BorderRadius.circular(27.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appText.selectQuizCategory,
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 12.h),
              _SelectionField(
                hint: appText.egQuranicScienceHint,
                value: category,
                onTap: onPickCategory,
              ),
              SizedBox(height: 16.h),
              Text(appText.numberOfQuizzes, style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              _SelectionField(
                hint: appText.numberOfQuizzes,
                value: quizCount == null
                    ? null
                    : context.localizedDigits('$quizCount'),
                onTap: onPickQuizCount,
              ),
              SizedBox(height: 16.h),
              Text(appText.questionsPerQuiz, style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              _SelectionField(
                hint: appText.questionsPerQuiz,
                value: questionCount == null
                    ? null
                    : context.localizedDigits('$questionCount'),
                onTap: onPickQuestionCount,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 14.h, right: 2.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (addedCount > 0)
                TextButton(
                  onPressed: onShowAdded,
                  child: Text(
                    context.localizedDigits(
                      '${appText.quizzesCountLabel} ($addedCount)',
                    ),
                  ),
                ),
              OutlinedButton(
                onPressed: onAdd,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFA1AD59),
                  minimumSize: Size(69.w, 38.h),
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: Color(0xFFA1AD59)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                child: Text(appText.add, style: TextStyle(fontSize: 14.sp)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration(BuildContext context, String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFB8B8B8)),
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: context.lineColor(Color(0xFFDDE8C1))),
      borderRadius: BorderRadius.circular(25.r),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFA1AD59)),
      borderRadius: BorderRadius.circular(25.r),
    ),
  );
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.hint,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String hint;

  /// The chosen value; the hint shows while it is `null`.
  final String? value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25.r),
      child: Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        decoration: BoxDecoration(
          border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value == null
                      ? const Color(0xFFB8B8B8)
                      : context.inkColor(const Color(0xFF303629)),
                  fontSize: 13.sp,
                ),
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  color: const Color(0xFFA1AD59),
                  size: 18.sp,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFFA1AD59),
                size: 22.sp,
              ),
          ],
        ),
      ),
    );
  }
}

class _AddedQuizView extends StatelessWidget {
  const _AddedQuizView({
    required this.planName,
    required this.portions,
    required this.onRemove,
    required this.onAddMore,
  });

  final String planName;
  final List<QuizPlanPortionDraft> portions;
  final ValueChanged<int> onRemove;
  final VoidCallback onAddMore;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 7.h, 16.w, 20.h),
      children: [
        if (planName.isNotEmpty) ...[
          Text(planName, style: TextStyle(fontSize: 14.sp)),
          SizedBox(height: 16.h),
        ],
        for (var i = 0; i < portions.length; i++) ...[
          _AddedQuizCard(portion: portions[i], onRemove: () => onRemove(i)),
          SizedBox(height: 8.h),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(top: 3.h, right: 1.w),
            child: OutlinedButton(
              onPressed: onAddMore,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFA1AD59),
                minimumSize: Size(99.w, 38.h),
                padding: EdgeInsets.zero,
                side: const BorderSide(color: Color(0xFFA1AD59)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: Text(
                AppText.of(context).addMore,
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddedQuizCard extends StatelessWidget {
  const _AddedQuizCard({required this.portion, required this.onRemove});

  final QuizPlanPortionDraft portion;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      height: 76.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
        borderRadius: BorderRadius.circular(21.r),
      ),
      child: Row(
        children: [
          Container(
            width: 47.w,
            height: 47.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
            ),
            child: Icon(
              Icons.image_outlined,
              color: context.inkColor(Color(0xFF8B9865)),
              size: 23.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.localized(portion.categoryName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 7.h),
                Text(
                  context.localizedDigits(
                    '${portion.quizCount} ${appText.quizzesCountLabel} · '
                    '${portion.questionCount} ${appText.questionsWord}',
                  ),
                  style: TextStyle(
                    color: const Color(0xFFA1AD59),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.close_rounded,
              size: 18.sp,
              color: context.inkColor(const Color(0xFFC15B4B)),
            ),
          ),
        ],
      ),
    );
  }
}
