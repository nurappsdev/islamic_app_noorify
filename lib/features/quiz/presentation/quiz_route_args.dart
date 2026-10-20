import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_category.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_enums.dart';

/// Which quiz the question screen should fetch and play.
class QuizLaunchArgs {
  const QuizLaunchArgs.daily()
    : attemptType = QuizAttemptType.daily,
      categoryId = null,
      categoryName = LocalizedText.empty,
      limit = 10,
      difficulty = null;

  QuizLaunchArgs.category(
    QuizCategory category, {
    this.limit = 10,
    this.difficulty,
  }) : attemptType = QuizAttemptType.category,
       categoryId = category.id,
       categoryName = category.name;

  final QuizAttemptType attemptType;
  final String? categoryId;
  final LocalizedText categoryName;

  /// How many questions to draw for a category quiz; the server may return
  /// fewer when the category holds fewer.
  final int limit;
  final QuizDifficulty? difficulty;
}

/// What the result screen shows: the server-scored attempt.
class QuizCompletionArgs {
  const QuizCompletionArgs({
    required this.result,
    required this.launch,
    this.daily,
  });

  final QuizAttemptResult result;
  final QuizLaunchArgs launch;

  /// The played daily quiz's place in its day, so the result can offer the
  /// next one.
  final DailyQuizProgress? daily;
}
