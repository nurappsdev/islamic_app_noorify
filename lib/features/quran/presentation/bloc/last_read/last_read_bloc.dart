import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/quran/data/repositories/quran_reading_repository_impl.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_local_store.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_progress.dart';
import 'package:tuhfatul_muslim/features/quran/domain/reading_history_entry.dart';
import 'package:tuhfatul_muslim/features/quran/domain/repositories/quran_reading_repository.dart';

import 'last_read_event.dart';
import 'last_read_state.dart';

export 'last_read_event.dart';
export 'last_read_state.dart';

/// The last Quran reading, for "Last Read" / "Continue Reading".
///
/// Combines the device's own record (every page opened here, even offline or
/// signed out) with the account's (`GET /quran/reading/last-read`, which
/// includes other devices), preferring whichever is more recent. Reloads by
/// itself after each tracked reading.
class LastReadBloc extends Bloc<LastReadEvent, LastReadState> {
  LastReadBloc({QuranLocalStore? store, QuranReadingRepository? repository})
    : _store = store,
      _repository = repository ?? QuranReadingRepositoryImpl.shared,
      super(const LastReadState()) {
    on<LoadLastRead>(_onLoad);
    _tracked = _repository.onReadingTracked.listen(
      (_) => add(const LoadLastRead()),
    );
  }

  QuranLocalStore? _store;
  final QuranReadingRepository _repository;
  late final StreamSubscription<void> _tracked;

  Future<void> _onLoad(LoadLastRead event, Emitter<LastReadState> emit) async {
    final store = _store ??= await QuranLocalStore.create();
    final local = await store.lastRead();
    // Show the device's record at once; the account's may take a moment.
    emit(LastReadState(isLoading: false, entry: local));
    if (!_repository.isSignedIn) return;

    final result = await _repository.getLastRead();
    result.fold((_) {}, (remote) {
      final record = remote.lastRead;
      final readAt = record?.lastReadAt?.toLocal();
      if (record == null || readAt == null) return;
      if (local != null && !readAt.isAfter(local.readAt)) return;
      final next = remote.continueFrom;
      emit(
        LastReadState(
          isLoading: false,
          entry: ReadingHistoryEntry(
            surahNo: record.surahNumber,
            ayahNo: record.ayahNumber,
            surahName: record.surahNameEnglish,
            readAt: readAt,
          ),
          continueFrom: next == null ? null : _targetOf(next),
        ),
      );
    });
  }

  static QuranContinueTarget _targetOf(QuranAyahPosition ayah) => (
    surahNo: ayah.surahNumber,
    ayahNo: ayah.ayahNumber,
    surahName: ayah.surahNameEnglish,
  );

  @override
  Future<void> close() {
    _tracked.cancel();
    return super.close();
  }
}
