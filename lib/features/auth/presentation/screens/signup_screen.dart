import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:islami_app_noorify/features/auth/data/services/auth_service.dart';
import 'package:islami_app_noorify/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:islami_app_noorify/features/auth/presentation/cubit/sign_up/sign_up_cubit.dart';
import 'package:islami_app_noorify/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:islami_app_noorify/features/auth/presentation/widgets/auth_button.dart';
import 'package:islami_app_noorify/shared/services/app_globals.dart';

typedef GoogleSignUpRouteResolver = Future<String> Function();

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key, this.googleSignUpRouteResolver});

  final GoogleSignUpRouteResolver? googleSignUpRouteResolver;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignUpCubit>(
      create: (_) => SignUpCubit(),
      child: _SignupView(googleSignUpRouteResolver: googleSignUpRouteResolver),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView({this.googleSignUpRouteResolver});

  final GoogleSignUpRouteResolver? googleSignUpRouteResolver;

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  SignUpCubit get _auth => context.read<SignUpCubit>();
  SignUpState get _authState => _auth.state;
  bool get _isLoading => _authState.isLoading;
  bool get _obscurePassword => _authState.obscurePassword;
  bool get _obscureConfirm => _authState.obscureConfirm;
  bool get _termsAccepted => _authState.saveInfo;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      hintStyle: TextStyle(color: AppColor.authHint, fontSize: 13.sp),
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

  Future<void> _createAccount() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EmailVerificationScreen(
          initiallyShowOtp: true,
          onOtpVerified: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
          },
        ),
      ),
    );
  }

  Future<String> _defaultGoogleSignUpRouteResolver() async {
    await SignUpUseCase(AuthRepositoryImpl(AuthService.instance)).withGoogle();
    await _setSkipAuthGate(false);
    return RouteNames.home;
  }

  Future<void> _setSkipAuthGate(bool value) async {
    skipAuthGateNotifier.value = value;
    await saveAppPreferences();
  }

  void _showMessage(String message) {
    if (!mounted || message.trim().isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signUpWithGoogle() async {
    _auth.setLoading(true);
    try {
      final route =
          await (widget.googleSignUpRouteResolver ??
              _defaultGoogleSignUpRouteResolver)();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    } on GoogleSignInException catch (e) {
      _showMessage(AuthService.instance.messageForGoogleException(e));
    } on FirebaseAuthException catch (e) {
      _showMessage(AuthService.instance.messageForException(e));
    } catch (_) {
      _showMessage('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) {
        _auth.setLoading(false);
      }
    }
  }

  Widget _authField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      height: 48.h,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        decoration: _fieldDecoration(
          hint: hint,
          prefixIcon: icon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _passwordVisibilityButton({
    required AppText appText,
    required bool obscure,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: appText.togglePassword,
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColor.authIcon,
        size: 18.sp,
      ),
    );
  }

  Widget _termsRow(AppText appText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24.w,
          height: 24.w,
          child: Checkbox(
            value: _termsAccepted,
            activeColor: AppColor.primary,
            side: const BorderSide(color: AppColor.authFieldBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.r),
            ),
            onChanged: (value) => _auth.setSaveInfo(value ?? false),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppColor.authLogo,
                fontSize: 12.sp,
                height: 1.35,
              ),
              children: [
                TextSpan(text: '${appText.iAgreeToThe} '),
                TextSpan(
                  text: appText.termsOfServices,
                  style: const TextStyle(color: AppColor.primary),
                ),
                const TextSpan(text: ' & '),
                TextSpan(
                  text: appText.privacyPolicy,
                  style: const TextStyle(color: AppColor.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialSignupSection(AppText appText) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColor.authFieldBorder)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Text(
                appText.signUpWithOthers,
                style: TextStyle(color: AppColor.primary, fontSize: 13.sp),
              ),
            ),
            const Expanded(child: Divider(color: AppColor.authFieldBorder)),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialIconButton(
              key: const Key('signup_google_button'),
              tooltip: 'Google',
              onPressed: _isLoading ? null : _signUpWithGoogle,
              child: Text(
                'G',
                style: TextStyle(
                  color: const Color(0xFF4285F4),
                  fontSize: 23.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: 18.w),
            _socialIconButton(
              key: const Key('signup_facebook_button'),
              tooltip: 'Facebook',
              onPressed: () {},
              child: Icon(
                Icons.facebook,
                color: const Color(0xFF1877F2),
                size: 24.sp,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _socialIconButton({
    required Key key,
    required String tooltip,
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return SizedBox.square(
      dimension: 40.r,
      child: OutlinedButton(
        key: key,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColor.authFieldBorder),
          foregroundColor: AppColor.primary,
          backgroundColor: Colors.white,
        ),
        child: Tooltip(message: tooltip, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    context.watch<SignUpCubit>();

    return Scaffold(
      backgroundColor: AppColor.authBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 22.h),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFAD7),
                      foregroundColor: Colors.black,
                      fixedSize: Size(36.r, 36.r),
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back_ios_new, size: 15.sp),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  appText.createAccount,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColor.authLogo,
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  appText.signUpSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColor.authLogo,
                    fontSize: 15.sp,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 12.h),
                _authField(
                  controller: _nameController,
                  hint: appText.enterYourName,
                  icon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 9.h),
                _authField(
                  controller: _emailController,
                  hint: appText.emailAddress,
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 9.h),
                _authField(
                  controller: _phoneController,
                  hint: appText.phoneNo,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 9.h),
                SizedBox(
                  height: 48.h,
                  child: DropdownButtonFormField<String>(
                    decoration: _fieldDecoration(
                      hint: appText.gender,
                      prefixIcon: Icons.male_outlined,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColor.authIcon,
                      size: 20.sp,
                    ),
                    dropdownColor: Colors.white,
                    items: [
                      DropdownMenuItem(
                        value: 'male',
                        child: Text(appText.male),
                      ),
                      DropdownMenuItem(
                        value: 'female',
                        child: Text(appText.female),
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                ),
                SizedBox(height: 9.h),
                _authField(
                  controller: _passwordController,
                  hint: appText.passwordHint,
                  icon: Icons.key_outlined,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  suffixIcon: _passwordVisibilityButton(
                    appText: appText,
                    obscure: _obscurePassword,
                    onPressed: () => _auth.toggleObscurePassword(),
                  ),
                ),
                SizedBox(height: 9.h),
                _authField(
                  controller: _confirmPasswordController,
                  hint: appText.confirmPassword,
                  icon: Icons.key_outlined,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  suffixIcon: _passwordVisibilityButton(
                    appText: appText,
                    obscure: _obscureConfirm,
                    onPressed: () => _auth.toggleObscureConfirm(),
                  ),
                ),
                SizedBox(height: 28.h),
                _socialSignupSection(appText),
                SizedBox(height: 28.h),
                _termsRow(appText),
                SizedBox(height: 12.h),
                AuthButton(
                  label: appText.createAccount,
                  isLoading: _isLoading,
                  height: 60.h,
                  onPressed: _createAccount,
                ),
                SizedBox(height: 10.h),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4.w,
                  children: [
                    Text(
                      appText.alreadyHaveAccount,
                      style: TextStyle(
                        color: AppColor.authLogo,
                        fontSize: 12.sp,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushReplacementNamed(RouteNames.signIn),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        minimumSize: Size(0, 30.h),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColor.createAccount,
                      ),
                      child: Text(
                        appText.logIn,
                        style: TextStyle(
                          fontSize: 12.sp,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
