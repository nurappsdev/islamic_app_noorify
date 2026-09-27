abstract class QuizCategoriesEvent {
  const QuizCategoriesEvent();
}

/// Fetches the categories; also used by Try Again.
class LoadQuizCategories extends QuizCategoriesEvent {
  const LoadQuizCategories();
}
