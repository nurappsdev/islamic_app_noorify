import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/auth/auth_feature.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/widgets/facebook_sign_in_button.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_context.dart';
import 'package:tuhfatul_muslim/core/storage/session_cleaner.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/services/google_auth_service.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/google_sign_in_params.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/login_params.dart';
import 'package:tuhfatul_muslim/shared/services/firebase/firebase_token_service.dart';
import 'package:tuhfatul_muslim/features/profile/data/services/profile_service.dart';
import 'package:tuhfatul_muslim/features/auth/data/repositories/account_repository_impl.dart';
import 'package:tuhfatul_muslim/features/auth/domain/usecases/register_account.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/bloc/register/register_bloc.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/bloc/sign_up/sign_up_bloc.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/widgets/auth_button.dart';
import 'package:tuhfatul_muslim/features/legal/domain/entities/legal_document.dart';
import 'package:tuhfatul_muslim/features/legal/presentation/screens/legal_document_screen.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';
import 'package:tuhfatul_muslim/core/localization/localized_validator.dart';
import 'package:tuhfatul_muslim/core/localization/localized_form_scope.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/core/localization/localization_context.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

/// Carries a REST [Failure]'s message out of the Google route resolver, so the
/// caller can tell a backend refusal apart from a cancelled account picker.
class _GoogleSignUpFailure implements Exception {
  const _GoogleSignUpFailure(this.message);

  final String message;
}

class _Country {
  const _Country(this.flag, this.name, this.dialCode, this.nameBn);

  final String flag;
  final String name;
  final String dialCode;
  final String nameBn;

  /// The name in the selected language. The dial code stays as it is: it is
  /// part of the phone number that is sent.
  String displayName(AppLanguage language) =>
      language == AppLanguage.bangla ? nameBn : name;
}

