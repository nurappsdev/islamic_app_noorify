import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';
import 'package:islami_app_noorify/features/quiz/data/models/quiz_category_model.dart';
import 'package:islami_app_noorify/features/quiz/data/models/quiz_dashboard_model.dart';
import 'package:islami_app_noorify/features/quiz/data/models/quiz_model.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';

int _int(Object? value) => readNum(value)?.toInt() ?? 0;

/// An API timestamp (UTC `...Z` or with an offset) as local time.
DateTime? readQuizPlanDate(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}

/// [value] as the API takes it: the same instant in UTC ISO-8601, e.g.
/// `2026-09-30T12:00:00.000Z` for 6 pm in Dhaka. The offset comes from the
/// device's time zone; nothing is added or subtracted by hand.
String writeQuizPlanDate(DateTime value) => value.toUtc().toIso8601String();

List<Map<String, dynamic>> _maps(Object? json) => json is List
    ? json.map(readMap).whereType<Map<String, dynamic>>().toList()
    : const [];

class QuizPlanPortionModel extends QuizPlanPortion {
  const QuizPlanPortionModel({
    required super.id,
    required super.order,
    required super.categoryId,
    required super.categoryName,
    required super.difficulty,
    required super.totalQuestions,
    required super.isCompleted,
    required super.attemptId,
    required super.scorePercentage,
    required super.completedAt,
  });

  factory QuizPlanPortionModel.fromJson(Map<String, dynamic> json) {
    return QuizPlanPortionModel(
      id: readId(json['id']) ?? '',
      order: _int(json['order']),
      categoryId: readId(json['categoryId']) ?? '',
      categoryName: LocalizedText.fromJson(json['categoryName']),
      difficulty: QuizDifficulty.fromApi(json['difficulty']),
      totalQuestions: _int(json['totalQuestions']),
      isCompleted: json['isCompleted'] == true,
      attemptId: readId(json['attemptId']),
      scorePercentage: readNum(json['scorePercentage']),
      completedAt: readQuizPlanDate(json['completedAt']),
    );
  }
}

class QuizPlanModel extends QuizPlan {
  const QuizPlanModel({
    required super.id,
    required super.name,
    required super.scheduledAt,
    required super.startedAt,
    required super.createdAt,
    required super.status,
    required super.rawStatus,
    required super.totalQuizzes,
    required super.completedQuizzes,
    required super.remainingQuizzes,
    required super.totalQuestions,
    required super.completionPercentage,
    required super.portions,
  });

  factory QuizPlanModel.fromJson(Map<String, dynamic> json) {
    final portions =
        _maps(json['portions']).map(QuizPlanPortionModel.fromJson).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return QuizPlanModel(
      id: readId(json['id']) ?? '',
      name: json['name']?.toString() ?? '',
      scheduledAt: readQuizPlanDate(json['scheduledAt']),
      startedAt: readQuizPlanDate(json['startedAt']),
      createdAt: readQuizPlanDate(json['createdAt']),
      status: QuizPlanStatus.fromApi(json['status']),
      rawStatus: json['status']?.toString() ?? '',
      totalQuizzes: _int(json['totalQuizzes']),
      completedQuizzes: _int(json['completedQuizzes']),
      remainingQuizzes: _int(json['remainingQuizzes']),
      totalQuestions: _int(json['totalQuestions']),
      completionPercentage: readNum(json['completionPercentage']) ?? 0,
      portions: portions,
    );
  }

  static List<QuizPlan> listFromJson(Object? json) =>
      _maps(json).map(QuizPlanModel.fromJson).toList();
}

class PlannedQuestionModel extends PlannedQuestion {
  const PlannedQuestionModel({
    required super.id,
    required super.categoryId,
    required super.question,
    required super.options,
    required super.difficulty,
    required super.checkedBy,
    required super.portionId,
    required super.questionOrder,
  });

  factory PlannedQuestionModel.fromJson(Map<String, dynamic> json) {
    return PlannedQuestionModel(
      id: readId(json['id']) ?? '',
      categoryId: readId(json['categoryId']),
      question: LocalizedText.fromJson(json['question']),
      options: QuizOptionModel.listFromJson(json['options']),
      // A plain `easy` / `medium` / `hard` string here.
      difficulty: QuizDifficulty.fromApi(json['difficulty']),
      checkedBy: readId(json['checkedBy']),
      portionId: readId(json['portionId']) ?? '',
      questionOrder: _int(json['questionOrder']),
    );
  }

