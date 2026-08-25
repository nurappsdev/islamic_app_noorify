import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_local_store.dart';

import 'reading_history_event.dart';
import 'reading_history_state.dart';

export 'reading_history_event.dart';
export 'reading_history_state.dart';

class ReadingHistoryBloc
    extends Bloc<ReadingHistoryEvent, ReadingHistoryState> {
  ReadingHistoryBloc({QuranLocalStore? store})
    : _store = store,
      super(const ReadingHistoryState()) {
    on<LoadReadingHistory>(_onLoad);
  }

  QuranLocalStore? _store;

  Future<void> _onLoad(
    LoadReadingHistory event,
    Emitter<ReadingHistoryState> emit,
  ) async {
    final store = _store ??= await QuranLocalStore.create();
    final entries = await store.history();
    emit(state.copyWith(isLoading: false, entries: entries));
  }
}
