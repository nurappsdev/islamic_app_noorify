import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/quiz/data/models/quiz_category_model.dart';
import 'package:tuhfatul_muslim/features/quiz/data/models/quiz_model.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_enums.dart';

/// The `POST /quizzes/attempts` body. Only what the user did is sent - the
/// checked option keys and the time taken - never a score or an answer key.
extension QuizAttemptSubmissionJson on QuizAttemptSubmission {
  Map<String, dynamic> toJson() => {
    'attemptType': attemptType.apiValue,
    if (quizId != null) 'quizId': quizId,
    if (categoryId != null) 'categoryId': categoryId,
    'timeSpentSeconds': timeSpentSeconds,
    'used5050Lifeline': used5050Lifeline,
    'answers': [
      for (final answer in answers)
        {'questionId': answer.questionId, 'checkedBy': answer.checkedBy},
    ],
  };
}

int _int(Object? value) => readNum(value)?.toInt() ?? 0;

class QuizAttemptResultModel extends QuizAttemptResult {
  const QuizAttemptResultModel({
    required super.id,
    required super.attemptType,
    required super.totalQuestions,
    required super.correctAnswers,
    required super.incorrectAnswers,
    required super.scorePercentage,
    required super.pointsEarned,
    required super.maxPoints,
    required super.timeSpentSeconds,
    required super.amol,
  });

  factory QuizAttemptResultModel.fromJson(Map<String, dynamic> json) {
    final amol = readMap(json['amol']);
    return QuizAttemptResultModel(
      id: readId(json['id']) ?? '',
      attemptType: QuizAttemptType.fromApi(json['attemptType']),
      totalQuestions: _int(json['totalQuestions']),
      correctAnswers: _int(json['correctAnswers']),
      incorrectAnswers: _int(json['incorrectAnswers']),
      scorePercentage: readNum(json['scorePercentage']) ?? 0,
      pointsEarned: readNum(json['pointsEarned']) ?? 0,
      maxPoints: readNum(json['maxPoints']) ?? 0,
      timeSpentSeconds: _int(json['timeSpentSeconds']),
      amol: amol == null
          ? null
          : QuizAmolPoints(
              logDate: amol['logDate']?.toString() ?? '',
              quizPoints: readNum(amol['quizPoints']) ?? 0,
              quizMaxPoints: readNum(amol['quizMaxPoints']) ?? 0,
              dayTotalPoints: readNum(amol['dayTotalPoints']) ?? 0,
              dayMaxPoints: readNum(amol['dayMaxPoints']) ?? 0,
            ),
    );
  }
}

