import 'quran_reading_json.dart';

/// One day's Quran reading against the daily goal — `data.daily` of
/// `POST /quran/reading/track`, `data.today` of the dashboard, and each day
/// of the reading history.
class QuranDailyProgress {
  const QuranDailyProgress({
    required this.date,
    required this.readSeconds,
    required this.readMinutes,
    required this.goalSeconds,
    required this.goalMinutes,
    required this.remainingSeconds,
    required this.remainingMinutes,
    required this.points,
    required this.maxPoints,
    required this.percentage,
    required this.isGoalMet,
    required this.ayahsRead,
    required this.pointsText,
    required this.progressText,
    this.dailyTotalPoints,
    this.dailyTotalMaxPoints,
  });

  factory QuranDailyProgress.fromJson(Map<String, dynamic> json) =>
      QuranDailyProgress(
        date: readDay(json['date']),
        readSeconds: readInt(json['readSeconds']),
        readMinutes: readDouble(json['readMinutes']),
        goalSeconds: readInt(json['goalSeconds']),
        goalMinutes: readDouble(json['goalMinutes']),
        remainingSeconds: readInt(json['remainingSeconds']),
        remainingMinutes: readDouble(json['remainingMinutes']),
        points: readDouble(json['points']),
        maxPoints: readDouble(json['maxPoints']),
        percentage: readInt(json['percentage']),
        isGoalMet: readBool(json['isGoalMet']),
        ayahsRead: readInt(json['ayahsRead']),
        pointsText: readString(json['pointsText']),
        progressText: readString(json['progressText']),
        dailyTotalPoints: json['dailyTotalPoints'] is num
            ? readDouble(json['dailyTotalPoints'])
            : null,
        dailyTotalMaxPoints: json['dailyTotalMaxPoints'] is num
            ? readDouble(json['dailyTotalMaxPoints'])
            : null,
      );

  /// The calendar day (`YYYY-MM-DD`), or null if the API left it out.
  final DateTime? date;
  final int readSeconds;
  final double readMinutes;
  final int goalSeconds;
  final double goalMinutes;
  final int remainingSeconds;
  final double remainingMinutes;
  final double points;
  final double maxPoints;

  /// Progress towards the daily goal, 0-100.
  final int percentage;
  final bool isGoalMet;
  final int ayahsRead;

  /// Server-formatted English labels, e.g. `Point : 3/11` and `12/44 min`.
  final String pointsText;
  final String progressText;

  /// All of today's points across the app (dashboard `today` only).
  final double? dailyTotalPoints;
  final double? dailyTotalMaxPoints;
}

/// An ayah with the names of its Surah — the API's `from`/`to` of a track,
/// the dashboard's `nextAyah` and `continueFrom`.
class QuranAyahPosition {
  const QuranAyahPosition({
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahKey,
    required this.paraNumber,
    required this.surahNameEnglish,
    required this.surahNameBangla,
    required this.surahNameArabic,
  });

  factory QuranAyahPosition.fromJson(Map<String, dynamic> json) =>
      QuranAyahPosition(
        surahNumber: readInt(json['surahNumber']),
        ayahNumber: readInt(json['ayahNumber']),
        ayahKey: readString(json['ayahKey']),
        paraNumber: readInt(json['paraNumber']),
        surahNameEnglish: readString(json['surahNameEnglish']),
        surahNameBangla: readString(json['surahNameBangla']),
        surahNameArabic: readString(json['surahNameArabic']),
      );

  static QuranAyahPosition? tryParse(Object? json) {
    final map = readMapOrNull(json);
    return map == null ? null : QuranAyahPosition.fromJson(map);
  }

  final int surahNumber;
  final int ayahNumber;

  /// `surah:ayah`, e.g. `2:255`.
  final String ayahKey;
  final int paraNumber;
  final String surahNameEnglish;
  final String surahNameBangla;
  final String surahNameArabic;
}

/// One ayah's stored reading state after a track (`data.ayahs[]`).
class QuranTrackedAyah {
  const QuranTrackedAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.readSeconds,
    required this.sessionCount,
    required this.isRead,
  });

  factory QuranTrackedAyah.fromJson(Map<String, dynamic> json) =>
      QuranTrackedAyah(
        surahNumber: readInt(json['surahNumber']),
        ayahNumber: readInt(json['ayahNumber']),
        readSeconds: readInt(json['readSeconds']),
        sessionCount: readInt(json['sessionCount']),
        isRead: readBool(json['isRead']),
      );

  final int surahNumber;
  final int ayahNumber;
  final int readSeconds;
  final int sessionCount;
  final bool isRead;
}

