import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tuhfatul_muslim/features/quiz/domain/entities/daily_quiz_status.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_daily_quiz_status.dart';

enum DailyQuizStatusLoadStatus { initial, loading, success, failure }

class DailyQuizStatusState {
  const DailyQuizStatusState({
    this.status = DailyQuizStatusLoadStatus.initial,
    this.dailyStatus,
    this.errorMessage,
  });

  final DailyQuizStatusLoadStatus status;
  final DailyQuizStatus? dailyStatus;
  final String? errorMessage;

  bool get isCompleted => dailyStatus?.completed ?? false;

  DailyQuizStatusState copyWith({
    DailyQuizStatusLoadStatus? status,
    DailyQuizStatus? dailyStatus,
    String? errorMessage,
  }) {
    return DailyQuizStatusState(
      status: status ?? this.status,
      dailyStatus: dailyStatus ?? this.dailyStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DailyQuizStatusCubit extends Cubit<DailyQuizStatusState> {
  DailyQuizStatusCubit(this._getDailyQuizStatus)
    : super(const DailyQuizStatusState());

  final GetDailyQuizStatus _getDailyQuizStatus;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(status: DailyQuizStatusLoadStatus.loading));
    }
    final result = await _getDailyQuizStatus();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DailyQuizStatusLoadStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (dailyStatus) => emit(
        state.copyWith(
          status: DailyQuizStatusLoadStatus.success,
          dailyStatus: dailyStatus,
        ),
      ),
    );
  }
}
