import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/quran/data/repositories/quran_playlist_repository_impl.dart';
import 'package:tuhfatul_muslim/features/quran/domain/repositories/quran_playlist_repository.dart';

import 'quran_playlist_event.dart';
import 'quran_playlist_state.dart';

export 'quran_playlist_event.dart';
export 'quran_playlist_state.dart';

class QuranPlaylistBloc extends Bloc<QuranPlaylistEvent, QuranPlaylistState> {
  QuranPlaylistBloc({QuranPlaylistRepository? repository})
    : _repository = repository ?? QuranPlaylistRepositoryImpl.shared,
      super(const QuranPlaylistState()) {
    on<LoadQuranPlaylists>(_onLoadPlaylists);
    on<LoadMoreQuranPlaylists>(_onLoadMorePlaylists);
    on<LoadQuranPlaylistDetails>(_onLoadPlaylistDetails);
    on<CreateQuranPlaylistSubmitted>(_onCreatePlaylist);
    on<UpdateQuranPlaylistSubmitted>(_onUpdatePlaylist);
    on<DeleteQuranPlaylist>(_onDeletePlaylist);
    on<LoadPlaylistAyahs>(_onLoadPlaylistAyahs);
    on<LoadMorePlaylistAyahs>(_onLoadMorePlaylistAyahs);
    on<ChangePlaylistAyahsFilter>(_onChangePlaylistAyahsFilter);
    on<SavePlaylistPosition>(_onSavePlaylistPosition);
    on<ClearPlaylistOperations>(_onClearOperations);

    _playlistChangedSub = _repository.onPlaylistChanged.listen((_) {
      add(const LoadQuranPlaylists(forceRefresh: true));
      if (state.selectedPlaylistDetails != null) {
        add(
          LoadQuranPlaylistDetails(
            playlistId: state.selectedPlaylistDetails!.id,
            forceRefresh: true,
          ),
        );
      }
    });
  }

  final QuranPlaylistRepository _repository;
  StreamSubscription<void>? _playlistChangedSub;
  int _generation = 0;

