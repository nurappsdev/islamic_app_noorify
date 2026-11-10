import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/onboarding/presentation/screens/welcome_onboarding_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

void main() {
  testWidgets('uses the wide browser onboarding composition', (tester) async {
    if (!kIsWeb) return;

    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final language = LanguageBloc(persist: (_) async {});
    addTearDown(language.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: language,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => const MaterialApp(home: WelcomeOnboardingScreen()),
        ),
      ),
    );

    expect(find.byKey(const Key('web-onboarding-wide-layout')), findsOneWidget);
    expect(find.text('প্রতিটি ভালো আমলকে মূল্যবান করুন'), findsOneWidget);
  });
}
