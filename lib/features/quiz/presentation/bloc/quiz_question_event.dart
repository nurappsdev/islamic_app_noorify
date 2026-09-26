abstract class QuizQuestionEvent {
  const QuizQuestionEvent();
}

/// Fetches the quiz and, once it has questions, starts the clock. Also used by
/// Try Again after a failed load.
class LoadQuiz extends QuizQuestionEvent {
  const LoadQuiz();
}

/// Checks the option with [optionKey] for the current question.
class SelectAnswer extends QuizQuestionEvent {
  const SelectAnswer(this.optionKey);

  final String optionKey;
}

class GoToNextQuestion extends QuizQuestionEvent {
  const GoToNextQuestion();
}

class GoToPreviousQuestion extends QuizQuestionEvent {
  const GoToPreviousQuestion();
}

/// Re-reads the clock. Sent every second, and when the app comes back to the
/// foreground so time spent away is counted at once.
class QuizTimerTicked extends QuizQuestionEvent {
  const QuizTimerTicked();
}

/// Sends the answers for scoring - from the last question, when time runs out,
/// or to retry a failed submission. Ignored while one is in flight or done.
class SubmitQuiz extends QuizQuestionEvent {
  const SubmitQuiz();
}
