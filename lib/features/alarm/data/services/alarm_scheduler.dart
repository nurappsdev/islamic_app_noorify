import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:vibration/vibration.dart';

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/features/alarm/data/services/alarm_log.dart';
import 'package:tuhfatul_muslim/features/alarm/data/services/alarm_sync_plan.dart';
import 'package:tuhfatul_muslim/features/alarm/data/services/ringtone_cache.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/alarm_entry.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/prayer_alarm_builder.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/alarm_ring_payload.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';

// Bumped to `_v2`: on Android 8+, a channel's sound/importance are locked in
// at first creation and can't be changed by the app afterwards — only by
// deleting and recreating the channel under a new id, which is what this is.
const _channelId = 'islami_app_noorify_alarms_v2';

/// Same importance as [_channelId] but with no sound and no vibration of its
/// own: used whenever the app plays the chosen ringtone (and vibrates) itself,
/// so the channel's built-in fallback beep never sounds on top of it.
const _silentChannelId = 'islami_app_noorify_alarms_silent_v1';
const _channelName = 'Alarms';
const _channelDescription = 'Prayer and custom alarm ringtones.';
const _stopActionId = 'stop';
const _snoozeActionId = 'snooze';
const _snoozeDuration = Duration(minutes: 5);

/// How long the background isolate keeps the chosen ringtone looping if
/// nobody answers — the same cap the notification itself uses.
const _maxBackgroundRing = Duration(minutes: 5);

/// Set (via `groupKey`) on the notification once `AlarmRingingScreen` is up
/// and playing the ringtone itself, so the background player knows to stop
/// instead of playing over it.
const _ringingScreenGroup = 'ringing_screen';

/// Android's `Notification.FLAG_INSISTENT` — repeats the notification's
/// sound/vibration continuously until it's cancelled (our Stop/Snooze
/// actions both do) or the notification is opened. This is what actually
/// makes the alarm ring continuously: it's driven entirely by the OS's own
/// NotificationManager, so — unlike a custom audio player — it doesn't
/// depend on `AlarmRingingScreen` ever being opened (the notification isn't
/// a full-screen intent, so nothing auto-launches it; without this flag a
/// fired alarm would otherwise just be an ordinary heads-up notification
/// that plays its sound once, like the "1 second, like a notification"
/// symptom this fixes) or on any background isolate/process staying alive
/// for minutes.
const _insistentFlag = 4;
final _insistentFlags = Int32List.fromList(<int>[_insistentFlag]);

/// Bundled at `android/app/src/main/res/raw/alarm_fallback.wav` (a native
/// Android raw resource, separate from — but generated from the same
/// source as — `assets/audio/alarm_fallback.wav`) since a notification
/// channel's sound must be a local raw resource or content URI, never a
/// remote URL. It's what loops for [_insistentFlags]; the user's actually
/// selected ringtone still plays from `AlarmRingingScreen` whenever that
/// does get shown.
const _alarmChannelSound = RawResourceAndroidNotificationSound(
  'alarm_fallback',
);

/// The Flutter asset `just_audio` plays when the chosen ringtone isn't
/// cached locally (see [_playChosenRingtone]) — the same sound as
/// [_alarmChannelSound], just packaged for `AudioPlayer` instead of the
/// notification channel.
const _bundledFallbackAsset = 'assets/audio/alarm_fallback.wav';

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
final alarmNotificationEvents =
    StreamController<AlarmNotificationEvent>.broadcast();

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

/// FNV-1a over the id's UTF-16 code units. `String.hashCode` is not
/// guaranteed to give the same value after an app or SDK update, and a changed
/// value would leave the alarms armed under the old one impossible to cancel.
int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash;
}

/// The OS-level id of [alarmId]'s regular daily alarm. Always even, so its
/// snooze id (odd, see [_snoozeManagerIdFor]) can never be another alarm's.
int alarmManagerIdFor(String alarmId) =>
    (_stableHash(alarmId) & 0x3fffffff) << 1;

int _snoozeManagerIdFor(String alarmId) => alarmManagerIdFor(alarmId) | 1;

/// Ids earlier versions armed alarms under (`String.hashCode`). Still
/// cancelled with the current ones, so an alarm armed by an older version
/// can't outlive its deletion.
int _legacyManagerIdFor(String alarmId) => alarmId.hashCode & 0x7fffffff;
int _legacySnoozeManagerIdFor(String alarmId) =>
    (_legacyManagerIdFor(alarmId) + 1) & 0x7fffffff;