  static List<PlannedQuestion> listFromJson(Object? json) => _maps(
    json,
  ).map(PlannedQuestionModel.fromJson).where((q) => q.id.isNotEmpty).toList();
}

class PlannedQuizResultModel extends PlannedQuizResult {
  const PlannedQuizResultModel({
    required super.id,
    required super.planId,
    required super.portionId,
    required super.attemptType,
    required super.answeredQuestions,
    required super.unansweredQuestions,
    required super.wrongAnswers,
    required super.answeredPercentage,
    required super.correctPercentage,
    required super.accuracyPercentage,
    required super.totalQuestions,
    required super.correctAnswers,
    required super.incorrectAnswers,
    required super.scorePercentage,
    required super.pointsEarned,
    required super.maxPoints,
    required super.amol,
    required super.timeSpentSeconds,
    required super.completedAt,
    required super.answers,
  });

  factory PlannedQuizResultModel.fromJson(Map<String, dynamic> json) {
    final amol = readMap(json['amol']);
    return PlannedQuizResultModel(
      id: readId(json['id']) ?? '',
      planId: readId(json['planId']),
      portionId: readId(json['portionId']),
      attemptType: QuizAttemptType.fromApi(json['attemptType']),
      answeredQuestions: readNum(json['answeredQuestions'])?.toInt(),
      unansweredQuestions: readNum(json['unansweredQuestions'])?.toInt(),
      wrongAnswers: readNum(json['wrongAnswers'])?.toInt(),
      answeredPercentage: readNum(json['answeredPercentage']),
      correctPercentage: readNum(json['correctPercentage']) ?? 0,
      accuracyPercentage: readNum(json['accuracyPercentage']),
      totalQuestions: _int(json['totalQuestions']),
      correctAnswers: _int(json['correctAnswers']),
      incorrectAnswers: _int(json['incorrectAnswers']),
      scorePercentage: readNum(json['scorePercentage']) ?? 0,
      pointsEarned: readNum(json['pointsEarned']) ?? 0,
      maxPoints: readNum(json['maxPoints']) ?? 0,
      amol: amol == null
          ? null
          : QuizAmolPoints(
              logDate: amol['logDate']?.toString() ?? '',
              quizPoints: readNum(amol['quizPoints']) ?? 0,
              quizMaxPoints: readNum(amol['quizMaxPoints']) ?? 0,
              dayTotalPoints: readNum(amol['dayTotalPoints']) ?? 0,
              dayMaxPoints: readNum(amol['dayMaxPoints']) ?? 0,
            ),
      timeSpentSeconds: _int(json['timeSpentSeconds']),
      completedAt: readQuizPlanDate(json['completedAt']),
      answers: _maps(json['answers'])
          .map(
            (a) => PlannedAnswerResult(
              questionId: readId(a['questionId']) ?? '',
              checkedBy: readId(a['checkedBy']),
              correctAnswerKey: readId(a['correctAnswerKey']),
              isCorrect: a['isCorrect'] == true,
            ),
          )
          .toList(),
    );
  }
}

/// A page of plans or questions: `data` plus the envelope's `meta`.
PaginationMeta readQuizPlanMeta(Object? meta, int itemCount) =>
    PaginationMetaModel.fromJson(meta, itemCount: itemCount);

extension QuizPlanDraftJson on QuizPlanDraft {
  Map<String, dynamic> toJson() {
    final schedule = scheduledAt;
    return {
      'name': name.trim(),
      if (schedule != null) 'scheduledAt': writeQuizPlanDate(schedule),
      'portions': [
        for (final portion in portions)
          {
            'categoryId': portion.categoryId,
            'quizCount': portion.quizCount,
            'questionCount': portion.questionCount,
            if (portion.difficulty != null)
              'difficulty': portion.difficulty!.apiValue,
          },
      ],
    };
  }
}

extension QuizPlanUpdateJson on QuizPlanUpdate {
  Map<String, dynamic> toJson() {
    final schedule = scheduledAt;
    return {
      if (name != null) 'name': name!.trim(),
      if (clearSchedule)
        'scheduledAt': null
      else if (schedule != null)
        'scheduledAt': writeQuizPlanDate(schedule),
    };
  }
}

extension PlannedQuizSubmissionJson on PlannedQuizSubmission {
  Map<String, dynamic> toJson() => {
    'timeSpentSeconds': timeSpentSeconds,
    'used5050Lifeline': used5050Lifeline,
    'answers': [
      for (final answer in answers)
        {'questionId': answer.questionId, 'checkedBy': answer.checkedBy},
    ],
  };
}
