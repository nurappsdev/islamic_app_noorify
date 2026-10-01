import 'quran_reading_json.dart';
import 'quran_reading_progress.dart';

/// Totals over a reading window (`totals` of the history, the dashboard's
/// week, and each compared user).
class QuranReadingTotals {
  const QuranReadingTotals({
    required this.totalSeconds,
    required this.totalMinutes,
    required this.totalPoints,
    required this.maxPoints,
    required this.totalAyahs,
    required this.daysTracked,
    required this.daysGoalMet,
    required this.currentStreak,
    required this.averageMinutesPerDay,
  });

  factory QuranReadingTotals.fromJson(Map<String, dynamic> json) =>
      QuranReadingTotals(
        totalSeconds: readInt(json['totalSeconds']),
        totalMinutes: readDouble(json['totalMinutes']),
        totalPoints: readDouble(json['totalPoints']),
        maxPoints: readDouble(json['maxPoints']),
        totalAyahs: readInt(json['totalAyahs']),
        daysTracked: readInt(json['daysTracked']),
        daysGoalMet: readInt(json['daysGoalMet']),
        currentStreak: readInt(json['currentStreak']),
        averageMinutesPerDay: readDouble(json['averageMinutesPerDay']),
      );

  final int totalSeconds;
  final double totalMinutes;
  final double totalPoints;
  final double maxPoints;
  final int totalAyahs;
  final int daysTracked;
  final int daysGoalMet;

  /// Consecutive days meeting the goal, counted back from the window's end.
  final int currentStreak;
  final double averageMinutesPerDay;
}

/// Day-by-day reading over a window — `GET /quran/reading/history` and the
/// dashboard's `week`.
class QuranReadingHistory {
  const QuranReadingHistory({
    required this.from,
    required this.to,
    required this.days,
    required this.totals,
  });

  factory QuranReadingHistory.fromJson(Map<String, dynamic> json) =>
      QuranReadingHistory(
        from: readDay(json['from']),
        to: readDay(json['to']),
        days: [
          for (final day in readMapList(json['days']))
            QuranDailyProgress.fromJson(day),
        ],
        totals: QuranReadingTotals.fromJson(readMap(json['totals'])),
      );

  final DateTime? from;
  final DateTime? to;

  /// One entry per day of the window, oldest first.
  final List<QuranDailyProgress> days;
  final QuranReadingTotals totals;
}

/// One side of a reading comparison (`data.users[]`).
class QuranComparedUser extends QuranReadingHistory {
  const QuranComparedUser({
    required this.key,
    required this.rank,
    required this.isCurrentUser,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.totalPoints,
    required super.from,
    required super.to,
    required super.days,
    required super.totals,
  });

  factory QuranComparedUser.fromJson(Map<String, dynamic> json) {
    final history = QuranReadingHistory.fromJson(json);
    return QuranComparedUser(
      key: readString(json['key']),
      rank: readInt(json['rank']),
      isCurrentUser: readBool(json['isCurrentUser']),
      userId: readString(json['userId']),
      name: readStringOrNull(json['name']),
      avatarUrl: readStringOrNull(json['avatarUrl']),
      totalPoints: readDouble(json['totalPoints']),
      from: history.from,
      to: history.to,
      days: history.days,
      totals: history.totals,
    );
  }

  /// `user1` (the signed-in user) or `user2`.
  final String key;
  final int rank;
  final bool isCurrentUser;
  final String userId;
  final String? name;
  final String? avatarUrl;

  /// Leaderboard points, all time.
  final double totalPoints;
}

/// Current user minus the compared user, as the API computes it.
class QuranComparisonDifference {
  const QuranComparisonDifference({
    required this.totalPoints,
    required this.totalMinutes,
    required this.totalAyahs,
    required this.daysGoalMet,
    required this.isAhead,
  });

  factory QuranComparisonDifference.fromJson(Map<String, dynamic> json) =>
      QuranComparisonDifference(
        totalPoints: readDouble(json['totalPoints']),
        totalMinutes: readDouble(json['totalMinutes']),
        totalAyahs: readInt(json['totalAyahs']),
        daysGoalMet: readInt(json['daysGoalMet']),
        isAhead: readBool(json['isAhead']),
      );

  final double totalPoints;
  final double totalMinutes;
  final int totalAyahs;
  final int daysGoalMet;
  final bool isAhead;
}

/// `GET /quran/reading/history/compare`: the user's reading next to the
/// leaderboard leader's (or runner-up's, for the leader).
class QuranReadingComparison {
  const QuranReadingComparison({
    required this.from,
    required this.to,
    required this.comparedWith,
    required this.users,
    required this.difference,
  });

  factory QuranReadingComparison.fromJson(Map<String, dynamic> json) {
    final difference = readMapOrNull(json['difference']);
    return QuranReadingComparison(
      from: readDay(json['from']),
      to: readDay(json['to']),
      comparedWith: readStringOrNull(json['comparedWith']),
      users: [
        for (final user in readMapList(json['users']))
          QuranComparedUser.fromJson(user),
      ],
      difference: difference == null
          ? null
          : QuranComparisonDifference.fromJson(difference),
    );
  }

  final DateTime? from;
  final DateTime? to;

  /// `first_place` or `second_place`; null when there is nobody to compare.
  final String? comparedWith;
  final List<QuranComparedUser> users;

  /// Null when there is nobody to compare with.
  final QuranComparisonDifference? difference;

  QuranComparedUser? get currentUser =>
      users.where((user) => user.isCurrentUser).firstOrNull;

  QuranComparedUser? get competitor =>
      users.where((user) => !user.isCurrentUser).firstOrNull;
}
