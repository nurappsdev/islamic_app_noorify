/// The `attemptType` the API scores an attempt under. Kept here once so the
/// wire strings are never scattered through the app.
enum QuizAttemptType {
  daily('daily'),
  category('category'),
  plan('plan');

  const QuizAttemptType(this.apiValue);

  final String apiValue;

  /// Unknown values read as [category]: scored, but earning no amol points.
  static QuizAttemptType fromApi(Object? value) => QuizAttemptType.values
      .firstWhere((type) => type.apiValue == value, orElse: () => category);
}

/// The `difficulty` filter a category quiz can be drawn with.
enum QuizDifficulty {
  easy('easy'),
  medium('medium'),
  hard('hard');

  const QuizDifficulty(this.apiValue);

  final String apiValue;

  static QuizDifficulty? fromApi(Object? value) {
    for (final difficulty in QuizDifficulty.values) {
      if (difficulty.apiValue == value) return difficulty;
    }
    return null;
  }
}

/// Where a quiz submission stands. Once it leaves [idle] the quiz is closed:
/// the timer stops and only a retry of a [failed] submission is accepted.
enum QuizSubmissionStatus { idle, submitting, submitted, failed }

/// How a question of a finished attempt went, as the server reports it.
enum QuizAnswerStatus {
  correct('correct'),
  incorrect('incorrect'),
  unanswered('unanswered');

  const QuizAnswerStatus(this.apiValue);

  final String apiValue;

  static QuizAnswerStatus? fromApi(Object? value) {
    for (final status in QuizAnswerStatus.values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }
}
