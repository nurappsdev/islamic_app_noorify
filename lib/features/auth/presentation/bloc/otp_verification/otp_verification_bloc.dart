import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/auth/domain/usecases/verify_email_otp.dart';

import 'otp_verification_event.dart';
import 'otp_verification_state.dart';

export 'otp_verification_event.dart';
export 'otp_verification_state.dart';

class OtpVerificationBloc
    extends Bloc<OtpVerificationEvent, OtpVerificationState> {
  OtpVerificationBloc(this._verifyEmailOtp)
    : super(const OtpVerificationState.initial()) {
    on<OtpSubmitted>(_onSubmitted);
    on<OtpVerificationReset>(
      (_, emit) => emit(const OtpVerificationState.initial()),
    );
  }

  final VerifyEmailOtp _verifyEmailOtp;

  Future<void> _onSubmitted(
    OtpSubmitted event,
    Emitter<OtpVerificationState> emit,
  ) async {
    emit(const OtpVerificationState.loading());

    final result = await _verifyEmailOtp(
      VerifyOtpParams(email: event.email, otp: event.otp),
    );

    result.fold(
      (failure) => emit(OtpVerificationState.failure(failure)),
      (message) => emit(OtpVerificationState.success(message)),
    );
  }
}
