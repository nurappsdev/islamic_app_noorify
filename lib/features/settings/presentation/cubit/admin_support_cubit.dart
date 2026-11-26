import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tuhfatul_muslim/features/settings/domain/entities/support_overview.dart';
import 'package:tuhfatul_muslim/features/settings/domain/usecases/get_support_overview.dart';
import 'package:tuhfatul_muslim/features/settings/domain/usecases/submit_support_ticket.dart';

enum SupportOverviewStatus { loading, success, failure }

enum TicketSubmitStatus { idle, sending, sent, failure }

class AdminSupportState {
  const AdminSupportState({
    this.overviewStatus = SupportOverviewStatus.loading,
    this.overview,
    this.overviewError,
    this.submitStatus = TicketSubmitStatus.idle,
    this.submitMessage,
  });

  final SupportOverviewStatus overviewStatus;
  final SupportOverview? overview;
  final String? overviewError;

  final TicketSubmitStatus submitStatus;

  /// The server's message for the last submit, success or failure.
  final String? submitMessage;

  bool get isSending => submitStatus == TicketSubmitStatus.sending;

  AdminSupportState copyWith({
    SupportOverviewStatus? overviewStatus,
    SupportOverview? overview,
    String? overviewError,
    TicketSubmitStatus? submitStatus,
    String? submitMessage,
  }) => AdminSupportState(
    overviewStatus: overviewStatus ?? this.overviewStatus,
    overview: overview ?? this.overview,
    overviewError: overviewError ?? this.overviewError,
    submitStatus: submitStatus ?? this.submitStatus,
    submitMessage: submitMessage ?? this.submitMessage,
  );
}

/// Drives the Admin Support screen: the contact details it shows and the
/// ticket form it submits.
class AdminSupportCubit extends Cubit<AdminSupportState> {
  AdminSupportCubit(this._getOverview, this._submitTicket)
    : super(const AdminSupportState());

  final GetSupportOverview _getOverview;
  final SubmitSupportTicket _submitTicket;

  Future<void> loadOverview() async {
    emit(
      state.copyWith(
        overviewStatus: SupportOverviewStatus.loading,
        overviewError: '',
      ),
    );
    final result = await _getOverview();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => state.copyWith(
          overviewStatus: SupportOverviewStatus.failure,
          overviewError: failure.message,
        ),
        (overview) => state.copyWith(
          overviewStatus: SupportOverviewStatus.success,
          overview: overview,
        ),
      ),
    );
  }

  Future<void> submitTicket({
    required String reason,
    required String description,
  }) async {
    if (state.isSending) return;
    emit(
      state.copyWith(
        submitStatus: TicketSubmitStatus.sending,
        submitMessage: '',
      ),
    );
    final result = await _submitTicket(
      SubmitSupportTicketParams(reason: reason, description: description),
    );
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => state.copyWith(
          submitStatus: TicketSubmitStatus.failure,
          submitMessage: failure.message,
        ),
        (message) => state.copyWith(
          submitStatus: TicketSubmitStatus.sent,
          submitMessage: message,
        ),
      ),
    );
  }

  /// Back to `idle` once the screen has shown the outcome, so the same
  /// message is not reported twice.
  void acknowledgeSubmit() {
    if (state.submitStatus == TicketSubmitStatus.idle) return;
    emit(state.copyWith(submitStatus: TicketSubmitStatus.idle));
  }
}
