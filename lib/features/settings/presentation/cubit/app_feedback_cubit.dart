import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tuhfatul_muslim/features/settings/domain/usecases/submit_app_feedback.dart';

enum FeedbackSubmitStatus { idle, sending, sent, failure }

class AppFeedbackState {
  const AppFeedbackState({
    this.rating = 0,
    this.status = FeedbackSubmitStatus.idle,
    this.message,
  });

  /// 0 until the user picks a star.
  final int rating;
  final FeedbackSubmitStatus status;

  /// The server's message for the last submit, success or failure.
  final String? message;

  bool get isSending => status == FeedbackSubmitStatus.sending;

  AppFeedbackState copyWith({
    int? rating,
    FeedbackSubmitStatus? status,
    String? message,
  }) => AppFeedbackState(
    rating: rating ?? this.rating,
    status: status ?? this.status,
    message: message ?? this.message,
  );
}

/// Drives the Feedback & Rating screen.
class AppFeedbackCubit extends Cubit<AppFeedbackState> {
  AppFeedbackCubit(this._submitFeedback) : super(const AppFeedbackState());

  final SubmitAppFeedback _submitFeedback;

  void setRating(int rating) {
    if (state.isSending) return;
    emit(state.copyWith(rating: rating.clamp(1, 5)));
  }

  Future<void> submit(String feedbackText) async {
    if (state.isSending || state.rating < 1) return;
    emit(state.copyWith(status: FeedbackSubmitStatus.sending, message: ''));
    final result = await _submitFeedback(
      SubmitAppFeedbackParams(rating: state.rating, feedbackText: feedbackText),
    );
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: FeedbackSubmitStatus.failure,
          message: failure.message,
        ),
        (message) =>
            state.copyWith(status: FeedbackSubmitStatus.sent, message: message),
      ),
    );
  }

  /// Back to `idle` once the screen has shown the outcome.
  void acknowledge() {
    if (state.status == FeedbackSubmitStatus.idle) return;
    emit(state.copyWith(status: FeedbackSubmitStatus.idle));
  }
}
