import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_category.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';

/// The option the user checked for one question; `null` when left unanswered.
class QuizAnswer {
  const QuizAnswer({required this.questionId, required this.checkedBy});

  final String questionId;
  final String? checkedBy;
}

/// What the client sends to `POST /quizzes/attempts`. Deliberately carries no
/// score or correctness: the server decides those from its answer key.
class QuizAttemptSubmission {
  const QuizAttemptSubmission({
    required this.attemptType,
    required this.quizId,
    required this.categoryId,
    required this.timeSpentSeconds,
    this.used5050Lifeline = false,
    required this.answers,
  });

  final QuizAttemptType attemptType;
  final String? quizId;
  final String? categoryId;
  final int timeSpentSeconds;
  final bool used5050Lifeline;
  final List<QuizAnswer> answers;
}

/// Where the daily quiz pillar of today's amol record stands after a daily
/// attempt. The day keeps its best score.
class QuizAmolPoints {
  const QuizAmolPoints({
    required this.logDate,
    required this.quizPoints,
    required this.quizMaxPoints,
    required this.dayTotalPoints,
    required this.dayMaxPoints,
  });

  final String logDate;
  final num quizPoints;
  final num quizMaxPoints;
  final num dayTotalPoints;
  final num dayMaxPoints;
}

/// The server-scored outcome of a submitted attempt.
class QuizAttemptResult {
  const QuizAttemptResult({
    required this.id,
    required this.attemptType,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.scorePercentage,
    required this.pointsEarned,
    required this.maxPoints,
    required this.timeSpentSeconds,
    required this.amol,
  });

  final String id;
  final QuizAttemptType attemptType;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final num scorePercentage;
  final num pointsEarned;
  final num maxPoints;
  final int timeSpentSeconds;

  /// Present for a daily attempt only.
  final QuizAmolPoints? amol;
}

/// One row of the attempt history (`GET /quizzes/attempts`).
class QuizAttempt {
  const QuizAttempt({
    required this.id,
    required this.attemptType,
    required this.quizId,
    required this.category,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.scorePercentage,
    required this.pointsEarned,
    required this.maxPoints,
    required this.timeSpentSeconds,
    required this.used5050Lifeline,
    required this.completedAt,
  });

  final String id;
  final QuizAttemptType attemptType;
  final String? quizId;
  final QuizCategory? category;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final num scorePercentage;
  final num pointsEarned;
  final num maxPoints;
  final int timeSpentSeconds;
  final bool used5050Lifeline;
  final DateTime? completedAt;
}

/// The history's headline figures, as computed by the server.
class QuizAttemptSummary {
  const QuizAttemptSummary({
    required this.attempts,
    required this.bestScorePercentage,
    required this.averageScorePercentage,
  });

  static const QuizAttemptSummary empty = QuizAttemptSummary(
    attempts: 0,
    bestScorePercentage: 0,
    averageScorePercentage: 0,
  );

  final int attempts;
  final num bestScorePercentage;
  final num averageScorePercentage;
}

/// One page of the attempt history.
class QuizAttemptPage {
  const QuizAttemptPage({
    required this.summary,
    required this.attempts,
    required this.page,
    required this.totalPage,
  });

  final QuizAttemptSummary summary;
  final List<QuizAttempt> attempts;
  final int page;
  final int totalPage;

  bool get hasMore => page < totalPage;
}

/// A question of a finished attempt, with the answer revealed and the
/// server's verdict on it.
class EvaluatedQuestion {
  const EvaluatedQuestion({
    required this.id,
    required this.categoryId,
    required this.category,
    required this.question,
    required this.options,
    required this.checkedBy,
    required this.correctAnswerKey,
    required this.explanation,
    required this.difficulty,
    required this.difficultyLabel,
    required this.displayOrder,
    required this.isActive,
    required this.isCorrect,
    required this.status,
  });

  final String id;
  final String? categoryId;
  final QuizCategory? category;

  /// Empty when the question has since been removed from the bank.
  final LocalizedText question;
  final List<QuizOption> options;
  final String? checkedBy;
  final String? correctAnswerKey;
  final LocalizedText explanation;
  final QuizDifficulty? difficulty;
  final LocalizedText difficultyLabel;
  final int? displayOrder;
  final bool isActive;
  final bool isCorrect;

  /// The source of truth for how the question is marked.
  final QuizAnswerStatus status;
}

/// The attempt's questions grouped by [EvaluatedQuestion.status], as sent.
class QuizAttemptReview {
  const QuizAttemptReview({
    required this.correct,
    required this.incorrect,
    required this.unanswered,
  });

  final List<EvaluatedQuestion> correct;
  final List<EvaluatedQuestion> incorrect;
  final List<EvaluatedQuestion> unanswered;
}

/// One attempt in full (`GET /quizzes/attempts/{id}/review`). The answered
/// figures are `null` for an attempt recorded before answers were stored.
class QuizAttemptDetail {
  const QuizAttemptDetail({
    required this.attempt,
    required this.planId,
    required this.portionId,
    required this.answeredQuestions,
    required this.unansweredQuestions,
    required this.wrongAnswers,
    required this.answeredPercentage,
    required this.correctPercentage,
    required this.accuracyPercentage,
    required this.questions,
    required this.review,
  });

  final QuizAttempt attempt;
  final String? planId;
  final String? portionId;
  final int? answeredQuestions;
  final int? unansweredQuestions;
  final int? wrongAnswers;
  final num? answeredPercentage;
  final num correctPercentage;
  final num? accuracyPercentage;

  /// Every question in the order it was asked.
  final List<EvaluatedQuestion> questions;
  final QuizAttemptReview review;
}
