/// The loop counts an ayah's repeat button steps through: 1 (no loop),
/// 2, 3, 5, then back to 1.
int nextAyahRepeatCount(int count) => switch (count) {
  1 => 2,
  2 => 3,
  3 => 5,
  _ => 1,
};

class SurahPlaybackState {
  const SurahPlaybackState({
    this.currentAyahNo = 1,
    this.isPlaying = false,
    this.isBuffering = false,
    this.needsDownload = false,
    this.repeatCount = 1,
    this.remainingRepeats = 1,
    this.finished = false,
    this.ayahRepeats = const {},
    this.ayahPlaysLeft = 1,
  });

  /// The ayah currently active. `0` means the opening Bismillah clip (played
  /// before ayah 1 for every surah except Al-Fatiha and At-Tawbah).
  final int currentAyahNo;
  final bool isPlaying;
  final bool isBuffering;

  /// True when the user pressed play but the surah's audio is not downloaded.
  final bool needsDownload;

  /// How many times the entire surah should be played.
  final int repeatCount;

  /// How many repeats are left for the current playback session.
  final int remainingRepeats;

  /// True once the last ayah (and every repeat) has played to the end on its
  /// own — not after a pause. Cleared when playback starts again.
  final bool finished;

  /// Ayahs set to play more than once, and how many times.
  final Map<int, int> ayahRepeats;

  /// Plays of [currentAyahNo] left, the one under way included.
  final int ayahPlaysLeft;

  /// How many times [ayahNo] plays before playback moves on.
  int repeatCountFor(int ayahNo) => ayahRepeats[ayahNo] ?? 1;

  SurahPlaybackState copyWith({
    int? currentAyahNo,
    bool? isPlaying,
    bool? isBuffering,
    bool? needsDownload,
    int? repeatCount,
    int? remainingRepeats,
    bool? finished,
    Map<int, int>? ayahRepeats,
    int? ayahPlaysLeft,
  }) {
    return SurahPlaybackState(
      currentAyahNo: currentAyahNo ?? this.currentAyahNo,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      needsDownload: needsDownload ?? this.needsDownload,
      repeatCount: repeatCount ?? this.repeatCount,
      remainingRepeats: remainingRepeats ?? this.remainingRepeats,
      finished: finished ?? this.finished,
      ayahRepeats: ayahRepeats ?? this.ayahRepeats,
      ayahPlaysLeft: ayahPlaysLeft ?? this.ayahPlaysLeft,
    );
  }
}
