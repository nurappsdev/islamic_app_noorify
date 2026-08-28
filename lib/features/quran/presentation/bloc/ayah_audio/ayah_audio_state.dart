class AyahAudioState {
  const AyahAudioState({
    this.playingVerseKey,
    this.isBuffering = false,
    this.needsDownloadForVerseKey,
    this.repeatCount = 1,
    this.remainingRepeats = 1,
  });

  final String? playingVerseKey;
  final bool isBuffering;

  /// Set to the verse key the user just tried to play when the surah's audio
  /// is not on the device yet. The screen reacts by prompting a download.
  final String? needsDownloadForVerseKey;

  /// How many times a tapped ayah is played before playback stops
  /// (user-set; 1 = play once).
  final int repeatCount;

  /// Plays left for the ayah currently sounding.
  final int remainingRepeats;

  AyahAudioState copyWith({
    String? playingVerseKey,
    bool clearPlayingVerseKey = false,
    bool? isBuffering,
    String? needsDownloadForVerseKey,
    bool clearNeedsDownload = false,
    int? repeatCount,
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
      repeatCount: repeatCount ?? this.repeatCount,
      remainingRepeats: remainingRepeats ?? this.remainingRepeats,
    );
  }
}
