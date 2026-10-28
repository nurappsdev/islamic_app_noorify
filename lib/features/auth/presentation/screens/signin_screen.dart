import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/auth/data/repositories/account_repository_impl.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/services/google_auth_service.dart';
import 'package:tuhfatul_muslim/features/auth/domain/usecases/google_sign_in_user.dart';
import 'package:tuhfatul_muslim/features/auth/domain/usecases/login_user.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/bloc/login/login_bloc.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/widgets/auth_button.dart';
import 'package:tuhfatul_muslim/features/profile/data/services/profile_service.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';
import 'package:tuhfatul_muslim/shared/services/firebase/firebase_token_service.dart';
import 'package:tuhfatul_muslim/core/localization/localized_validator.dart';
import 'package:tuhfatul_muslim/core/localization/localized_form_scope.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SignInBloc>(create: (_) => SignInBloc()),
        BlocProvider<LoginBloc>(
          create: (_) {
            final repository = AccountRepositoryImpl(
              AuthRemoteDataSourceImpl(),
            );
            return LoginBloc(
              LoginUser(repository),
              GoogleSignInUser(repository),
            );
          },
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
  static const _logoImagePath = 'assets/appLogoFinal.png';
  static const _errorColor = Color(0xFFD93025);
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// `true` only while the Google account picker is on screen; the REST
  /// exchange that follows is tracked by [LoginBloc] like any other sign-in.
  bool _googleBusy = false;

  SignInBloc get _auth => context.read<SignInBloc>();
  SignInState get _authState => _auth.state;

  /// Whether a sign-in is in flight. This *watches* [LoginBloc], so it may
  /// only be read while building — [build] reads it once and hands the value
  /// down, since a field callback that read it here crashed with provider's
  /// "Tried to listen to a value exposed with provider, from outside of the
  /// widget tree".
  bool get _isLoading =>
      _authState.isLoading ||
      _googleBusy ||
      context.watch<LoginBloc>().state.isLoading;
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
      errorStyle: TextStyle(color: _errorColor, fontSize: 11.5.sp, height: 1.2),
      errorMaxLines: null,
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: _errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: _errorColor, width: 1.2),
      ),
    );
  }

  String? _validateEmail(String? value) =>
      LocalizedValidator.readOf(context).email(value);

  String? _validatePassword(String? value) =>
      LocalizedValidator.readOf(context).password(value);

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Captured before the await below so nothing here touches `context`
    // once this device's FCM token has been fetched.
    final loginBloc = context.read<LoginBloc>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fcmToken = await FirebaseTokenService.instance.getToken();
    loginBloc.add(
      LoginSubmitted(email: email, password: password, fcmToken: fcmToken),
    );
  }

  /// Runs the Google account picker, then hands the ID token to [LoginBloc]
  /// to be exchanged for an app session. A cancelled picker is silent.
  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    final appText = AppText.of(context);
    final loginBloc = context.read<LoginBloc>();

    setState(() => _googleBusy = true);
    try {
      final result = await GoogleAuthService.instance.signIn();
      final fcmToken = await FirebaseTokenService.instance.getToken();
      loginBloc.add(
        GoogleLoginSubmitted(
          idToken: result.idToken,
          email: result.email,
          displayName: result.displayName,
          photoUrl: result.photoUrl,
          fcmToken: fcmToken,
        ),
      );
    } on GoogleSignInException catch (e) {
      _showMessage(GoogleAuthService.messageFor(e, appText));
    } catch (_) {
      _showMessage(appText.googleAuthErrorGeneric);
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted || message.trim().isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
              state.errorMessage ?? AppText.readOf(context).signInFailed,
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

  /// "Continue with Google", styled to sit beside [AuthButton] as the
  /// secondary action rather than competing with it.
  Widget _googleSignInButton(AppText appText, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: OutlinedButton.icon(
        key: const Key('signin_google_button'),
        onPressed: isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.inkColor(AppColor.authLogo),
          side: BorderSide(color: context.lineColor(AppColor.authFieldBorder)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        icon: Text(
          'G',
          style: TextStyle(
            color: const Color(0xFF4285F4),
            fontSize: 19.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        label: Text(
          appText.google,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
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
      child: _buildScaffold(appText, _isLoading),
    );
  }

  Widget _buildScaffold(AppText appText, bool isLoading) {
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
                            AppText.of(context).tuhfatulMuslim,
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
                      color: context.inkColor(const Color(0xFF859065)),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  LocalizedFormScope(
                    child: Form(
                      key: _formKey,
                      // Disabled here, not onUserInteraction: Form tracks
                      // "has the user interacted" at the form level, so
                      // onUserInteraction on the Form re-validates every
                      // field once ANY field is touched. Each field below
                      // instead validates only itself via its own key.
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: _emailFieldKey,
                            controller: _emailController,
                            validator: _validateEmail,
                            onChanged: (_) =>
                                _emailFieldKey.currentState?.validate(),
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
                          SizedBox(height: 8.h),
                          TextFormField(
                            key: _passwordFieldKey,
                            controller: _passwordController,
                            validator: _validatePassword,
                            onChanged: (_) =>
                                _passwordFieldKey.currentState?.validate(),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) {
                              if (isLoading) return;
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
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : _openEmailVerification,
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
                    isLoading: isLoading,
                    onPressed: _signIn,
                  ),
                  SizedBox(height: 18.h),
                  _googleSignInButton(appText, isLoading),
                  SizedBox(height: 14.h),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4.w,
                    children: [
                      Text(
                        appText.newToTuhfatulMuslim,
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
                    onPressed: isLoading ? null : _continueAsGuest,
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
