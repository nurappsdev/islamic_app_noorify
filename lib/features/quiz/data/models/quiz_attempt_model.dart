import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/data/models/quiz_category_model.dart';
import 'package:islami_app_noorify/features/quiz/data/models/quiz_model.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';

/// The `POST /quizzes/attempts` body. Only what the user did is sent - the
/// checked option keys and the time taken - never a score or an answer key.
extension QuizAttemptSubmissionJson on QuizAttemptSubmission {
  Map<String, dynamic> toJson() => {
    'attemptType': attemptType.apiValue,
    if (quizId != null) 'quizId': quizId,
    if (categoryId != null) 'categoryId': categoryId,
    'timeSpentSeconds': timeSpentSeconds,
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

class QuizReviewQuestionModel extends QuizReviewQuestion {
  const QuizReviewQuestionModel({
    required super.id,
    required super.question,
    required super.options,
    required super.checkedBy,
    required super.correctAnswerKey,
    required super.explanation,
    required super.difficultyLabel,
    required super.isCorrect,
  });

  /// A question deleted from the bank since comes back as `{id, question:
  /// null}` with the user's answer; it still counts, so it is kept.
  factory QuizReviewQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizReviewQuestionModel(
      id: readId(json['id']) ?? '',
      question: LocalizedText.fromJson(json['question']),
      options: QuizOptionModel.listFromJson(json['options']),
      checkedBy: readId(json['checkedBy']),
      correctAnswerKey: readId(json['correctAnswerKey']),
      explanation: LocalizedText.fromJson(json['explanation']),
      difficultyLabel: readDifficulty(json['difficulty']).label,
      isCorrect: json['isCorrect'] == true,
    );
  }
}

class QuizAttemptDetailModel extends QuizAttemptDetail {
  const QuizAttemptDetailModel({
    required super.attempt,
    required super.questions,
  });

  factory QuizAttemptDetailModel.fromJson(Map<String, dynamic> json) {
    final rows = json['questions'];
    return QuizAttemptDetailModel(
      attempt: QuizAttemptModel.fromJson(json),
      questions: rows is List
          ? rows
                .map(readMap)
                .whereType<Map<String, dynamic>>()
                .map(QuizReviewQuestionModel.fromJson)
                .toList()
          : const [],
    );
  }
}
