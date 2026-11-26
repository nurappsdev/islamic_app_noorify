import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tuhfatul_muslim/features/settings/domain/entities/app_update_note.dart';
import 'package:tuhfatul_muslim/features/settings/domain/usecases/get_new_updates.dart';

enum NewUpdatesStatus { loading, success, failure }

class NewUpdatesState {
  const NewUpdatesState({
    this.status = NewUpdatesStatus.loading,
    this.note,
    this.errorMessage,
  });

  final NewUpdatesStatus status;
  final AppUpdateNote? note;
  final String? errorMessage;
}

/// Loads the release notes for the New Updates screen.
class NewUpdatesCubit extends Cubit<NewUpdatesState> {
  NewUpdatesCubit(this._getNewUpdates) : super(const NewUpdatesState());

  final GetNewUpdates _getNewUpdates;

  Future<void> load() async {
    emit(const NewUpdatesState());
    final result = await _getNewUpdates();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => NewUpdatesState(
          status: NewUpdatesStatus.failure,
          errorMessage: failure.message,
        ),
        (note) => NewUpdatesState(status: NewUpdatesStatus.success, note: note),
      ),
    );
  }
}
