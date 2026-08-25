class AyahAudioState {
  const AyahAudioState({this.playingVerseKey, this.isBuffering = false});

  final String? playingVerseKey;
  final bool isBuffering;
}
