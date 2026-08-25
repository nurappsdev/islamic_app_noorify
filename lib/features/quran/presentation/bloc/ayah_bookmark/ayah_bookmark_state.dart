class AyahBookmarkState {
  const AyahBookmarkState({this.isBookmarked = false});

  final bool isBookmarked;

  AyahBookmarkState copyWith({bool? isBookmarked}) {
    return AyahBookmarkState(isBookmarked: isBookmarked ?? this.isBookmarked);
  }
}
