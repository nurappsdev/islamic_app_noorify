import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/quran/data/services/quran_audio_downloader.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_audio_handler.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/reciter/reciter_bloc.dart'
    show defaultRecitationId;

import 'surah_playback_event.dart';
import 'surah_playback_state.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_preference.dart';
import 'package:tuhfatul_muslim/core/localization/localized_number_formatter.dart';

export 'surah_playback_event.dart';
export 'surah_playback_state.dart';

class _AdvanceAyah extends SurahPlaybackEvent {
  const _AdvanceAyah();
}

class _AudioCommand extends SurahPlaybackEvent {
  const _AudioCommand(this.command);
  final QuranAudioCommand command;
}

/// Plays a surah continuously from downloaded files: the opening Bismillah
/// clip (where the surah has one) followed by every ayah, auto-advancing as
/// each file finishes. An ayah set to repeat ([SetAyahRepeat]) plays that
/// many times before playback moves on to the next. If the surah's audio is not on the device the bloc
/// reports [SurahPlaybackState.needsDownload] instead of streaming.
///
/// Play, pause and stop from the notification, lock screen, a headset or an
/// interruption ([QuranAudioCommand]) update its state while it is the one
/// playing, so it keeps advancing (or stays stopped) in the background.
class SurahPlaybackBloc extends Bloc<SurahPlaybackEvent, SurahPlaybackState> {
  // The audio notification has no BuildContext: it is written in the language
  // the app is showing right now.
  AppText get _text => AppText.forLanguage(LanguagePreference.current);
  LocalizedNumberFormatter get _numbers => LanguagePreference.numbers;

  SurahPlaybackBloc({
    QuranAudioDownloader? downloader,
    QuranAudioHandler? audio,
    this.startAyah = 1,
    this.endAyah,
    this.stopAudioOnClose = true,
  }) : _downloader = downloader ?? QuranAudioDownloader(),
       _audio = audio ?? quranAudioHandler,
       super(SurahPlaybackState(currentAyahNo: startAyah)) {
    _completedSub = _audio.onCompleted.listen((_) => add(const _AdvanceAyah()));
    _commandSub = _audio.commands.listen((c) => add(_AudioCommand(c)));
    on<_AudioCommand>(_onCommand);
    on<PlaySurah>(_onPlay);
    on<PauseSurah>(_onPause);
    on<SetActiveAyah>((event, emit) async {
      await _audio.stopCurrent();
      emit(
        state.copyWith(
          currentAyahNo: event.ayahNo,
          isPlaying: false,
          isBuffering: false,
        ),
      );
    });
    on<SetRepeatCount>(
      (event, emit) => emit(
        state.copyWith(
          repeatCount: event.count,
          // Takes effect now, during playback too.
          remainingRepeats: event.count,
        ),
      ),
    );
    on<SetAyahRepeat>(_onSetAyahRepeat);
    on<_AdvanceAyah>(_onAdvance);
  }

  /// Al-Fatiha and At-Tawbah do not open with the Basmala.
  static const _surahsWithoutBismillah = {1, 9};

  final int startAyah;
  final int? endAyah;

  /// Whether closing while playing ends the background session; a playlist
  /// moving to its next Surah keeps it, so it never has to start again from
  /// the background.
  final bool stopAudioOnClose;
  late final StreamSubscription<QuranAudioCommand> _commandSub;
  final QuranAudioDownloader _downloader;
  final QuranAudioHandler _audio;
  late final StreamSubscription<void> _completedSub;
  int _surahNo = 0;
  int _totalAyah = 0;
  int _recitationId = defaultRecitationId;

  bool get _hasBismillah => !_surahsWithoutBismillah.contains(_surahNo);

  /// Briefly raises [SurahPlaybackState.needsDownload] so a listener fires,
  /// then lowers it — a repeat play tap re-triggers the download prompt.
  void _pulseNeedsDownload(Emitter<SurahPlaybackState> emit) {
    emit(
      state.copyWith(isPlaying: false, isBuffering: false, needsDownload: true),
    );
    emit(state.copyWith(needsDownload: false));
  }

  void _onSetAyahRepeat(SetAyahRepeat event, Emitter<SurahPlaybackState> emit) {
    final repeats = Map<int, int>.of(state.ayahRepeats);
    if (event.count <= 1) {
      repeats.remove(event.ayahNo);
    } else {
      repeats[event.ayahNo] = event.count;
    }
    emit(
      state.copyWith(
        ayahRepeats: repeats,
        // The ayah playing now: from this play on.
        ayahPlaysLeft: state.currentAyahNo == event.ayahNo
            ? event.count.clamp(1, 1 << 16)
            : null,
      ),
    );
  }

