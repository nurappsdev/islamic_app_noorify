import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/bloc/app_preferences/app_preferences_bloc.dart';
import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/core/theme/app_typography.dart';
import 'package:tuhfatul_muslim/core/theme/light_theme.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/alarm/presentation/screens/all_alarm_screen.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/screens/signin_screen.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/screens/signup_screen.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/screens/hadith_intro_screen.dart';
import 'package:tuhfatul_muslim/features/onboarding/presentation/screens/welcome_onboarding_screen.dart';
import 'package:tuhfatul_muslim/features/profile/presentation/screens/app_language_screen.dart';
import 'package:tuhfatul_muslim/features/profile/presentation/screens/settings_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Bangla says the same thing in more characters than English does, so a row
/// or button sized around its English label is where Bangla spills out of
/// its box. These open each screen in Bangla, on the narrowest phone the app
/// supports, and fail on any overflow the layout reports.
/// Built lazily: a screen's constructor can reach for storage, which is only
/// ready once [main]'s setUpAll has run.
final _screens = <String, Widget Function()>{
  'Sign in': SignInScreen.new,
  'Sign up': SignupScreen.new,
  'Forgot password': ForgotPasswordScreen.new,
  'Settings': SettingsScreen.new,
  'App language': AppLanguageScreen.new,
  'Alarms': AllAlarmScreen.new,
  'Hadith intro': HadithIntroScreen.new,
  'Onboarding': WelcomeOnboardingScreen.new,
};

/// 360 x 640 logical pixels: the narrowest, shortest screen in common use.
const _narrowPhone = Size(360, 640);

Future<List<String>> _overflowsOn(WidgetTester tester, Widget screen) async {
  final overflows = <String>[];
  final reportError = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    // Anything else - a stubbed-out request, an image that cannot load in a
    // test - is not what these tests are about.
    if (text.contains('overflowed')) overflows.add(text.split('\n').first);
  };
  final language = LanguageBloc(
    initialLanguage: AppLanguage.bangla,
    persist: (_) async {},
  );
  final preferences = AppPreferencesBloc();
  tester.view.physicalSize = _narrowPhone * 3;
  tester.view.devicePixelRatio = 3;
  try {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: language),
          BlocProvider.value(value: preferences),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            theme: lightTheme(fontFamily: appFontFamilyBangla),
            home: screen,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    FlutterError.onError = reportError;
    await language.close();
    await preferences.close();
    tester.view.reset();
  }
  return overflows;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppText.load();
    final dir = Directory.systemTemp.createTempSync('bangla_layout_hive');
    Hive.init(dir.path);
    for (final box in [
      HiveService.authBox,
      HiveService.alarmsBox,
      HiveService.prayerAlarmsBox,
    ]) {
      await Hive.openBox<dynamic>(box);
    }
  });

  _screens.forEach((name, build) {
    testWidgets('$name lays Bangla out without overflowing', (tester) async {
      final overflows = await _overflowsOn(tester, build());
      expect(overflows, isEmpty, reason: '$name:\n${overflows.join('\n')}');
    });
  });
}
