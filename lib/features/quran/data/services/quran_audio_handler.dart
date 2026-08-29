import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Set once in `main()` via [AudioService.init], before any ayah/surah bloc
/// is created.
late QuranAudioHandler quranAudioHandler;

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
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _onCompleted.add(null);
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final _onCompleted = StreamController<void>.broadcast();

  /// Fires each time the current file finishes playing on its own (not from
  /// a manual pause/stop) — callers use this to advance to the next ayah.
  Stream<void> get onCompleted => _onCompleted.stream;

  /// Loads [path] from scratch and starts playing it, replacing whatever
  /// this handler was previously playing.
  Future<void> playFile(String path, {required MediaItem item}) async {
    await _player.stop();
    mediaItem.add(item);
    await _player.setFilePath(path);
    await _player.play();
  }

  /// Stops the current clip without ending the background session/notif.
  Future<void> stopCurrent() => _player.stop();

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
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
