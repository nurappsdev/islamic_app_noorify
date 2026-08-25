class SurahPlaybackState {
  const SurahPlaybackState({
    this.currentAyahNo = 1,
    this.isPlaying = false,
    this.isBuffering = false,
  });

  final int currentAyahNo;
  final bool isPlaying;
  final bool isBuffering;

  SurahPlaybackState copyWith({
    int? currentAyahNo,
    bool? isPlaying,
    bool? isBuffering,
  }) {
    return SurahPlaybackState(
      currentAyahNo: currentAyahNo ?? this.currentAyahNo,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
    );
  }
}
