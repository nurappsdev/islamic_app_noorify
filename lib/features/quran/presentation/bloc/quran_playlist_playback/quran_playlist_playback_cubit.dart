import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/quran/data/services/quran_audio_downloader.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_audio_handler.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_playlist.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/surah_playback/surah_playback_bloc.dart';

class QuranPlaylistPlaybackState {
  const QuranPlaylistPlaybackState({
    required this.index,
    required this.track,
    this.finished = false,
  });

  /// The playlist item playing (or paused) now.
  final int index;

  /// Plays [index]'s ayah range; replaced for every track and restart.
  final SurahPlaybackBloc track;

  /// The last track played to its end.
  final bool finished;
}

/// Plays a playlist's Surahs one after another through the shared Quran
/// audio engine, each with its own [SurahPlaybackBloc] limited to the
/// item's ayah range.
///
/// Moving on happens here, on the track's own events, not in a widget
/// build: the screen is not drawn while it is off or the app is in the
/// background, and playback must go on regardless. The notification and
/// lock screen get Previous/Next (Surah) while it plays; the whole session
/// ends once the last track finishes, or with [close].
class QuranPlaylistPlaybackCubit extends Cubit<QuranPlaylistPlaybackState> {
  QuranPlaylistPlaybackCubit({
    required List<QuranPlaylistItem> items,
    int initialIndex = 0,
    required int Function() recitationId,
    QuranAudioDownloader? downloader,
    QuranAudioHandler? audio,
  }) : this._(
         items,
         initialIndex.clamp(0, items.isEmpty ? 0 : items.length - 1),
         recitationId,
         downloader ?? QuranAudioDownloader(),
         audio ?? quranAudioHandler,
       );

  QuranPlaylistPlaybackCubit._(
    this.items,
    int index,
    this._recitationId,
    this._downloader,
    this._audio,
  ) : super(
        QuranPlaylistPlaybackState(
          index: index,
          track: _trackFor(items, index, _downloader, _audio),
        ),
      ) {
    if (items.isNotEmpty) {
      _audio.showQueueControls = true;
      _commandSub = _audio.commands.listen(_onCommand);
    }
    _start(state.track);
  }

  final List<QuranPlaylistItem> items;
  final int Function() _recitationId;
  final QuranAudioDownloader _downloader;
  final QuranAudioHandler _audio;
  StreamSubscription<QuranAudioCommand>? _commandSub;
  StreamSubscription<SurahPlaybackState>? _trackSub;

  bool get hasPrevious => state.index > 0;
  bool get hasNext => state.index < items.length - 1;

  static SurahPlaybackBloc _trackFor(
    List<QuranPlaylistItem> items,
    int index,
    QuranAudioDownloader downloader,
    QuranAudioHandler audio,
  ) {
    final item = items.isEmpty ? null : items[index];
    return SurahPlaybackBloc(
      downloader: downloader,
      audio: audio,
      startAyah: item?.startAyah ?? 1,
      endAyah: item?.endAyah,
      // The next track takes the engine over; [close] ends the session.
      stopAudioOnClose: false,
    );
  }

  void _start(SurahPlaybackBloc track) {
    if (items.isEmpty) return;
    final item = items[state.index];
    var finished = false;
    _trackSub = track.stream.listen((playback) {
      // Once per ending: later states may still say finished.
      if (playback.finished && !finished) unawaited(_onTrackFinished(track));
      finished = playback.finished;
    });
    track.add(
      PlaySurah(
        surahNo: item.surahNo,
        totalAyah: item.totalAyah,
        recitationId: _recitationId(),
      ),
    );
  }

  Future<void> _onTrackFinished(SurahPlaybackBloc track) async {
    if (isClosed || track != state.track) return;
    if (hasNext) return select(state.index + 1);
    emit(
      QuranPlaylistPlaybackState(
        index: state.index,
        track: track,
        finished: true,
      ),
    );
    // The whole playlist has played: end the background session.
    _audio.showQueueControls = false;
    await _audio.stop();
  }

  void _onCommand(QuranAudioCommand command) {
    switch (command) {
      case QuranAudioCommand.next:
        if (hasNext) unawaited(select(state.index + 1));
      case QuranAudioCommand.previous:
        unawaited(hasPrevious ? select(state.index - 1) : restart());
      case QuranAudioCommand.play:
        // Played again after the playlist ended: Previous/Next come back.
        _audio.showQueueControls = true;
      case QuranAudioCommand.pause:
      case QuranAudioCommand.stop:
        break;
    }
  }

  /// Plays item [index] from its first ayah.
  Future<void> select(int index) async {
    if (isClosed || index < 0 || index >= items.length) return;
    final old = state.track;
    // Often called from that subscription's own listener: not awaited.
    unawaited(_trackSub?.cancel());
    final track = _trackFor(items, index, _downloader, _audio);
    emit(QuranPlaylistPlaybackState(index: index, track: track));
    _audio.showQueueControls = true;
    _start(track);
    await old.close();
  }

  /// Plays the current item again from its first ayah.
  Future<void> restart() => select(state.index);

  @override
  Future<void> close() async {
    await _commandSub?.cancel();
    await _trackSub?.cancel();
    final playing = state.track.state.isPlaying;
    await state.track.close();
    _audio.showQueueControls = false;
    // Leaving the player ends the playlist, as before.
    if (playing) await _audio.stop();
    return super.close();
  }
}
