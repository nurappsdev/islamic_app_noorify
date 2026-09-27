import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_formatters.dart';

/// Route arguments for playing one portion of a started plan.
class PlannedQuizArgs {
  const PlannedQuizArgs({required this.plan, required this.portion});

  final QuizPlan plan;
  final QuizPlanPortion portion;
}

/// Route arguments for the result of a planned quiz.
class PlannedQuizResultArgs {
  const PlannedQuizResultArgs({
    required this.plan,
    required this.portion,
    required this.questions,
    required this.result,
  });

  final QuizPlan plan;
  final QuizPlanPortion portion;

  /// The questions as they were asked, for the answer review.
  final List<PlannedQuestion> questions;
  final PlannedQuizResult result;
}

/// Opens a plan's details; resolves with nothing.
Future<void> openQuizPlanDetail(BuildContext context, QuizPlan plan) =>
    Navigator.of(context).pushNamed(RouteNames.plannerDetails, arguments: plan);

/// Plays [portion] of the started [plan].
Future<void> openPlannedQuiz(
  BuildContext context,
  QuizPlan plan,
  QuizPlanPortion portion,
) => Navigator.of(context).pushNamed(
  RouteNames.plannedQuiz,
  arguments: PlannedQuizArgs(plan: plan, portion: portion),
);

/// The plan's status as the server sent it: localized when known, the raw
/// value for a status this build does not know yet.
String quizPlanStatusLabel(AppText appText, QuizPlan plan) =>
    switch (plan.status) {
      QuizPlanStatus.planned => appText.planStatusPlanned,
      QuizPlanStatus.inProgress => appText.planStatusInProgress,
      QuizPlanStatus.completed => appText.planStatusCompleted,
      QuizPlanStatus.abandoned => appText.planStatusAbandoned,
      QuizPlanStatus.unknown => plan.rawStatus.isEmpty ? '—' : plan.rawStatus,
    };

/// The schedule in the device's local time, or "Not scheduled".
String quizPlanScheduleLabel(AppText appText, DateTime? scheduledAt) =>
    scheduledAt == null
    ? appText.notScheduled
    : formatQuizDateTime(scheduledAt, appText.monthNames);

/// The portion's name: its category, numbered when the plan has several of the
/// same category.
String quizPlanPortionTitle(
  BuildContext context,
  QuizPlan plan,
  QuizPlanPortion portion,
) {
  final appText = AppText.of(context);
  final name = context.localized(portion.categoryName);
  final label = context.localizedDigits(
    fillTemplate(appText.planQuizLabel, {'number': portion.order}),
  );
  return name.isEmpty ? label : '$label ( $name )';
}

class QuizPlanStatusChip extends StatelessWidget {
  const QuizPlanStatusChip({super.key, required this.plan});

  final QuizPlan plan;

  @override
  Widget build(BuildContext context) {
    final color = switch (plan.status) {
      QuizPlanStatus.planned => const Color(0xFF84945F),
      QuizPlanStatus.inProgress => const Color(0xFF5D896D),
      QuizPlanStatus.completed => const Color(0xFF20C664),
      QuizPlanStatus.abandoned => const Color(0xFFC15B4B),
      QuizPlanStatus.unknown => const Color(0xFF929BB6),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        border: Border.all(color: context.lineColor(color)),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        quizPlanStatusLabel(AppText.of(context), plan),
        style: TextStyle(fontSize: 10.sp, color: context.inkColor(color)),
      ),
    );
  }
}

enum _PlanMenuAction { edit, abandon }

/// The ⋮ menu of a plan: Edit, and Abandon while the plan is still open.
class QuizPlanMenu extends StatelessWidget {
  const QuizPlanMenu({
    super.key,
    required this.plan,
    required this.onEdit,
    required this.onAbandon,
  });

