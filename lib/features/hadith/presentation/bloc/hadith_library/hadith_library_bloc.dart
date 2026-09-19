import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_library_books.dart';

import 'hadith_library_event.dart';
import 'hadith_library_state.dart';

export 'hadith_library_event.dart';
export 'hadith_library_state.dart';

class HadithLibraryBloc extends Bloc<HadithLibraryEvent, HadithLibraryState> {
  HadithLibraryBloc(this._getBooks) : super(const HadithLibraryState()) {
    on<LoadHadithLibrary>(_onLoad);
  }

  final GetHadithLibraryBooks _getBooks;

  Future<void> _onLoad(
    LoadHadithLibrary event,
    Emitter<HadithLibraryState> emit,
  ) async {
    emit(const HadithLibraryState(status: HadithLibraryStatus.loading));
    final result = await _getBooks();
    result.fold(
      (failure) => emit(
        HadithLibraryState(
          status: HadithLibraryStatus.failure,
          failure: failure,
        ),
      ),
      (books) => emit(
        HadithLibraryState(status: HadithLibraryStatus.success, books: books),
      ),
    );
  }
}
