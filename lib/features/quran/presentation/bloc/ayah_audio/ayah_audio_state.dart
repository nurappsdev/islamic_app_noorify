class AyahAudioState {
  const AyahAudioState({
    this.playingVerseKey,
    this.isBuffering = false,
    this.needsDownloadForVerseKey,
    this.repeatCounts = const {},
    this.remainingRepeats = 1,
  });

  final String? playingVerseKey;
  final bool isBuffering;

  /// Set to the verse key the user just tried to play when the surah's audio
  /// is not on the device yet. The screen reacts by prompting a download.
  final String? needsDownloadForVerseKey;

  /// Per-ayah repeat setting: verse key (e.g. "2:5") -> how many times that
  /// ayah plays before playback stops (user-set; absent / 1 = play once).
  final Map<String, int> repeatCounts;

  /// Plays left for the ayah currently sounding.
  final int remainingRepeats;

  /// Repeat count set for [verseKey] (1 when none has been set).
  int repeatCountFor(String verseKey) => repeatCounts[verseKey] ?? 1;

  AyahAudioState copyWith({
    String? playingVerseKey,
    bool clearPlayingVerseKey = false,
    bool? isBuffering,
    String? needsDownloadForVerseKey,
    bool clearNeedsDownload = false,
    Map<String, int>? repeatCounts,
    int? remainingRepeats,
  }) {
    return AyahAudioState(
      playingVerseKey: clearPlayingVerseKey
          ? null
          : (playingVerseKey ?? this.playingVerseKey),
      isBuffering: isBuffering ?? this.isBuffering,
      needsDownloadForVerseKey: clearNeedsDownload
          ? null
          : (needsDownloadForVerseKey ?? this.needsDownloadForVerseKey),
      repeatCounts: repeatCounts ?? this.repeatCounts,
      remainingRepeats: remainingRepeats ?? this.remainingRepeats,
    );
  }
}
