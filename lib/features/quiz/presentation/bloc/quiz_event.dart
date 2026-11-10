abstract class QuizEvent {
  const QuizEvent();
}

/// Loads the first page of attempts; also used by Try Again.
class LoadCompletedQuizHistory extends QuizEvent {
  const LoadCompletedQuizHistory();
}

/// Appends the next page, when there is one.
class LoadMoreQuizHistory extends QuizEvent {
  const LoadMoreQuizHistory();
}
