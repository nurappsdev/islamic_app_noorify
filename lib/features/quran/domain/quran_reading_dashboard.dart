import 'quran_last_read.dart';
import 'quran_reading_history.dart';
import 'quran_reading_json.dart';
import 'quran_reading_progress.dart';

/// Overall completion (`completion` of the dashboard).
class QuranCompletionSummary {
  const QuranCompletionSummary({
    required this.totalAyahs,
    required this.readAyahs,
    required this.percentage,
    required this.surahsCompleted,
    required this.totalSurahs,
    required this.parasCompleted,
    required this.totalParas,
    required this.nextAyah,
  });

  factory QuranCompletionSummary.fromJson(Map<String, dynamic> json) =>
      QuranCompletionSummary(
        totalAyahs: readInt(json['totalAyahs']),
        readAyahs: readInt(json['readAyahs']),
        percentage: readInt(json['percentage']),
        surahsCompleted: readInt(json['surahsCompleted']),
        totalSurahs: readInt(json['totalSurahs']),
        parasCompleted: readInt(json['parasCompleted']),
        totalParas: readInt(json['totalParas']),
        nextAyah: QuranAyahPosition.tryParse(json['nextAyah']),
      );

  final int totalAyahs;
  final int readAyahs;
  final int percentage;
  final int surahsCompleted;
  final int totalSurahs;
  final int parasCompleted;
  final int totalParas;

  /// The first ayah not yet read; null once the whole Quran is.
  final QuranAyahPosition? nextAyah;
}

/// Reading plan counts (`plans` of the dashboard).
class QuranPlansSummary {
  const QuranPlansSummary({required this.inProgress, required this.completed});

  factory QuranPlansSummary.fromJson(Map<String, dynamic> json) =>
      QuranPlansSummary(
        inProgress: readInt(json['inProgress']),
        completed: readInt(json['completed']),
      );

  final int inProgress;
  final int completed;
}

/// `GET /quran/reading/dashboard`: the Quran screens' data in one call.
class QuranReadingDashboard {
  const QuranReadingDashboard({
    required this.today,
    required this.week,
    required this.completion,
    required this.lastRead,
    required this.continueFrom,
    required this.plans,
  });

  factory QuranReadingDashboard.fromJson(Map<String, dynamic> json) =>
      QuranReadingDashboard(
        today: QuranDailyProgress.fromJson(readMap(json['today'])),
        week: QuranReadingHistory.fromJson(readMap(json['week'])),
        completion: QuranCompletionSummary.fromJson(
          readMap(json['completion']),
        ),
        lastRead: QuranLastReadRecord.tryParse(json['lastRead']),
        continueFrom: QuranAyahPosition.tryParse(json['continueFrom']),
        plans: QuranPlansSummary.fromJson(readMap(json['plans'])),
      );

  /// Today, with the day's app-wide points (`dailyTotalPoints`).
  final QuranDailyProgress today;

  /// The last 7 days.
  final QuranReadingHistory week;
  final QuranCompletionSummary completion;
  final QuranLastReadRecord? lastRead;
  final QuranAyahPosition? continueFrom;
  final QuranPlansSummary plans;
}
