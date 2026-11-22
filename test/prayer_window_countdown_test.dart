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

  /// Dhuhr runs 11:44 to 3:34 here, the window the countdown is built for.
  static const times = DailyPrayerTimes(
    dateKey: '2026-11-22',
    readableDate: '22 Nov 2026',
    hijriDate: '12 Jumada al-Thani 1448 Hijri',
    fajr: PrayerClockTime(hour: 5, minute: 5),
    sunrise: PrayerClockTime(hour: 6, minute: 20),
    dhuhr: PrayerClockTime(hour: 11, minute: 44),
    asr: PrayerClockTime(hour: 15, minute: 34),
    maghrib: PrayerClockTime(hour: 17, minute: 14),
    sunset: PrayerClockTime(hour: 17, minute: 14),
    isha: PrayerClockTime(hour: 18, minute: 30),
  );

  @override
  DailyPrayerTimes? cachedPrayerTimes(DateTime date) => times;

  @override
  Future<DailyPrayerTimes?> loadPrayerTimes(DateTime date) async => times;
}

/// Stands in for a day whose times have not loaded yet.
class _EmptyService implements PrayerTimeService {
  const _EmptyService();

  @override
  DailyPrayerTimes? cachedPrayerTimes(DateTime date) => null;

  @override
  Future<DailyPrayerTimes?> loadPrayerTimes(DateTime date) async => null;
}

List<String> _visibleText(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    if (text.data != null) text.data!,
];

Future<void> _pump(
  WidgetTester tester, {
  required DateTime at,
  AppLanguage language = AppLanguage.english,
  Size size = const Size(375, 812),
  PrayerTimeService service = const _Service(),
}) async {
  await tester.runAsync(AppText.load);
  tester.view.physicalSize = size;
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
          home: PrayerTimesScreen(prayerTimeService: service, now: () => at),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

double _progress(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(
      find.descendant(
        of: find.byKey(const ValueKey('prayer-window-progress')),
        matching: find.byType(FractionallySizedBox),
      ),
    )
    .widthFactor!;

/// The colors of the bar's filled part.
List<Color> _barColors(WidgetTester tester) {
  final fill = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byKey(const ValueKey('prayer-window-progress')),
      matching: find.byType(DecoratedBox),
    ),
  );
  final gradient = (fill.decoration as BoxDecoration).gradient;
  return (gradient as LinearGradient).colors;
}

void main() {
  testWidgets('the running prayer window counts down to its end', (
    tester,
  ) async {
    // 1:30 PM, inside Dhuhr (11:44 – 3:34): 2 hr 4 min left of 3 hr 50 min.
    await _pump(tester, at: DateTime(2026, 11, 22, 13, 30));

    final texts = _visibleText(tester);
    expect(
      texts,
      contains('Ends in 2 hr 4 min'),
      reason: 'the countdown to the end of the active window',
    );
    expect(_progress(tester), closeTo(106 / 230, 0.01));

    // The chip carries the waqt, its range in bare digits, the countdown and
    // the bar — no `Prayer Time` suffix and no part-of-day name. (The list
    // row below still writes the range out in full, as `Noon 11:44 – …`.)
    expect(texts, contains('Dhuhr'));
    expect(texts, contains('11:44 – 3:34'));
    expect(texts, isNot(contains('Dhuhr Prayer Time')));
  });

  testWidgets('the gap before Dhuhr counts down to its start instead', (
    tester,
  ) async {
    // 9:44 AM: no fard prayer is running, Dhuhr opens in two hours.
    await _pump(tester, at: DateTime(2026, 11, 22, 9, 44));

    expect(_visibleText(tester), contains('Starts in 2 hr'));
    expect(_progress(tester), closeTo(204 / 324, 0.01));
  });

  testWidgets('every Nafl window is listed with its times', (tester) async {
    await _pump(tester, at: DateTime(2026, 11, 22, 13, 30));
    final texts = _visibleText(tester);

    expect(texts, contains('Nafl prayer times'));
    expect(texts, contains('Tahajjud'));
    expect(texts, contains('Ishraq'));
    expect(texts, contains('Chast (Duha)'));
    expect(texts, contains('Awabin'));
    // Ishraq: sunrise + 15 min, up to a quarter through the daylight hours.
    expect(texts, contains('Morning 6:35 – 9:03'));
    // Chasht (Duha): from there to the Zawal window before Dhuhr.
    expect(texts, contains('Morning 9:03 – 11:40'));
  });

  testWidgets('Bangla writes the countdown in Bangla digits and words', (
    tester,
  ) async {
    await _pump(
      tester,
      at: DateTime(2026, 11, 22, 13, 30),
      language: AppLanguage.bangla,
    );

    expect(_visibleText(tester), contains('শেষ হতে বাকি ২ ঘণ্টা ৪ মিনিট'));
    for (final text in _visibleText(tester)) {
      expect(text, isNot(matches(RegExp('[0-9]'))), reason: 'digit in "$text"');
      expect(text, isNot(matches(RegExp('[A-Za-z]{2,}'))), reason: text);
    }
  });

  testWidgets('the bar turns light red while prayer is prohibited', (
    tester,
  ) async {
    // 11:42 AM sits in the Zawal window (11:40 – 11:46), four minutes before
    // Dhuhr.
    await _pump(tester, at: DateTime(2026, 11, 22, 11, 42));
    expect(_barColors(tester).first, const Color(0xFFF08A84));

    // 5:05 PM is inside the window before sunset (4:59 – 5:14).
    await _pump(tester, at: DateTime(2026, 11, 22, 17, 5));
    expect(_barColors(tester).first, const Color(0xFFF08A84));

    // 6:25 AM is inside the window after sunrise (6:20 – 6:35).
    await _pump(tester, at: DateTime(2026, 11, 22, 6, 25));
    expect(_barColors(tester).first, const Color(0xFFF08A84));
  });

  testWidgets('the bar stays olive when prayer is not prohibited', (
    tester,
  ) async {
    await _pump(tester, at: DateTime(2026, 11, 22, 13, 30));
    expect(_barColors(tester).first, const Color(0xFF6F7F52));
  });

  // The countdown made the header taller and the Nafl windows made the list
  // longer, so the screen is checked end to end — a layout error anywhere in
  // it fails these.
  for (final size in const [Size(320, 568), Size(375, 812), Size(430, 932)]) {
    for (final language in AppLanguage.values) {
      testWidgets('lays out at $size in $language', (tester) async {
        for (final at in [
          DateTime(2026, 11, 22, 0, 30), // the Tahajjud window
          DateTime(2026, 11, 22, 9, 44), // the gap before Dhuhr
          DateTime(2026, 11, 22, 13, 30), // Dhuhr running
        ]) {
          await _pump(tester, at: at, language: language, size: size);
          // Scrolled to the end, so every Nafl tile is laid out too.
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -400),
          );
          await tester.pump();
        }
      });
    }
  }

  testWidgets('shows the whole screen before the times have loaded', (
    tester,
  ) async {
    await _pump(
      tester,
      at: DateTime(2026, 11, 22, 13, 30),
      service: const _EmptyService(),
    );
    final texts = _visibleText(tester);

    // No window is known, so there is nothing to count down and no bar.
    expect(find.byKey(const ValueKey('prayer-window-progress')), findsNothing);
    expect(texts, contains('Nafl prayer times'));
    expect(texts.where((t) => t.contains('--:--')), isNotEmpty);
  });
}
