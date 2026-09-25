import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:vibration/vibration.dart';

import 'package:islami_app_noorify/core/storage/hive_service.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_ring_payload.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

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
/// actions both do) or its window is opened. This is what actually makes
/// the alarm ring continuously: it's driven entirely by the OS's own
/// NotificationManager, so — unlike a custom audio player — it doesn't
/// depend on `AlarmRingingScreen` ever being shown (which Android only
/// auto-launches over a *locked* screen; on an unlocked device a fired
/// alarm is otherwise just an ordinary heads-up notification that plays
/// its sound once, like the "1 second, like a notification" symptom this
/// fixes) or on any background isolate/process staying alive for minutes.
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

  /// Prayer alarms (the "Prayers Alarm" tab / Set All Alarm) live only on the
  /// server, so they're armed straight from `GET /alarms` under a stable
  /// `prayer_<type>` id — re-arming the same id replaces the previous one.
  /// [ringtoneUrls] maps ringtone id -> audio URL so the ringing screen can
  /// play the chosen adhan; without one it falls back to the bundled beep.
  static Future<void> reschedulePrayerAlarms(
    List<PrayerAlarm> prayers, {
    Map<String, String> ringtoneUrls = const {},
  }) async {
    final userSet = await userPrayerAlarmTypes();
    for (final prayer in prayers) {
      final id = 'prayer_${prayer.prayerType}';
      final time = parseClockTime12h(prayer.alarmTime);
      // The server lists every prayer (often pre-enabled by default); only
      // the ones the user picked in "Set All Alarm" may ring on this device.
      if (!userSet.contains(prayer.prayerType) ||
          !prayer.isEnabled ||
          time == null) {
        await cancelAlarm(id);
        continue;
      }
      await scheduleAlarm(
        AlarmEntry(
          id: id,
          hour: time.hour,
          minute: time.minute,
          vibrateAndRing: prayer.soundMode == 'vibrate_and_ring',
          vibrate: prayer.soundMode == 'vibrate',
          ring: prayer.soundMode == 'ring',
          enabled: true,
          label: prayer.title,
          ringtoneId: prayer.ringtoneId,
          ringtoneName: prayer.ringtoneName,
          ringtoneUrl: ringtoneUrls[prayer.ringtoneId] ?? '',
        ),
      );
    }
  }

  static const _userPrayerTypesKey = 'user_prayer_alarm_types';

  /// Prayer types (`fajr`, ...) the user explicitly set via "Set All Alarm".
  static Future<Set<String>> userPrayerAlarmTypes() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_userPrayerTypesKey) ?? const []).toSet();
  }

  /// Replaces the user's chosen prayer set; anything no longer in it is
  /// disarmed on the next [reschedulePrayerAlarms].
  static Future<void> saveUserPrayerAlarmTypes(List<String> types) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_userPrayerTypesKey, types);
  }

  static Future<void> scheduleAlarm(AlarmEntry alarm) => _schedule(
    AlarmRingPayload.fromEntity(alarm),
    _nextOccurrence(alarm.hour, alarm.minute),
    chain: true,
  );

  /// Disarms every alarm this device knows about — the cached custom alarms
  /// and the user-picked prayer alarms — and forgets them. Used on logout and
  /// for a signed-out (guest) session: OS-level alarms re-arm themselves daily
  /// and survive reboots, so they'd otherwise keep ringing for whoever uses
  /// the app next. Main isolate only (reads Hive).
  static Future<void> cancelAllAlarms() async {
    final ids = <String>{};
    try {
      final box = HiveService.alarms;
      ids.addAll(box.keys.map((k) => k.toString()));
      for (final type in await userPrayerAlarmTypes()) {
        ids.add('prayer_$type');
      }
      for (final id in ids) {
        try {
          await cancelAlarm(id);
        } catch (_) {}
      }
      await box.clear();
      await saveUserPrayerAlarmTypes(const []);
    } catch (_) {}
  }

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
    await _notifications.cancel(id: alarmManagerIdFor(alarmId));
    await _notifications.cancel(id: _snoozeManagerIdFor(alarmId));
    await _silenceVibration();
  }

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
  if (await _dismissedSince(payload, firedAt - _dismissEchoWindow)) return;

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
  } catch (_) {
    // Best-effort: if local storage isn't reachable here, the chain breaks
    // for this alarm; the next `AlarmScheduler.rescheduleAll` (app startup)
    // repairs it from the saved alarm list.
  }
}

/// Whether the app itself plays this alarm's chosen ringtone (rather than
/// the notification channel's built-in fallback beep).
bool _playsChosenRingtone(AlarmRingPayload payload) =>
    payload.shouldPlaySound && payload.ringtoneUrl.isNotEmpty;

/// Plays the alarm's chosen ringtone (`ringtoneUrl`, resolved from its
/// `ringtoneId`) on a loop straight from the background isolate, so the
/// selected music sounds even when `AlarmRingingScreen` never opens (an
/// unlocked phone only gets a heads-up notification). Vibrates alongside it
/// when the alarm asks for vibration. Stops once the notification is
/// dismissed (Stop/Snooze), once the ringing screen takes over, or after
/// [_maxBackgroundRing].
///
/// The notification is posted on the silent channel for these alarms, so if
/// the ringtone can't load (404, offline) it is re-posted on the beep
/// channel — the alarm never goes silent, and never plays both at once.
Future<void> _playChosenRingtone(
  FlutterLocalNotificationsPlugin plugin,
  AlarmRingPayload payload, {
  required int notificationId,
  required int firedAt,
}) async {
  if (!_playsChosenRingtone(payload)) return;

  final player = AudioPlayer();
  try {
    await player.setAndroidAudioAttributes(
      const AndroidAudioAttributes(
        usage: AndroidAudioUsage.alarm,
        contentType: AndroidAudioContentType.music,
      ),
    );
    await player.setUrl(payload.ringtoneUrl);
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
          ? _silentDetails(payload, fullScreenIntent: true)
          : _androidDetails(payload),
    ),
    payload: payload.encode(),
  );
  return plugin;
}

/// The default alarm notification: the channel's looping fallback beep (and
/// vibration) repeats via [_insistentFlags] until Stop/Snooze cancels it.
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
/// own. Used when the app plays the chosen ringtone itself (initially, with
/// [fullScreenIntent] so a locked phone still opens `AlarmRingingScreen`) and
/// for the update `AlarmRingingScreen` posts once it takes over ([groupKey]
/// tells the background player to stop). Still cancellable via Stop/Snooze.
AndroidNotificationDetails _silentDetails(
  AlarmRingPayload payload, {
  bool fullScreenIntent = false,
  String? groupKey,
}) => AndroidNotificationDetails(
  _silentChannelId,
  _channelName,
  channelDescription: _channelDescription,
  importance: Importance.max,
  priority: Priority.max,
  category: AndroidNotificationCategory.alarm,
  fullScreenIntent: fullScreenIntent,
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
