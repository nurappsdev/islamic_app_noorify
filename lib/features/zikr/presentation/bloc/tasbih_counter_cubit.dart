import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/zikr/domain/repositories/zikr_repository.dart';

class TasbihCounterState {
  const TasbihCounterState({
    this.pendingCount = 0,
    this.isSyncing = false,
    this.error,
  });
  final int pendingCount;
  final bool isSyncing;
  final String? error;
  TasbihCounterState copyWith({
    int? pendingCount,
    bool? isSyncing,
    String? error,
    bool clearError = false,
  }) => TasbihCounterState(
    pendingCount: pendingCount ?? this.pendingCount,
    isSyncing: isSyncing ?? this.isSyncing,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Keeps tap feedback entirely in the screen's synchronous state and batches
/// only the server side-effect. A screen calls [tap] after each instant local
/// increment, [syncNow] on an item target, and [flush] during dispose/back.
class TasbihCounterCubit extends Cubit<TasbihCounterState> {
  TasbihCounterCubit(this._repository) : super(const TasbihCounterState());
  final ZikrRepository _repository;
  Timer? _debounce;
  Map<String, dynamic>? _latestContext;

  void tap(Map<String, dynamic> context) {
    _latestContext = context;
    _debounce?.cancel();
    emit(
      state.copyWith(pendingCount: state.pendingCount + 1, clearError: true),
    );
    _debounce = Timer(const Duration(seconds: 3), syncNow);
  }

  Future<void> syncNow() async {
    _debounce?.cancel();
    final count = state.pendingCount;
    final context = _latestContext;
    if (count == 0 || context == null || state.isSyncing) return;
    emit(state.copyWith(pendingCount: 0, isSyncing: true));
    try {
      await _repository.incrementTasbih({...context, 'countAdded': count});
      emit(state.copyWith(isSyncing: false));
    } catch (error) {
      // Keep failed taps queued. The next 3-second pause or screen exit
      // retries them without ever making the visual counter feel delayed.
      emit(
        state.copyWith(
          pendingCount: state.pendingCount + count,
          isSyncing: false,
          error: '$error',
        ),
      );
    }
  }

  Future<void> flush() => syncNow();

  @override
  Future<void> close() async {
    await flush();
    _debounce?.cancel();
    return super.close();
  }
}