/// Schedules, cancels, and displays the alarms saved on the "All Alarm"
/// screen so they fire — with the user's selected ringtone — at the exact
/// clock time, whether the app is foregrounded, backgrounded, or killed.
///
/// Android: [AndroidAlarmManager] fires a background-isolate callback at the
/// exact wall-clock time (persisted across reboots via
/// `rescheduleOnReboot`), which shows a high-priority, alarm-category
/// notification (`Importance.max`/`Priority.max`, no full-screen intent —
/// see `_androidDetails`) that loops the ringtone/vibration via
/// `Notification.FLAG_INSISTENT` until Stop/Snooze; opening it (tap, or
/// either action) launches `AlarmRingingScreen`, which takes over playing
/// the chosen ringtone itself.
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

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: _handleResponse,
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
        playSound: true,
        sound: _alarmChannelSound,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _silentChannelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        enableVibration: false,
        playSound: false,
      ),
    );
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android => _notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Whether this device can currently schedule exact alarms. Always `true`
  /// off Android (and on Android below 12, where the permission doesn't
  /// exist). Best-effort: a failed check never blocks scheduling, since the
  /// check itself failing isn't evidence the permission is missing.
  static Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _android?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Checks exact-alarm access and, if it isn't granted, opens Android's
  /// "Alarms & reminders" settings screen so the user can grant it — the
  /// `SCHEDULE_EXACT_ALARM` permission's user-facing name since Android 13 made
  /// it user-togglable rather than install-time. Returns whether it ends up
  /// granted. Call this before scheduling so a newly enabled/created alarm is
  /// only armed once access is actually available (see [_applyPlan], which
  /// also gates on this as a safety net for every other caller).
  static Future<bool> ensureExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final android = _android;
      if (android == null) return true;
      if (await android.canScheduleExactNotifications() ?? false) return true;
      return await android.requestExactAlarmsPermission() ?? false;
    } catch (_) {
      return true;
    }
  }

  /// Logs what the OS has scheduled for this app, so an alarm the app doesn't
  /// list stands out in the log. Call once after [init].
  static Future<void> logScheduledAlarms() async {
    final held = await persistedOsAlarmIds();
    await AlarmLog.record(
      'startup',
      status: 'ok',
      detail: 'OS holds ${held.length} alarm(s): ${held.toList()..sort()}',
    );
    if (kDebugMode) {
      for (final line
          in (await AlarmLog.history()).reversed.take(20).toList()..sort()) {
        debugPrint('[Alarm][history] $line');
      }
    }
  }

  static Future<NotificationAppLaunchDetails?> launchDetails() =>
      _notifications.getNotificationAppLaunchDetails();

  static Future<void> _serial = Future<void>.value();

  /// Makes this device's OS schedule match [plan] - the alarms saved on the
  /// device - exactly: arms every alarm in it (re-arming an id replaces the
  /// previous one), disarms the ones it excludes, and finally cancels every
  /// other alarm the OS still holds for this app. That last sweep is what
  /// removes alarms nothing else remembers: ones armed by an older version, or
  /// left behind by a failed cancel.
  ///
  /// Only call this with a plan built from alarms that were read successfully:
  /// an empty plan from a failed read would disarm everything. Calls run one at
  /// a time so a late sweep can't cancel what a newer sync just armed.
  static Future<void> sync(AlarmSyncPlan plan) {
    final run = _serial.then((_) => _applyPlan(plan));
    _serial = run.catchError((Object _) {});
    return run;
  }

  static Future<void> _applyPlan(AlarmSyncPlan plan) async {
    // Disabling/deleting an alarm never needs this permission — only arming
    // a new one does — so a missing permission still lets the loop below
    // disarm and sweep normally; it just skips arming until it's granted.
    final canArm = plan.armed.isEmpty || await hasExactAlarmPermission();
    if (!canArm) {
      await AlarmLog.record(
        'arm',
        status: 'skipped',
        detail:
            'exact-alarm permission not granted; ${plan.armed.length} '
            'alarm(s) left unarmed until it is',
      );
    }

    final desired = <int, String>{}; // OS id -> alarm id
    for (final alarm in plan.armed) {
      final osId = alarmManagerIdFor(alarm.id);
      final clash = desired[osId];
      if (clash != null && clash != alarm.id) {
        // Two different ids hashing to one OS id would silently replace each
        // other; arming neither twice is safer than losing one unnoticed.
        await AlarmLog.record(
          'skip',
          id: alarm.id,
          name: alarm.label,
          status: 'id-collision',
          detail: 'shares OS id $osId with $clash',
        );
        continue;
      }
      desired[osId] = alarm.id;
      if (!canArm) continue;
      try {
        await scheduleAlarm(alarm, source: AlarmSource.backend);
      } catch (e) {
        await AlarmLog.record(
          'arm',
          id: alarm.id,
          name: alarm.label,
          source: AlarmSource.backend,
          status: 'failed',
          detail: '$e',
        );
      }
    }
    // Left exactly as they are, but not swept as unknown below.
    for (final id in plan.retained) {
      desired[alarmManagerIdFor(id)] = id;
    }
    for (final entry in plan.skipped.entries) {
      await cancelAlarm(entry.key, reason: entry.value);
    }

    // Everything else the OS holds is an alarm this device no longer has.
    for (final osId in await persistedOsAlarmIds()) {
      if (desired.containsKey(osId & ~1)) continue; // wanted, or its snooze
      await _cancelOsAlarm(osId);
      await AlarmLog.record(
        'sweep',
        status: 'cancelled',
        detail: 'OS alarm $osId is not one of the saved alarms',
      );
    }
    if (plan.duplicateTimes.isNotEmpty) {
      await AlarmLog.record(
        'warn',
        status: 'duplicate-times',
        detail: 'several alarms share ${plan.duplicateTimes.join(', ')}',
      );
    }
    await AlarmLog.record(
      'sync',
      status: 'ok',
      detail: 'armed ${desired.length}, disarmed ${plan.skipped.length}',
    );
  }

  static const _nativeChannel = MethodChannel('islami_app_noorify/alarms');

  /// The OS ids of every alarm still scheduled for this app.
  ///
  /// Android: the ids `android_alarm_manager_plus` has persisted, read
  /// natively (it has no Dart API for this). iOS: the pending notifications.
  static Future<Set<int>> persistedOsAlarmIds() async {
    try {
      if (Platform.isAndroid) {
        final ids = await _nativeChannel.invokeListMethod<int>(
          'persistedAlarmIds',
        );
        return {...?ids};
      }
      if (Platform.isIOS || Platform.isMacOS) {
        final pending = await _notifications.pendingNotificationRequests();
        return {for (final request in pending) request.id};
      }
    } catch (e) {
      await AlarmLog.record(
        'list',
        status: 'failed',
        detail: 'could not read the OS alarm list: $e',
      );
    }
    return {};
  }

  static Future<void> _cancelOsAlarm(int osId) async {
    try {
      if (Platform.isAndroid) await AndroidAlarmManager.cancel(osId);
      await _notifications.cancel(id: osId);
    } catch (_) {}
  }

  static Future<void> scheduleAlarm(
    AlarmEntry alarm, {
    AlarmSource source = AlarmSource.backend,
  }) => _schedule(
    AlarmRingPayload.fromEntity(alarm),
    _nextOccurrence(alarm.hour, alarm.minute),
    chain: true,
    source: source,
  );

  /// Disarms every alarm on this device and deletes the saved ones, custom
  /// and prayer alike.
  ///
  /// It cancels what the app knows about (the saved alarms and the prayer
  /// alarm ids) *and* every alarm the OS still holds for the app, including
  /// ones an older version armed under ids nothing remembers. Main isolate only
  /// (reads Hive).
  static Future<void> cancelAllAlarms({String reason = 'requested'}) async {
    final ids = <String>{
      for (final type in PrayerAlarmBuilder.prayerTypes)
        AlarmSyncPlan.prayerAlarmId(type),
    };
    try {
      ids.addAll(HiveService.alarms.keys.map((k) => k.toString()));
    } catch (_) {}
    for (final id in ids) {
      await cancelAlarm(id, reason: reason);
    }

    final held = await persistedOsAlarmIds();
    for (final osId in held) {
      await _cancelOsAlarm(osId);
    }
    try {
      await _notifications.cancelAll(); // ringing / pending notifications
    } catch (_) {}
    await _silenceVibration();
    try {
      await HiveService.alarms.clear();
      await HiveService.prayerAlarms.clear();
    } catch (_) {}

    await AlarmLog.record(
      'cancel-all',
      status: 'ok',
      detail: '$reason; ${ids.length} known, ${held.length} held by the OS',
    );
  }

  /// Disarms one alarm: its daily schedule and any pending snooze, under both
  /// the current and the pre-update id scheme, plus their notifications.
  static Future<void> cancelAlarm(
    String alarmId, {
    String reason = 'requested',
  }) async {
    var ok = true;
    for (final id in {
      alarmManagerIdFor(alarmId),
      _snoozeManagerIdFor(alarmId),
      _legacyManagerIdFor(alarmId),
      _legacySnoozeManagerIdFor(alarmId),
    }) {
      try {
        if (Platform.isAndroid) await AndroidAlarmManager.cancel(id);
        await _notifications.cancel(id: id);
      } catch (_) {
        ok = false;
      }
    }
    await AlarmLog.record(
      'disarm',
      id: alarmId,
      status: ok ? 'cancelled' : 'failed',
      detail: reason,
    );
  }

  /// Clears whichever ringing notification is currently showing for
  /// [alarmId], without touching its underlying schedule — the regular
  /// daily recurrence is already re-armed for tomorrow by the time this is
  /// called (see [_fire]), so this is safe to call from the "Stop"/"Snooze"
  /// buttons on [AlarmRingingScreen] alone.
  /// `'stop'` / `'snooze'` for a notification action id, `null` for a plain
  /// tap on the notification body.
  static String? actionFor(String? actionId) => switch (actionId) {
    _stopActionId => 'stop',
    _snoozeActionId => 'snooze',
    _ => null,
  };

  /// Records that [payload]'s alarm was stopped/snoozed so a background
  /// ringer in another isolate stops at its next check. Call before
  /// [dismissNotification].
  static Future<void> markDismissed(AlarmRingPayload payload) =>
      _markDismissed(payload);

  static Future<void> dismissNotification(String alarmId) async {
    // Do not wait for NotificationManager before cancelling the native
    // vibration pattern. A repeating pattern may have been started by the
    // alarm-manager isolate, and notification cancellation can be delayed or
    // fail independently on some Android versions.
    final vibrationCancellation = _silenceVibration();
    try {
      await _notifications.cancel(id: alarmManagerIdFor(alarmId));
    } catch (_) {}
    try {
      await _notifications.cancel(id: _snoozeManagerIdFor(alarmId));
    } catch (_) {}
    // A notification an older version posted is under its old id.
    try {
      await _notifications.cancel(id: _legacyManagerIdFor(alarmId));
      await _notifications.cancel(id: _legacySnoozeManagerIdFor(alarmId));
    } catch (_) {}
    await vibrationCancellation;
  }

  /// Immediately cancels the process-wide native vibration pattern.
  ///
  /// This is deliberately separate from notification cleanup so a ringing
  /// screen can stop haptics and a background-isolate vibration without
  /// waiting for storage or NotificationManager calls to finish.
  static Future<void> stopVibration() => _silenceVibration();

  /// Vibration is a process-wide native service, so this also cuts off the
  /// repeating pattern the background ringer started in its own isolate —
  /// instantly, rather than at its next once-a-second check.
  static Future<void> _silenceVibration() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  /// Stops the notification's own [_insistentFlags] repeat once
  /// [AlarmRingingScreen] is up and playing the user's actual chosen
  /// ringtone itself, so the fallback beep and the real ringtone don't
  /// overlap. The notification stays visible/cancellable either way.
  static Future<void> muteInsistentNotification(AlarmRingPayload payload) =>
      _notifications.show(
        id: alarmManagerIdFor(payload.alarmId),
        title: payload.label.isEmpty ? 'Alarm' : payload.label,
        body: _timeLabel(payload.hour, payload.minute),
        notificationDetails: NotificationDetails(
          android: _silentDetails(payload, groupKey: _ringingScreenGroup),
        ),
        payload: payload.encode(),
      );

  static Future<void> snooze(
    AlarmRingPayload payload, [
    Duration delay = _snoozeDuration,
  ]) => _schedule(
    payload,
    DateTime.now().add(delay),
    chain: false,
    source: AlarmSource.local,
  );

  static Future<void> _schedule(
    AlarmRingPayload payload,
    DateTime at, {
    required bool chain,
    required AlarmSource source,
  }) async {
    final id = chain
        ? alarmManagerIdFor(payload.alarmId)
        : _snoozeManagerIdFor(payload.alarmId);
    if (Platform.isAndroid) {
      final ok = await AndroidAlarmManager.oneShotAt(
        at,
        id,
        chain ? alarmFiredCallback : alarmSnoozeFiredCallback,
        alarmClock: true,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: chain,
        params: payload.toJson(),
      );
      await AlarmLog.record(
        chain ? 'arm' : 'snooze',
        id: payload.alarmId,
        name: payload.label,
        at: at,
        source: source,
        status: ok ? 'ok' : 'failed',
        detail: 'os=$id',
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
      await AlarmLog.record(
        chain ? 'arm' : 'snooze',
        id: payload.alarmId,
        name: payload.label,
        at: at,
        source: source,
        status: 'ok',
        detail: 'os=$id',
      );
    }
  }
}

