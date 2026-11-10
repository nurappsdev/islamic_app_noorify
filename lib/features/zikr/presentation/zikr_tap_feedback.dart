import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';

/// Click-and-buzz feedback for the tasbih counter: every single tap fires a
/// soft bead click (`assets/audio/zikr_click.wav`, 85 ms — a rounded mid tone
/// with no noise transient, so it reads as a muted tock rather than a sharp
/// tick) together with a 50 ms vibration — one pulse per count.
///
/// Each tap goes down **two** haptic paths on Android, because either one can
/// be silenced by device settings:
///
///  * [HapticFeedback] (`performHapticFeedback` under the hood) — does nothing
///    when the system's touch-feedback/vibration-on-tap switch is off.
///  * the `vibration` plugin, which drives the motor directly. Its native code
///    tags the effect `USAGE_ALARM`, so it survives touch feedback being off,
///    but an OEM "alarm vibration intensity = 0" can mute it instead.
///
/// They are fired in that order, so on a healthy device the stronger
/// motor pulse replaces the system tick and it still feels like one buzz.
///
/// Call [prepare] once when the counter opens — it pre-decodes the clip into a
/// small pool of players, so a tap only has to seek and play and the sound
/// lands with the finger rather than a beat later. Everything is
/// fire-and-forget and failure-tolerant: a device with no vibrator, a denied
/// audio session or a missing asset simply gives less feedback, never an error
/// in the counting path. In debug builds every step logs under
/// `[zikr-haptic]`, so a device that stays silent can be diagnosed from the
/// console. Call [dispose] with the screen.
class ZikrTapFeedback {
  ZikrTapFeedback({
    this.asset = 'assets/audio/zikr_click.wav',
    this.volume = 0.7,
  });

  final String asset;
  final double volume;

  /// Three is enough to cover taps faster than the clip is long without
  /// holding more decoders open than needed.
  static const int _poolSize = 3;

  /// Short enough to read as a tap, long enough that phone motors actually
  /// render it — below ~40 ms many devices produce nothing at all.
  static const int _tapMs = 50;

  final List<AudioPlayer> _players = <AudioPlayer>[];
  int _next = 0;
  bool _ready = false;
  bool _disposed = false;
  bool _hasVibrator = false;

  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Loads the click into the player pool and probes the vibrator. Safe to
  /// await or to leave running — taps landing before it finishes still
  /// vibrate, the probe only feeds the debug log.
  Future<void> prepare() async {
    await Future.wait<void>([_prepareAudio(), _probeVibrator()]);
  }

  Future<void> _prepareAudio() async {
    for (var i = 0; i < _poolSize; i++) {
      if (_disposed) return;
      try {
        // Never take audio focus for a tap-length click: recitation or a
        // podcast playing underneath should keep going untouched.
        final player = AudioPlayer(handleAudioSessionActivation: false);
        await player.setAsset(asset);
        await player.setVolume(volume);
        if (_disposed) {
          await player.dispose();
          return;
        }
        _players.add(player);
      } catch (error) {
        _log('click asset failed to load: $error');
        break; // Whatever loaded is enough; the rest stay silent.
      }
    }
    _ready = _players.isNotEmpty;
  }

  /// Diagnostic only — the tap path does not gate on this, since a device
  /// reporting no vibrator is exactly a device worth trying anyway.
  Future<void> _probeVibrator() async {
    if (_isIos) return;
    try {
      _hasVibrator = await Vibration.hasVibrator();
      _log('hasVibrator=$_hasVibrator');
    } catch (error) {
      _log('hasVibrator probe failed: $error');
    }
  }

  /// One counted bead: click + vibration, both fired without awaiting so the
  /// counter never waits on the platform.
  void tap() {
    _click();
    _buzz();
  }

  /// Finishing a zikr: a double pulse, no click, so completion stays
  /// distinguishable from a plain tap.
  void milestone() {
    if (_disposed) return;
    if (_isIos) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.heavyImpact();
    _vibrate(pattern: const [0, 60, 80, 120]);
  }

  /// Reset: a single, slightly softer pulse.
  void soft() {
    if (_disposed) return;
    if (_isIos) {
      HapticFeedback.lightImpact();
      return;
    }
    HapticFeedback.lightImpact();
    _vibrate(duration: 35, amplitude: 160);
  }

  void _buzz() {
    if (_disposed) return;
    if (_isIos) {
      // Core Haptics via the platform: the right feel for a per-tap tick, and
      // the `vibration` package's iOS path is a long system buzz instead.
      HapticFeedback.mediumImpact();
      return;
    }
    // First the system haptic (silent if touch feedback is off), then the
    // motor pulse, which replaces it when both are live.
    HapticFeedback.heavyImpact();
    _vibrate(duration: _tapMs, amplitude: 255);
  }

  void _click() {
    if (_disposed || !_ready) return;
    final player = _players[_next];
    _next = (_next + 1) % _players.length;
    // Rewind first: the clip is short, so a player in the pool is normally
    // parked at its end.
    player
        .seek(Duration.zero)
        .then((_) {
          if (_disposed) return;
          unawaited(player.play().catchError((_) {}));
        })
        .catchError((Object error) => _log('click failed: $error'));
  }

  void _vibrate({
    int duration = _tapMs,
    int amplitude = 255,
    List<int> pattern = const [],
  }) {
    try {
      // Amplitude is passed through as-is: the plugin's native side checks
      // `hasAmplitudeControl()` itself and falls back to the default strength.
      unawaited(
        Vibration.vibrate(
          duration: duration,
          amplitude: amplitude,
          pattern: pattern,
        ).catchError((Object error) => _log('vibrate failed: $error')),
      );
    } catch (error) {
      // Platform channel gone (hot restart, detached engine) — ignore.
      _log('vibrate threw: $error');
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[zikr-haptic] $message');
  }

  Future<void> dispose() async {
    _disposed = true;
    _ready = false;
    final players = List<AudioPlayer>.of(_players);
    _players.clear();
    for (final player in players) {
      try {
        await player.dispose();
      } catch (_) {}
    }
  }
}