const _countries = <_Country>[
  _Country('🇧🇩', 'Bangladesh', '+880', 'বাংলাদেশ'),
  _Country('🇮🇳', 'India', '+91', 'ভারত'),
  _Country('🇵🇰', 'Pakistan', '+92', 'পাকিস্তান'),
  _Country('🇺🇸', 'United States', '+1', 'যুক্তরাষ্ট্র'),
  _Country('🇨🇦', 'Canada', '+1', 'কানাডা'),
  _Country('🇬🇧', 'United Kingdom', '+44', 'যুক্তরাজ্য'),
  _Country('🇸🇦', 'Saudi Arabia', '+966', 'সৌদি আরব'),
  _Country('🇦🇪', 'United Arab Emirates', '+971', 'সংযুক্ত আরব আমিরাত'),
  _Country('🇶🇦', 'Qatar', '+974', 'কাতার'),
  _Country('🇰🇼', 'Kuwait', '+965', 'কুয়েত'),
  _Country('🇴🇲', 'Oman', '+968', 'ওমান'),
  _Country('🇧🇭', 'Bahrain', '+973', 'বাহরাইন'),
  _Country('🇲🇾', 'Malaysia', '+60', 'মালয়েশিয়া'),
  _Country('🇸🇬', 'Singapore', '+65', 'সিঙ্গাপুর'),
  _Country('🇮🇩', 'Indonesia', '+62', 'ইন্দোনেশিয়া'),
  _Country('🇹🇷', 'Türkiye', '+90', 'তুরস্ক'),
  _Country('🇪🇬', 'Egypt', '+20', 'মিশর'),
  _Country('🇦🇺', 'Australia', '+61', 'অস্ট্রেলিয়া'),
  _Country('🇩🇪', 'Germany', '+49', 'জার্মানি'),
  _Country('🇫🇷', 'France', '+33', 'ফ্রান্স'),
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

  final _formKey = GlobalKey<FormState>();
  final _confirmFieldKey = GlobalKey<FormFieldState<String>>();

  static const _errorColor = Color(0xFFD93025);

  String? _selectedGender;
  _Country _selectedCountry = _countries.first;

  /// `true` only while the Google sign-up is in flight. Kept out of
  /// [_isLoading] on purpose: the spinner belongs inside the Google button,
  /// so the Create Account button is left alone while Google runs.
  bool _googleBusy = false;

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
      constraints: BoxConstraints(minHeight: 48.h),
      errorStyle: TextStyle(color: _errorColor, fontSize: 11.5.sp, height: 1.2),
      // Password errors are separate, localized lines. Do not cap them: a
      // narrow screen must be able to show every remaining requirement.
      errorMaxLines: null,
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
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _errorColor, width: 1.2),
      ),
    );
  }

  String? _validateName(String? value) =>
      LocalizedValidator.readOf(context).name(value);

  String? _validateEmail(String? value) =>
      LocalizedValidator.readOf(context).email(value);

  String? _validatePassword(String? value) =>
      LocalizedValidator.readOf(context).password(value);

  String? _validateConfirmPassword(String? value) => LocalizedValidator.readOf(
    context,
  ).confirmPassword(value, _passwordController.text);

  void _openLegal(LegalDocumentType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegalDocumentScreen(type: type)),
    );
  }

  void _createAccount() {
    FocusScope.of(context).unfocus();

    if (_googleBusy) return;
    if (!_termsAccepted) {
      _showMessage(AppText.readOf(context).validatorTermsRequired);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
          state.errorMessage ?? AppText.readOf(context).registrationFailed,
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
    // Offer the new credentials to the device's password manager.
    TextInput.finishAutofillContext(shouldSave: true);
    skipAuthGateNotifier.value = true;
    unawaited(saveAppPreferences());
    unawaited(ProfileService.instance.refresh());
    navigator.pushNamedAndRemoveUntil(RouteNames.home, (_) => false);
  }

  /// Signs up (or signs straight in, when the Google e-mail already has an
  /// account) through the REST backend. Firebase Authentication plays no part:
  /// the ID token goes to `POST /auth/google`, and the token that comes back
  /// is cached in the same Hive key as an e-mail sign-in — so this is a
  /// first-class session, unlike the Firebase-only one it replaces.
  Future<String> _defaultGoogleSignUpRouteResolver() async {
    final result = await GoogleAuthService.instance.signIn();
    final fcmToken = await FirebaseTokenService.instance.getToken();

    final outcome = await AccountRepositoryImpl(AuthRemoteDataSourceImpl())
        .googleSignIn(
          GoogleSignInParams(
            idToken: result.idToken,
            email: result.email,
            displayName: result.displayName,
            photoUrl: result.photoUrl,
            fcmToken: fcmToken,
          ),
        );

    final failure = outcome.fold((f) => f, (_) => null);
    if (failure != null) {
      throw _GoogleSignUpFailure(failure.message);
    }

    // Whatever was armed as a Guest must not carry into this account.
    await SessionCleaner.clearGuestAlarms();
    await _setSkipAuthGate(true);
    unawaited(ProfileService.instance.refresh());
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
    FocusScope.of(context).unfocus();
    if (_googleBusy || context.read<RegisterBloc>().state.isLoading) return;
    final appText = AppText.of(context);
    setState(() => _googleBusy = true);
    try {
      final route =
          await (widget.googleSignUpRouteResolver ??
              _defaultGoogleSignUpRouteResolver)();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    } on GoogleSignInException catch (e) {
      _showMessage(GoogleAuthService.messageFor(e, appText));
    } on _GoogleSignUpFailure catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage(appText.googleAuthErrorGeneric);
    } finally {
      if (mounted) setState(() => _googleBusy = false);
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
          PopupMenuItem(
            value: 'female',
            child: Text(context.localizedDigits(appText.female)),
          ),
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
                      '${country.flag} ${country.displayName(context.appLanguage)} ${country.dialCode}',
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
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      decoration: _fieldDecoration(hint: appText.phoneNo, prefix: prefix),
    );
  }

  Widget _authField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    Key? fieldKey,
    ValueChanged<String>? onChanged,
    Iterable<String>? autofillHints,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      autofillHints: autofillHints,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      // Like Gmail: errors appear once the user has interacted with the
      // field (or on submit) and vanish as soon as the input is valid.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _fieldDecoration(
        hint: hint,
        prefixIcon: icon,
        suffixIcon: suffixIcon,
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
            // Flexible, because the Bangla label is wider than the English
            // one and overflowed the row at narrow widths.
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Text(
                  appText.signUpWithOthers,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.primary, fontSize: 13.sp),
                ),
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
        GoogleSignInButton(
          key: const Key('signup_google_button'),
          label: AuthPromptTexts.signUpWithGoogle.resolve(languageOf(context)),
          isLoading: _googleBusy,
          height: 60.h,
          onPressed: _signUpWithGoogle,
        ),
        SizedBox(height: 16.h),
        // Presentation only: Facebook login is not wired up yet.
        FacebookSignInButton(
          key: const Key('signup_facebook_button'),
          label: AuthPromptTexts.signUpWithFacebook.resolve(
            languageOf(context),
          ),
          height: 60.h,
          onPressed: () {},
        ),
      ],
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
              child: LocalizedFormScope(
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
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
                          validator: _validateName,
                          autofillHints: const [AutofillHints.name],
                          textInputAction: TextInputAction.next,
                        ),
                        SizedBox(height: 9.h),
                        _authField(
                          controller: _emailController,
                          hint: appText.emailAddress,
                          icon: Icons.mail_outline,
                          validator: _validateEmail,
                          autofillHints: const [AutofillHints.newUsername],
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
                          validator: _validatePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          // Re-check the confirm field if it was already filled.
                          onChanged: (_) {
                            if (_confirmPasswordController.text.isNotEmpty) {
                              _confirmFieldKey.currentState?.validate();
                            }
                          },
                          textInputAction: TextInputAction.next,
                          suffixIcon: _passwordVisibilityButton(
                            appText: appText,
                            obscure: _obscurePassword,
                            onPressed: () =>
                                _auth.add(const ToggleObscurePassword()),
                          ),
                        ),
                        SizedBox(height: 9.h),
                        _authField(
                          controller: _confirmPasswordController,
                          hint: appText.confirmPassword,
                          icon: Icons.key_outlined,
                          obscureText: _obscureConfirm,
                          fieldKey: _confirmFieldKey,
                          validator: _validateConfirmPassword,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.done,
                          suffixIcon: _passwordVisibilityButton(
                            appText: appText,
                            obscure: _obscureConfirm,
                            onPressed: () =>
                                _auth.add(const ToggleObscureConfirm()),
                          ),
                        ),
                        SizedBox(height: 28.h),
                        // TODO: re-enable "Sign Up with Others" (Google / Facebook)
                        // when social sign-up is ready.
                        // _socialSignupSection(appText),
                        // SizedBox(height: 28.h),
                        _termsRow(appText),
                        SizedBox(height: 12.h),
                        AuthButton(
                          label: appText.createAccount,
                          isLoading: _isLoading,
                          height: 60.h,
                          onPressed: _termsAccepted ? _createAccount : null,
                        ),
                        SizedBox(height: 18.h),
                        GoogleSignInButton(
                          key: const Key('signup_google_button'),
                          label: AuthPromptTexts.continueWithGoogle.resolve(
                            languageOf(context),
                          ),
                          isLoading: _googleBusy,
                          height: 60.h,
                          onPressed: _signUpWithGoogle,
                        ),
                        SizedBox(height: 18.h),
                        // Presentation only: Facebook login is not wired up
                        // yet.
                        FacebookSignInButton(
                          key: const Key('signup_facebook_button'),
                          label: AuthPromptTexts.continueWithFacebook.resolve(
                            languageOf(context),
                          ),
                          height: 60.h,
                          onPressed: () {},
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
          ),
        ),
      ),
    );
  }
}
