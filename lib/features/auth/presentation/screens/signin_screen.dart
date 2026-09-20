import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/auth/data/repositories/account_repository_impl.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:islami_app_noorify/features/auth/domain/usecases/login_user.dart';
import 'package:islami_app_noorify/features/auth/presentation/bloc/login/login_bloc.dart';
import 'package:islami_app_noorify/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:islami_app_noorify/features/auth/presentation/widgets/auth_button.dart';
import 'package:islami_app_noorify/features/profile/data/services/profile_service.dart';
import 'package:islami_app_noorify/shared/services/app_globals.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SignInBloc>(create: (_) => SignInBloc()),
        BlocProvider<LoginBloc>(
          create: (_) => LoginBloc(
            LoginUser(AccountRepositoryImpl(AuthRemoteDataSourceImpl())),
          ),
        ),
      ],
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

  SignInBloc get _auth => context.read<SignInBloc>();
  SignInState get _authState => _auth.state;
  bool get _isLoading =>
      _authState.isLoading || context.watch<LoginBloc>().state.isLoading;
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

  void _signIn() {
    FocusScope.of(context).unfocus();
    context.read<LoginBloc>().add(
      LoginSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _onLoginState(BuildContext context, LoginState state) {
    switch (state.status) {
      case LoginStatus.success:
        // Token is already stored in Hive by the repository at this point.
        skipAuthGateNotifier.value = true;
        unawaited(saveAppPreferences());
        unawaited(ProfileService.instance.refresh());
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
      case LoginStatus.failure:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.errorMessage ?? 'Sign in failed. Please try again.',
            ),
          ),
        );
        context.read<LoginBloc>().add(const LoginReset());
      case LoginStatus.initial:
      case LoginStatus.loading:
        break;
    }
  }

  void _openEmailVerification() {
    Navigator.of(context).pushNamed(RouteNames.forgotPassword);
  }

  void _continueAsGuest() {
    // No token is stored, so the user stays unauthenticated while browsing.
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    context.watch<SignInBloc>();

    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onLoginState,
      child: _buildScaffold(appText),
    );
  }

  Widget _buildScaffold(AppText appText) {
    return Scaffold(
      backgroundColor: context.pageColor(AppColor.authBackground),
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
                          onPressed: () =>
                              _auth.add(const ToggleObscurePassword()),
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
                        foregroundColor: context.inkColor(
                          AppColor.forgotPassword,
                        ),
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
                          color: context.inkColor(AppColor.authLogo),
                          fontSize: 11.sp,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed(RouteNames.signUp),
                        child: Text(
                          appText.createAccount,
                          style: TextStyle(
                            color: context.inkColor(AppColor.createAccount),
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  TextButton(
                    onPressed: _isLoading ? null : _continueAsGuest,
                    style: TextButton.styleFrom(
                      foregroundColor: context.inkColor(AppColor.authLogo),
                      minimumSize: Size(0, 34.h),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      appText.guestUser,
                      style: TextStyle(
                        fontSize: 12.sp,
                        decoration: TextDecoration.underline,
                      ),
                    ),
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
