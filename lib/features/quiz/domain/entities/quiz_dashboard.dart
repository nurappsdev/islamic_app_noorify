/// The `period` a quiz dashboard or comparison is requested for.
enum QuizDashboardPeriod {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly');

  const QuizDashboardPeriod(this.apiValue);

  final String apiValue;

  /// Unknown values read as [weekly], the API's own default.
  static QuizDashboardPeriod fromApi(Object? value) => QuizDashboardPeriod
      .values
      .firstWhere((period) => period.apiValue == value, orElse: () => weekly);
}

/// Query for `GET /quizzes/dashboard` and the two compare endpoints. Only the
/// fields that are set are sent.
class QuizDashboardFilter {
  const QuizDashboardFilter({
    required this.period,
    this.days,
    this.from,
    this.to,
    this.page = 1,
    this.limit = 10,
  });

  final QuizDashboardPeriod period;

  /// Window length; the API ignores it when [from] is given.
  final int? days;

  /// Inclusive local calendar days, sent as `YYYY-MM-DD`.
  final DateTime? from;
  final DateTime? to;
  final int page;
  final int limit;

  QuizDashboardFilter copyWith({int? page}) => QuizDashboardFilter(
    period: period,
    days: days,
    from: from,
    to: to,
    page: page ?? this.page,
    limit: limit,
  );
}

/// The comparison endpoints take exactly the dashboard's query.
typedef QuizComparisonFilter = QuizDashboardFilter;

/// The API's `meta`: pagination over the range's [QuizDashboardData.days].
class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPage,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPage;

  bool get hasMore => page < totalPage;
}

/// Quiz activity figures as computed by the server. The answered-based
/// figures are `null` when the range holds attempts recorded before answers
/// were stored, as the server cannot report them for those.
class QuizDashboardStats {
  const QuizDashboardStats({
    required this.attempts,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.answeredQuestions,
    required this.unansweredQuestions,
    required this.wrongAnswers,
    required this.answeredPercentage,
    required this.correctPercentage,
    required this.accuracyPercentage,
    required this.totalSeconds,
    required this.totalMinutes,
    required this.totalPoints,
    required this.bestScorePercentage,
    required this.averageScorePercentage,
  });

  final int attempts;
  final int totalQuestions;
  final int correctAnswers;
  final int? answeredQuestions;
  final int? unansweredQuestions;
  final int? wrongAnswers;
  final num? answeredPercentage;
  final num correctPercentage;
  final num? accuracyPercentage;
  final int totalSeconds;
  final num totalMinutes;
  final num totalPoints;
  final num bestScorePercentage;
  final num averageScorePercentage;
}

/// One calendar day (UTC) of the range.
class QuizDashboardDayMetric extends QuizDashboardStats {
  const QuizDashboardDayMetric({
    required this.date,
    required super.attempts,
    required super.totalQuestions,
    required super.correctAnswers,
    required super.answeredQuestions,
    required super.unansweredQuestions,
    required super.wrongAnswers,
    required super.answeredPercentage,
    required super.correctPercentage,
    required super.accuracyPercentage,
    required super.totalSeconds,
    required super.totalMinutes,
    required super.totalPoints,
    required super.bestScorePercentage,
    required super.averageScorePercentage,
  });

  /// `YYYY-MM-DD`, as sent.
  final String date;
}

/// The whole range, plus the figures only a range has.
class QuizDashboardTotals extends QuizDashboardStats {
  const QuizDashboardTotals({
    required super.attempts,
    required super.totalQuestions,
    required super.correctAnswers,
    required super.answeredQuestions,
    required super.unansweredQuestions,
    required super.wrongAnswers,
    required super.answeredPercentage,
    required super.correctPercentage,
    required super.accuracyPercentage,
    required super.totalSeconds,
    required super.totalMinutes,
    required super.totalPoints,
    required super.bestScorePercentage,
    required super.averageScorePercentage,
    required this.daysTracked,
    required this.currentStreak,
    required this.averageMinutesPerDay,
  });

  final int daysTracked;
  final int currentStreak;
  final num averageMinutesPerDay;
}

/// `GET /quizzes/dashboard`: [days] is one page of the range; [totals] always
/// covers the whole range.
class QuizDashboardData {
  const QuizDashboardData({
    required this.from,
    required this.to,
    required this.period,
    required this.days,
    required this.totals,
    required this.meta,
  });

  final String from;
  final String to;
  final QuizDashboardPeriod period;
  final List<QuizDashboardDayMetric> days;
  final QuizDashboardTotals totals;
  final PaginationMeta meta;
}

/// A user in a comparison, with their own dashboard over the same range.
class QuizComparedUser {
  const QuizComparedUser({
    required this.key,
    required this.rank,
    required this.isCurrentUser,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.totalPoints,
    required this.dashboard,
  });

  /// `user1`, `user2`.
  final String key;

  /// The overall leaderboard rank, as the server ranks it.
  final int rank;
  final bool isCurrentUser;
  final String userId;
  final String name;
  final String? avatarUrl;

  /// Overall points, not only this range's.
  final num totalPoints;

  /// This user's `from`, `to`, `period`, `meta`, `days` and `totals`.
  final QuizDashboardData dashboard;
}

/// How the current user stands against the other, as the server computed it:
/// the current user's figure minus theirs.
class QuizComparisonDifference {
  const QuizComparisonDifference({
    required this.attempts,
    required this.totalPoints,
    required this.totalMinutes,
    required this.correctPercentage,
    required this.isAhead,
  });

  final int attempts;
  final num totalPoints;
  final num totalMinutes;
  final num correctPercentage;
  final bool isAhead;
}

/// `GET /quizzes/dashboard/compare` or `/quizzes/dashboard/history/compare`.
class QuizComparison {
  const QuizComparison({
    required this.from,
    required this.to,
    required this.period,
    required this.comparedWith,
    required this.users,
    required this.difference,
    required this.meta,
  });

  final String from;
  final String to;
  final QuizDashboardPeriod period;

  /// `first_place`, `second_place`, or `null` when nobody else is ranked.
  final String? comparedWith;

  /// In the server's order; at most the current user and one other.
  final List<QuizComparedUser> users;

  /// `null` when there is nobody to compare with.
  final QuizComparisonDifference? difference;
  final PaginationMeta meta;

  QuizComparedUser? get currentUser {
    for (final user in users) {
      if (user.isCurrentUser) return user;
    }
    return null;
  }

  QuizComparedUser? get otherUser {
    for (final user in users) {
      if (!user.isCurrentUser) return user;
    }
    return null;
  }
}
