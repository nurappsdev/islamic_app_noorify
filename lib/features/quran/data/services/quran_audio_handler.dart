import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Set once in `main()` via [AudioService.init], before any ayah/surah bloc
/// is created.
late QuranAudioHandler quranAudioHandler;

/// `MediaControl.stop`'s custom-action name on Android 13+ — see
/// [QuranAudioHandler._stopControl] for why Stop uses this instead.
const _stopActionName = 'quran_stop';

/// The app's single audio engine for Quran recitation (both single-ayah
/// preview and continuous full-surah playback share this one player).
/// Registering it with `audio_service` gives it a real Android foreground
/// service + notification and an iOS background-audio session, so playback
/// keeps going when the app is minimized, backgrounded, or the screen is
/// locked, with play/pause reachable from the lock screen/notification.
class QuranAudioHandler extends BaseAudioHandler {
  QuranAudioHandler() {
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

  final AudioPlayer _player = AudioPlayer();
  final _onCompleted = StreamController<void>.broadcast();

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
  Future<void> play() => _player.play();

  Stream<Duration> get positionStream => _player.positionStream;
  Duration? get duration => _player.duration;

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> pause() => _player.pause();

  /// Stops playback and tears the background session down: `super.stop()`
  /// sets [AudioProcessingState.idle], which `audio_service`'s native side
  /// treats as "done" — it cancels the media notification and stops the
  /// Android foreground service (see `AudioService.java`'s `setState`/
  /// `exitForegroundState`). The Stop button on the notification/lock screen
  /// calls this same method.
  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
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
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          playing ? MediaControl.pause : MediaControl.play,
          _stopControl,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1],
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
