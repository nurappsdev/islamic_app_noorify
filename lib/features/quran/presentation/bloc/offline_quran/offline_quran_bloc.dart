import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_offline_database.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_offline_downloader.dart';

import 'offline_quran_event.dart';
import 'offline_quran_state.dart';

export 'offline_quran_event.dart';
export 'offline_quran_state.dart';

class OfflineQuranBloc extends Bloc<OfflineQuranEvent, OfflineQuranState> {
  OfflineQuranBloc({
    QuranOfflineDatabase? database,
    QuranOfflineDownloader? downloader,
  }) : _database = database ?? QuranOfflineDatabase(),
       _downloader = downloader ?? QuranOfflineDownloader(),
       super(const OfflineQuranState()) {
    on<CheckOfflineQuran>(_onCheck);
    on<PrepareOfflineQuran>(_onPrepare);
  }

  final QuranOfflineDatabase _database;
  final QuranOfflineDownloader _downloader;

  Future<void> _onCheck(
    CheckOfflineQuran event,
    Emitter<OfflineQuranState> emit,
  ) async {
    emit(const OfflineQuranState(status: OfflineQuranStatus.checking));
    final ready = await _database.isReady();
    emit(
      OfflineQuranState(
        status: ready
            ? OfflineQuranStatus.ready
            : OfflineQuranStatus.needsSetup,
      ),
    );
  }

  Future<void> _onPrepare(
    PrepareOfflineQuran event,
    Emitter<OfflineQuranState> emit,
  ) async {
    if (state.status == OfflineQuranStatus.preparing) return;
    emit(const OfflineQuranState(status: OfflineQuranStatus.preparing));
    try {
      await emit.forEach<QuranSetupProgress>(
        _downloader.downloadAllText(),
        onData: (progress) => OfflineQuranState(
          status: OfflineQuranStatus.preparing,
          done: progress.done,
          total: progress.total,
        ),
      );
      final ready = await _database.isReady();
      emit(
        OfflineQuranState(
          status: ready
              ? OfflineQuranStatus.ready
              : OfflineQuranStatus.failed,
        ),
      );
    } catch (error) {
      // Keep whatever has been downloaded so the next attempt resumes.
      emit(
        OfflineQuranState(
          status: OfflineQuranStatus.failed,
          errorMessage: error is QuranSetupException ? error.message : '$error',
        ),
      );
    }
  }
}
