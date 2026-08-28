import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_local_store.dart';

import 'ayah_bookmark_event.dart';
import 'ayah_bookmark_state.dart';

export 'ayah_bookmark_event.dart';
export 'ayah_bookmark_state.dart';

/// One instance per [AyahCard]; tracks and toggles the bookmark status of
/// a single surah/ayah pair.
class AyahBookmarkBloc extends Bloc<AyahBookmarkEvent, AyahBookmarkState> {
  AyahBookmarkBloc({
    required this.surahNo,
    required this.ayahNo,
    required this.surahName,
    required this.snippet,
    QuranLocalStore? store,
  }) : _store = store,
       super(const AyahBookmarkState()) {
    on<LoadBookmarkStatus>(_onLoad);
    on<ToggleAyahBookmark>(_onToggle);
  }

  final int surahNo;
  final int ayahNo;
  final String surahName;
  final String snippet;
  QuranLocalStore? _store;

  Future<QuranLocalStore> _resolveStore() async =>
      _store ??= await QuranLocalStore.create();

  Future<void> _onLoad(
    LoadBookmarkStatus event,
    Emitter<AyahBookmarkState> emit,
  ) async {
    final store = await _resolveStore();
    final isBookmarked = await store.isBookmarked(surahNo, ayahNo);
    emit(state.copyWith(isBookmarked: isBookmarked));
  }

  Future<void> _onToggle(
    ToggleAyahBookmark event,
    Emitter<AyahBookmarkState> emit,
  ) async {
    final store = await _resolveStore();
    await store.toggleBookmark(
      surahNo: surahNo,
      ayahNo: ayahNo,
      surahName: surahName,
      snippet: snippet,
    );
    emit(state.copyWith(isBookmarked: !state.isBookmarked));
  }
}
