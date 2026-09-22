import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

/// What the edit dialog returns: the name and the target days as typed. The
/// days are null when the field is empty or not a positive number.
typedef HadithPlanEdit = ({String name, int? targetDays});

/// Asks for a plan's new name and target days, starting from the current
/// ones. Returns the entered values on "Save", or null when cancelled.
Future<HadithPlanEdit?> showEditPlanDialog(
  BuildContext context, {
  required String name,
  int? targetDays,
}) => showDialog<HadithPlanEdit>(
  context: context,
  builder: (_) => _EditPlanDialog(name: name, targetDays: targetDays),
);

/// Asks whether to delete the plan called [name]. True on "Delete".
Future<bool> showDeletePlanDialog(
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
          appText.planDeleteQuestion,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          name,
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
            child: Text(appText.planDelete),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// Asks whether to mark the plan called [name] as complete. True on
/// "Complete".
Future<bool> showCompletePlanDialog(
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
          appText.planCompleteQuestion,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          name,
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
              backgroundColor: const Color(0xFF008000),
            ),
            child: Text(appText.planComplete),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

class _EditPlanDialog extends StatefulWidget {
  const _EditPlanDialog({required this.name, this.targetDays});

  final String name;
  final int? targetDays;

  @override
  State<_EditPlanDialog> createState() => _EditPlanDialogState();
}

class _EditPlanDialogState extends State<_EditPlanDialog> {
  late final _nameController = TextEditingController(text: widget.name);
  late final _daysController = TextEditingController(
    text: widget.targetDays?.toString() ?? '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  void _save() {
    final days = int.tryParse(_daysController.text.trim());
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      targetDays: days != null && days > 0 ? days : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    InputDecoration decoration(String hint) => InputDecoration(
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

    return AlertDialog(
      backgroundColor: context.surfaceColor(Colors.white),
      title: Text(
        appText.planEditTitle,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appText.planNameLabel, style: TextStyle(fontSize: 13.sp)),
            SizedBox(height: 8.h),
            TextField(
              key: const Key('edit-plan-name'),
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 13.sp),
              decoration: decoration(appText.writeHereHint),
            ),
            SizedBox(height: 14.h),
            Text(
              appText.planTargetDaysLabel,
              style: TextStyle(fontSize: 13.sp),
            ),
            SizedBox(height: 8.h),
            // Whole days only: digits, up to four of them.
            TextField(
              key: const Key('edit-plan-days'),
              controller: _daysController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: TextStyle(fontSize: 13.sp),
              decoration: decoration(appText.planTargetDaysHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appText.planCancel),
        ),
        FilledButton(
          // A plan needs a name.
          onPressed: _canSave ? _save : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFA1AD59),
          ),
          child: Text(appText.saveAction),
        ),
      ],
    );
  }
}
