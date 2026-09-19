import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_scheduler.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_ring_payload.dart';
import 'package:islami_app_noorify/features/alarm/presentation/widgets/alarm_settings_widgets.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

const _olive = Color(0xFF8D9B70);

/// Full-screen "alarm is ringing" UI. Reached either by a full-screen-intent
/// notification launching the app over the lock screen (Android), or by
/// tapping the alarm notification (any platform) — see `AlarmScheduler` and
/// `main.dart`'s wiring of `alarmNotificationEvents`/`launchDetails`.
///
/// This is the only place the selected ringtone is actually played: it loops
/// the audio and vibrates for as long as the alarm's toggles ask for, until
/// the user stops or snoozes it — from this screen's own buttons, or from
/// the notification's Stop/Snooze actions (relayed via [alarmNotificationEvents]).
/// Either action always lands back on the home screen (img_25) — see
/// [_leaveScreen].
class AlarmRingingScreen extends StatefulWidget {
  const AlarmRingingScreen({super.key, required this.payload});

  final AlarmRingPayload payload;

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  // `androidApplyAudioAttributes: false` opts this player out of following
  // the app's shared `AudioSession` (configured elsewhere, e.g. for Quran
  // recitation, as a plain "media" session) — otherwise that session's
  // config stream would silently reset this player back to the media/music
  // stream right after we set it to alarm below, and it would play on a
  // volume slider that's very likely muted or zeroed on a phone sitting
  // idle, i.e. "triggering" with no audible sound.
  final _player = AudioPlayer(androidApplyAudioAttributes: false);
  Timer? _vibrateTimer;

  /// Polls [AudioPlayer.playing] and restarts playback (from the guaranteed
  /// -good bundled asset) whenever it's found stopped — a network drop
  /// mid-stream, a remote source erroring out asynchronously after it looked
  /// like it loaded fine, or any other way [LoopMode.one] might not carry
  /// playback forward. This is what actually guarantees "keeps ringing
  /// until Stop/Snooze" rather than trusting a single playback session to
  /// never hiccup for minutes on end.
  Timer? _watchdogTimer;

  /// Safety cap so an unanswered alarm doesn't ring forever in the
  /// background — matches stock alarm-clock behaviour.
  static const _maxRingDuration = Duration(minutes: 3);
  Timer? _autoStopTimer;

