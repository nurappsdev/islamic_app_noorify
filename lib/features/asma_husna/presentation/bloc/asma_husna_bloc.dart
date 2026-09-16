import 'package:bloc/bloc.dart';
import 'package:just_audio/just_audio.dart';

import 'package:islami_app_noorify/features/asma_husna/domain/usecases/get_asma_names.dart';

import 'asma_husna_event.dart';
import 'asma_husna_state.dart';

export 'asma_husna_event.dart';
export 'asma_husna_state.dart';

/// Loads the 99 Names of Allah and drives the "Click to play" audio preview
/// on each name card. Owns a private [AudioPlayer] — one name streams at a
/// time; tapping the currently-playing name pauses it instead of restarting.
class AsmaHusnaBloc extends Bloc<AsmaHusnaEvent, AsmaHusnaState> {
  AsmaHusnaBloc(this._getNames) : super(const AsmaHusnaState()) {
    on<LoadAsmaNames>(_onLoad);
    on<SearchAsmaNames>(_onSearch);
    on<TogglePlayAsmaAudio>(_onTogglePlay);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        add(const TogglePlayAsmaAudio(nameId: '', audioUrl: ''));
      }
    });
  }

  final GetAsmaNames _getNames;
  final AudioPlayer _player = AudioPlayer();

  Future<void> _onLoad(
    LoadAsmaNames event,
    Emitter<AsmaHusnaState> emit,
  ) async {
    emit(state.copyWith(status: AsmaHusnaStatus.loading));
    final result = await _getNames();
    result.fold(
      (failure) => emit(
        state.copyWith(status: AsmaHusnaStatus.failure, failure: failure),
      ),
      (names) => emit(
        state.copyWith(
          status: AsmaHusnaStatus.success,
          names: names,
          clearFailure: true,
        ),
      ),
    );
  }

  void _onSearch(SearchAsmaNames event, Emitter<AsmaHusnaState> emit) {
    emit(state.copyWith(query: event.query));
  }

  Future<void> _onTogglePlay(
    TogglePlayAsmaAudio event,
    Emitter<AsmaHusnaState> emit,
  ) async {
    // Playback finished on its own (see the processingStateStream listener
    // above, which fires this with an empty id) — just clear the state.
    if (event.nameId.isEmpty) {
      await _player.stop();
      emit(state.copyWith(clearPlayingId: true, isBuffering: false));
      return;
    }

    if (state.playingId == event.nameId) {
      await _player.pause();
      emit(state.copyWith(clearPlayingId: true, isBuffering: false));
      return;
    }

    emit(state.copyWith(playingId: event.nameId, isBuffering: true));
    try {
      await _player.setUrl(event.audioUrl);
      if (state.playingId != event.nameId) return;
      await _player.play();
      emit(state.copyWith(playingId: event.nameId, isBuffering: false));
    } catch (_) {
      emit(state.copyWith(clearPlayingId: true, isBuffering: false));
    }
  }

  @override
  Future<void> close() {
    _player.dispose();
    return super.close();
  }
}
