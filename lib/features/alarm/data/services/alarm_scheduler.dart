import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:islami_app_noorify/features/alarm/data/datasources/alarm_local_data_source.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_ring_payload.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

const _channelId = 'islami_app_noorify_alarms';
const _channelName = 'Alarms';
const _channelDescription = 'Prayer and custom alarm ringtones.';
const _stopActionId = 'stop';
const _snoozeActionId = 'snooze';
const _snoozeDuration = Duration(minutes: 5);

/// What to do with an [AlarmRingPayload] once a notification response comes
/// back — `open` means "bring the ringing screen to the foreground",
/// `stop`/`snooze` mirror the on-screen buttons for whoever answers from the
/// notification shade instead of the full-screen alarm UI.
class AlarmNotificationEvent {
  const AlarmNotificationEvent(this.payload, this.action);

  final AlarmRingPayload payload;
  final String action;
}

/// Broadcasts every notification tap (body or action button) handled while
/// the app's main isolate is alive. [AlarmRingingScreen] listens for
/// `stop`/`snooze` on its own alarm id (in case the user answers from the
/// notification shade instead of its own buttons); `main.dart` listens for
/// `open` to push the ringing screen for an alarm that fired while some
/// other screen was on top.
final alarmNotificationEvents = StreamController<AlarmNotificationEvent>.broadcast();

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

int alarmManagerIdFor(String alarmId) => alarmId.hashCode & 0x7fffffff;
int _snoozeManagerIdFor(String alarmId) =>
    (alarmManagerIdFor(alarmId) + 1) & 0x7fffffff;

/// Schedules, cancels, and displays the alarms saved on the "All Alarm"
/// screen so they fire — with the user's selected ringtone — at the exact
/// clock time, whether the app is foregrounded, backgrounded, or killed.
///
/// Android: [AndroidAlarmManager] fires a background-isolate callback at the
/// exact wall-clock time (persisted across reboots via
/// `rescheduleOnReboot`), which shows a full-screen-intent, alarm-category
/// notification; that notification launches `AlarmRingingScreen` — even over
/// the lock screen (see `MainActivity`'s `showWhenLocked`/`turnScreenOn`) —
/// which is what actually loops the ringtone audio.
///
/// iOS: Apple gives third-party apps no way to run code (or audio) in the
/// background at an arbitrary wall-clock time, so the OS itself fires a
/// local notification at the exact time instead; opening it plays the
/// ringtone the same way `AlarmRingingScreen` does on Android.
class AlarmScheduler {
  const AlarmScheduler._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (response) => _handleResponse(response),
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
  }

  static Future<NotificationAppLaunchDetails?> launchDetails() =>
      _notifications.getNotificationAppLaunchDetails();

  /// Called once at startup with the freshly-loaded local alarm list, so the
  /// OS-level schedule always matches what's saved — even if the app was
  /// reinstalled or the OS silently dropped a pending alarm.
  static Future<void> rescheduleAll(List<AlarmEntry> alarms) async {
    for (final alarm in alarms) {
      if (alarm.enabled) {
        await scheduleAlarm(alarm);
      } else {
        await cancelAlarm(alarm.id);
      }
    }
  }

  static Future<void> scheduleAlarm(AlarmEntry alarm) => _schedule(
    AlarmRingPayload.fromEntity(alarm),
    _nextOccurrence(alarm.hour, alarm.minute),
    chain: true,
  );

  static Future<void> cancelAlarm(String alarmId) async {
    final id = alarmManagerIdFor(alarmId);
    final snoozeId = _snoozeManagerIdFor(alarmId);
    if (Platform.isAndroid) {
      await AndroidAlarmManager.cancel(id);
      await AndroidAlarmManager.cancel(snoozeId);
    }
    await _notifications.cancel(id: id);
    await _notifications.cancel(id: snoozeId);
  }

  /// Clears whichever ringing notification is currently showing for
  /// [alarmId], without touching its underlying schedule — the regular
  /// daily recurrence is already re-armed for tomorrow by the time this is
  /// called (see [_fire]), so this is safe to call from the "Stop"/"Snooze"
  /// buttons on [AlarmRingingScreen] alone.
  static Future<void> dismissNotification(String alarmId) async {
    await _notifications.cancel(id: alarmManagerIdFor(alarmId));
    await _notifications.cancel(id: _snoozeManagerIdFor(alarmId));
  }

  static Future<void> snooze(
    AlarmRingPayload payload, [
    Duration delay = _snoozeDuration,
  ]) => _schedule(payload, DateTime.now().add(delay), chain: false);

  static Future<void> _schedule(
    AlarmRingPayload payload,
    DateTime at, {
    required bool chain,
  }) async {
    final id = chain
        ? alarmManagerIdFor(payload.alarmId)
        : _snoozeManagerIdFor(payload.alarmId);
    if (Platform.isAndroid) {
      await AndroidAlarmManager.oneShotAt(
        at,
        id,
        chain ? alarmFiredCallback : alarmSnoozeFiredCallback,
        alarmClock: true,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: chain,
        params: payload.toJson(),
      );
      return;
    }
    if (Platform.isIOS || Platform.isMacOS) {
      final scheduled = tz.TZDateTime.from(at.toUtc(), tz.UTC);
      await _notifications.zonedSchedule(
        id: id,
        title: payload.label.isEmpty ? 'Alarm' : payload.label,
        body: _timeLabel(payload.hour, payload.minute),
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(iOS: _darwinDetails(payload)),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: chain ? DateTimeComponents.time : null,
        payload: payload.encode(),
      );
    }
  }
}

