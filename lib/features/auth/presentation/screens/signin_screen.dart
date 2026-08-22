import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/auth/presentation/cubit/sign_in/sign_in_cubit.dart';
import 'package:islami_app_noorify/features/auth/presentation/widgets/auth_button.dart';
import 'package:islami_app_noorify/shared/services/app_globals.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInCubit>(
      create: (_) => SignInCubit(),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatefulWidget {
  const _SignInView();

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  static const _logoImagePath = 'assets/noorifyLogo.png';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  SignInCubit get _auth => context.read<SignInCubit>();
  SignInState get _authState => _auth.state;
  bool get _isLoading => _authState.isLoading;
  bool get _obscurePassword => _authState.obscurePassword;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final radius = BorderRadius.circular(24.r);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColor.authHint, fontSize: 11.sp),
      prefixIcon: Icon(prefixIcon, color: AppColor.authIcon, size: 18.sp),
      suffixIcon: suffixIcon,
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

  Future<void> _signIn() async {
    skipAuthGateNotifier.value = true;
    unawaited(saveAppPreferences());
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
  }

  void _openEmailVerification() {
    Navigator.of(context).pushNamed(RouteNames.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    context.watch<SignInCubit>();

    return Scaffold(
      backgroundColor: AppColor.authBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 360.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 52.h),
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
                  SizedBox(height: 38.h),
                  SizedBox(
                    height: 45.h,
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.email,
                        AutofillHints.telephoneNumber,
                      ],
                      decoration: _fieldDecoration(
                        hint: appText.emailOrPhoneHint,
                        prefixIcon: Icons.mark_email_unread_outlined,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 45.h,
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) {
                        if (_isLoading) return;
                        _signIn();
                      },
                      decoration: _fieldDecoration(
                        hint: appText.passwordHint,
                        prefixIcon: Icons.key_outlined,
                        suffixIcon: IconButton(
                          tooltip: appText.togglePassword,
                          onPressed: () => _auth.toggleObscurePassword(),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColor.authIcon,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _openEmailVerification,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColor.forgotPassword,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        minimumSize: Size(0, 34.h),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        appText.forgotPassword,
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  AuthButton(
                    label: appText.login,
                    isLoading: _isLoading,
                    onPressed: _signIn,
                  ),
                  SizedBox(height: 14.h),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4.w,
                    children: [
                      Text(
                        appText.newToNoorify,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColor.authLogo,
                          fontSize: 11.sp,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed(RouteNames.signUp),
                        child: Text(
                          appText.createAccount,
                          style: TextStyle(
                            color: AppColor.createAccount,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 72.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
