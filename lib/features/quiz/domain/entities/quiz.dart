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

/// Where a daily quiz stands in its day: a day has [quizzesPerDay] quizzes,
/// played one after the other, the next drawn once the one before it is
/// submitted.
class DailyQuizProgress {
  const DailyQuizProgress({
    required this.sequence,
    required this.quizzesPerDay,
    required this.completedQuizzes,
    required this.dayCompleted,
  });

  /// Which of the day's quizzes this is (1-based).
  final int sequence;
  final int quizzesPerDay;

  /// How many of the day's quizzes were done before this one was served.
  final int completedQuizzes;

  /// Every quiz of the day is done: this one is the last, already played.
  final bool dayCompleted;

  /// More than one daily quiz a day, so they are numbered.
  bool get numbered => quizzesPerDay > 1;

  /// Another quiz of the day follows this one.
  bool get hasNext => sequence < quizzesPerDay;
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
    this.daily,
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

  /// A daily quiz's place in its day; null for other quizzes.
  final DailyQuizProgress? daily;
}