  Future<void> _onPlay(
    PlaySurah event,
    Emitter<SurahPlaybackState> emit,
  ) async {
    final from = event.fromAyah;
    if (from == null &&
        _surahNo == event.surahNo &&
        _recitationId == event.recitationId &&
        _audio.mediaItem.value?.id ==
            '${event.surahNo}:${state.currentAyahNo}' &&
        _audio.playbackState.value.processingState ==
            AudioProcessingState.ready) {
      unawaited(_audio.play());
      emit(state.copyWith(isPlaying: true, isBuffering: false));
      return;
    }
    _surahNo = event.surahNo;
    _totalAyah = event.totalAyah;
    _recitationId = event.recitationId;

    final complete = await _downloader.isSurahComplete(
      reciterId: _recitationId,
      surahNo: _surahNo,
      totalAyah: _totalAyah,
    );
    if (!complete) {
      _pulseNeedsDownload(emit);
      return;
    }

    emit(state.copyWith(remainingRepeats: state.repeatCount));

    // A chosen ayah plays as itself; from the top, the Bismillah comes first.
    final startAt = from != null
        ? from.clamp(1, _totalAyah)
        : state.currentAyahNo <= 1 && _hasBismillah
        ? 0
        : state.currentAyahNo;
    await _playAyah(startAt, emit);
  }

  /// Whether the clip loaded in the engine is this bloc's current ayah.
  bool get _ownsAudio =>
      _surahNo != 0 &&
      _audio.mediaItem.value?.id == '$_surahNo:${state.currentAyahNo}';

  Future<void> _onCommand(
    _AudioCommand event,
    Emitter<SurahPlaybackState> emit,
  ) async {
    if (!_ownsAudio) return;
    switch (event.command) {
      case QuranAudioCommand.pause:
      case QuranAudioCommand.stop:
        if (state.isPlaying || state.isBuffering) {
          emit(state.copyWith(isPlaying: false, isBuffering: false));
        }
      case QuranAudioCommand.play:
        if (state.isPlaying || state.finished) return;
        if (_audio.playbackState.value.processingState ==
            AudioProcessingState.ready) {
          // The engine resumed the paused clip itself.
          emit(state.copyWith(isPlaying: true, isBuffering: false));
        } else {
          // Stopped: load the ayah again.
          await _playAyah(state.currentAyahNo, emit);
        }
      case QuranAudioCommand.next:
      case QuranAudioCommand.previous:
        // Surah to Surah: up to a playlist, if one is playing.
        break;
    }
  }

  Future<void> _onPause(
    PauseSurah event,
    Emitter<SurahPlaybackState> emit,
  ) async {
    await _audio.pause();
    emit(state.copyWith(isPlaying: false));
  }

  Future<void> _onAdvance(
    _AdvanceAyah event,
    Emitter<SurahPlaybackState> emit,
  ) async {
    if (!state.isPlaying) return;
    // This ayah is set to play again.
    if (state.ayahPlaysLeft > 1) {
      emit(state.copyWith(ayahPlaysLeft: state.ayahPlaysLeft - 1));
      await _playAyah(state.currentAyahNo, emit, replay: true);
      return;
    }
    final next = state.currentAyahNo + 1;
    if (next > (endAyah ?? _totalAyah)) {
      if (state.remainingRepeats > 1) {
        emit(state.copyWith(remainingRepeats: state.remainingRepeats - 1));
        final startAt = startAyah == 1 && _hasBismillah ? 0 : startAyah;
        await _playAyah(startAt, emit);
      } else {
        emit(
          state.copyWith(isPlaying: false, remainingRepeats: 1, finished: true),
        );
      }
      return;
    }
    await _playAyah(next, emit);
  }

  /// Plays [ayahNo]; [replay] for another play of the same ayah, keeping
  /// its count of plays left.
  Future<void> _playAyah(
    int ayahNo,
    Emitter<SurahPlaybackState> emit, {
    bool replay = false,
  }) async {
    emit(
      state.copyWith(
        currentAyahNo: ayahNo,
        isPlaying: true,
        isBuffering: true,
        needsDownload: false,
        finished: false,
        ayahPlaysLeft: replay ? null : state.repeatCountFor(ayahNo),
      ),
    );
    try {
      final localPath = ayahNo == 0
          ? await _downloader.localBismillahPath(_recitationId)
          : await _downloader.localPathFor(
              reciterId: _recitationId,
              verseKey: '$_surahNo:$ayahNo',
            );
      if (!state.isPlaying || state.currentAyahNo != ayahNo) return;
      if (localPath == null) {
        // A missing Bismillah file should not block the recitation itself.
        if (ayahNo == 0) {
          await _playAyah(1, emit);
          return;
        }
        _pulseNeedsDownload(emit);
        return;
      }
      await _audio.playFile(
        localPath,
        item: MediaItem(
          id: '$_surahNo:$ayahNo',
          title: ayahNo == 0
              ? _text.quranBismillah
              : _text.quranAudioAyahTitle.fill({
                  'key': _numbers.digits('$ayahNo'),
                }),
          album: _text.quranSurahNumberTitle.fill({
            'n': _numbers.digits('$_surahNo'),
          }),
        ),
      );
      emit(state.copyWith(isBuffering: false));
    } catch (_) {
      emit(state.copyWith(isPlaying: false, isBuffering: false));
    }
  }

  @override
  Future<void> close() {
    _completedSub.cancel();
    _commandSub.cancel();
    // Only tear down the shared engine if this bloc was the one driving it —
    // another screen (e.g. a single-ayah preview) may have taken it over
    // since, and its playback shouldn't be cut off by this bloc closing.
    if (state.isPlaying && stopAudioOnClose) _audio.stop();
    return super.close();
  }
}
