import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_time_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/prayer_time_card.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

// Dhuhr sits at 11:48, so the Zawal (নিষিদ্ধ) window runs 11:44 – 11:50.
DateTime _duringZawal() => DateTime(2026, 9, 28, 11, 46);
DateTime _afterZawal() => DateTime(2026, 9, 28, 12);

const _maghrib = PrayerClockTime(hour: 17, minute: 49);

Future<void> _pumpCard(WidgetTester tester, DateTime Function() now) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => LanguageBloc()..add(UpdateLanguage(AppLanguage.bangla)),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: PrayerTimeCard(
              prayerTimeService: const _FakeService(),
              now: now,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Color _badgeColor(WidgetTester tester, String key) {
  final box = tester.widget<Container>(find.byKey(ValueKey(key)));
  return (box.decoration! as BoxDecoration).color!;
}

void main() {
  testWidgets('badge turns light red inside a prohibited prayer window', (
    tester,
  ) async {
    await _pumpCard(tester, _duringZawal);

    expect(find.byKey(const ValueKey('current-prayer-badge')), findsNothing);
    expect(
      _badgeColor(tester, 'current-prayer-badge-prohibited'),
      AppColor.lightDangerTint,
    );

    await tester.pumpWidget(const SizedBox()); // cancels the card's timers
  });

  testWidgets('badge keeps its usual colour outside the windows', (
    tester,
  ) async {
    await _pumpCard(tester, _afterZawal);

    expect(
      find.byKey(const ValueKey('current-prayer-badge-prohibited')),
      findsNothing,
    );
    expect(
      _badgeColor(tester, 'current-prayer-badge'),
      const Color(0xFFE4EDB6),
    );

    await tester.pumpWidget(const SizedBox());
  });
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
