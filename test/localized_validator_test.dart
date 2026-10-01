import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/localization/localized_form_scope.dart';
import 'package:tuhfatul_muslim/core/localization/localized_validator.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

LocalizedValidator _en() => LocalizedValidator.forLanguage(AppLanguage.english);
LocalizedValidator _bn() => LocalizedValidator.forLanguage(AppLanguage.bangla);

void main() {
  group('messages', () {
    test('English', () {
      expect(_en().email(''), 'Please enter your email');
      expect(_en().email('nope'), 'Please enter a valid email address');
      expect(_en().password(''), 'Please enter your password');
      expect(_en().required('  '), 'This field is required');
      expect(_en().name(''), 'Please enter your name');
      expect(_en().name('A'), 'Please enter your full name');
      expect(
        _en().newPassword('Ab1!', currentPassword: 'x'),
        'Password must be at least 8 characters',
      );
    });

    test('Bangla', () {
      expect(_bn().email(''), 'ইমেইল লিখুন');
      expect(_bn().email('nope'), 'সঠিক ইমেইল ঠিকানা লিখুন');
      expect(_bn().password(''), 'পাসওয়ার্ড লিখুন');
      expect(_bn().required('  '), 'এই ঘরটি পূরণ করা আবশ্যক');
      expect(
        _bn().newPassword('Ab1!', currentPassword: 'x'),
        'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে',
      );
    });

    test('valid values return null in both languages', () {
      for (final v in [_en(), _bn()]) {
        expect(v.email('a@b.co'), isNull);
        expect(v.password('Abcdef1!'), isNull);
        expect(v.name('Rahim Uddin'), isNull);
        expect(v.confirmPassword('x', 'x'), isNull);
        expect(v.required('x'), isNull);
        expect(v.newPassword('Abcdef1!', currentPassword: 'old'), isNull);
      }
    });

    test('every rule has a message in both languages, none left blank', () {
      final en = AppText.forLanguage(AppLanguage.english);
      final bn = AppText.forLanguage(AppLanguage.bangla);
      final pairs = <String, (String, String)>{
        'required': (en.validatorRequired, bn.validatorRequired),
        'emailEmpty': (en.validatorEmailEmpty, bn.validatorEmailEmpty),
        'emailInvalid': (en.validatorEmailInvalid, bn.validatorEmailInvalid),
        'passwordEmpty': (en.validatorPasswordEmpty, bn.validatorPasswordEmpty),
        'passwordRule': (en.validatorPasswordRule, bn.validatorPasswordRule),
        'passwordMin': (en.validatorPasswordMin, bn.validatorPasswordMin),
        'passwordMax': (en.validatorPasswordMax, bn.validatorPasswordMax),
        'nameEmpty': (en.validatorNameEmpty, bn.validatorNameEmpty),
        'nameShort': (en.validatorNameShort, bn.validatorNameShort),
        'confirmEmpty': (
          en.validatorConfirmPasswordEmpty,
          bn.validatorConfirmPasswordEmpty,
        ),
        'mismatch': (
          en.validatorPasswordMismatch,
          bn.validatorPasswordMismatch,
        ),
        'currentEmpty': (
          en.validatorCurrentPasswordEmpty,
          bn.validatorCurrentPasswordEmpty,
        ),
        'newEmpty': (
          en.validatorNewPasswordEmpty,
          bn.validatorNewPasswordEmpty,
        ),
        'noSpaces': (
          en.validatorPasswordNoSpaces,
          bn.validatorPasswordNoSpaces,
        ),
        'upper': (en.validatorPasswordUppercase, bn.validatorPasswordUppercase),
        'lower': (en.validatorPasswordLowercase, bn.validatorPasswordLowercase),
        'number': (en.validatorPasswordNumber, bn.validatorPasswordNumber),
        'special': (en.validatorPasswordSpecial, bn.validatorPasswordSpecial),
        'sameAsOld': (
          en.validatorPasswordSameAsOld,
          bn.validatorPasswordSameAsOld,
        ),
        'confirmNewEmpty': (
          en.validatorConfirmNewPasswordEmpty,
          bn.validatorConfirmNewPasswordEmpty,
        ),
      };
      pairs.forEach((name, texts) {
        expect(texts.$1, isNotEmpty, reason: '$name (en)');
        expect(texts.$2, isNotEmpty, reason: '$name (bn)');
        expect(texts.$1, isNot(texts.$2), reason: '$name is not translated');
        // Bangla messages carry no Latin words.
        final withoutPlaceholders = texts.$2.replaceAll(RegExp(r'\{\w+\}'), '');
        expect(
          withoutPlaceholders,
          isNot(matches(RegExp('[A-Za-z]{3,}'))),
          reason: name,
        );
      });
    });
  });

  group('screens', () {
    test('no form screen writes a validator message itself', () {
      // A `return 'Some English';` inside a validator is a hardcoded message.
      final offenders = <String>[];
      for (final path in [
        'lib/features/auth/presentation/screens/signin_screen.dart',
        'lib/features/auth/presentation/screens/signup_screen.dart',
        'lib/features/profile/presentation/screens/change_password_screen.dart',
        'lib/features/profile/presentation/screens/profile_edit_screen.dart',
      ]) {
        final source = File(path).readAsStringSync();
        if (RegExp(r"""return\s+['"][A-Za-z]""").hasMatch(source)) {
          offenders.add(path);
        }
        expect(source, contains('LocalizedValidator'), reason: path);
        expect(source, contains('LocalizedFormScope'), reason: path);
      }
      expect(offenders, isEmpty);
    });
  });

  group('changing the language while an error is showing', () {
    testWidgets('the message on screen switches language on its own', (
      tester,
    ) async {
      final bloc = LanguageBloc(
        initialLanguage: AppLanguage.bangla,
        persist: (_) async {},
      );
      addTearDown(bloc.close);
      final formKey = GlobalKey<FormState>();
      final emailKey = GlobalKey<FormFieldState<String>>();

      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            home: Scaffold(
              body: LocalizedFormScope(
                child: Form(
                  key: formKey,
                  child: Builder(
                    builder: (context) => Column(
                      children: [
                        TextFormField(
                          key: emailKey,
                          validator: (v) =>
                              LocalizedValidator.readOf(context).email(v),
                        ),
                        // A field the user has not touched: it must not be
                        // flagged just because the language changed.
                        TextFormField(
                          validator: (v) =>
                              LocalizedValidator.readOf(context).required(v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Validate only the first field, as if the user submitted just it.
      emailKey.currentState!.validate();
      await tester.pump();
      expect(find.text('ইমেইল লিখুন'), findsOneWidget);
      expect(find.text('এই ঘরটি পূরণ করা আবশ্যক'), findsNothing);

      bloc.add(const UpdateLanguage(AppLanguage.english));
      await tester.pump(); // the language changes
      await tester.pump(); // the post-frame re-validation

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('ইমেইল লিখুন'), findsNothing);
      // The untouched field was not flagged.
      expect(find.text('This field is required'), findsNothing);

      bloc.add(const UpdateLanguage(AppLanguage.bangla));
      await tester.pump();
      await tester.pump();
      expect(find.text('ইমেইল লিখুন'), findsOneWidget);
    });
  });
}
