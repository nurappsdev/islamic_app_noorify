import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';

/// A plan's `status`, as the server derives it. Any value this build does not
/// know is kept as [unknown], with the raw text in [QuizPlan.rawStatus].
enum QuizPlanStatus {
  planned('planned'),
  inProgress('in_progress'),
  completed('completed'),
  abandoned('abandoned'),
  unknown('');

  const QuizPlanStatus(this.apiValue);

  final String apiValue;

  static QuizPlanStatus fromApi(Object? value) =>
      QuizPlanStatus.values.firstWhere(
        (s) => s != unknown && s.apiValue == value,
        orElse: () => unknown,
      );

  /// Still open: not finished and not given up.
  bool get isActive => this == planned || this == inProgress;
}

/// One quiz of a plan: a set of questions drawn from one category.
class QuizPlanPortion {
  const QuizPlanPortion({
    required this.id,
    required this.order,
    required this.categoryId,
    required this.categoryName,
    required this.difficulty,
    required this.totalQuestions,
    required this.isCompleted,
    required this.attemptId,
    required this.scorePercentage,
    required this.completedAt,
  });

  final String id;

  /// 1-based position in the plan.
  final int order;
  final String categoryId;
  final LocalizedText categoryName;
  final QuizDifficulty? difficulty;
  final int totalQuestions;
  final bool isCompleted;

  /// The attempt that completed it; `null` until then.
  final String? attemptId;
  final num? scorePercentage;
  final DateTime? completedAt;
}

/// A scheduled quiz plan (`/quizzes/plans`). Every figure is the server's.
class QuizPlan {
  const QuizPlan({
    required this.id,
    required this.name,
    required this.scheduledAt,
    required this.startedAt,
    required this.createdAt,
    required this.status,
    required this.rawStatus,
    required this.totalQuizzes,
    required this.completedQuizzes,
    required this.remainingQuizzes,
    required this.totalQuestions,
    required this.completionPercentage,
    required this.portions,
  });

  final String id;
  final String name;

  /// Local time; `null` when the plan has no schedule.
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? createdAt;
  final QuizPlanStatus status;

  /// The status exactly as sent, for a status this build does not know.
  final String rawStatus;
  final int totalQuizzes;
  final int completedQuizzes;
  final int remainingQuizzes;
  final int totalQuestions;
  final num completionPercentage;

  /// In plan order.
  final List<QuizPlanPortion> portions;

  /// The first portion still to be played, if any.
  QuizPlanPortion? get nextPortion {
    for (final portion in portions) {
      if (!portion.isCompleted) return portion;
    }
    return null;
  }

  /// A plan that has not been started can be; the server refuses abandoned.
  bool get canStart => status == QuizPlanStatus.planned;

  /// A started plan with a quiz left can be played on.
  bool get canContinue =>
      status == QuizPlanStatus.inProgress && nextPortion != null;

  /// Only an open plan can be abandoned.
  bool get canAbandon => status.isActive;
}

/// One quiz to create: [quizCount] quizzes of [questionCount] questions each
/// from one category. The server turns each into its own portion.
class QuizPlanPortionDraft {
  const QuizPlanPortionDraft({
    required this.categoryId,
    required this.categoryName,
    required this.quizCount,
    required this.questionCount,
    this.difficulty,
  });

  final String categoryId;

  /// For showing the draft only; not sent.
  final LocalizedText categoryName;
  final int quizCount;
  final int questionCount;
  final QuizDifficulty? difficulty;
}

/// `POST /quizzes/plans`.
class QuizPlanDraft {
  const QuizPlanDraft({
    required this.name,
    required this.scheduledAt,
    required this.portions,
  });

  final String name;
  final DateTime? scheduledAt;
  final List<QuizPlanPortionDraft> portions;
}

/// `PATCH /quizzes/plans/{id}`: the only fields the server lets change.
class QuizPlanUpdate {
  const QuizPlanUpdate({
    this.name,
    this.scheduledAt,
    this.clearSchedule = false,
  });

  final String? name;
  final DateTime? scheduledAt;

  /// Sends `scheduledAt: null`, removing the schedule.
  final bool clearSchedule;

  bool get isEmpty => name == null && scheduledAt == null && !clearSchedule;
}

/// One page of `GET /quizzes/plans`.
class QuizPlanPage {
  const QuizPlanPage({required this.plans, required this.meta});

  final List<QuizPlan> plans;
  final PaginationMeta meta;
}

/// A question of a started plan. Its `difficulty` is a plain `easy` /
/// `medium` / `hard` string here, unlike the normal quiz's labelled object,
/// and the answer key is never sent.
class PlannedQuestion {
  const PlannedQuestion({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.options,
    required this.difficulty,
    required this.checkedBy,
    required this.portionId,
    required this.questionOrder,
  });

  final String id;
  final String? categoryId;
  final LocalizedText question;
  final List<QuizOption> options;
  final QuizDifficulty? difficulty;
  final String? checkedBy;
  final String portionId;

  /// 1-based position in its portion.
  final int questionOrder;
}

/// One page of `GET /quizzes/plans/{id}/questions`.
class PlannedQuestionPage {
  const PlannedQuestionPage({required this.questions, required this.meta});

  final List<PlannedQuestion> questions;
  final PaginationMeta meta;
}

/// `POST /quizzes/plans/{planId}/portions/{portionId}/attempts`. Only what
/// the user did; the server scores it.
class PlannedQuizSubmission {
  const PlannedQuizSubmission({
    required this.timeSpentSeconds,
    required this.used5050Lifeline,
    required this.answers,
  });

  final int timeSpentSeconds;
  final bool used5050Lifeline;

  /// Every question; one left unanswered has a `null` checkedBy.
  final List<QuizAnswer> answers;
}

/// How one submitted answer was marked.
class PlannedAnswerResult {
  const PlannedAnswerResult({
    required this.questionId,
    required this.checkedBy,
    required this.correctAnswerKey,
    required this.isCorrect,
  });

  final String questionId;
  final String? checkedBy;
  final String? correctAnswerKey;
  final bool isCorrect;
}

/// The server's scoring of a planned quiz.
class PlannedQuizResult {
  const PlannedQuizResult({
    required this.id,
    required this.planId,
    required this.portionId,
    required this.attemptType,
    required this.answeredQuestions,
    required this.unansweredQuestions,
    required this.wrongAnswers,
    required this.answeredPercentage,
    required this.correctPercentage,
    required this.accuracyPercentage,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.scorePercentage,
    required this.pointsEarned,
    required this.maxPoints,
    required this.amol,
    required this.timeSpentSeconds,
    required this.completedAt,
    required this.answers,
  });

  final String id;
  final String? planId;
  final String? portionId;
  final QuizAttemptType attemptType;
  final int? answeredQuestions;
  final int? unansweredQuestions;
  final int? wrongAnswers;
  final num? answeredPercentage;
  final num correctPercentage;
  final num? accuracyPercentage;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final num scorePercentage;
  final num pointsEarned;
  final num maxPoints;

  /// Only a daily quiz books amol points, so usually `null` here.
  final QuizAmolPoints? amol;
  final int timeSpentSeconds;
  final DateTime? completedAt;
  final List<PlannedAnswerResult> answers;
}
