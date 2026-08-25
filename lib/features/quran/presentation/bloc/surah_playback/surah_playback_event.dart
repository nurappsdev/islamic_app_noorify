abstract class SurahPlaybackEvent {
  const SurahPlaybackEvent();
}

/// Starts (or resumes) sequential ayah-by-ayah playback of a surah.
class PlaySurah extends SurahPlaybackEvent {
  const PlaySurah({
    required this.surahNo,
    required this.totalAyah,
    required this.recitationId,
  });

  final int surahNo;
  final int totalAyah;
  final int recitationId;
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
