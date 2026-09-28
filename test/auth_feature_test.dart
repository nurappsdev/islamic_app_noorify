import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/auth/auth_feature.dart';
import 'package:islami_app_noorify/core/widgets/login_required_dialog.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

const _ids = [
  AuthFeatures.general,
  AuthFeatures.quran,
  AuthFeatures.salah,
  AuthFeatures.amol,
  AuthFeatures.hadith,
  AuthFeatures.hadithPlanner,
  AuthFeatures.hadithDashboard,
  AuthFeatures.quiz,
  AuthFeatures.quizPlanner,
  AuthFeatures.leaderboard,
  AuthFeatures.bookmark,
];

void main() {
  group('AuthFeatures', () {
    for (final language in AppLanguage.values) {
      test('every feature has a complete message in ${language.name}', () {
        for (final id in _ids) {
          final feature = AuthFeatures.of(id);
          expect(feature.id, id);
          expect(feature.featureName.resolve(language), isNotEmpty, reason: id);
          final message = feature.messageFor(language);
          expect(message, isNotEmpty, reason: id);
          // No template placeholder is left unfilled.
          expect(message, isNot(contains('{')), reason: id);
        }
      });
    }

    test('a hand-written message is used as written', () {
      expect(
        AuthFeatures.of(AuthFeatures.salah).messageFor(AppLanguage.bangla),
        'আপনি আপনার সালাতের আমল ট্র্যাক করতে চান। আপনার দৈনিক সালাতের অগ্রগতি '
        'সংরক্ষণ করতে অনুগ্রহ করে সাইন-ইন করুন।',
      );
    });

    test(
      'a feature without one gets a generated message naming its action',
      () {
        final feature = AuthFeatures.of(AuthFeatures.hadithPlanner);
        expect(feature.message, isNull);
        expect(
          feature.messageFor(AppLanguage.english),
          contains('plan your Hadith reading'),
        );
        expect(
          feature.messageFor(AppLanguage.bangla),
          contains('আপনার হাদিস পড়ার পরিকল্পনা করতে'),
        );
      },
    );

    test('an unregistered id is a programming error', () {
      expect(() => AuthFeatures.of('nope'), throwsAssertionError);
    });
  });

  group('requireLogin', () {
    Future<void> pump(WidgetTester tester, AppLanguage language) async {
      // A phone-sized screen, matching the design size ScreenUtil scales from.
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final bloc = LanguageBloc()..add(UpdateLanguage(language));
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              home: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showLoginRequiredDialog(
                    context,
                    feature: AuthFeatures.quiz,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the feature-specific message in English', (
      tester,
    ) async {
      await pump(tester, AppLanguage.english);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Islamic quiz'), findsOneWidget);
      expect(
        find.textContaining('take the Islamic quiz and save your results'),
        findsOneWidget,
      );
      expect(find.text('Not now'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('shows the feature-specific message in Bangla', (tester) async {
      await pump(tester, AppLanguage.bangla);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('ইসলামিক কুইজ'), findsOneWidget);
      expect(find.textContaining('কুইজের অগ্রগতি ধরে রাখতে'), findsOneWidget);
      expect(find.text('এখন নয়'), findsOneWidget);
    });
  });
}
