import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Set once in `main()` via [AudioService.init], before any ayah/surah bloc
/// is created.
late QuranAudioHandler quranAudioHandler;

/// `MediaControl.stop`'s custom-action name on Android 13+ — see
/// [QuranAudioHandler._stopControl] for why Stop uses this instead.
const _stopActionName = 'quran_stop';

/// A play/pause/stop/skip request from outside the app's own buttons: the
/// notification, the lock screen, a headset or car, or the system (a call,
/// unplugged headphones). Playback blocs follow these so their state always
/// matches what is heard.
enum QuranAudioCommand { play, pause, stop, next, previous }

/// The app's single audio engine for Quran recitation (both single-ayah
/// preview and continuous full-surah playback share this one player).
/// Registering it with `audio_service` gives it a real Android foreground
/// service + notification and an iOS background-audio session, so playback
/// keeps going when the app is minimized, backgrounded, or the screen is
/// locked, with play/pause reachable from the lock screen/notification.
///
/// The audio session is configured for music (on iOS: plays with the silent
/// switch on and the screen locked), and interruptions are handled here
/// rather than inside the player, so they go through [play]/[pause] and are
/// announced on [commands] like any other request: a call or another app's
/// audio pauses recitation (resuming after a temporary one), a notification
/// ducks it, and unplugging headphones pauses it.
class QuranAudioHandler extends BaseAudioHandler {
  QuranAudioHandler() {
    unawaited(_configureSession());
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object error, StackTrace stackTrace) {},
    );
    // just_audio only guarantees playbackEventStream fires on *processing*
    // transitions (loading/buffering/ready/...), not on a bare play()/pause()
    // toggle — confirmed on a real device: without this, the notification's
    // Play/Pause button froze on whatever it showed during the initial load
    // and never flipped to Pause once playback actually started. Mirrors
    // audio_service's own example, which does the same for properties
    // `playbackEventStream` doesn't cover (there: shuffle mode).
    _player.playingStream.listen((_) => _broadcastState(_player.playbackEvent));
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _onCompleted.add(null);
    });
  }

  // Interruptions are handled in [_onInterruption] instead.
  final AudioPlayer _player = AudioPlayer(handleInterruptions: false);
  final _onCompleted = StreamController<void>.broadcast();
  final _commands = StreamController<QuranAudioCommand>.broadcast();
  bool _queueControls = false;
  // Paused by a temporary interruption (a call), to resume after it.
  bool _resumeAfterInterruption = false;

  Future<void> _configureSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      session.interruptionEventStream.listen(_onInterruption);
      session.becomingNoisyEventStream.listen((_) => pause());
    } catch (error) {
      debugPrint('Quran audio session not configured: $error');
    }
  }

  void _onInterruption(AudioInterruptionEvent event) {
    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          unawaited(_player.setVolume(.5));
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          if (!_player.playing) return;
          _resumeAfterInterruption = event.type == AudioInterruptionType.pause;
          unawaited(pause());
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.duck:
          unawaited(_player.setVolume(1));
        case AudioInterruptionType.pause:
          if (_resumeAfterInterruption) unawaited(play());
          _resumeAfterInterruption = false;
        case AudioInterruptionType.unknown:
          _resumeAfterInterruption = false;
      }
    }
  }

  /// Requests from outside the app's own buttons (see [QuranAudioCommand]),
  /// after this handler has acted on them.
  Stream<QuranAudioCommand> get commands => _commands.stream;

  /// Whether the notification and lock screen offer Previous/Next (to the
  /// previous/next Surah of a playlist), announced on [commands].
  set showQueueControls(bool value) {
    if (_queueControls == value) return;
    _queueControls = value;
    _broadcastState(_player.playbackEvent);
  }

  /// A plain custom control rather than the built-in [MediaControl.stop]:
  /// on Android 13+, `audio_service`'s native side maps `MediaControl.stop`
  /// to a `MediaSession` *custom action* instead of a regular notification
  /// button (Android 13 reserves the notification's few visible action slots
  /// for play/pause/skip — see `AudioService.java`'s `createCustomAction`,
  /// citing https://developer.android.com/about/versions/13/behavior-changes-13).
  /// Custom actions aren't rendered as a visible button by most launchers, so
  /// the Stop button silently disappeared from the notification on Android
  /// 13+ (confirmed on a real Android 13+ device: only Play/Pause showed).
  /// Using [MediaControl.custom] with an action name of our own isn't
  /// special-cased, so it always renders as a regular, always-visible
  /// notification button — handled in [customAction] below.
  static final _stopControl = MediaControl.custom(
    androidIcon: 'drawable/audio_service_stop',
    label: 'Stop',
    name: _stopActionName,
  );

  /// Fires each time the current file finishes playing on its own (not from
  /// a manual pause/stop) — callers use this to advance to the next ayah.
  Stream<void> get onCompleted => _onCompleted.stream;

  /// Loads [path] from scratch and starts playing it, replacing whatever
  /// this handler was previously playing.
  Future<void> playFile(String path, {required MediaItem item}) async {
    await _player.stop();
    mediaItem.add(item);
    await _player.setFilePath(path);
    unawaited(_player.play());
  }

  /// Stops the current clip without ending the background session/notif.
  Future<void> stopCurrent() => _player.stop();

  @override
  Future<void> play() {
    // just_audio's play() completes only once playback stops again.
    final playing = _player.play();
    _commands.add(QuranAudioCommand.play);
    return playing;
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Duration? get duration => _player.duration;

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> pause() async {
    _resumeAfterInterruption = false;
    await _player.pause();
    _commands.add(QuranAudioCommand.pause);
  }

  @override
  Future<void> skipToNext() async => _commands.add(QuranAudioCommand.next);

  @override
  Future<void> skipToPrevious() async =>
      _commands.add(QuranAudioCommand.previous);

  /// Stops playback and tears the background session down: `super.stop()`
  /// sets [AudioProcessingState.idle], which `audio_service`'s native side
  /// treats as "done" — it cancels the media notification and stops the
  /// Android foreground service (see `AudioService.java`'s `setState`/
  /// `exitForegroundState`). The Stop button on the notification/lock screen
  /// calls this same method.
  @override
  Future<void> stop() async {
    _resumeAfterInterruption = false;
    await _player.stop();
    await super.stop();
    _commands.add(QuranAudioCommand.stop);
  }

  /// Called by `audio_service` when the user swipes the media notification
  /// away (while paused — Android keeps it pinned while a foreground service
  /// is actively playing, same as every other media app). The base
  /// implementation already calls [stop] here; overridden explicitly so that
  /// guarantee is self-documented rather than relying on an unreferenced
  /// default from the package.
  @override
  Future<void> onNotificationDeleted() => stop();

  /// Dispatches [_stopControl]'s button press (see its doc comment).
  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == _stopActionName) await stop();
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final playPause = playing ? MediaControl.pause : MediaControl.play;
    playbackState.add(
      playbackState.value.copyWith(
        controls: _queueControls
            ? [
                MediaControl.skipToPrevious,
                playPause,
                MediaControl.skipToNext,
                _stopControl,
              ]
            : [playPause, _stopControl],
        systemActions: {
          MediaAction.seek,
          if (_queueControls) ...{
            MediaAction.skipToNext,
            MediaAction.skipToPrevious,
          },
        },
        androidCompactActionIndices: _queueControls
            ? const [0, 1, 2]
            : const [0, 1],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }
}
