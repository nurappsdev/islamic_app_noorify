import 'package:tuhfatul_muslim/features/quiz/domain/entities/daily_quiz_status.dart';

class DailyQuizStatusModel extends DailyQuizStatus {
  const DailyQuizStatusModel({
    required super.date,
    super.quizId,
    super.isAvailable,
    super.isCompleted,
    super.hasCompleted,
    super.attemptCount,
    super.pointsEarned,
    super.pointsGained,
    super.quizScore,
    super.maxPoints,
    super.bestScorePercentage,
    super.latestAttemptId,
    super.completedAt,
  });

  factory DailyQuizStatusModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    num parseNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value == 1 || value == '1' || value == 'true') return true;
      return false;
    }

    return DailyQuizStatusModel(
      date: json['date']?.toString() ?? '',
      quizId: json['quizId']?.toString(),
      isAvailable: parseBool(json['isAvailable']),
      isCompleted: parseBool(json['isCompleted']),
      hasCompleted: parseBool(json['hasCompleted']),
      attemptCount: parseInt(json['attemptCount']),
      pointsEarned: parseNum(json['pointsEarned']),
      pointsGained: parseNum(json['pointsGained']),
      quizScore: parseNum(json['quizScore']),
      maxPoints: parseNum(json['maxPoints']),
      bestScorePercentage: parseNum(json['bestScorePercentage']),
      latestAttemptId: json['latestAttemptId']?.toString(),
      completedAt: parseDate(json['completedAt']),
    );
  }
}
