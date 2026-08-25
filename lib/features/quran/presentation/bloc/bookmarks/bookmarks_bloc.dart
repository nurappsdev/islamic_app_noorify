import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_local_store.dart';

import 'bookmarks_event.dart';
import 'bookmarks_state.dart';

export 'bookmarks_event.dart';
export 'bookmarks_state.dart';

class BookmarksBloc extends Bloc<BookmarksEvent, BookmarksState> {
  BookmarksBloc({QuranLocalStore? store})
    : _store = store,
      super(const BookmarksState()) {
    on<LoadBookmarks>(_onLoad);
    on<RemoveBookmark>(_onRemove);
  }

  QuranLocalStore? _store;

  Future<QuranLocalStore> _resolveStore() async =>
      _store ??= await QuranLocalStore.create();

  Future<void> _onLoad(LoadBookmarks event, Emitter<BookmarksState> emit) async {
    final store = await _resolveStore();
    final bookmarks = await store.bookmarks();
    emit(state.copyWith(isLoading: false, bookmarks: bookmarks));
  }

  Future<void> _onRemove(
    RemoveBookmark event,
    Emitter<BookmarksState> emit,
  ) async {
    final store = await _resolveStore();
    await store.removeBookmark(event.surahNo, event.ayahNo);
    final bookmarks = await store.bookmarks();
    emit(state.copyWith(bookmarks: bookmarks));
  }
}
