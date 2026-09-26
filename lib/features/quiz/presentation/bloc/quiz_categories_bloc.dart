import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quiz/domain/usecases/get_quiz_categories.dart';

import 'quiz_categories_event.dart';
import 'quiz_categories_state.dart';

export 'quiz_categories_event.dart';
export 'quiz_categories_state.dart';

class QuizCategoriesBloc
    extends Bloc<QuizCategoriesEvent, QuizCategoriesState> {
  QuizCategoriesBloc(this._getCategories) : super(const QuizCategoriesState()) {
    on<LoadQuizCategories>((event, emit) async {
      emit(
        QuizCategoriesState(
          status: QuizCategoriesStatus.loading,
          categories: state.categories,
        ),
      );
      final result = await _getCategories();
      result.fold(
        (failure) => emit(
          QuizCategoriesState(
            status: QuizCategoriesStatus.failure,
            categories: state.categories,
            errorMessage: failure.message,
          ),
        ),
        (categories) => emit(
          QuizCategoriesState(
            status: QuizCategoriesStatus.success,
            categories: categories,
          ),
        ),
      );
    });
  }

  final GetQuizCategories _getCategories;
}
