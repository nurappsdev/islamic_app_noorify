import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuhfatul_muslim/features/onboarding/data/onboarding_preference.dart';
import 'package:tuhfatul_muslim/features/onboarding/presentation/screens/welcome_onboarding_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

void main() {
  test('a fresh install has not completed onboarding', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await OnboardingPreference.isCompleted(), isFalse);
    await OnboardingPreference.markCompleted();
    expect(await OnboardingPreference.isCompleted(), isTrue);
  });

  testWidgets('shows English first and lets the user switch to Bangla', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final languageBloc = LanguageBloc();
    addTearDown(languageBloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: languageBloc,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => const MaterialApp(home: WelcomeOnboardingScreen()),
        ),
      ),
    );

    expect(find.text('Make Every Good Deed Count'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(_onboardingImage('assets/onboard/salatImg.png'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pump();

    expect(find.text('প্রতিটি ভালো আমলকে মূল্যবান করুন'), findsOneWidget);
    expect(find.text('বাংলা'), findsOneWidget);
    expect(_onboardingImage('assets/onboard/salatBangla.png'), findsOneWidget);

    for (var index = 0; index < 3; index++) {
      await tester.tap(find.text('পরবর্তী'));
      await tester.pumpAndSettle();
    }

    expect(
      _onboardingImage('assets/onboard/onBoard4Bangla.png'),
      findsOneWidget,
    );
  });
}

Finder _onboardingImage(String assetPath) => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == assetPath,
);