/// Fallback for a Stop/Snooze press that reaches the background isolate
/// instead of the UI (the notification actions normally open the app — see
/// [_notificationActions]). Async and fully awaited so the short-lived
/// isolate isn't torn down before the work is done.
@pragma('vm:entry-point')
Future<void> _onBackgroundResponse(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final payload = AlarmRingPayload.tryDecode(response.payload);
  if (payload == null) return;
  final notifId = response.id ?? alarmManagerIdFor(payload.alarmId);
  switch (response.actionId) {
    case _stopActionId:
      await _cancelRinging(payload, notifId);
      break;
    case _snoozeActionId:
      // Schedule the re-ring first: it's what matters most if anything
      // below fails.
      try {
        await AlarmScheduler.snooze(payload);
      } catch (_) {}
      await _cancelRinging(payload, notifId);
      break;
  }
}

/// Main-isolate handler for a notification tap or action press. It only
/// relays the request: `main.dart` opens `AlarmRingingScreen` (the screen
/// whose Stop/Snooze are known to silence the alarm) and it does the work.
void _handleResponse(NotificationResponse response) {
  final payload = AlarmRingPayload.tryDecode(response.payload);
  if (payload == null) return;
  alarmNotificationEvents.add(
    AlarmNotificationEvent(
      payload,
      AlarmScheduler.actionFor(response.actionId) ?? 'open',
    ),
  );
}

