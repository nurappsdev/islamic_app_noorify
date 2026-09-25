import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:islami_app_noorify/features/auth/data/repositories/account_repository_impl.dart';
import 'package:islami_app_noorify/features/auth/domain/usecases/reset_password.dart';
import 'package:islami_app_noorify/features/auth/presentation/bloc/reset_password/reset_password_bloc.dart';
import 'package:islami_app_noorify/features/auth/presentation/widgets/auth_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.resetToken});

  /// Short-lived token from OTP verification that authorises the reset.
  final String? resetToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const _logoImagePath = 'assets/noorifyLogo.png';

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  late final ResetPasswordBloc _bloc = ResetPasswordBloc(
    ResetPassword(AccountRepositoryImpl(AuthRemoteDataSourceImpl())),
  );

  @override
  void dispose() {
    _bloc.close();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    _bloc.add(
      ResetPasswordSubmitted(
        resetToken: widget.resetToken ?? '',
        password: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      ),
    );
  }

  void _onState(BuildContext context, ResetPasswordState state) {
    switch (state.status) {
      case ResetPasswordStatus.success:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Your password has been updated.'),
            ),
          );
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RouteNames.signIn, (route) => false);
      case ResetPasswordStatus.failure:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? 'Could not reset password. Try again.',
              ),
            ),
          );
        _bloc.add(const ResetPasswordReset());
      case ResetPasswordStatus.initial:
      case ResetPasswordStatus.loading:
        break;
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefixIcon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    final radius = BorderRadius.circular(24.r);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColor.authHint, fontSize: 14.sp),
      prefixIcon: Icon(prefixIcon, color: AppColor.authIcon, size: 18.sp),
      suffixIcon: IconButton(
        tooltip: AppText.of(context).togglePassword,
        onPressed: onToggleVisibility,
        icon: Icon(
          obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColor.authIcon,
          size: 18.sp,
        ),
      ),
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

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    TextInputAction? textInputAction,
  }) {
    return SizedBox(
      height: 45.h,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        decoration: _fieldDecoration(
          hint: hint,
          prefixIcon: Icons.key_outlined,
          obscureText: obscureText,
          onToggleVisibility: onToggleVisibility,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);

    return BlocProvider<ResetPasswordBloc>.value(
      value: _bloc,
      child: BlocListener<ResetPasswordBloc, ResetPasswordState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: _onState,
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
                      appText.resetPassword,
                      style: TextStyle(
                        color: context.inkColor(Colors.black),
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 74.h),
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
                          'Tuhfatul Muslim',
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
                  appText.tuhfatulMuslim,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.inkColor(Colors.black),
                    fontSize: 14.sp,
                    height: 1.2,
                    fontFamily: 'Times New Roman',
                  ),
                ),
                SizedBox(height: 40.h),
                _passwordField(
                  controller: _newPasswordController,
                  hint: appText.newPassword,
                  obscureText: _obscureNewPassword,
                  textInputAction: TextInputAction.next,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                SizedBox(height: 7.h),
                _passwordField(
                  controller: _confirmPasswordController,
                  hint: appText.confirmPassword,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                SizedBox(height: 78.h),
                BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
                  builder: (context, state) {
                    return AuthButton(
                      label: appText.confirm,
                      height: 50.h,
                      isLoading: state.isLoading,
                      onPressed: _submit,
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
