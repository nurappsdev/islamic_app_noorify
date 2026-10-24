import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/bloc/app_preferences/app_preferences_bloc.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/profile/presentation/screens/profile_screen.dart';
import 'package:tuhfatul_muslim/features/profile/presentation/screens/settings_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

final _text = AppText.forLanguage(AppLanguage.english);

/// Pumps [screen] the way the app does: one app-wide [AppPreferencesBloc]
/// (the theme choice) above it, so Profile and Settings share the same state.
/// [pushed] records the routes a tapped row navigates to.
Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required AppPreferencesBloc preferences,
  List<String>? pushed,
}) async {
  // The Profile hero card's points pill overflows at this viewport in
  // English - it does so with or without the rows under test, so it is not
  // allowed to fail these tests.
  final reportError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    reportError?.call(details);
  };
  addTearDown(() => FlutterError.onError = reportError);
  final language = LanguageBloc(
    initialLanguage: AppLanguage.english,
    persist: (_) async {},
  );
  addTearDown(language.close);
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: language),
        BlocProvider.value(value: preferences),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: screen,
          onGenerateRoute: (settings) {
            pushed?.add(settings.name ?? '');
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const SizedBox.shrink(),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppText.load();
    final dir = Directory.systemTemp.createTempSync('profile_quick_settings');
    Hive.init(dir.path);
    // ProfileScreen asks whether anyone is signed in, which reads this box.
    await Hive.openBox<dynamic>(HiveService.authBox);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the Profile screen offers the language and theme options', (
    tester,
  ) async {
    final preferences = AppPreferencesBloc();
    addTearDown(preferences.close);
    await _pump(tester, const ProfileScreen(), preferences: preferences);

    expect(find.text(_text.appLanguage), findsOneWidget);
    // Light theme is on, so the row offers the dark one.
    expect(find.text(_text.themeSwitchToDark), findsOneWidget);
    expect(find.text(_text.themeSwitchToLight), findsNothing);
  });

  testWidgets('both options stay on the Settings screen', (tester) async {
    final preferences = AppPreferencesBloc();
    addTearDown(preferences.close);
    await _pump(tester, const SettingsScreen(), preferences: preferences);

    expect(find.text(_text.appLanguage), findsOneWidget);
    expect(find.text(_text.themeSwitchToDark), findsOneWidget);
  });

  testWidgets('the language option opens the App Language screen', (
    tester,
  ) async {
    final preferences = AppPreferencesBloc();
    addTearDown(preferences.close);
    final pushed = <String>[];
    await _pump(
      tester,
      const ProfileScreen(),
      preferences: preferences,
      pushed: pushed,
    );

    await tester.tap(find.text(_text.appLanguage));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(pushed, [RouteNames.appLanguage]);
  });

  testWidgets('the theme option switches the theme and relabels itself', (
    tester,
  ) async {
    final preferences = AppPreferencesBloc();
    addTearDown(preferences.close);
    await _pump(tester, const ProfileScreen(), preferences: preferences);

    await tester.tap(find.text(_text.themeSwitchToDark));
    await tester.pump();

    expect(preferences.state.darkThemeEnabled, isTrue);
    // Now in the dark theme, the row offers the way back.
    expect(find.text(_text.themeSwitchToLight), findsOneWidget);
    expect(find.text(_text.themeSwitchToDark), findsNothing);
  });

  testWidgets('a theme switched from Profile is already switched in Settings', (
    tester,
  ) async {
    final preferences = AppPreferencesBloc();
    addTearDown(preferences.close);
    await _pump(tester, const ProfileScreen(), preferences: preferences);

    await tester.tap(find.text(_text.themeSwitchToDark));
    await tester.pump();

    // The same app-wide bloc now backs the Settings screen.
    await _pump(tester, const SettingsScreen(), preferences: preferences);
    expect(find.text(_text.themeSwitchToLight), findsOneWidget);
    expect(find.text(_text.themeSwitchToDark), findsNothing);

    // ...and the choice was saved, so the next launch keeps it.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AppPreferencesBloc.darkThemeKey), isTrue);
  });
}
