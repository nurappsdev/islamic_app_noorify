import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_time_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';
import 'package:tuhfatul_muslim/features/home/presentation/screens/prayer_times_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

class _Service implements PrayerTimeService {
  const _Service();

  static const times = DailyPrayerTimes(
    dateKey: '2026-09-28',
    // The API's own English text: it must not be what the screen shows.
    readableDate: '28 Sep 2026',
    hijriDate: '17 Rabi al-Thani 1448 Hijri',
    fajr: PrayerClockTime(hour: 4, minute: 23),
    sunrise: PrayerClockTime(hour: 5, minute: 40),
    dhuhr: PrayerClockTime(hour: 11, minute: 48),
    asr: PrayerClockTime(hour: 15, minute: 10),
    maghrib: PrayerClockTime(hour: 17, minute: 56),
    sunset: PrayerClockTime(hour: 17, minute: 56),
    isha: PrayerClockTime(hour: 19, minute: 5),
  );

  @override
  DailyPrayerTimes? cachedPrayerTimes(DateTime date) => times;

  @override
  Future<DailyPrayerTimes?> loadPrayerTimes(DateTime date) async => times;
}

DateTime _now() => DateTime(2026, 9, 28, 17, 56);

/// Every piece of text the screen is showing, tooltips included.
List<String> _visibleText(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    if (text.data != null) text.data!,
  for (final button in tester.widgetList<IconButton>(find.byType(IconButton)))
    if (button.tooltip != null) button.tooltip!,
];

Future<void> _pump(WidgetTester tester, AppLanguage language) async {
  await tester.runAsync(AppText.load);
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bloc = LanguageBloc(initialLanguage: language, persist: (_) async {});
  addTearDown(bloc.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: PrayerTimesScreen(
            prayerTimeService: const _Service(),
            now: _now,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('Bangla: dates, times, digits and AM/PM are all Bangla', (
    tester,
  ) async {
    await _pump(tester, AppLanguage.bangla);
    final texts = _visibleText(tester);

    // The exact values the requirement names, in the exact style.
    expect(texts, contains('১৭ রবিউস সানি ১৪৪৮ হিজরি')); // after Maghrib
    expect(texts, contains('১৩ আশ্বিন ১৪৩৩'));
    expect(texts, contains('২৮ সেপ্টেম্বর ২০২৬'));
    expect(texts, contains('৫:৫৬ অপরাহ্ণ')); // the current time
    // Prayer windows and edge times.
    expect(texts.any((t) => t.contains('৪:২৩ পূর্বাহ্ণ')), isTrue);
    expect(texts.any((t) => t.contains('অপরাহ্ণ')), isTrue);

    for (final text in texts) {
      expect(text, isNot(matches(RegExp('[0-9]'))), reason: 'digit in "$text"');
      expect(text, isNot(matches(RegExp(r'\b(AM|PM)\b'))), reason: text);
    }
  });

  testWidgets('Bangla: no Latin word is left on the screen', (tester) async {
    await _pump(tester, AppLanguage.bangla);
    final latin = [
      for (final text in _visibleText(tester))
        if (RegExp('[A-Za-z]{2,}').hasMatch(text)) text,
    ];
    expect(latin, isEmpty, reason: 'English text in Bangla mode: $latin');
  });

  testWidgets('English: unchanged, with English digits and AM/PM', (
    tester,
  ) async {
    await _pump(tester, AppLanguage.english);
    final texts = _visibleText(tester);

    expect(texts, contains("17 Rabi' al-thani 1448 Hijri"));
    expect(texts, contains('13 Ashwin, 1433'));
    expect(texts, contains('28 Sep 2026'));
    expect(texts, contains('5:56 PM'));
    expect(
      texts.any((t) => RegExp('[০-৯]|অপরাহ্ণ|পূর্বাহ্ণ').hasMatch(t)),
      isFalse,
      reason: 'Bangla digits or AM/PM in English mode',
    );
  });
}
