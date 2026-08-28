class AyahAudioState {
  const AyahAudioState({
    this.playingVerseKey,
    this.isBuffering = false,
    this.needsDownloadForVerseKey,
  });

  final String? playingVerseKey;
  final bool isBuffering;

  /// Set to the verse key the user just tried to play when the surah's audio
  /// is not on the device yet. The screen reacts by prompting a download.
  final String? needsDownloadForVerseKey;
}
