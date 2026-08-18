import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'package:islami_app_noorify/core/utils/app_text_bn.dart';
import 'package:islami_app_noorify/core/utils/app_text_en.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_cubit.dart';

class AppText {
  const AppText({
    required this.noorify,
    required this.splashTitle,
    required this.splashQuote,
    required this.emailOrPhoneHint,
    required this.passwordHint,
    required this.forgotPassword,
    required this.login,
    required this.newToNoorify,
    required this.createAccount,
    required this.signUpSubtitle,
    required this.enterYourName,
    required this.emailAddress,
    required this.emailVerification,
    required this.sendOtp,
    required this.otpVerification,
    required this.verify,
    required this.resendIn,
    required this.resetPassword,
    required this.newPassword,
    required this.confirm,
    required this.phoneNo,
    required this.gender,
    required this.male,
    required this.female,
    required this.confirmPassword,
    required this.signUpWithOthers,
    required this.togglePassword,
    required this.iAgreeToThe,
    required this.termsOfServices,
    required this.privacyPolicy,
    required this.alreadyHaveAccount,
    required this.logIn,
  });

  final String noorify;
  final String splashTitle;
  final String splashQuote;
  final String emailOrPhoneHint;
  final String passwordHint;
  final String forgotPassword;
  final String login;
  final String newToNoorify;
  final String createAccount;
  final String signUpSubtitle;
  final String enterYourName;
  final String emailAddress;
  final String emailVerification;
  final String sendOtp;
  final String otpVerification;
  final String verify;
  final String resendIn;
  final String resetPassword;
  final String newPassword;
  final String confirm;
  final String phoneNo;
  final String gender;
  final String male;
  final String female;
  final String confirmPassword;
  final String signUpWithOthers;
  final String togglePassword;
  final String iAgreeToThe;
  final String termsOfServices;
  final String privacyPolicy;
  final String alreadyHaveAccount;
  final String logIn;

  factory AppText.fromMap(Map<dynamic, dynamic> map, {AppText? fallback}) {
    return AppText(
      noorify: _read(map, 'noorify', fallback?.noorify ?? ''),
      splashTitle: _read(map, 'splashTitle', fallback?.splashTitle ?? ''),
      splashQuote: _read(map, 'splashQuote', fallback?.splashQuote ?? ''),
      emailOrPhoneHint: _read(
        map,
        'emailOrPhoneHint',
        fallback?.emailOrPhoneHint ?? '',
      ),
      passwordHint: _read(map, 'passwordHint', fallback?.passwordHint ?? ''),
      forgotPassword: _read(
        map,
        'forgotPassword',
        fallback?.forgotPassword ?? '',
      ),
      login: _read(map, 'login', fallback?.login ?? ''),
      newToNoorify: _read(map, 'newToNoorify', fallback?.newToNoorify ?? ''),
      createAccount: _read(map, 'createAccount', fallback?.createAccount ?? ''),
      signUpSubtitle: _read(
        map,
        'signUpSubtitle',
        fallback?.signUpSubtitle ?? '',
      ),
      enterYourName: _read(map, 'enterYourName', fallback?.enterYourName ?? ''),
      emailAddress: _read(map, 'emailAddress', fallback?.emailAddress ?? ''),
      emailVerification: _read(
        map,
        'emailVerification',
        fallback?.emailVerification ?? '',
      ),
      sendOtp: _read(map, 'sendOtp', fallback?.sendOtp ?? ''),
      otpVerification: _read(
        map,
        'otpVerification',
        fallback?.otpVerification ?? '',
      ),
      verify: _read(map, 'verify', fallback?.verify ?? ''),
      resendIn: _read(map, 'resendIn', fallback?.resendIn ?? ''),
      resetPassword: _read(map, 'resetPassword', fallback?.resetPassword ?? ''),
      newPassword: _read(map, 'newPassword', fallback?.newPassword ?? ''),
      confirm: _read(map, 'confirm', fallback?.confirm ?? ''),
      phoneNo: _read(map, 'phoneNo', fallback?.phoneNo ?? ''),
      gender: _read(map, 'gender', fallback?.gender ?? ''),
      male: _read(map, 'male', fallback?.male ?? ''),
      female: _read(map, 'female', fallback?.female ?? ''),
      confirmPassword: _read(
        map,
        'confirmPassword',
        fallback?.confirmPassword ?? '',
      ),
      signUpWithOthers: _read(
        map,
        'signUpWithOthers',
        fallback?.signUpWithOthers ?? '',
      ),
      togglePassword: _read(
        map,
        'togglePassword',
        fallback?.togglePassword ?? '',
      ),
      iAgreeToThe: _read(map, 'iAgreeToThe', fallback?.iAgreeToThe ?? ''),
      termsOfServices: _read(
        map,
        'termsOfServices',
        fallback?.termsOfServices ?? '',
      ),
      privacyPolicy: _read(map, 'privacyPolicy', fallback?.privacyPolicy ?? ''),
      alreadyHaveAccount: _read(
        map,
        'alreadyHaveAccount',
        fallback?.alreadyHaveAccount ?? '',
      ),
      logIn: _read(map, 'logIn', fallback?.logIn ?? ''),
    );
  }

  static final AppText _fallbackEnglish = AppText.fromMap(appTextEn);
  static final AppText _fallbackBangla = AppText.fromMap(appTextBn);

  static final Map<AppLanguage, AppText> _cache = <AppLanguage, AppText>{
    AppLanguage.english: _fallbackEnglish,
    AppLanguage.bangla: _fallbackBangla,
  };

  static Future<void> load() async {
    _cache[AppLanguage.english] = await _loadFile(
      'assets/language/en.json',
      _fallbackEnglish,
    );
    _cache[AppLanguage.bangla] = await _loadFile(
      'assets/language/bn.json',
      _fallbackBangla,
    );
  }

  static AppText of(BuildContext context) {
    final language = context.watch<LanguageCubit>().state.language;
    return forLanguage(language);
  }

  static AppText forLanguage(AppLanguage language) {
    return _cache[language] ??
        (language == AppLanguage.bangla ? _fallbackBangla : _fallbackEnglish);
  }

  static Future<AppText> _loadFile(String path, AppText fallback) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return fallback;
      return AppText.fromMap(decoded, fallback: fallback);
    } catch (_) {
      return fallback;
    }
  }

  static String _read(Map<dynamic, dynamic> json, String key, String fallback) {
    final value = json[key];
    if (value is! String) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }
}
