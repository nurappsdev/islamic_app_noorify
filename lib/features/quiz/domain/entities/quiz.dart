import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_category.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_enums.dart';

/// One answer choice. [key] (`A`-`E`) is what gets submitted, never the text.
class QuizOption {
  const QuizOption({required this.key, required this.text});

  final String key;
  final LocalizedText text;
}

/// A question as served for playing: the answer key is withheld.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.options,
    required this.difficulty,
    required this.difficultyLabel,
    required this.displayOrder,
    required this.isActive,
  });

  final String id;
  final String? categoryId;
  final LocalizedText question;
  final List<QuizOption> options;
  final QuizDifficulty? difficulty;
  final LocalizedText difficultyLabel;
  final int? displayOrder;
  final bool isActive;
}

/// A playable quiz: the day's quiz (`GET /quizzes/daily`) or a practice quiz
/// drawn from one category (`GET /quizzes/categories/{id}/quiz`).
class Quiz {
  const Quiz({
    required this.source,
    required this.id,
    required this.quizDate,
    required this.category,
    required this.pointsReward,
    required this.timeLimitSeconds,
    required this.totalQuestions,
    required this.questions,
  });

  /// Which kind of quiz this is, and so the `attemptType` it is submitted as.
  final QuizAttemptType source;

  /// The stored quiz id; only a daily quiz has one.
  final String? id;
  final String? quizDate;

  /// The category a practice quiz was drawn from.
  final QuizCategory? category;
  final num pointsReward;
  final int timeLimitSeconds;
  final int totalQuestions;

  /// Active questions only, in play order.
  final List<QuizQuestion> questions;
}
