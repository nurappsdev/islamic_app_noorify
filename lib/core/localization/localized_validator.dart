import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tuhfatul_muslim/core/localization/localized_number_formatter.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Form validators whose messages come from the app's localization, in the
/// language that is selected at the moment they run.
///
/// Use it inside a `validator:` so a message is never written into a screen:
///
/// ```dart
/// validator: (value) => LocalizedValidator.readOf(context).email(value),
/// ```
///
/// Each method returns `null` when the value is valid, like a
/// [FormFieldValidator].
class LocalizedValidator {
  const LocalizedValidator(this._text, this._numbers);

  factory LocalizedValidator.forLanguage(AppLanguage language) =>
      LocalizedValidator(
        AppText.forLanguage(language),
        LocalizedNumberFormatter(language),
      );

  /// The validator for the language selected right now. Reads the language
  /// without subscribing, so it is safe inside a `validator:` callback.
  factory LocalizedValidator.readOf(BuildContext context) =>
      LocalizedValidator.forLanguage(
        context.read<LanguageBloc>().state.language,
      );

  final AppText _text;
  final LocalizedNumberFormatter _numbers;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _specialForSignIn = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]');

  /// The shortest password sign-in and sign-up accept.
  static const passwordMinLength = 8;

  String _withNumber(String template, String name, int value) =>
      template.replaceAll('{$name}', _numbers.integer(value));

  /// Any non-blank value.
  String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? _text.validatorRequired : null;

  String? name(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return _text.validatorNameEmpty;
    if (name.length < 2) return _text.validatorNameShort;
    return null;
  }

  String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return _text.validatorEmailEmpty;
    if (!_emailPattern.hasMatch(email)) return _text.validatorEmailInvalid;
    return null;
  }

  /// The password rule of the sign-in and sign-up screens.
  String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return _text.validatorPasswordEmpty;
    final missingRequirements = passwordMissingRequirements(password);
    return missingRequirements.isEmpty ? null : missingRequirements.join('\n');
  }

  /// Localized messages for only the password requirements that [value] has
  /// not met yet. Keeping the requirements separate lets field errors update
  /// as the user types instead of repeating requirements already satisfied.
  List<String> passwordMissingRequirements(String? value) {
    final password = value ?? '';
    return [
      if (password.length < passwordMinLength)
        _withNumber(_text.validatorPasswordMin, 'min', passwordMinLength),
      if (!password.contains(RegExp(r'[A-Z]')))
        _text.validatorPasswordUppercase,
      if (!password.contains(RegExp(r'[0-9]'))) _text.validatorPasswordNumber,
      if (!password.contains(_specialForSignIn)) _text.validatorPasswordSpecial,
    ];
  }

  /// [value] must equal [original].
  String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return _text.validatorConfirmPasswordEmpty;
    }
    if (value != original) return _text.validatorPasswordMismatch;
    return null;
  }

  String? currentPassword(String? value) => (value == null || value.isEmpty)
      ? _text.validatorCurrentPasswordEmpty
      : null;

  /// The stricter rule of the change-password screen.
  String? newPassword(
    String? value, {
    required String currentPassword,
    int minLength = 8,
    int maxLength = 64,
  }) {
    final v = value ?? '';
    if (v.isEmpty) return _text.validatorNewPasswordEmpty;
    if (v.contains(RegExp(r'\s'))) return _text.validatorPasswordNoSpaces;
    if (v.length < minLength) {
      return _withNumber(_text.validatorPasswordMin, 'min', minLength);
    }
    if (v.length > maxLength) {
      return _withNumber(_text.validatorPasswordMax, 'max', maxLength);
    }
    if (!v.contains(RegExp(r'[A-Z]'))) return _text.validatorPasswordUppercase;
    if (!v.contains(RegExp(r'[a-z]'))) return _text.validatorPasswordLowercase;
    if (!v.contains(RegExp(r'[0-9]'))) return _text.validatorPasswordNumber;
    if (!v.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return _text.validatorPasswordSpecial;
    }
    if (v == currentPassword) return _text.validatorPasswordSameAsOld;
    return null;
  }

  String? confirmNewPassword(String? value, String newPassword) {
    if (value == null || value.isEmpty) {
      return _text.validatorConfirmNewPasswordEmpty;
    }
    if (value != newPassword) return _text.validatorPasswordMismatch;
    return null;
  }

  /// The hint under the change-password form: which characters a password
  /// needs.
  String passwordRequirementsHint(int minLength) =>
      _withNumber(_text.passwordRequirementsHint, 'min', minLength);
}
