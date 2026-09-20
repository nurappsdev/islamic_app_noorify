import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/app_text.dart';
import '../../../../core/utils/app_color.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/usecases/resend_otp.dart';
import '../../domain/usecases/verify_email_otp.dart';
import '../bloc/otp_verification/otp_verification_bloc.dart';
import '../widgets/auth_button.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    this.initiallyShowOtp = false,
    this.email,
    this.onRequestOtp,
    this.onOtpVerified,
  });

  final bool initiallyShowOtp;

  /// E-mail the OTP was sent to. Required for the verify call in OTP mode.
  final String? email;

  /// Called by the "Send OTP" button (email step). Return `null` on success to
  /// advance to the code step, or an error message to show. When omitted the
  /// button just switches to the code step without a network call (sign-up).
  final Future<String?> Function(String email)? onRequestOtp;

  /// Called after the code is verified. Receives the `resetToken` when the
  /// backend returns one (forgot-password flow); `null` otherwise (sign-up).
  final void Function(String? resetToken)? onOtpVerified;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const _logoImagePath = 'assets/noorifyLogo.png';
  static const _otpLength = 6;

  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List<TextEditingController>.generate(
        _otpLength,
        (_) => TextEditingController(),
      );
  final List<FocusNode> _otpFocusNodes = List<FocusNode>.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  late bool _isOtpMode = widget.initiallyShowOtp;

  static const int _resendCooldownSeconds = 60;

  late final OtpVerificationBloc _otpBloc = _createOtpBloc();

  Timer? _resendTimer;
  int _resendSecondsLeft = 0;

  OtpVerificationBloc _createOtpBloc() {
    final repository = AccountRepositoryImpl(AuthRemoteDataSourceImpl());
    return OtpVerificationBloc(
      VerifyEmailOtp(repository),
      ResendOtp(repository),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.email != null && widget.email!.isNotEmpty) {
      _emailController.text = widget.email!;
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpBloc.close();
    _emailController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

  void _submitOtp() {
    FocusScope.of(context).unfocus();
    _otpBloc.add(
      OtpSubmitted(email: _emailController.text.trim(), otp: _enteredOtp),
    );
  }

  void _resendOtp() {
    if (_resendSecondsLeft > 0) return;
    FocusScope.of(context).unfocus();
    _otpBloc.add(OtpResendRequested(_emailController.text.trim()));
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendSecondsLeft <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _resendSecondsLeft--);
    });
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onOtpState(BuildContext context, OtpVerificationState state) {
    switch (state.resendStatus) {
      case OtpResendStatus.sent:
        _showSnack(
          context,
          state.resendMessage ?? 'A new code has been sent to your email.',
        );
        _startResendCooldown();
      case OtpResendStatus.failure:
        _showSnack(
          context,
          state.resendErrorMessage ?? 'Could not resend the code. Try again.',
        );
      case OtpResendStatus.idle:
      case OtpResendStatus.sending:
        break;
    }

    switch (state.status) {
      case OtpVerificationStatus.success:
        // Consumer navigates away here; don't touch the (soon-disposed) bloc.
        widget.onOtpVerified?.call(state.resetToken);
      case OtpVerificationStatus.failure:
        _showSnack(
          context,
          state.errorMessage ?? 'Verification failed. Please try again.',
        );
        _otpBloc.add(const OtpVerificationReset());
      case OtpVerificationStatus.initial:
      case OtpVerificationStatus.loading:
        break;
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    final radius = BorderRadius.circular(24.r);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColor.authHint, fontSize: 11.sp),
      prefixIcon: Icon(prefixIcon, color: AppColor.authIcon, size: 16.sp),
      filled: true,
      fillColor: context.surfaceColor(Colors.white),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: context.lineColor(AppColor.authFieldBorder),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: context.lineColor(AppColor.authFieldBorder),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColor.primary, width: 1.2),
      ),
    );
  }

  Widget _buildResendControl() {
    return BlocBuilder<OtpVerificationBloc, OtpVerificationState>(
      buildWhen: (previous, current) =>
          previous.resendStatus != current.resendStatus,
      builder: (context, state) {
        if (state.isResending) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: SizedBox(
              width: 16.w,
              height: 16.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final onCooldown = _resendSecondsLeft > 0;
        return TextButton(
          onPressed: onCooldown ? null : _resendOtp,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            minimumSize: Size(0, 32.h),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppColor.primary,
          ),
          child: Text(
            onCooldown
                ? 'Resend code in ${_resendSecondsLeft}s'
                : "Didn't get the code? Resend",
            style: TextStyle(
              fontSize: 12.sp,
              color: context.inkColor(
                onCooldown ? AppColor.authLogo : AppColor.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  bool _sendingOtp = false;

  Future<void> _sendOtp() async {
    final onRequestOtp = widget.onRequestOtp;
    if (onRequestOtp == null) {
      setState(() => _isOtpMode = true);
      return;
    }

    final email = _emailController.text.trim();
    FocusScope.of(context).unfocus();
    setState(() => _sendingOtp = true);
    final error = await onRequestOtp(email);
    if (!mounted) return;
    setState(() => _sendingOtp = false);

    if (error == null) {
      setState(() => _isOtpMode = true);
    } else if (error.isNotEmpty) {
      _showSnack(context, error);
    }
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(_otpLength, (index) {
        final hasDigit = _otpControllers[index].text.isNotEmpty;
        return SizedBox(
          width: 48.w,
          height: 48.h,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            keyboardType: TextInputType.number,
            textInputAction: index == _otpLength - 1
                ? TextInputAction.done
                : TextInputAction.next,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            style: TextStyle(
              color: context.inkColor(AppColor.otpDigit),
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: context.surfaceColor(
                hasDigit ? AppColor.otpFieldFill : Colors.white,
              ),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.r),
                borderSide: BorderSide(
                  color: context.lineColor(AppColor.authFieldBorder),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.r),
                borderSide: BorderSide(
                  color: context.lineColor(
                    hasDigit ? AppColor.otpFieldFill : AppColor.authFieldBorder,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.r),
                borderSide: const BorderSide(
                  color: AppColor.primary,
                  width: 1.2,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() {});
              if (value.isNotEmpty && index < _otpLength - 1) {
                _otpFocusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);

    return BlocProvider<OtpVerificationBloc>.value(
      value: _otpBloc,
      child: BlocListener<OtpVerificationBloc, OtpVerificationState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.resendStatus != current.resendStatus,
        listener: _onOtpState,
        child: _buildScaffold(appText),
      ),
    );
  }

  Widget _buildScaffold(AppText appText) {
    return Scaffold(
      backgroundColor: context.pageColor(AppColor.authBackground),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  40.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: context.surfaceColor(
                            Color(0xFFFFFAD7),
                          ),
                          foregroundColor: context.inkColor(Colors.black),
                          fixedSize: Size(30.r, 30.r),
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.arrow_back_ios_new, size: 13.sp),
                      ),
                    ),
                    Text(
                      _isOtpMode
                          ? appText.otpVerification
                          : appText.emailVerification,
                      style: TextStyle(
                        color: context.inkColor(Colors.black),
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 72.h),
                Center(
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      AppColor.authLogo,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      _logoImagePath,
                      width: 96.w,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          'Noorify',
                          style: TextStyle(
                            color: context.inkColor(AppColor.authLogo),
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  appText.noorify,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.inkColor(Colors.black),
                    fontSize: 14.sp,
                    height: 1.2,
                    fontFamily: 'Times New Roman',
                  ),
                ),
                SizedBox(height: _isOtpMode ? 38.h : 32.h),
                if (_isOtpMode) ...[
                  _buildOtpFields(),
                  SizedBox(height: 6.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildResendControl(),
                  ),
                ] else
                  SizedBox(
                    height: 45.h,
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      decoration: _fieldDecoration(
                        hint: appText.emailAddress,
                        prefixIcon: Icons.mail_outline,
                      ),
                    ),
                  ),
                SizedBox(height: _isOtpMode ? 110.h : 94.h),
                BlocBuilder<OtpVerificationBloc, OtpVerificationState>(
                  builder: (context, state) {
                    return AuthButton(
                      label: _isOtpMode ? appText.verify : appText.sendOtp,
                      height: 50.h,
                      isLoading: _isOtpMode ? state.isLoading : _sendingOtp,
                      onPressed: () {
                        if (_isOtpMode) {
                          _submitOtp();
                        } else {
                          _sendOtp();
                        }
                      },
                    );
                  },
                ),
                SizedBox(height: 120.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
