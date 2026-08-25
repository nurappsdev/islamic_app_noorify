abstract class AyahAudioEvent {
  const AyahAudioEvent();
}

/// Toggles playback for [verseKey] (e.g. "1:2"): plays it with
/// [recitationId]'s reciter, or stops it if it's already playing.
/// Pass [restart]: true to always (re)play from the start instead of
/// toggling off when it's already the one playing.
class PlayAyahAudio extends AyahAudioEvent {
  const PlayAyahAudio({
    required this.verseKey,
    required this.recitationId,
    this.restart = false,
  });

  final String verseKey;
  final int recitationId;
  final bool restart;
}

class StopAyahAudio extends AyahAudioEvent {
  const StopAyahAudio();
}
