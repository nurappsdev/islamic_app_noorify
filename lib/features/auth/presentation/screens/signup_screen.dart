import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/login_params.dart';
import 'package:islami_app_noorify/features/profile/data/services/profile_service.dart';
import 'package:islami_app_noorify/features/auth/data/repositories/account_repository_impl.dart';
import 'package:islami_app_noorify/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:islami_app_noorify/features/auth/data/services/auth_service.dart';
import 'package:islami_app_noorify/features/auth/domain/usecases/register_account.dart';
import 'package:islami_app_noorify/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:islami_app_noorify/features/auth/presentation/bloc/register/register_bloc.dart';
import 'package:islami_app_noorify/features/auth/presentation/bloc/sign_up/sign_up_bloc.dart';
import 'package:islami_app_noorify/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:islami_app_noorify/features/auth/presentation/widgets/auth_button.dart';
import 'package:islami_app_noorify/features/legal/domain/entities/legal_document.dart';
import 'package:islami_app_noorify/features/legal/presentation/screens/legal_document_screen.dart';
import 'package:islami_app_noorify/shared/services/app_globals.dart';

class _Country {
  const _Country(this.flag, this.name, this.dialCode);

  final String flag;
  final String name;
  final String dialCode;
}

const _countries = <_Country>[
  _Country('🇧🇩', 'Bangladesh', '+880'),
  _Country('🇮🇳', 'India', '+91'),
  _Country('🇵🇰', 'Pakistan', '+92'),
  _Country('🇺🇸', 'United States', '+1'),
  _Country('🇨🇦', 'Canada', '+1'),
  _Country('🇬🇧', 'United Kingdom', '+44'),
  _Country('🇸🇦', 'Saudi Arabia', '+966'),
  _Country('🇦🇪', 'United Arab Emirates', '+971'),
  _Country('🇶🇦', 'Qatar', '+974'),
  _Country('🇰🇼', 'Kuwait', '+965'),
  _Country('🇴🇲', 'Oman', '+968'),
  _Country('🇧🇭', 'Bahrain', '+973'),
  _Country('🇲🇾', 'Malaysia', '+60'),
  _Country('🇸🇬', 'Singapore', '+65'),
  _Country('🇮🇩', 'Indonesia', '+62'),
  _Country('🇹🇷', 'Türkiye', '+90'),
  _Country('🇪🇬', 'Egypt', '+20'),
  _Country('🇦🇺', 'Australia', '+61'),
  _Country('🇩🇪', 'Germany', '+49'),
  _Country('🇫🇷', 'France', '+33'),
];

