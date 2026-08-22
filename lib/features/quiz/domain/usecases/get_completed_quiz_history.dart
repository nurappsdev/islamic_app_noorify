import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_history_item.dart';
import 'package:islami_app_noorify/features/quiz/domain/repositories/quiz_repository.dart';

class GetCompletedQuizHistory {
  const GetCompletedQuizHistory(this._repository);

  final QuizRepository _repository;

  Future<List<QuizHistoryItem>> call() => _repository.getCompletedHistory();
}
