import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_category.dart';

enum QuizCategoriesStatus { initial, loading, success, failure }

class QuizCategoriesState {
  const QuizCategoriesState({
    this.status = QuizCategoriesStatus.initial,
    this.categories = const [],
    this.errorMessage,
  });

  final QuizCategoriesStatus status;

  /// Active categories, in display order.
  final List<QuizCategory> categories;
  final String? errorMessage;
}
