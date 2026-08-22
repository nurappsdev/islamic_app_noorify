import 'package:islami_app_noorify/features/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_history_item.dart';
import 'package:islami_app_noorify/features/quiz/domain/repositories/quiz_repository.dart';

class QuizRepositoryImpl implements QuizRepository {
  const QuizRepositoryImpl(this._localDataSource);

  final QuizLocalDataSource _localDataSource;

  @override
  Future<List<QuizHistoryItem>> getCompletedHistory() {
    return _localDataSource.getCompletedHistory();
  }
}
