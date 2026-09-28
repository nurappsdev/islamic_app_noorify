import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_calendar_card.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _arabicDigit = RegExp('[٠-٩]');
final _banglaDigit = RegExp('[০-৯]');
final _englishWeekday = RegExp(
  'Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday',
);

Future<void> _pumpCard(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.english,
}) async {
  SharedPreferences.setMockInitialValues({});
  // The tab labels come from the JSON language files, loaded at app start.
  await tester.runAsync(AppText.load);
  tester.view.physicalSize = const Size(375 * 3, 1400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => LanguageBloc()..add(UpdateLanguage(language)),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HomeCalendarCard()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The Arabic <-> Bangla indicator, which lives inside the Arabic tab.
final _indicator = find.byKey(const ValueKey('arabic-format-switch'));

Future<void> _openArabic(WidgetTester tester) async {
  await tester.tap(find.text('Arabic'));
  await tester.pump();
}

/// Tapping the (already selected) Arabic tab is the toggle.
Future<void> _tapArabicTab(WidgetTester tester) async {
  await tester.tap(find.text('Arabic'));
  await tester.pump();
}

bool _showsArabic() =>
    find.textContaining(_arabicDigit).evaluate().isNotEmpty &&
    find.textContaining(_banglaDigit).evaluate().isEmpty;

bool _showsBangla() =>
    find.textContaining(_banglaDigit).evaluate().isNotEmpty &&
    find.textContaining(_arabicDigit).evaluate().isEmpty;

void main() {
  testWidgets('English tab still shows the English date line', (tester) async {
    await _pumpCard(tester);

    // Sanity for the negative checks below: the English tab has this line.
    expect(find.textContaining(_englishWeekday), findsOneWidget);
    expect(_indicator, findsNothing);
  });

  testWidgets('selecting the Arabic tab shows full Arabic by default', (
    tester,
  ) async {
    await _pumpCard(tester);
    await _openArabic(tester);

    expect(_showsArabic(), isTrue);
    expect(_indicator, findsOneWidget);
  });

  testWidgets('the toggle sits inside the Arabic tab, not in the content', (
    tester,
  ) async {
    await _pumpCard(tester);
    await _openArabic(tester);

    // Same row as the tab labels, and inside the Arabic tab's own bounds.
    final label = tester.getRect(find.text('Arabic'));
    final indicator = tester.getRect(_indicator);
    final tab = tester.getRect(
      find
          .ancestor(of: find.text('Arabic'), matching: find.byType(InkWell))
          .first,
    );
    expect(tab.contains(indicator.center), isTrue);
    expect((indicator.center.dy - label.center.dy).abs(), lessThan(8));

    // Nothing else was added to the content: no Bangla button, no "view in"
    // button, no Material switch, no English date line.
    expect(find.text('বাংলা'), findsNothing);
    expect(find.textContaining('View in'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.textContaining(_englishWeekday), findsNothing);
  });

  testWidgets('tapping the Arabic tab flips Arabic -> Bangla -> Arabic', (
    tester,
  ) async {
    await _pumpCard(tester);
    await _openArabic(tester);
    expect(_showsArabic(), isTrue);

    await _tapArabicTab(tester);
    expect(_showsBangla(), isTrue);
    expect(_indicator, findsOneWidget);
    expect(find.text('বাংলা'), findsNothing);
    expect(find.textContaining(_englishWeekday), findsNothing);

    await _tapArabicTab(tester);
    expect(_showsArabic(), isTrue);
  });

  testWidgets('arriving at the Arabic tab from another tab does not flip it', (
    tester,
  ) async {
    await _pumpCard(tester);
    await _openArabic(tester);
    expect(_showsArabic(), isTrue);

    await tester.tap(find.text('English'));
    await tester.pump();
    await _openArabic(tester);
    expect(_showsArabic(), isTrue); // first tap on the tab only selects it
  });

  testWidgets('the date is the same in both forms', (tester) async {
    await _pumpCard(tester);
    await _openArabic(tester);

    // The day-of-month cells, read as numbers in either script.
    List<int> days(RegExp digits, String zero) => [
      for (final text in tester.widgetList<Text>(find.byType(Text)))
        if (RegExp('^${digits.pattern}+\$').hasMatch(text.data ?? ''))
          int.parse(
            text.data!
                .split('')
                .map((c) => c.codeUnitAt(0) - zero.codeUnitAt(0))
                .join(),
          ),
    ];

    final arabic = days(_arabicDigit, '٠');
    await _tapArabicTab(tester);
    final bangla = days(_banglaDigit, '০');

    expect(arabic, isNotEmpty);
    expect(bangla, arabic);
  });

  testWidgets('works the same in Bangla mode', (tester) async {
    await _pumpCard(tester, language: AppLanguage.bangla);
    final arabicTab = find.text('আরবি').first;
    await tester.tap(arabicTab);
    await tester.pump();
    expect(_showsArabic(), isTrue);

    await tester.tap(arabicTab);
    await tester.pump();
    expect(_showsBangla(), isTrue);
  });

  testWidgets('Bangla and English tabs are unchanged', (tester) async {
    await _pumpCard(tester);
    await tester.tap(find.text('Bangla'));
    await tester.pump();
    expect(_indicator, findsNothing);
    expect(find.textContaining('হিজরি:'), findsOneWidget);
    // Tapping the selected Bangla tab again does nothing special.
    await tester.tap(find.text('Bangla'));
    await tester.pump();
    expect(_indicator, findsNothing);
    expect(find.textContaining('হিজরি:'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pump();
    expect(_indicator, findsNothing);
    expect(find.textContaining(_englishWeekday), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pump();
    expect(find.textContaining(_englishWeekday), findsOneWidget);
  });
}
