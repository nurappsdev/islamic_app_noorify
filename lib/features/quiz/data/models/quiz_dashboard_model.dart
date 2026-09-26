import 'package:islami_app_noorify/features/quiz/data/models/quiz_category_model.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_dashboard.dart';

int _int(Object? value) => readNum(value)?.toInt() ?? 0;
int? _intOrNull(Object? value) => readNum(value)?.toInt();

class PaginationMetaModel extends PaginationMeta {
  const PaginationMetaModel({
    required super.page,
    required super.limit,
    required super.total,
    required super.totalPage,
  });

  /// A missing `meta` is read as a single page holding [itemCount] items.
  factory PaginationMetaModel.fromJson(Object? json, {int itemCount = 0}) {
    final map = readMap(json);
    return PaginationMetaModel(
      page: readNum(map?['page'])?.toInt() ?? 1,
      limit: readNum(map?['limit'])?.toInt() ?? itemCount,
      total: readNum(map?['total'])?.toInt() ?? itemCount,
      totalPage: readNum(map?['totalPage'])?.toInt() ?? 1,
    );
  }
}

class QuizDashboardDayMetricModel extends QuizDashboardDayMetric {
  const QuizDashboardDayMetricModel({
    required super.date,
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

  factory QuizDashboardDayMetricModel.fromJson(Map<String, dynamic> json) {
    return QuizDashboardDayMetricModel(
      date: json['date']?.toString() ?? '',
      attempts: _int(json['attempts']),
      totalQuestions: _int(json['totalQuestions']),
      correctAnswers: _int(json['correctAnswers']),
      answeredQuestions: _intOrNull(json['answeredQuestions']),
      unansweredQuestions: _intOrNull(json['unansweredQuestions']),
      wrongAnswers: _intOrNull(json['wrongAnswers']),
      answeredPercentage: readNum(json['answeredPercentage']),
      correctPercentage: readNum(json['correctPercentage']) ?? 0,
      accuracyPercentage: readNum(json['accuracyPercentage']),
      totalSeconds: _int(json['totalSeconds']),
      totalMinutes: readNum(json['totalMinutes']) ?? 0,
      totalPoints: readNum(json['totalPoints']) ?? 0,
      bestScorePercentage: readNum(json['bestScorePercentage']) ?? 0,
      averageScorePercentage: readNum(json['averageScorePercentage']) ?? 0,
    );
  }
}

class QuizDashboardTotalsModel extends QuizDashboardTotals {
  const QuizDashboardTotalsModel({
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
    required super.daysTracked,
    required super.currentStreak,
    required super.averageMinutesPerDay,
  });

  factory QuizDashboardTotalsModel.fromJson(Map<String, dynamic>? json) {
    final m = json ?? const <String, dynamic>{};
    return QuizDashboardTotalsModel(
      attempts: _int(m['attempts']),
      totalQuestions: _int(m['totalQuestions']),
      correctAnswers: _int(m['correctAnswers']),
      answeredQuestions: _intOrNull(m['answeredQuestions']),
      unansweredQuestions: _intOrNull(m['unansweredQuestions']),
      wrongAnswers: _intOrNull(m['wrongAnswers']),
      answeredPercentage: readNum(m['answeredPercentage']),
      correctPercentage: readNum(m['correctPercentage']) ?? 0,
      accuracyPercentage: readNum(m['accuracyPercentage']),
      totalSeconds: _int(m['totalSeconds']),
      totalMinutes: readNum(m['totalMinutes']) ?? 0,
      totalPoints: readNum(m['totalPoints']) ?? 0,
      bestScorePercentage: readNum(m['bestScorePercentage']) ?? 0,
      averageScorePercentage: readNum(m['averageScorePercentage']) ?? 0,
      daysTracked: _int(m['daysTracked']),
      currentStreak: _int(m['currentStreak']),
      averageMinutesPerDay: readNum(m['averageMinutesPerDay']) ?? 0,
    );
  }
}

class QuizDashboardDataModel extends QuizDashboardData {
  const QuizDashboardDataModel({
    required super.from,
    required super.to,
    required super.period,
    required super.days,
    required super.totals,
    required super.meta,
  });

  /// [json] is the dashboard object. The endpoint sends `meta` beside `data`
  /// in the envelope, a compared user carries it inside, so it is passed in.
  factory QuizDashboardDataModel.fromJson(
    Map<String, dynamic> json, {
    Object? meta,
  }) {
    final rawDays = json['days'];
    final days = rawDays is List
        ? rawDays
              .map(readMap)
              .whereType<Map<String, dynamic>>()
              .map(QuizDashboardDayMetricModel.fromJson)
              .toList()
        : const <QuizDashboardDayMetric>[];
    return QuizDashboardDataModel(
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      period: QuizDashboardPeriod.fromApi(json['period']),
      days: days,
      totals: QuizDashboardTotalsModel.fromJson(readMap(json['totals'])),
      meta: PaginationMetaModel.fromJson(
        meta ?? json['meta'],
        itemCount: days.length,
      ),
    );
  }
}

class QuizComparedUserModel extends QuizComparedUser {
  const QuizComparedUserModel({
    required super.key,
    required super.rank,
    required super.isCurrentUser,
    required super.userId,
    required super.name,
    required super.avatarUrl,
    required super.totalPoints,
    required super.dashboard,
  });

  factory QuizComparedUserModel.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatarUrl']?.toString().trim();
    return QuizComparedUserModel(
      key: json['key']?.toString() ?? '',
      rank: _int(json['rank']),
      isCurrentUser: json['isCurrentUser'] == true,
      userId: readId(json['userId']) ?? '',
      name: json['name']?.toString().trim() ?? '',
      avatarUrl: (avatar == null || avatar.isEmpty) ? null : avatar,
      totalPoints: readNum(json['totalPoints']) ?? 0,
      dashboard: QuizDashboardDataModel.fromJson(json),
    );
  }
}

class QuizComparisonModel extends QuizComparison {
  const QuizComparisonModel({
    required super.from,
    required super.to,
    required super.period,
    required super.comparedWith,
    required super.users,
    required super.difference,
    required super.meta,
  });

  factory QuizComparisonModel.fromJson(
    Map<String, dynamic> json, {
    Object? meta,
  }) {
    final rawUsers = json['users'];
    final users = rawUsers is List
        ? rawUsers
              .map(readMap)
              .whereType<Map<String, dynamic>>()
              .map(QuizComparedUserModel.fromJson)
              .toList()
        : const <QuizComparedUser>[];
    final difference = readMap(json['difference']);
    return QuizComparisonModel(
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      period: QuizDashboardPeriod.fromApi(json['period']),
      comparedWith: readId(json['comparedWith']),
      users: users,
      difference: difference == null
          ? null
          : QuizComparisonDifference(
              attempts: _int(difference['attempts']),
              totalPoints: readNum(difference['totalPoints']) ?? 0,
              totalMinutes: readNum(difference['totalMinutes']) ?? 0,
              correctPercentage: readNum(difference['correctPercentage']) ?? 0,
              isAhead: difference['isAhead'] == true,
            ),
      meta: PaginationMetaModel.fromJson(meta, itemCount: users.length),
    );
  }
}
