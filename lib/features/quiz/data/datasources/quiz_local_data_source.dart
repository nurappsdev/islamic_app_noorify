import 'package:islami_app_noorify/features/quiz/data/models/quiz_history_model.dart';

abstract interface class QuizLocalDataSource {
  Future<List<QuizHistoryModel>> getCompletedHistory();
}

/// Temporary local source until the quiz API or persistent storage is added.
class QuizLocalDataSourceImpl implements QuizLocalDataSource {
  const QuizLocalDataSourceImpl();

  static const _completedHistory = [
    QuizHistoryModel(
      id: 'quiz-1',
      title: 'Quiz 1 ( Quranic Science )',
      questionCount: 20,
      score: .67,
    ),
    QuizHistoryModel(
      id: 'quiz-2',
      title: 'Quiz 2 ( Quranic Science )',
      questionCount: 20,
      score: .60,
    ),
    QuizHistoryModel(
      id: 'quiz-3',
      title: 'Quiz 3 ( Quranic Science )',
      questionCount: 20,
      score: .60,
    ),
    QuizHistoryModel(
      id: 'quiz-4',
      title: 'Quiz 4 ( Quranic Science )',
      questionCount: 20,
      score: .60,
    ),
    QuizHistoryModel(
      id: 'quiz-5',
      title: 'Quiz 5 ( Quranic Science )',
      questionCount: 20,
      score: .60,
    ),
  ];

  @override
  Future<List<QuizHistoryModel>> getCompletedHistory() async {
    return List.unmodifiable(_completedHistory);
  }
}
