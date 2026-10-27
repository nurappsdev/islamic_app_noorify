import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/hadith/data/hadith_content_settings.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/screens/hadith_language_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

Future<List<HadithContentSettings>> _pump(
  WidgetTester tester, {
  HadithContentSettings settings = const HadithContentSettings(),
  AppLanguage language = AppLanguage.english,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final changes = <HadithContentSettings>[];
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => LanguageBloc(initialLanguage: language),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: HadithLanguageScreen(
            settings: settings,
            onChanged: changes.add,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return changes;
}

void main() {
  setUpAll(() async => AppText.load());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('picking English reports it and marks the row', (tester) async {
    final changes = await _pump(tester);

    expect(find.text('Reading Language'), findsOneWidget);
    expect(find.text('HADITH READING LANGUAGE'), findsOneWidget);
    expect(find.text('TRANSLATION'), findsOneWidget);
    // Bangla is the default, so only it is checked to begin with.
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pump();

    expect(changes, hasLength(1));
    expect(
      changes.single.translationLanguage,
      HadithTranslationLanguage.english,
    );
    // Still exactly one check, now on the English row.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('the Arabic switch cannot turn off the last text', (
    tester,
  ) async {
    final changes = await _pump(
      tester,
      settings: const HadithContentSettings(showTranslation: false),
    );

    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(changes, isEmpty);
  });

  testWidgets('turning Arabic off is reported while a translation shows', (
    tester,
  ) async {
    final changes = await _pump(tester);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(changes.single.showArabic, isFalse);
  });

  testWidgets('in dark mode the pale close badge keeps a dark icon', (
    tester,
  ) async {
    await _pump(tester, brightness: Brightness.dark);

    final close = tester.widget<IconButton>(find.byType(IconButton));
    expect(
      close.style!.foregroundColor!.resolve(const <WidgetState>{}),
      Colors.black,
    );
    expect(
      close.style!.backgroundColor!.resolve(const <WidgetState>{}),
      const Color(0xFFCBD16B),
    );
  });

  test('the chosen translation survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final store = HadithContentSettingsStore();
    expect(
      (await store.load()).translationLanguage,
      HadithTranslationLanguage.bangla,
    );

    await store.save(
      const HadithContentSettings(
        translationLanguage: HadithTranslationLanguage.english,
      ),
    );
    expect(
      (await store.load()).translationLanguage,
      HadithTranslationLanguage.english,
    );
  });
}