  StreamSubscription<AlarmNotificationEvent>? _eventSub;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _startRinging();
    _autoStopTimer = Timer(_maxRingDuration, () {
      if (!_dismissed) _stop();
    });
    _eventSub = alarmNotificationEvents.stream.listen((event) {
      if (event.payload.alarmId != widget.payload.alarmId) return;
      if (event.action == 'stop' || event.action == 'snooze') {
        _dismiss();
      }
    });
  }

  /// Bundled locally (`assets/audio/alarm_fallback.wav`) so it always plays
  /// regardless of network state or backend content — used whenever the
  /// selected ringtone can't actually be streamed (a 404/unreachable
  /// `ringtoneUrl`, seen in practice with a couple of catalog entries whose
  /// files were never uploaded server-side; a network hiccup; or no
  /// ringtone ever having been picked), so the alarm always has *some*
  /// continuous, looping sound instead of going silent after the
  /// notification's own brief one-shot ping.
  static const _fallbackRingtoneAsset = 'assets/audio/alarm_fallback.wav';

  Future<void> _startRinging() async {
    final payload = widget.payload;
    // This screen now owns ringing (sound + vibration) itself, using the
    // user's actual chosen ringtone — stop the notification's own
    // fallback-beep repeat (see `AlarmScheduler.muteInsistentNotification`)
    // so the two don't sound at once. The notification stays up and
    // cancellable either way.
    unawaited(AlarmScheduler.muteInsistentNotification(payload));
    if (payload.shouldVibrate) {
      _vibrateTimer = Timer.periodic(
        const Duration(milliseconds: 900),
        (_) => HapticFeedback.vibrate(),
      );
    }
    if (!payload.shouldPlaySound) return;
    if (Platform.isAndroid) {
      // Routes playback to the device's alarm volume stream instead of the
      // default media stream, and bypasses Do Not Disturb the way a real
      // alarm clock does.
      await _player.setAndroidAudioAttributes(
        const AndroidAudioAttributes(
          usage: AndroidAudioUsage.alarm,
          contentType: AndroidAudioContentType.music,
        ),
      );
    }
    await _player.setVolume(1);
    final playedChosen =
        payload.ringtoneUrl.isNotEmpty &&
        await _tryLoad(() => _player.setUrl(payload.ringtoneUrl));
    if (!playedChosen) {
      await _tryLoad(() => _player.setAsset(_fallbackRingtoneAsset));
    }
    _watchdogTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _ensureStillPlaying(),
    );
  }

  Future<bool> _tryLoad(Future<Duration?> Function() load) async {
    try {
      await load();
      // Stop/Snooze may have been pressed while the source was still
      // loading — don't start playing after the fact.
      if (_dismissed) return true;
      await _player.setLoopMode(LoopMode.one);
      await _player.play();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Called every 2s while the alarm is ringing. `LoopMode.one` should keep
  /// audio going indefinitely on its own, but if playback has stopped for
  /// any reason — a dropped connection, a source that errored out after
  /// already starting, anything — this restarts it from the bundled asset,
  /// which has no external dependency and can't 404 or time out.
  Future<void> _ensureStillPlaying() async {
    if (_dismissed || !widget.payload.shouldPlaySound || _player.playing) {
      return;
    }
    await _tryLoad(() => _player.setAsset(_fallbackRingtoneAsset));
  }

  Future<void> _dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    _vibrateTimer?.cancel();
    _watchdogTimer?.cancel();
    _autoStopTimer?.cancel();
    // Never let the audio player hold the buttons hostage: `stop()` can wait
    // on a still-loading network source, which used to leave this screen
    // stuck with Stop/Snooze apparently doing nothing. Leave straight away;
    // `dispose()` releases the player either way.
    unawaited(
      _player
          .stop()
          .timeout(const Duration(seconds: 1))
          .catchError((Object _) {}),
    );
    _leaveScreen();
  }

  /// Both Stop and Snooze always land on the home screen / main bottom nav
  /// (img_25) — not just "back to wherever this was pushed from" — clearing
  /// the whole stack under it (which, on a cold launch, is the splash
  /// screen; see `RamadanSplashScreen`'s `isCurrent` guard for why that
  /// doesn't race with this screen while it's still showing).
  void _leaveScreen() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
  }

  Future<void> _stop() async {
    try {
      await AlarmScheduler.dismissNotification(widget.payload.alarmId);
    } catch (_) {
      // Still leave and stop the sound even if the notification can't be
      // cleared.
    }
    await _dismiss();
  }

  Future<void> _snooze() async {
    // Schedule the re-ring first, and guard each step so a failure in one
    // can't stop the alarm from being silenced.
    try {
      await AlarmScheduler.snooze(widget.payload);
    } catch (_) {}
    try {
      await AlarmScheduler.dismissNotification(widget.payload.alarmId);
    } catch (_) {}
    await _dismiss();
  }

  @override
  void dispose() {
    _vibrateTimer?.cancel();
    _watchdogTimer?.cancel();
    _autoStopTimer?.cancel();
    _eventSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final payload = widget.payload;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFDF8),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_alarm, size: 64.sp, color: _olive),
                SizedBox(height: 18.h),
                Text(
                  appText.alarmIsRinging,
                  style: alarmItalicStyle(16.sp, color: _olive),
                ),
                SizedBox(height: 10.h),
                Text(
                  formatPrayerTime(
                    PrayerClockTime(hour: payload.hour, minute: payload.minute),
                  ),
                  style: TextStyle(
                    fontSize: 48.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (payload.label.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(payload.label, style: alarmItalicStyle(14.sp)),
                ],
                SizedBox(height: 48.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _stop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _olive,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      appText.stopAlarm,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: OutlinedButton(
                    onPressed: _snooze,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _olive),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      appText.snoozeAlarm,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: _olive,
                      ),
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
