import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:islami_app_noorify/features/home/domain/calendar/date_labels.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/prayer_time_card.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

// Midday on 28 Sep 2026, before Maghrib.
DateTime _noon() => DateTime(2026, 9, 28, 12);

const _maghrib = PrayerClockTime(hour: 17, minute: 49);

Future<void> _pumpCard(
  WidgetTester tester,
  AppLanguage language, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => LanguageBloc()..add(UpdateLanguage(language)),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: PrayerTimeCard(
              prayerTimeService: const _FakeService(),
              now: _noon,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The two date [Text]s along the top of the card.
(Text hijri, Text bengali) _dates(WidgetTester tester, AppLanguage language) {
  final bangla = language == AppLanguage.bangla;
  return (
    tester.widget<Text>(
      find.text(hijriDateLabel(_noon(), bangla: bangla, maghrib: _maghrib)),
    ),
    tester.widget<Text>(find.text(banglaDateLabel(_noon(), english: !bangla))),
  );
}

void _expectSameStyle(Text hijri, Text bengali) {
  expect(hijri.style!.fontSize, bengali.style!.fontSize);
  expect(hijri.style!.fontWeight, bengali.style!.fontWeight);
  expect(hijri.style!.height, bengali.style!.height);
  expect(hijri.style!.fontFamily, bengali.style!.fontFamily);
  expect(hijri.style!.fontStyle, bengali.style!.fontStyle);
}

void main() {
  for (final language in AppLanguage.values) {
    testWidgets('Hijri and Bengali dates share one style in ${language.name}', (
      tester,
    ) async {
      await _pumpCard(tester, language);

      final (hijri, bengali) = _dates(tester, language);
      _expectSameStyle(hijri, bengali);
      // Sized by the text style itself, not scaled by a wrapper of its own.
      // (Tests render with the Ahem font, whose wide glyphs make the pair
      // shrink here; what matters is that they shrink identically.)
      expect(
        find.ancestor(
          of: find.byWidget(hijri),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox()); // cancels the card's timers
    });

    testWidgets('both dates shrink together when they do not fit in '
        '${language.name}', (tester) async {
      await _pumpCard(tester, language, textScale: 1.6);

      final (hijri, bengali) = _dates(tester, language);
      _expectSameStyle(hijri, bengali);
      expect(hijri.style!.fontSize, lessThan(10.sp));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });
  }
}

class _FakeService implements PrayerTimeService {
  const _FakeService();

  static const _times = DailyPrayerTimes(
    dateKey: '2026-09-28',
    readableDate: '28 Sep 2026',
    hijriDate: '17 Rabi al-thani 1448 Hijri',
    fajr: PrayerClockTime(hour: 4, minute: 23),
    sunrise: PrayerClockTime(hour: 5, minute: 40),
    dhuhr: PrayerClockTime(hour: 11, minute: 48),
    asr: PrayerClockTime(hour: 15, minute: 10),
    maghrib: _maghrib,
    sunset: _maghrib,
    isha: PrayerClockTime(hour: 19, minute: 5),
  );

  @override
  DailyPrayerTimes? cachedPrayerTimes(DateTime date) => _times;

  @override
  Future<DailyPrayerTimes?> loadPrayerTimes(DateTime date) async => _times;
}
