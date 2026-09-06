import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/auth/domain/usecases/resend_otp.dart';
import 'package:islami_app_noorify/features/auth/domain/usecases/verify_email_otp.dart';

import 'otp_verification_event.dart';
import 'otp_verification_state.dart';

export 'otp_verification_event.dart';
export 'otp_verification_state.dart';

class OtpVerificationBloc
    extends Bloc<OtpVerificationEvent, OtpVerificationState> {
  OtpVerificationBloc({
    required VerifyEmailOtp verifyEmailOtp,
    required ResendOtp resendOtp,
  }) : _verifyEmailOtp = verifyEmailOtp,
       _resendOtp = resendOtp,
       super(const OtpVerificationState()) {
    on<OtpSubmitted>(_onSubmitted);
    on<OtpResendRequested>(_onResendRequested);
    on<OtpVerificationReset>(
      (_, emit) => emit(state.copyWith(status: OtpVerificationStatus.initial)),
    );
  }

  final VerifyEmailOtp _verifyEmailOtp;
  final ResendOtp _resendOtp;

  Future<void> _onSubmitted(
    OtpSubmitted event,
    Emitter<OtpVerificationState> emit,
  ) async {
    emit(state.copyWith(status: OtpVerificationStatus.loading));

    final result = await _verifyEmailOtp(
      VerifyOtpParams(email: event.email, otp: event.otp),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: OtpVerificationStatus.failure,
          failure: failure,
        ),
      ),
      (message) => emit(
        state.copyWith(
          status: OtpVerificationStatus.success,
          message: message,
        ),
      ),
    );
  }

  Future<void> _onResendRequested(
    OtpResendRequested event,
    Emitter<OtpVerificationState> emit,
  ) async {
    emit(state.copyWith(resendStatus: OtpResendStatus.sending));

    final result = await _resendOtp(event.email);

    result.fold(
      (failure) => emit(
        state.copyWith(
          resendStatus: OtpResendStatus.failure,
          resendFailure: failure,
        ),
      ),
      (message) => emit(
        state.copyWith(
          resendStatus: OtpResendStatus.sent,
          resendMessage: message,
        ),
      ),
    );
  }
}
