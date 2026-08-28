class SurahPlaybackState {
  const SurahPlaybackState({
    this.currentAyahNo = 1,
    this.isPlaying = false,
    this.isBuffering = false,
    this.needsDownload = false,
  });

  /// The ayah currently active. `0` means the opening Bismillah clip (played
  /// before ayah 1 for every surah except Al-Fatiha and At-Tawbah).
  final int currentAyahNo;
  final bool isPlaying;
  final bool isBuffering;

  /// True when the user pressed play but the surah's audio is not downloaded.
  final bool needsDownload;

  SurahPlaybackState copyWith({
    int? currentAyahNo,
    bool? isPlaying,
    bool? isBuffering,
    bool? needsDownload,
  }) {
    return SurahPlaybackState(
      currentAyahNo: currentAyahNo ?? this.currentAyahNo,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      needsDownload: needsDownload ?? this.needsDownload,
    );
  }
}
