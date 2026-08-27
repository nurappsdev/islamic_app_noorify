abstract class SurahAudioDownloadEvent {
  const SurahAudioDownloadEvent();
}

/// Look up how much of this surah's audio is already on the device.
class CheckSurahAudioStatus extends SurahAudioDownloadEvent {
  const CheckSurahAudioStatus({
    required this.reciterId,
    required this.surahNo,
    required this.totalAyah,
  });

  final int reciterId;
  final int surahNo;
  final int totalAyah;
}

/// Download every ayah of this surah for the given reciter.
class StartSurahAudioDownload extends SurahAudioDownloadEvent {
  const StartSurahAudioDownload({
    required this.reciterId,
    required this.surahNo,
    required this.totalAyah,
  });

  final int reciterId;
  final int surahNo;
  final int totalAyah;
}