  final QuizPlan plan;
  final VoidCallback onEdit;
  final VoidCallback onAbandon;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    const abandonColor = Color(0xFFC15B4B);
    return PopupMenuButton<_PlanMenuAction>(
      tooltip: '',
      padding: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: SizedBox(
        width: 24.w,
        height: 48.h,
        child: Icon(
          Icons.more_vert_rounded,
          color: context.inkColor(Colors.black),
          size: 20.sp,
        ),
      ),
      onSelected: (action) => switch (action) {
        _PlanMenuAction.edit => onEdit(),
        _PlanMenuAction.abandon => onAbandon(),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _PlanMenuAction.edit,
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18.sp,
                color: const Color(0xFF4C5A34),
              ),
              SizedBox(width: 10.w),
              Text(appText.planEdit),
            ],
          ),
        ),
        if (plan.canAbandon)
          PopupMenuItem(
            value: _PlanMenuAction.abandon,
            child: Row(
              children: [
                Icon(Icons.block_rounded, size: 18.sp, color: abandonColor),
                SizedBox(width: 10.w),
                Text(
                  appText.abandonPlan,
                  style: const TextStyle(color: abandonColor),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Asks before abandoning the plan called [name]. True on "Abandon".
Future<bool> showAbandonQuizPlanDialog(
  BuildContext context, {
  required String name,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final appText = AppText.of(dialogContext);
      return AlertDialog(
        backgroundColor: dialogContext.surfaceColor(Colors.white),
        title: Text(
          appText.abandonPlanQuestion,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          '$name\n\n${appText.abandonPlanNote}',
          style: TextStyle(
            fontSize: 13.sp,
            color: dialogContext.inkColor(const Color(0xFF5D6B44)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appText.planCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC15B4B),
            ),
            child: Text(appText.abandonPlan),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// Asks for a date, then a time; `null` when either is cancelled. The result
/// is in the device's local time.
Future<DateTime?> pickQuizPlanSchedule(
  BuildContext context,
  DateTime? initial,
) async {
  final now = DateTime.now();
  final start = initial ?? now.add(const Duration(hours: 1));
  final date = await showDatePicker(
    context: context,
    initialDate: start.isBefore(now) ? now : start,
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: DateTime(now.year + 5),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(start),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// Edits the fields the server lets change: the name and the schedule.
/// Resolves with only what changed, or `null` when cancelled or unchanged.
Future<QuizPlanUpdate?> showEditQuizPlanDialog(
  BuildContext context,
  QuizPlan plan,
) {
  return showDialog<QuizPlanUpdate>(
    context: context,
    builder: (_) => _EditQuizPlanDialog(plan: plan),
  );
}

class _EditQuizPlanDialog extends StatefulWidget {
  const _EditQuizPlanDialog({required this.plan});

  final QuizPlan plan;

  @override
  State<_EditQuizPlanDialog> createState() => _EditQuizPlanDialogState();
}

class _EditQuizPlanDialogState extends State<_EditQuizPlanDialog> {
  late final _name = TextEditingController(text: widget.plan.name);
  late DateTime? _schedule = widget.plan.scheduledAt;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final nameChanged = name != widget.plan.name;
    final scheduleChanged = _schedule != widget.plan.scheduledAt;
    final update = QuizPlanUpdate(
      name: nameChanged ? name : null,
      scheduledAt: scheduleChanged ? _schedule : null,
      clearSchedule: scheduleChanged && _schedule == null,
    );
    Navigator.pop(context, update.isEmpty ? null : update);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return AlertDialog(
      backgroundColor: context.surfaceColor(Colors.white),
      title: Text(
        appText.planEditTitle,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appText.planNameLabel, style: TextStyle(fontSize: 12.sp)),
          SizedBox(height: 6.h),
          TextField(
            controller: _name,
            maxLength: 120,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: appText.writeHereHint,
              errorText: _name.text.trim().isEmpty
                  ? appText.planNameRequired
                  : null,
            ),
          ),
          SizedBox(height: 8.h),
          Text(appText.scheduleLabel, style: TextStyle(fontSize: 12.sp)),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () async {
                    final picked = await pickQuizPlanSchedule(
                      context,
                      _schedule,
                    );
                    if (picked != null) setState(() => _schedule = picked);
                  },
                  child: Text(
                    context.localizedDigits(
                      quizPlanScheduleLabel(appText, _schedule),
                    ),
                  ),
                ),
              ),
              if (_schedule != null)
                TextButton(
                  onPressed: () => setState(() => _schedule = null),
                  child: Text(appText.clearLabel),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(appText.planCancel),
        ),
        FilledButton(
          onPressed: _name.text.trim().isEmpty ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFA1AD59),
          ),
          child: Text(appText.planSave),
        ),
      ],
    );
  }
}
