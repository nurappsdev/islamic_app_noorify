abstract class AyahBookmarkEvent {
  const AyahBookmarkEvent();
}

class LoadBookmarkStatus extends AyahBookmarkEvent {
  const LoadBookmarkStatus();
}

class ToggleAyahBookmark extends AyahBookmarkEvent {
  const ToggleAyahBookmark();
}