/// How much of a whole (a Surah, a Para, the Quran) has been read.
class QuranCompletionProgress {
  const QuranCompletionProgress({
    required this.totalAyahs,
    required this.readAyahs,
    required this.remainingAyahs,
    required this.percentage,
    required this.isCompleted,
  });

  factory QuranCompletionProgress.fromJson(Map<String, dynamic> json) =>
      QuranCompletionProgress(
        totalAyahs: readInt(json['totalAyahs']),
        readAyahs: readInt(json['readAyahs']),
        remainingAyahs: readInt(json['remainingAyahs']),
        percentage: readInt(json['percentage']),
        isCompleted: readBool(json['isCompleted']),
      );

  final int totalAyahs;
  final int readAyahs;
  final int remainingAyahs;
  final int percentage;
  final bool isCompleted;
}

/// A tracked Surah's progress (`data.progress.surahs[]`).
class QuranSurahProgress extends QuranCompletionProgress {
  const QuranSurahProgress({
    required this.surahNumber,
    required this.nameEnglish,
    required this.nameBangla,
    required super.totalAyahs,
    required super.readAyahs,
    required super.remainingAyahs,
    required super.percentage,
    required super.isCompleted,
  });

  factory QuranSurahProgress.fromJson(Map<String, dynamic> json) {
    final progress = QuranCompletionProgress.fromJson(json);
    return QuranSurahProgress(
      surahNumber: readInt(json['surahNumber']),
      nameEnglish: readString(json['nameEnglish']),
      nameBangla: readString(json['nameBangla']),
      totalAyahs: progress.totalAyahs,
      readAyahs: progress.readAyahs,
      remainingAyahs: progress.remainingAyahs,
      percentage: progress.percentage,
      isCompleted: progress.isCompleted,
    );
  }

  final int surahNumber;
  final String nameEnglish;
  final String nameBangla;
}

/// A tracked Para's progress (`data.progress.paras[]`).
class QuranParaProgress extends QuranCompletionProgress {
  const QuranParaProgress({
    required this.paraNumber,
    required super.totalAyahs,
    required super.readAyahs,
    required super.remainingAyahs,
    required super.percentage,
    required super.isCompleted,
  });

  factory QuranParaProgress.fromJson(Map<String, dynamic> json) {
    final progress = QuranCompletionProgress.fromJson(json);
    return QuranParaProgress(
      paraNumber: readInt(json['paraNumber']),
      totalAyahs: progress.totalAyahs,
      readAyahs: progress.readAyahs,
      remainingAyahs: progress.remainingAyahs,
      percentage: progress.percentage,
      isCompleted: progress.isCompleted,
    );
  }

  final int paraNumber;
}

/// What `POST /quran/reading/track` returns.
class QuranReadingTrackResult {
  const QuranReadingTrackResult({
    required this.daily,
    required this.trackedAyahs,
    required this.newlyReadAyahs,
    required this.from,
    required this.to,
    required this.ayahs,
    required this.surahs,
    required this.paras,
    required this.quran,
  });

  factory QuranReadingTrackResult.fromJson(Map<String, dynamic> json) {
    final progress = readMap(json['progress']);
    return QuranReadingTrackResult(
      daily: QuranDailyProgress.fromJson(readMap(json['daily'])),
      trackedAyahs: readInt(json['trackedAyahs']),
      newlyReadAyahs: readInt(json['newlyReadAyahs']),
      from: QuranAyahPosition.tryParse(json['from']),
      to: QuranAyahPosition.tryParse(json['to']),
      ayahs: [
        for (final ayah in readMapList(json['ayahs']))
          QuranTrackedAyah.fromJson(ayah),
      ],
      surahs: [
        for (final surah in readMapList(progress['surahs']))
          QuranSurahProgress.fromJson(surah),
      ],
      paras: [
        for (final para in readMapList(progress['paras']))
          QuranParaProgress.fromJson(para),
      ],
      quran: QuranCompletionProgress.fromJson(readMap(progress['quran'])),
    );
  }

  final QuranDailyProgress daily;
  final int trackedAyahs;
  final int newlyReadAyahs;
  final QuranAyahPosition? from;
  final QuranAyahPosition? to;
  final List<QuranTrackedAyah> ayahs;
  final List<QuranSurahProgress> surahs;
  final List<QuranParaProgress> paras;

  /// The whole Quran.
  final QuranCompletionProgress quran;
}