typedef GoogleSignUpRouteResolver = Future<String> Function();

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key, this.googleSignUpRouteResolver});

  final GoogleSignUpRouteResolver? googleSignUpRouteResolver;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SignUpBloc>(create: (_) => SignUpBloc()),
        BlocProvider<RegisterBloc>(
          create: (_) => RegisterBloc(
            RegisterAccount(AccountRepositoryImpl(AuthRemoteDataSourceImpl())),
          ),
        ),
      ],
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

  final TextEditingController _genderController = TextEditingController();
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => _openLegal(LegalDocumentType.termsOfService);
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => _openLegal(LegalDocumentType.privacyPolicy);

  String? _selectedGender;
  _Country _selectedCountry = _countries.first;

  SignUpBloc get _auth => context.read<SignUpBloc>();
  SignUpState get _authState => _auth.state;
  bool get _isLoading =>
      _authState.isLoading || context.watch<RegisterBloc>().state.isLoading;
  bool get _obscurePassword => _authState.obscurePassword;
  bool get _obscureConfirm => _authState.obscureConfirm;
  bool get _termsAccepted => _authState.saveInfo;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? prefix,
    Widget? suffixIcon,
    EdgeInsetsGeometry? contentPadding,
    bool isDense = false,
  }) {
    final radius = BorderRadius.circular(24.r);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColor.authHint, fontSize: 13.sp),
      prefixIcon:
          prefix ??
          (prefixIcon == null
              ? null
              : Icon(prefixIcon, color: AppColor.authIcon, size: 18.sp)),
      prefixIconConstraints: prefix == null
          ? null
          : const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffixIcon,
      isDense: isDense,
      filled: true,
      fillColor: context.surfaceColor(Colors.white),
      contentPadding:
          contentPadding ??
          EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
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

  void _openLegal(LegalDocumentType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegalDocumentScreen(type: type)),
    );
  }

  void _createAccount() {
    FocusScope.of(context).unfocus();

    if (!_termsAccepted) {
      _showMessage('Please accept the Terms of Service to continue.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match.');
      return;
    }

    context.read<RegisterBloc>().add(
      RegisterSubmitted(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : '${_selectedCountry.dialCode}${_phoneController.text.trim()}',
        gender: _selectedGender,
      ),
    );
  }

  void _onRegisterStateChanged(BuildContext context, RegisterState state) {
    switch (state.status) {
      case RegisterStatus.success:
        final password = _passwordController.text;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EmailVerificationScreen(
              initiallyShowOtp: true,
              startSession: true,
              email: state.user?.email,
              onOtpVerified: (_) => _finishSignUp(
                state.user?.email ?? _emailController.text.trim(),
                password,
              ),
            ),
          ),
        );
        context.read<RegisterBloc>().add(const RegisterReset());
      case RegisterStatus.failure:
        _showMessage(
          state.errorMessage ?? 'Registration failed. Please try again.',
        );
        context.read<RegisterBloc>().add(const RegisterReset());
      case RegisterStatus.initial:
      case RegisterStatus.loading:
        break;
    }
  }

  /// After the OTP is verified: make sure a session exists (the verify call
  /// stores the token when the API returns one, otherwise sign in with the
  /// credentials just used), load the user, and open Home as that user.
  Future<void> _finishSignUp(String email, String password) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!AuthLocalDataSourceImpl().hasToken) {
      final result = await AccountRepositoryImpl(
        AuthRemoteDataSourceImpl(),
      ).login(LoginParams(email: email, password: password));
      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) {
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
        navigator.pushNamedAndRemoveUntil(RouteNames.signIn, (_) => false);
        return;
      }
    }
    skipAuthGateNotifier.value = true;
    unawaited(saveAppPreferences());
    unawaited(ProfileService.instance.refresh());
    navigator.pushNamedAndRemoveUntil(RouteNames.home, (_) => false);
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
    final appText = AppText.of(context);
    _auth.add(const SetLoading(true));
    try {
      final route =
          await (widget.googleSignUpRouteResolver ??
              _defaultGoogleSignUpRouteResolver)();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    } on GoogleSignInException catch (e) {
      _showMessage(AuthService.instance.messageForGoogleException(e, appText));
    } on FirebaseAuthException catch (e) {
      _showMessage(AuthService.instance.messageForException(e, appText));
    } catch (_) {
      _showMessage(appText.googleAuthErrorGeneric);
    } finally {
      if (mounted) {
        _auth.add(const SetLoading(false));
      }
    }
  }

  /// Gender selector built on the same read-only [TextField] + decoration as
  /// [_authField], so icon, text position and padding are identical. A popup
  /// menu supplies the options.
  Widget _genderField(AppText appText) {
    final label = switch (_selectedGender) {
      'male' => appText.male,
      'female' => appText.female,
      _ => '',
    };
    if (_genderController.text != label) _genderController.text = label;
    return LayoutBuilder(
      builder: (context, constraints) => PopupMenuButton<String>(
        position: PopupMenuPosition.under,
        constraints: BoxConstraints(minWidth: constraints.maxWidth),
        color: context.surfaceColor(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        onSelected: (value) => setState(() => _selectedGender = value),
        itemBuilder: (_) => [
          PopupMenuItem(value: 'male', child: Text(appText.male)),
          PopupMenuItem(value: 'female', child: Text(appText.female)),
        ],
        child: IgnorePointer(
          child: SizedBox(
            height: 48.h,
            child: TextField(
              controller: _genderController,
              readOnly: true,
              decoration: _fieldDecoration(
                hint: appText.gender,
                prefixIcon: Icons.wc_outlined,
                suffixIcon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColor.authIcon,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Phone field with the country dial-code dropdown inside the same border,
  /// followed by a divider and the number input.
  Widget _phoneField(AppText appText) {
    final prefix = Padding(
      padding: EdgeInsets.only(left: 14.w, right: 8.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<_Country>(
              value: _selectedCountry,
              isDense: true,
              borderRadius: BorderRadius.circular(16.r),
              dropdownColor: context.surfaceColor(Colors.white),
              style: TextStyle(
                color: context.inkColor(AppColor.authLogo),
                fontSize: 13.sp,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColor.authIcon,
                size: 18.sp,
              ),
              selectedItemBuilder: (_) => [
                for (final country in _countries)
                  Text('${country.flag} ${country.dialCode}'),
              ],
              items: [
                for (final country in _countries)
                  DropdownMenuItem(
                    value: country,
                    child: Text(
                      '${country.flag} ${country.name} ${country.dialCode}',
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedCountry = value);
              },
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            height: 22.h,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: context.lineColor(AppColor.authFieldBorder),
            ),
          ),
        ],
      ),
    );
    return SizedBox(
      height: 48.h,
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        decoration: _fieldDecoration(hint: appText.phoneNo, prefix: prefix),
      ),
    );
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
            side: BorderSide(
              color: context.lineColor(AppColor.authFieldBorder),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.r),
            ),
            onChanged: (value) => _auth.add(SetSaveInfo(value ?? false)),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: context.inkColor(AppColor.authLogo),
                fontSize: 12.sp,
                height: 1.35,
              ),
              children: [
                TextSpan(text: '${appText.iAgreeToThe} '),
                TextSpan(
                  text: appText.termsOfServices,
                  recognizer: _termsTap,
                  style: const TextStyle(color: AppColor.primary),
                ),
                const TextSpan(text: ' & '),
                TextSpan(
                  text: appText.privacyPolicy,
                  recognizer: _privacyTap,
                  style: const TextStyle(color: AppColor.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element -- hidden for now, see build()
  Widget _socialSignupSection(AppText appText) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: context.lineColor(AppColor.authFieldBorder),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Text(
                appText.signUpWithOthers,
                style: TextStyle(color: AppColor.primary, fontSize: 13.sp),
              ),
            ),
            Expanded(
              child: Divider(
                color: context.lineColor(AppColor.authFieldBorder),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialIconButton(
              key: const Key('signup_google_button'),
              tooltip: appText.google,
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
              tooltip: appText.facebook,
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
          side: BorderSide(color: context.lineColor(AppColor.authFieldBorder)),
          foregroundColor: AppColor.primary,
          backgroundColor: context.surfaceColor(Colors.white),
        ),
        child: Tooltip(message: tooltip, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    context.watch<SignUpBloc>();

    return BlocListener<RegisterBloc, RegisterState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onRegisterStateChanged,
      child: Scaffold(
        backgroundColor: context.pageColor(AppColor.authBackground),
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
                        backgroundColor: context.surfaceColor(
                          Color(0xFFFFFAD7),
                        ),
                        foregroundColor: context.inkColor(Colors.black),
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
                      color: context.inkColor(AppColor.authLogo),
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
                      color: context.inkColor(AppColor.authLogo),
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
                  _phoneField(appText),
                  SizedBox(height: 9.h),
                  _genderField(appText),
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
                      onPressed: () => _auth.add(const ToggleObscurePassword()),
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
                      onPressed: () => _auth.add(const ToggleObscureConfirm()),
                    ),
                  ),
                  SizedBox(height: 28.h),
                  // TODO: re-enable "Sign Up with Others" (Google / Facebook)
                  // when social sign-up is ready.
                  // _socialSignupSection(appText),
                  // SizedBox(height: 28.h),
                  _termsRow(appText),
                  // The button only appears once the terms checkbox is ticked.
                  if (_termsAccepted) ...[
                    SizedBox(height: 12.h),
                    AuthButton(
                      label: appText.createAccount,
                      isLoading: _isLoading,
                      height: 60.h,
                      onPressed: _createAccount,
                    ),
                  ],
                  SizedBox(height: 10.h),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4.w,
                    children: [
                      Text(
                        appText.alreadyHaveAccount,
                        style: TextStyle(
                          color: context.inkColor(AppColor.authLogo),
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
                          foregroundColor: context.inkColor(
                            AppColor.createAccount,
                          ),
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
      ),
    );
  }
}