  Future<void> _onLoadPlaylists(
    LoadQuranPlaylists event,
    Emitter<QuranPlaylistState> emit,
  ) async {
    final generation = ++_generation;
    emit(
      state.copyWith(
        status: QuranPlaylistLoadStatus.loading,
        clearFailure: true,
        searchTerm: event.searchTerm,
      ),
    );

    final result = await _repository.getPlaylists(
      searchTerm: event.searchTerm,
      page: 1,
      limit: 10,
      forceRefresh: event.forceRefresh,
    );

    if (generation != _generation) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: QuranPlaylistLoadStatus.failure,
          failure: failure,
        ),
      ),
      (response) => emit(
        state.copyWith(
          status: QuranPlaylistLoadStatus.success,
          playlists: response.playlists,
          meta: response.meta,
        ),
      ),
    );
  }

  Future<void> _onLoadMorePlaylists(
    LoadMoreQuranPlaylists event,
    Emitter<QuranPlaylistState> emit,
  ) async {
    if (state.isPaginating || !state.hasMore) return;

    emit(state.copyWith(isPaginating: true));

    final nextPage = state.meta.page + 1;
    final result = await _repository.getPlaylists(
      searchTerm: state.searchTerm,
      page: nextPage,
      limit: state.meta.limit,
    );

    result.fold(
      (failure) => emit(state.copyWith(isPaginating: false)),
      (response) => emit(
        state.copyWith(
          isPaginating: false,
          playlists: [...state.playlists, ...response.playlists],
          meta: response.meta,
        ),
      ),
    );
  }

  Future<void> _onLoadPlaylistDetails(
    LoadQuranPlaylistDetails event,
    Emitter<QuranPlaylistState> emit,
  ) async {
    emit(
      state.copyWith(isLoadingDetails: true, clearDetailsFailure: true),
    );

    final result = await _repository.getPlaylistDetails(
      event.playlistId,
      forceRefresh: event.forceRefresh,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isLoadingDetails: false, detailsFailure: failure),
      ),
      (playlist) => emit(
        state.copyWith(
          isLoadingDetails: false,
          selectedPlaylistDetails: playlist,
        ),
      ),
    );
  }

  Future<void> _onCreatePlaylist(
    CreateQuranPlaylistSubmitted event,
    Emitter<QuranPlaylistState> emit,
  ) async {
    emit(
      state.copyWith(
        isCreating: true,
        createSuccess: false,
        clearCreateFailure: true,
      ),
    );

    final result = await _repository.createPlaylist(event.request);

    result.fold(
      (failure) =>
          emit(state.copyWith(isCreating: false, createFailure: failure)),
      (playlist) {
        emit(
          state.copyWith(
            isCreating: false,
            createSuccess: true,
            createdPlaylist: playlist,
          ),
        );
      },
    );
  }

  Future<void> _onUpdatePlaylist(
    UpdateQuranPlaylistSubmitted event,
    Emitter<QuranPlaylistState> emit,
  ) async {
    emit(
      state.copyWith(
        isUpdating: true,
        updateSuccess: false,
        clearUpdateFailure: true,
      ),
    );

    final result = await _repository.updatePlaylist(
      event.playlistId,
      event.request,
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(isUpdating: false, updateFailure: failure)),
      (playlist) => emit(
        state.copyWith(
          isUpdating: false,
          updateSuccess: true,
          selectedPlaylistDetails: playlist,
        ),
      ),
    );
  }

  Future<void> _onDeletePlaylist(
    DeleteQuranPlaylist event,
    Emitter<QuranPlaylistState> emit,
  ) async {
    emit(
      state.copyWith(
        isDeleting: true,
        deleteSuccess: false,
        clearDeleteFailure: true,
      ),
    );

    final result = await _repository.deletePlaylist(event.playlistId);

    result.fold(
      (failure) =>
          emit(state.copyWith(isDeleting: false, deleteFailure: failure)),
      (_) {
        final remaining =
            state.playlists.where((p) => p.id != event.playlistId).toList();
        emit(
          state.copyWith(
            isDeleting: false,
            deleteSuccess: true,
            playlists: remaining,
          ),
        );
      },
    );
  }

  Future<void> _onLoadPlaylistAyahs(
    LoadPlaylistAyahs event,
    Emitter<QuranPlaylistState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingAyahs: true,
        clearAyahsFailure: true,
        ayahsFilter: event.filter,
      ),
    );

    final result = await _repository.getPlaylistAyahs(
      event.playlistId,
      filter: event.filter,
      withText: event.withText,
      page: event.page,
      limit: event.limit,
      forceRefresh: event.forceRefresh,
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingAyahs: false, ayahsFailure: failure)),
      (response) => emit(
        state.copyWith(
          isLoadingAyahs: false,
          ayahs: response.ayahs,
          ayahsMeta: response.meta,
        ),
      ),
    );
  }

  Future<void> _onLoadMorePlaylistAyahs(
    LoadMorePlaylistAyahs event,
    Emitter<QuranPlaylistState> emit,
  ) async {
    if (state.isPaginatingAyahs || !state.hasMoreAyahs) return;

    emit(state.copyWith(isPaginatingAyahs: true));

    final nextPage = state.ayahsMeta.page + 1;
    final result = await _repository.getPlaylistAyahs(
      event.playlistId,
      filter: state.ayahsFilter,
      page: nextPage,
      limit: state.ayahsMeta.limit,
    );

    result.fold(
      (failure) => emit(state.copyWith(isPaginatingAyahs: false)),
      (response) => emit(
        state.copyWith(
          isPaginatingAyahs: false,
          ayahs: [...state.ayahs, ...response.ayahs],
          ayahsMeta: response.meta,
        ),
      ),
    );
  }

  Future<void> _onChangePlaylistAyahsFilter(
    ChangePlaylistAyahsFilter event,
    Emitter<QuranPlaylistState> emit,
  ) async {
    add(
      LoadPlaylistAyahs(
        playlistId: event.playlistId,
        filter: event.filter,
        page: 1,
        forceRefresh: true,
      ),
    );
  }

  Future<void> _onSavePlaylistPosition(
    SavePlaylistPosition event,
    Emitter<QuranPlaylistState> emit,
  ) async {
    await _repository.savePosition(
      event.playlistId,
      surahNumber: event.surahNumber,
      ayahNumber: event.ayahNumber,
    );
  }

  void _onClearOperations(
    ClearPlaylistOperations event,
    Emitter<QuranPlaylistState> emit,
  ) {
    emit(
      state.copyWith(
        createSuccess: false,
        updateSuccess: false,
        deleteSuccess: false,
        clearCreateFailure: true,
        clearUpdateFailure: true,
        clearDeleteFailure: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _playlistChangedSub?.cancel();
    return super.close();
  }
}
