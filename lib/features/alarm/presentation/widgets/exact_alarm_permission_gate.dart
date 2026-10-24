import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/alarm/data/services/alarm_scheduler.dart';

const _olive = Color(0xFF8D9B70);

/// Makes sure this device may schedule exact alarms before an alarm is turned
/// on, asking for it only at that moment — never at app start.
///
/// Already granted (or nothing to grant, as off Android and on Android below
/// 12): returns `true` without showing anything. Otherwise it explains why the
/// permission is needed and offers Cancel / "Allow Permission": Cancel returns
/// `false`, while Allow opens Android's "Alarms & reminders" settings screen
/// and, once the user comes back, re-checks and returns whether it is now
/// granted. The caller only enables the alarm when this returns `true`.
///
/// [hasPermission] and [openSettings] stand in for the two [AlarmScheduler]
/// calls in tests, where no platform channel answers them.
Future<bool> ensureExactAlarmAccess(
  BuildContext context, {
  Future<bool> Function()? hasPermission,
  Future<bool> Function()? openSettings,
}) async {
  final has = hasPermission ?? AlarmScheduler.hasExactAlarmPermission;
  if (await has()) return true;
  if (!context.mounted) return false;
  final allow = await showDialog<bool>(
    context: context,
    builder: (_) => const ExactAlarmPermissionDialog(),
  );
  if (allow != true) return false;
  return (openSettings ?? AlarmScheduler.openExactAlarmSettings)();
}

/// The short "why this permission" explanation, styled like the app's other
/// alarm dialogs (see `_CustomOffsetDialog` on the Set All Alarm screen).
class ExactAlarmPermissionDialog extends StatelessWidget {
  const ExactAlarmPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return AlertDialog(
      backgroundColor: context.surfaceColor(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        appText.exactAlarmPermissionTitle,
        style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
      ),
      content: Text(
        appText.exactAlarmPermissionExplanation,
        style: TextStyle(
          fontSize: 13.sp,
          color: context.inkColor(Colors.black87),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            appText.alarmCancel,
            style: TextStyle(color: context.inkColor(Colors.black54)),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: context.surfaceColor(_olive),
            foregroundColor: Colors.white,
          ),
          child: Text(appText.exactAlarmPermissionAllow),
        ),
      ],
    );
  }
}
