abstract class SurahPlaybackEvent {
  const SurahPlaybackEvent();
}

/// Starts (or resumes) sequential ayah-by-ayah playback of a surah.
/// With [fromAyah], playback jumps to that ayah and plays on from it.
class PlaySurah extends SurahPlaybackEvent {
  const PlaySurah({
    required this.surahNo,
    required this.totalAyah,
    required this.recitationId,
    this.fromAyah,
  });

  final int surahNo;
  final int totalAyah;
  final int recitationId;
  final int? fromAyah;
}

class PauseSurah extends SurahPlaybackEvent {
  const PauseSurah();
}

/// Manually marks [ayahNo] as the active one (e.g. the repeat button),
/// without starting playback.
class SetActiveAyah extends SurahPlaybackEvent {
  const SetActiveAyah(this.ayahNo);

  final int ayahNo;
}

/// How many times [ayahNo] plays before playback moves on (1: once).
class SetAyahRepeat extends SurahPlaybackEvent {
  const SetAyahRepeat(this.ayahNo, this.count);

  final int ayahNo;
  final int count;
}

/// Updates how many times the surah should play.
class SetRepeatCount extends SurahPlaybackEvent {
  const SetRepeatCount(this.count);

  final int count;
}
