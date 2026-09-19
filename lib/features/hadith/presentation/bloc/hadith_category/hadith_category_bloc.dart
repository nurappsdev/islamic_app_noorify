import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_categories.dart';

import 'hadith_category_event.dart';
import 'hadith_category_state.dart';

export 'hadith_category_event.dart';
export 'hadith_category_state.dart';

class HadithCategoryBloc
    extends Bloc<HadithCategoryEvent, HadithCategoryState> {
  HadithCategoryBloc(this._getCategories) : super(const HadithCategoryState()) {
    on<LoadHadithCategories>(_onLoad);
  }

  final GetHadithCategories _getCategories;

  Future<void> _onLoad(
    LoadHadithCategories event,
    Emitter<HadithCategoryState> emit,
  ) async {
    emit(const HadithCategoryState(status: HadithCategoryStatus.loading));
    final result = await _getCategories(event.bookId);
    result.fold(
      (failure) => emit(
        HadithCategoryState(
          status: HadithCategoryStatus.failure,
          failure: failure,
        ),
      ),
      (categories) => emit(
        HadithCategoryState(
          status: HadithCategoryStatus.success,
          categories: categories,
        ),
      ),
    );
  }
}