/// Removes the ringing notification (which is what the background ringer
/// watches for to stop its music) and cuts the vibration.
Future<void> _cancelRinging(AlarmRingPayload payload, int notifId) async {
  await _markDismissed(payload);
  try {
    await _notifications.cancel(id: notifId);
    await AlarmScheduler.dismissNotification(payload.alarmId);
  } catch (_) {}
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
  await AlarmLog.record(
    'fire',
    id: payload.alarmId,
    name: payload.label,
    at: DateTime.now(),
    source: chain ? AlarmSource.backend : AlarmSource.local,
    status: 'triggered',
    detail:
        'set for ${payload.hour.toString().padLeft(2, '0')}:'
        '${payload.minute.toString().padLeft(2, '0')}, os=$id',
  );

  // No Hive lookup here: this runs in a background isolate where Hive was
  // never opened, so reading the saved list always failed and the old
  // "fail closed" check silently swallowed every alarm (no sound). Deleting
  // or disabling an alarm cancels its OS schedule (see `cancelAlarm`), which
  // is what stops it from firing.
  final firedAt = DateTime.now().millisecondsSinceEpoch;

  // Re-arm before anything else: it must happen even when this fire is
  // skipped below or the ringing runs for minutes.
  if (chain) await _rearmDaily(id, payload);

  // Alarm callbacks are queued and run one after another, so a duplicate
  // (same time, different id) waits behind the first and would start ringing
  // the moment the user stops that one — Stop appearing to do nothing. If
  // this time was just stopped/snoozed, this is that echo: skip it.
  if (await _dismissedSince(payload, firedAt - _dismissEchoWindow)) {
    await AlarmLog.record(
      'skip',
      id: payload.alarmId,
      name: payload.label,
      status: 'echo',
      detail: 'same time was just stopped or snoozed',
    );
    return;
  }

  final plugin = await _showAlarmNotification(payload, notificationId: id);

  // Last on purpose: this keeps the callback (and so the alarm service)
  // alive while the chosen ringtone loops.
  await _playChosenRingtone(
    plugin,
    payload,
    notificationId: id,
    firedAt: firedAt,
  );
}