@pragma('vm:entry-point')
void _onBackgroundResponse(NotificationResponse response) {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  _handleResponse(response);
}

void _handleResponse(NotificationResponse response) {
  final payload = AlarmRingPayload.tryDecode(response.payload);
  if (payload == null) return;
  final notifId = response.id ?? alarmManagerIdFor(payload.alarmId);
  switch (response.actionId) {
    case _stopActionId:
      unawaited(_notifications.cancel(id: notifId));
      alarmNotificationEvents.add(AlarmNotificationEvent(payload, 'stop'));
      break;
    case _snoozeActionId:
      unawaited(_notifications.cancel(id: notifId));
      unawaited(AlarmScheduler.snooze(payload));
      alarmNotificationEvents.add(AlarmNotificationEvent(payload, 'snooze'));
      break;
    default:
      alarmNotificationEvents.add(AlarmNotificationEvent(payload, 'open'));
  }
}

/// [AndroidAlarmManager] background-isolate entrypoint for a regular alarm.
/// Shows the ringing notification, then — if the alarm is still enabled —
/// re-arms itself 24h later so the alarm keeps repeating daily.
@pragma('vm:entry-point')
Future<void> alarmFiredCallback(int id, Map<String, dynamic> params) =>
    _fire(id, params, chain: true);

/// [AndroidAlarmManager] background-isolate entrypoint for a snoozed alarm —
/// a one-off re-ring that doesn't touch the regular daily schedule.
@pragma('vm:entry-point')
Future<void> alarmSnoozeFiredCallback(int id, Map<String, dynamic> params) =>
    _fire(id, params, chain: false);

Future<void> _fire(
  int id,
  Map<String, dynamic> params, {
  required bool chain,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final payload = AlarmRingPayload.fromJson(params);
  await _showAlarmNotification(payload, notificationId: id);

  if (!chain) return;
  try {
    final alarms = await AlarmLocalDataSourceImpl().getAlarms();
    final stillEnabled = alarms.any(
      (a) => a.id == payload.alarmId && a.enabled,
    );
    if (!stillEnabled) return;
    final next = _nextOccurrence(
      payload.hour,
      payload.minute,
      from: DateTime.now().add(const Duration(minutes: 1)),
    );
    await AndroidAlarmManager.oneShotAt(
      next,
      id,
      alarmFiredCallback,
      alarmClock: true,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: payload.toJson(),
    );
  } catch (_) {
    // Best-effort: if local storage isn't reachable here, the chain breaks
    // for this alarm; the next `AlarmScheduler.rescheduleAll` (app startup)
    // repairs it from the saved alarm list.
  }
}

Future<void> _showAlarmNotification(
  AlarmRingPayload payload, {
  required int notificationId,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await plugin.show(
    id: notificationId,
    title: payload.label.isEmpty ? 'Alarm' : payload.label,
    body: _timeLabel(payload.hour, payload.minute),
    notificationDetails: NotificationDetails(android: _androidDetails(payload)),
    payload: payload.encode(),
  );
}

AndroidNotificationDetails _androidDetails(AlarmRingPayload payload) =>
    AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      playSound: payload.shouldPlaySound,
      enableVibration: payload.shouldVibrate,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      // Auto-clears after 10 minutes so a missed/unanswered alarm doesn't
      // linger in the shade forever.
      timeoutAfter: 10 * 60 * 1000,
      actions: const [
        AndroidNotificationAction(
          _stopActionId,
          'Stop',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          _snoozeActionId,
          'Snooze',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

DarwinNotificationDetails _darwinDetails(AlarmRingPayload payload) =>
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: payload.shouldPlaySound,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

DateTime _nextOccurrence(int hour, int minute, {DateTime? from}) {
  final now = from ?? DateTime.now();
  var target = DateTime(now.year, now.month, now.day, hour, minute);
  if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
  return target;
}

String _timeLabel(int hour, int minute) =>
    formatPrayerTime(PrayerClockTime(hour: hour, minute: minute));
