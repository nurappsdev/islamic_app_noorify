import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_history_item.dart';

enum QuizStatus { initial, loading, success, failure }

class QuizState {
  const QuizState({
    this.status = QuizStatus.initial,
    this.completedHistory = const [],
    this.errorMessage,
  });

  final QuizStatus status;
  final List<QuizHistoryItem> completedHistory;
  final String? errorMessage;
}
