import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/widgets/login_required_dialog.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_progress.dart';

import 'hadith_reading_progress_event.dart';
import 'hadith_reading_progress_state.dart';

export 'hadith_reading_progress_event.dart';
export 'hadith_reading_progress_state.dart';

/// Loads a [HadithReadingProgress]: the categories' or the sub-categories'
/// use case (both are callable), so one bloc serves both screens.
typedef HadithProgressLoader =
    Future<Either<Failure, HadithReadingProgress>> Function();

class HadithReadingProgressBloc
    extends Bloc<HadithReadingProgressEvent, HadithReadingProgressState> {
  HadithReadingProgressBloc(this._getProgress)
    : super(const HadithReadingProgressState()) {
    on<LoadHadithReadingProgress>(_onLoad);
    on<RefreshHadithReadingProgress>(_onRefresh);
  }

  final HadithProgressLoader _getProgress;

  /// Bumped per request so a slow, superseded response can't overwrite a
  /// newer one.
  int _generation = 0;

  Future<void> _onLoad(
    LoadHadithReadingProgress event,
    Emitter<HadithReadingProgressState> emit,
  ) async {
    // Needs the login token; a guest sees 0% progress.
    if (!isUserSignedIn) return;
    emit(
      HadithReadingProgressState(
        status: HadithReadingProgressStatus.loading,
        progress: state.progress,
      ),
    );
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    RefreshHadithReadingProgress event,
    Emitter<HadithReadingProgressState> emit,
  ) => _fetch(emit);

  Future<void> _fetch(Emitter<HadithReadingProgressState> emit) async {
    if (!isUserSignedIn) return;
    final generation = ++_generation;
    final result = await _getProgress();
    if (generation != _generation || emit.isDone) return;
    result.fold(
      (failure) => emit(
        HadithReadingProgressState(
          status: HadithReadingProgressStatus.failure,
          progress: state.progress,
          failure: failure,
        ),
      ),
      (progress) => emit(
        HadithReadingProgressState(
          status: HadithReadingProgressStatus.success,
          progress: progress,
        ),
      ),
    );
  }
}
