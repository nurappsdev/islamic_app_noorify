import 'package:islami_app_noorify/features/quran/domain/bookmark.dart';

class BookmarksState {
  const BookmarksState({this.isLoading = true, this.bookmarks = const []});

  final bool isLoading;
  final List<Bookmark> bookmarks;

  BookmarksState copyWith({bool? isLoading, List<Bookmark>? bookmarks}) {
    return BookmarksState(
      isLoading: isLoading ?? this.isLoading,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}
