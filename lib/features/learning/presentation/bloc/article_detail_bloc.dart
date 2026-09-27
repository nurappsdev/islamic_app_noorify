import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/learning/domain/entities/article.dart';
import 'package:islami_app_noorify/features/learning/domain/usecases/get_article.dart';
import 'package:islami_app_noorify/features/learning/presentation/bloc/learning_paged_state.dart';

export 'package:islami_app_noorify/features/learning/presentation/bloc/learning_paged_state.dart'
    show LearningLoadStatus;

class ArticleDetailState {
  const ArticleDetailState({
    this.status = LearningLoadStatus.loading,
    this.article,
    this.failure,
  });

  final LearningLoadStatus status;
  final Article? article;
  final Failure? failure;
}

abstract class ArticleDetailEvent {
  const ArticleDetailEvent();
}

/// Fetches the article; also used by Try Again.
class LoadArticle extends ArticleDetailEvent {
  const LoadArticle();
}

/// One article, read in full from `GET /articles/{id}`.
class ArticleDetailBloc extends Bloc<ArticleDetailEvent, ArticleDetailState> {
  ArticleDetailBloc(this._getArticle, {required this.articleId})
    : super(const ArticleDetailState()) {
    on<LoadArticle>(_onLoad);
  }

  final GetArticle _getArticle;
  final String articleId;

  Future<void> _onLoad(
    LoadArticle event,
    Emitter<ArticleDetailState> emit,
  ) async {
    if (articleId.isEmpty) {
      emit(
        const ArticleDetailState(
          status: LearningLoadStatus.failure,
          failure: ServerFailure('No article id', statusCode: 404),
        ),
      );
      return;
    }
    emit(const ArticleDetailState());
    final result = await _getArticle(articleId);
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(
        ArticleDetailState(
          status: LearningLoadStatus.failure,
          failure: failure,
        ),
      ),
      (article) => emit(
        ArticleDetailState(
          status: LearningLoadStatus.success,
          article: article,
        ),
      ),
    );
  }
}