/// How long after a Stop/Snooze another fire of the same clock time is
/// treated as a duplicate echo rather than a real alarm.
const _dismissEchoWindow = 2 * 60 * 1000;

// Stop/Snooze can be pressed in any of three isolates (main UI, the
// notification-action isolate, the alarm isolate that's ringing), so the
// signal that stops the ringer goes through SharedPreferences — shared
// natively across them — instead of relying on notification state alone.
String _dismissKey(AlarmRingPayload payload) =>
    'alarm_dismissed_${payload.hour}_${payload.minute}';

Future<void> _markDismissed(AlarmRingPayload payload) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _dismissKey(payload),
      DateTime.now().millisecondsSinceEpoch,
    );
  } catch (_) {}
}

/// Whether [payload]'s time was stopped/snoozed at or after [sinceMs].
Future<bool> _dismissedSince(AlarmRingPayload payload, int sinceMs) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final at = prefs.getInt(_dismissKey(payload));
    return at != null && at >= sinceMs;
  } catch (_) {
    return false;
  }
}

Future<void> _rearmDaily(int id, AlarmRingPayload payload) async {
  try {
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
    await AlarmLog.record(
      'rearm',
      id: payload.alarmId,
      name: payload.label,
      at: next,
      source: AlarmSource.backend,
      status: 'ok',
      detail: 'os=$id',
    );
  } catch (e) {
    await AlarmLog.record(
      'rearm',
      id: payload.alarmId,
      name: payload.label,
      status: 'failed',
      detail: '$e',
    );
    // Best-effort: if local storage isn't reachable here, the chain breaks
    // for this alarm; the next `syncLocalAlarms` (app startup)
    // repairs it from the saved alarm list.
  }
}

