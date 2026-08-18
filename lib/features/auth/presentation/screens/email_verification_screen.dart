import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/app_text.dart';
import '../../../../core/utils/app_color.dart';
import '../widgets/auth_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    this.initiallyShowOtp = false,
    this.onOtpVerified,
  });

  final bool initiallyShowOtp;
  final VoidCallback? onOtpVerified;

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

  @override
  void dispose() {
    _emailController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
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
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColor.authFieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColor.authFieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColor.primary, width: 1.2),
      ),
    );
  }

  void _showOtpInput() {
    setState(() {
      _isOtpMode = true;
    });
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
              color: AppColor.otpDigit,
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: hasDigit ? AppColor.otpFieldFill : Colors.white,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.r),
                borderSide: const BorderSide(color: AppColor.authFieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.r),
                borderSide: BorderSide(
                  color: hasDigit
                      ? AppColor.otpFieldFill
                      : AppColor.authFieldBorder,
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

    return Scaffold(
      backgroundColor: AppColor.authBackground,
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
                          backgroundColor: const Color(0xFFFFFAD7),
                          foregroundColor: Colors.black,
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
                        color: Colors.black,
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
                            color: AppColor.authLogo,
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
                    color: Colors.black,
                    fontSize: 14.sp,
                    height: 1.2,
                    fontFamily: 'Times New Roman',
                  ),
                ),
                SizedBox(height: _isOtpMode ? 38.h : 32.h),
                if (_isOtpMode) ...[
                  _buildOtpFields(),
                  SizedBox(height: 10.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      appText.resendIn,
                      style: TextStyle(
                        color: AppColor.authLogo,
                        fontSize: 12.sp,
                      ),
                    ),
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
                AuthButton(
                  label: _isOtpMode ? appText.verify : appText.sendOtp,
                  height: 50.h,
                  onPressed: _isOtpMode
                      ? widget.onOtpVerified ?? () {}
                      : _showOtpInput,
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
