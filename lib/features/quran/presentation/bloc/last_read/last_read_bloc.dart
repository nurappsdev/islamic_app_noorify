import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_local_store.dart';

import 'last_read_event.dart';
import 'last_read_state.dart';

export 'last_read_event.dart';
export 'last_read_state.dart';

class LastReadBloc extends Bloc<LastReadEvent, LastReadState> {
  LastReadBloc({QuranLocalStore? store})
    : _store = store,
      super(const LastReadState()) {
    on<LoadLastRead>(_onLoad);
  }

  QuranLocalStore? _store;

  Future<void> _onLoad(LoadLastRead event, Emitter<LastReadState> emit) async {
    final store = _store ??= await QuranLocalStore.create();
    final entry = await store.lastRead();
    emit(LastReadState(isLoading: false, entry: entry));
  }
}
