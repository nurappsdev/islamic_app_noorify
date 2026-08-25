abstract class BookmarksEvent {
  const BookmarksEvent();
}

class LoadBookmarks extends BookmarksEvent {
  const LoadBookmarks();
}

class RemoveBookmark extends BookmarksEvent {
  const RemoveBookmark(this.surahNo, this.ayahNo);

  final int surahNo;
  final int ayahNo;
}
