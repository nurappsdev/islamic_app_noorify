import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_category.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';

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
  const QuizCompletionArgs({required this.result, required this.launch});

  final QuizAttemptResult result;
  final QuizLaunchArgs launch;
}
