import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_history_item.dart';

abstract interface class QuizRepository {
  Future<List<QuizHistoryItem>> getCompletedHistory();
}