/// Whether the app itself plays this alarm's chosen ringtone (rather than
/// the notification channel's built-in fallback beep).
bool _playsChosenRingtone(AlarmRingPayload payload) =>
    payload.shouldPlaySound && payload.ringtoneUrl.isNotEmpty;

/// Plays the alarm's chosen ringtone on a loop straight from the background
/// isolate, so the selected music sounds even when `AlarmRingingScreen`
/// never opens (an unlocked phone only gets a heads-up notification).
/// Vibrates alongside it when the alarm asks for vibration. Stops once the
/// notification is dismissed (Stop/Snooze), once the ringing screen takes
/// over, or after [_maxBackgroundRing].
///
/// Plays from [RingtoneCache]'s local copy of `ringtoneId` — never streams
/// `ringtoneUrl` at fire time, since the exact moment an alarm fires (often
/// a pre-dawn Fajr, with the network possibly asleep or absent) is the worst
/// possible time to depend on a network request. When nothing is cached
/// (the selection's download never finished, or the file was cleared), the
/// bundled [_bundledFallbackAsset] plays instead — the alarm is never
/// silent and never waits on the network.
///
/// The notification is posted on the silent channel for these alarms, so if
/// even that somehow throws, it is re-posted on the beep channel — the
/// alarm never goes silent, and never plays both at once.
Future<void> _playChosenRingtone(
  FlutterLocalNotificationsPlugin plugin,
  AlarmRingPayload payload, {
  required int notificationId,
  required int firedAt,
}) async {
  if (!_playsChosenRingtone(payload)) return;

  final cached = await RingtoneCache.cachedFile(payload.ringtoneId);
  final player = AudioPlayer();
  try {
    await player.setAndroidAudioAttributes(
      const AndroidAudioAttributes(
        usage: AndroidAudioUsage.alarm,
        contentType: AndroidAudioContentType.music,
      ),
    );
    if (cached != null) {
      await player.setFilePath(cached.path);
    } else {
      await player.setAsset(_bundledFallbackAsset);
    }
    await player.setLoopMode(LoopMode.one);
    await player.setVolume(1);
    // Stop/Snooze may have landed while the ringtone was still loading.
    if (await _dismissedSince(payload, firedAt)) {
      await player.dispose();
      return;
    }
    unawaited(player.play());
  } catch (_) {
    await player.dispose();
    await plugin.show(
      id: notificationId,
      title: payload.label.isEmpty ? 'Alarm' : payload.label,
      body: _timeLabel(payload.hour, payload.minute),
      notificationDetails: NotificationDetails(
        android: _androidDetails(payload),
      ),
      payload: payload.encode(),
    );
    return;
  }

  var vibrating = false;
  try {
    if (payload.shouldVibrate && await Vibration.hasVibrator()) {
      // repeat: 0 loops the pattern until cancelled.
      await Vibration.vibrate(pattern: [0, 800, 600], repeat: 0);
      vibrating = true;
    }

    final deadline = DateTime.now().add(_maxBackgroundRing);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (await _dismissedSince(payload, firedAt)) break;
      final active = await plugin.getActiveNotifications();
      final mine = active.where((n) => n.id == notificationId).firstOrNull;
      if (mine == null || mine.groupKey == _ringingScreenGroup) break;
    }
  } catch (_) {
    // Fall through to cleanup.
  } finally {
    if (vibrating) await Vibration.cancel();
    await player.stop();
    await player.dispose();
  }
}

