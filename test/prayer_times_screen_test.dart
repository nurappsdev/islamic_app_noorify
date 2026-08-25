import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/prayer_times_screen.dart';

void main() {
  testWidgets('shows dynamic prayer schedule in the reference layout', (
    tester,
  ) async {
    await _setReferenceViewport(tester);
    await tester.pumpWidget(
      _app(
        PrayerTimesScreen(
          prayerTimeService: const _FakeService(_times),
          now: _asrTime,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Prayer times'), findsOneWidget);
    expect(find.text('Mymensingh, Bangladesh'), findsOneWidget);
    for (final prayer in const [
      'Fajr',
      'Dhuhr',
      'Asr',
      'Maghrib & Iftar',
      'Isha',
    ]) {
      expect(find.text(prayer), findsWidgets);
    }
    for (final time in const [
      '4:23 AM',
      '12:08 PM',
      '4:32 PM',
      '6:35 PM',
      '7:55 PM',
    ]) {
      expect(find.textContaining(time), findsWidgets);
    }
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/backImg2.png',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('active-prayer-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('alarm-control')), findsNWidgets(5));
  });

  testWidgets('keeps the designed screen visible without prayer data', (
    tester,
  ) async {
    await _setReferenceViewport(tester);
    await tester.pumpWidget(
      _app(
        PrayerTimesScreen(
          prayerTimeService: const _FakeService(null),
          now: _asrTime,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Prayer times'), findsOneWidget);
    expect(find.text('--:--'), findsWidgets);
    expect(find.byKey(const ValueKey('active-prayer-row')), findsNothing);
  });

  testWidgets('back button returns to the previous screen', (tester) async {
    await _setReferenceViewport(tester);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PrayerTimesScreen(
                    prayerTimeService: const _FakeService(_times),
                    now: _asrTime,
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
  });
}

Future<void> _setReferenceViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(Widget home) => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (context, child) => MaterialApp(home: home),
);

DateTime _asrTime() => DateTime(2026, 8, 20, 16, 40);

class _FakeService implements PrayerTimeService {
  const _FakeService(this.times);

  final DailyPrayerTimes? times;

  @override
  DailyPrayerTimes? cachedPrayerTimes(DateTime date) => times;

  @override
  Future<DailyPrayerTimes?> loadPrayerTimes(DateTime date) async => times;
}

const _times = DailyPrayerTimes(
  dateKey: '2026-08-20',
  readableDate: '20 Aug 2026',
  hijriDate: '7 Safar 1448 Hijri',
  fajr: PrayerClockTime(hour: 4, minute: 23),
  sunrise: PrayerClockTime(hour: 5, minute: 40),
  dhuhr: PrayerClockTime(hour: 12, minute: 8),
  asr: PrayerClockTime(hour: 16, minute: 32),
  maghrib: PrayerClockTime(hour: 18, minute: 35),
  sunset: PrayerClockTime(hour: 18, minute: 35),
  isha: PrayerClockTime(hour: 19, minute: 55),
);