class QuizAttemptModel extends QuizAttempt {
  const QuizAttemptModel({
    required super.id,
    required super.attemptType,
    required super.quizId,
    required super.category,
    required super.totalQuestions,
    required super.correctAnswers,
    required super.incorrectAnswers,
    required super.scorePercentage,
    required super.pointsEarned,
    required super.maxPoints,
    required super.timeSpentSeconds,
    required super.used5050Lifeline,
    required super.completedAt,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    final category = readMap(json['category']);
    return QuizAttemptModel(
      id: readId(json['id']) ?? '',
      attemptType: QuizAttemptType.fromApi(json['attemptType']),
      quizId: readId(json['quizId']),
      category: category == null ? null : QuizCategoryModel.fromJson(category),
      totalQuestions: _int(json['totalQuestions']),
      correctAnswers: _int(json['correctAnswers']),
      incorrectAnswers: _int(json['incorrectAnswers']),
      scorePercentage: readNum(json['scorePercentage']) ?? 0,
      pointsEarned: readNum(json['pointsEarned']) ?? 0,
      maxPoints: readNum(json['maxPoints']) ?? 0,
      timeSpentSeconds: _int(json['timeSpentSeconds']),
      used5050Lifeline: json['used5050Lifeline'] == true,
      completedAt: DateTime.tryParse(
        json['completedAt']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}

class QuizAttemptPageModel extends QuizAttemptPage {
  const QuizAttemptPageModel({
    required super.summary,
    required super.attempts,
    required super.page,
    required super.totalPage,
  });

  /// [data] is `{summary, attempts}`; [meta] is the envelope's pagination.
  factory QuizAttemptPageModel.fromJson(
    Map<String, dynamic> data,
    Map<String, dynamic>? meta,
  ) {
    final summary = readMap(data['summary']);
    final rows = data['attempts'];
    return QuizAttemptPageModel(
      summary: summary == null
          ? QuizAttemptSummary.empty
          : QuizAttemptSummary(
              attempts: _int(summary['attempts']),
              bestScorePercentage: readNum(summary['bestScorePercentage']) ?? 0,
              averageScorePercentage:
                  readNum(summary['averageScorePercentage']) ?? 0,
            ),
      attempts: rows is List
          ? rows
                .map(readMap)
                .whereType<Map<String, dynamic>>()
                .map(QuizAttemptModel.fromJson)
                .toList()
          : const [],
      page: readNum(meta?['page'])?.toInt() ?? 1,
      totalPage: readNum(meta?['totalPage'])?.toInt() ?? 1,
    );
  }
}

class EvaluatedQuestionModel extends EvaluatedQuestion {
  const EvaluatedQuestionModel({
    required super.id,
    required super.categoryId,
    required super.category,
    required super.question,
    required super.options,
    required super.checkedBy,
    required super.correctAnswerKey,
    required super.explanation,
    required super.difficulty,
    required super.difficultyLabel,
    required super.displayOrder,
    required super.isActive,
    required super.isCorrect,
    required super.status,
  });

  /// A question deleted from the bank since comes back as `{id, question:
  /// null}` with the user's answer; it still counts, so it is kept.
  factory EvaluatedQuestionModel.fromJson(Map<String, dynamic> json) {
    final checkedBy = readId(json['checkedBy']);
    final isCorrect = json['isCorrect'] == true;
    final category = readMap(json['category']);
    final difficulty = readDifficulty(json['difficulty']);
    return EvaluatedQuestionModel(
      id: readId(json['id']) ?? '',
      categoryId: readId(json['categoryId']),
      category: category == null ? null : QuizCategoryModel.fromJson(category),
      question: LocalizedText.fromJson(json['question']),
      options: QuizOptionModel.listFromJson(json['options']),
      checkedBy: checkedBy,
      correctAnswerKey: readId(json['correctAnswerKey']),
      explanation: LocalizedText.fromJson(json['explanation']),
      difficulty: difficulty.level,
      difficultyLabel: difficulty.label,
      displayOrder: readNum(json['displayOrder'])?.toInt(),
      isActive: json['isActive'] != false,
      isCorrect: isCorrect,
      // `status` is the source of truth. Only a payload without it (an older
      // server) is derived, by the same rule the server applies.
      status:
          QuizAnswerStatus.fromApi(json['status']) ??
          (checkedBy == null
              ? QuizAnswerStatus.unanswered
              : (isCorrect
                    ? QuizAnswerStatus.correct
                    : QuizAnswerStatus.incorrect)),
    );
  }

  static List<EvaluatedQuestion> listFromJson(Object? json) => json is List
      ? json
            .map(readMap)
            .whereType<Map<String, dynamic>>()
            .map(EvaluatedQuestionModel.fromJson)
            .toList()
      : const [];
}

class QuizAttemptDetailModel extends QuizAttemptDetail {
  const QuizAttemptDetailModel({
    required super.attempt,
    required super.planId,
    required super.portionId,
    required super.answeredQuestions,
    required super.unansweredQuestions,
    required super.wrongAnswers,
    required super.answeredPercentage,
    required super.correctPercentage,
    required super.accuracyPercentage,
    required super.questions,
    required super.review,
  });

  factory QuizAttemptDetailModel.fromJson(Map<String, dynamic> json) {
    final questions = EvaluatedQuestionModel.listFromJson(json['questions']);
    final review = readMap(json['review']);
    List<EvaluatedQuestion> group(String name, QuizAnswerStatus status) =>
        review == null
        // Without the groups, split the ordered list by the same status.
        ? questions.where((q) => q.status == status).toList()
        : EvaluatedQuestionModel.listFromJson(review[name]);
    return QuizAttemptDetailModel(
      attempt: QuizAttemptModel.fromJson(json),
      planId: readId(json['planId']),
      portionId: readId(json['portionId']),
      answeredQuestions: readNum(json['answeredQuestions'])?.toInt(),
      unansweredQuestions: readNum(json['unansweredQuestions'])?.toInt(),
      wrongAnswers: readNum(json['wrongAnswers'])?.toInt(),
      answeredPercentage: readNum(json['answeredPercentage']),
      correctPercentage: readNum(json['correctPercentage']) ?? 0,
      accuracyPercentage: readNum(json['accuracyPercentage']),
      questions: questions,
      review: QuizAttemptReview(
        correct: group('correct', QuizAnswerStatus.correct),
        incorrect: group('incorrect', QuizAnswerStatus.incorrect),
        unanswered: group('unanswered', QuizAnswerStatus.unanswered),
      ),
    );
  }
}
