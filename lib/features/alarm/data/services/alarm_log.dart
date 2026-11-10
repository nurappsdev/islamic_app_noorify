import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where an armed alarm came from.
enum AlarmSource {
  /// The user's saved alarms and prayer alarms from `GET /alarms`. Nothing is
  /// generated on the device: the server list is what gets armed.
  backend,

  /// Created on the device itself, e.g. the 5-minute snooze.
  local,
}

/// One line per alarm lifecycle event - armed, disarmed, triggered, skipped,
/// swept - so an unexpected ring can be traced afterwards.
///
/// Lines go to the console (`adb logcat -s flutter | grep "\[Alarm\]"`) and to
/// a short history in SharedPreferences, which - unlike the console - is also
/// written by the alarm-manager isolate that runs when an alarm fires. Read it
/// back with [history].
class AlarmLog {
  const AlarmLog._();

  static const _historyKey = 'alarm_debug_log';
  static const _maxLines = 150;

  /// Records [event] (e.g. `arm`, `disarm`, `fire`, `skip`, `sweep`).
  ///
  /// [id] is the alarm's own id (`prayer_fajr`, a server id), [name] its
  /// label, [at] the time it is set to trigger, and [status] the outcome
  /// (`ok`, `failed`, `replaced`, ...).
  static Future<void> record(
    String event, {
    String? id,
    String? name,
    DateTime? at,
    AlarmSource? source,
    String? status,
    String? detail,
  }) async {
    final line = [
      DateTime.now().toIso8601String(),
      event,
      if (id != null) 'id=$id',
      if (name != null && name.isNotEmpty) 'name="$name"',
      if (at != null) 'at=${at.toIso8601String()}',
      if (source != null) 'source=${source.name}',
      if (status != null) 'status=$status',
      if (detail != null) detail,
    ].join(' | ');
    debugPrint('[Alarm] $line');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // another isolate may have written since
      final lines = prefs.getStringList(_historyKey) ?? <String>[];
      lines.add(line);
      if (lines.length > _maxLines) {
        lines.removeRange(0, lines.length - _maxLines);
      }
      await prefs.setStringList(_historyKey, lines);
    } catch (_) {
      // Logging must never break an alarm.
    }
  }

  /// The most recent events, oldest first.
  static Future<List<String>> history() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return prefs.getStringList(_historyKey) ?? const [];
    } catch (_) {
      return const [];
    }
  }
}
