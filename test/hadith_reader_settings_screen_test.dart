import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/hadith/data/hadith_content_settings.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/screens/hadith_language_screen.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/screens/hadith_reader_settings_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

Future<List<HadithContentSettings>> _pump(
  WidgetTester tester, {
  HadithContentSettings settings = const HadithContentSettings(),
}) async {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final changes = <HadithContentSettings>[];
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: HadithReaderSettingsScreen(
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

  testWidgets('shows both sections of the design', (tester) async {
    await _pump(tester);

    expect(find.text('Reader settings'), findsOneWidget);
    expect(find.text('DISPLAY & READING STYLE'), findsOneWidget);
    expect(find.text('TYPOGRAPHY & SCRIPT STYLING'), findsOneWidget);
    // Two switches (Arabic, translation) and two size sliders.
    expect(find.byType(Switch), findsNWidgets(2));
    expect(find.byType(Slider), findsNWidgets(2));
    // Both sizes start at 100%.
    expect(find.text('100%'), findsNWidgets(2));
  });

  testWidgets('the language row shows the choice and opens its screen', (
    tester,
  ) async {
    await _pump(
      tester,
      settings: const HadithContentSettings(
        translationLanguage: HadithTranslationLanguage.english,
      ),
    );

    expect(find.text('Reading Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('Reading Language'));
    await tester.pumpAndSettle();

    expect(find.byType(HadithLanguageScreen), findsOneWidget);
  });

  testWidgets('a size change is reported', (tester) async {
    final changes = await _pump(tester);

    // Drag the Arabic slider toward its maximum.
    await tester.drag(find.byType(Slider).first, const Offset(400, 0));
    await tester.pump();

    expect(changes, isNotEmpty);
    expect(changes.last.arabicScale, HadithContentSettings.maxScale);
    // The widened range reaches 250%.
    expect(find.text('250%'), findsOneWidget);
  });

  testWidgets('a text that is off cannot be resized or left alone', (
    tester,
  ) async {
    await _pump(
      tester,
      settings: const HadithContentSettings(showTranslation: false),
    );

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    // Arabic is the last text showing, so its switch is locked on.
    expect(switches.first.onChanged, isNull);
    // ...and the translation slider is disabled while it is hidden.
    expect(
      tester.widgetList<Slider>(find.byType(Slider)).last.onChanged,
      isNull,
    );
  });
}
