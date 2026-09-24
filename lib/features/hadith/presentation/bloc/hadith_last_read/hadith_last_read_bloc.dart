import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_login_required_dialog.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_last_read.dart';

import 'hadith_last_read_event.dart';
import 'hadith_last_read_state.dart';

export 'hadith_last_read_event.dart';
export 'hadith_last_read_state.dart';

class HadithLastReadBloc
    extends Bloc<HadithLastReadEvent, HadithLastReadState> {
  HadithLastReadBloc(this._getLastRead) : super(const HadithLastReadState()) {
    on<LoadHadithLastRead>(_onLoad);
  }

  final GetHadithLastRead _getLastRead;

  /// Bumped per request so a slow, superseded response can't overwrite a
  /// newer one.
  int _generation = 0;

  Future<void> _onLoad(
    LoadHadithLastRead event,
    Emitter<HadithLastReadState> emit,
  ) async {
    // Needs the login token; a guest simply has no last-read hadith.
    if (!hadithIsSignedIn) return;
    final generation = ++_generation;
    if (state.lastRead == null) {
      emit(const HadithLastReadState(status: HadithLastReadStatus.loading));
    }
    final result = await _getLastRead();
    if (generation != _generation || emit.isDone) return;
    result.fold(
      (failure) => emit(
        HadithLastReadState(
          status: HadithLastReadStatus.failure,
          lastRead: state.lastRead,
          failure: failure,
        ),
      ),
      (lastRead) => emit(
        HadithLastReadState(
          status: HadithLastReadStatus.success,
          lastRead: lastRead,
        ),
      ),
    );
  }
}