Future<FlutterLocalNotificationsPlugin> _showAlarmNotification(
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
    notificationDetails: NotificationDetails(
      android: _playsChosenRingtone(payload)
          ? _silentDetails(payload)
          : _androidDetails(payload),
    ),
    payload: payload.encode(),
  );
  return plugin;
}

/// The default alarm notification: the channel's looping fallback beep (and
/// vibration) repeats via [_insistentFlags] until Stop/Snooze cancels it.
///
/// Deliberately not a full-screen intent (`USE_FULL_SCREEN_INTENT` is no
/// longer declared — see `AndroidManifest.xml` — since Play policy reserves
/// it for a narrow set of app categories): `Importance.max` + `Priority.max`
/// + `AndroidNotificationCategory.alarm` is enough for a heads-up alarm
/// notification that bypasses Do Not Disturb on supported devices. Opening
/// it (tap, or the Stop/Snooze actions) still reaches `AlarmRingingScreen`
/// via [alarmNotificationEvents] / `main.dart`.
AndroidNotificationDetails _androidDetails(AlarmRingPayload payload) =>
    AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      playSound: payload.shouldPlaySound,
      sound: _alarmChannelSound,
      enableVibration: payload.shouldVibrate,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      // Repeats the sound/vibration above until Stop/Snooze cancels the
      // notification — see [_insistentFlags].
      additionalFlags: payload.shouldPlaySound || payload.shouldVibrate
          ? _insistentFlags
          : null,
      // Safety cap so an unanswered alarm doesn't ring forever: auto-clears
      // after 5 minutes, comfortably past the couple of minutes it should
      // take someone to respond.
      timeoutAfter: 5 * 60 * 1000,
      actions: _notificationActions,
    );

/// Same notification on the silent channel: no beep, no vibration of its
/// own. Used when the app plays the chosen ringtone itself (initially, and
/// for the update `AlarmRingingScreen` posts once it takes over — [groupKey]
/// tells the background player to stop). Still cancellable via Stop/Snooze;
/// see [_androidDetails] for why this isn't a full-screen intent either.
AndroidNotificationDetails _silentDetails(
  AlarmRingPayload payload, {
  String? groupKey,
}) => AndroidNotificationDetails(
  _silentChannelId,
  _channelName,
  channelDescription: _channelDescription,
  importance: Importance.max,
  priority: Priority.max,
  category: AndroidNotificationCategory.alarm,
  ongoing: true,
  autoCancel: false,
  onlyAlertOnce: true,
  visibility: NotificationVisibility.public,
  playSound: false,
  enableVibration: false,
  groupKey: groupKey,
  timeoutAfter: 5 * 60 * 1000,
  actions: _notificationActions,
);

const _notificationActions = [
  AndroidNotificationAction(
    _stopActionId,
    'Stop',
    cancelNotification: true,
    showsUserInterface: true,
  ),
  AndroidNotificationAction(
    _snoozeActionId,
    'Snooze',
    cancelNotification: true,
    showsUserInterface: true,
  ),
];

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
