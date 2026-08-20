import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:islami_app_noorify/core/bloc/app_preferences/app_preferences_cubit.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/amal_tracker_card.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/prayer_time_card.dart';
import 'package:islami_app_noorify/main.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_cubit.dart';

void main() {
  Widget appUnderTest({String? initialRoute}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LanguageCubit()),
        BlocProvider(create: (_) => AppPreferencesCubit()),
      ],
      child: MyApp(initialRoute: initialRoute),
    );
  }

  testWidgets('shows sign in screen', (WidgetTester tester) async {
    await AppText.load();

    await tester.pumpWidget(appUnderTest(initialRoute: RouteNames.signIn));

    await tester.pump();

    expect(
      find.text(AppText.forLanguage(AppLanguage.english).login),
      findsOneWidget,
    );
  });

  testWidgets('shows home screen content', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return const MaterialApp(home: HomeScreen());
        },
      ),
    );

    await tester.pump();

    expect(find.text('Todays Amol track'), findsOneWidget);
    expect(find.text('Todays highest value'), findsOneWidget);
    expect(find.text('Sehri : 4:09 AM     Iftar : 6:33 PM'), findsOneWidget);
    expect(find.text('Dhuhr Prayer Time'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('auto advances amal tracker carousel every three seconds', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return const MaterialApp(
            home: Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(9),
                  child: AmalTrackerCard(),
                ),
              ),
            ),
          );
        },
      ),
    );

    await tester.pump();

    final secondSlide = find.text('Todays highest value');
    expect(tester.getCenter(secondSlide).dx, greaterThan(375));

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(tester.getCenter(secondSlide).dx, inInclusiveRange(0, 375));
  });

  testWidgets('amal tracker carousel has eight cards', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return const MaterialApp(
            home: Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(9),
                  child: AmalTrackerCard(),
                ),
              ),
            ),
          );
        },
      ),
    );

    await tester.pump();

    for (var i = 0; i < 7; i++) {
      await tester.drag(find.byType(PageView), const Offset(-360, 0));
      await tester.pumpAndSettle();
    }

    expect(find.text('My position in, July'), findsOneWidget);
    expect(find.text('63 %'), findsOneWidget);
  });

  testWidgets('amal tracker progress uses a painted circular ring', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return const MaterialApp(
            home: Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(9),
                  child: AmalTrackerCard(),
                ),
              ),
            ),
          );
        },
      ),
    );

    await tester.pump();

    expect(find.text('86 %'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter.runtimeType.toString() == '_AmalProgressRingPainter',
      ),
      findsWidgets,
    );
  });

  testWidgets('prayer time card paints the prayer arc over the theme image', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return const MaterialApp(
            home: Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(9),
                  child: PrayerTimeCard(
                    prayerTimeService: _FakePrayerTimeService(
                      _testPrayerTimes,
                    ),
                    now: _noon,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/theme2.png',
      ),
      findsOneWidget,
    );
    expect(find.text('24 July 2026'), findsOneWidget);
    expect(find.text('01:37 PM'), findsOneWidget);
    expect(find.text('Dhuhr Prayer Time'), findsOneWidget);
    expect(find.text('Sunrise, Trishal'), findsOneWidget);
    expect(find.text('at 5:23 AM'), findsOneWidget);
    expect(find.text('Sunset, Trishal'), findsOneWidget);
    expect(find.text('at 6:54 PM'), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter.runtimeType.toString() == '_PrayerArcPainter',
      ),
      findsOneWidget,
    );
  });

  testWidgets('prayer time card changes its background at scheduled times', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cases = <(DateTime, String)>[
      (DateTime(2026, 8, 20, 8), 'assets/images/theme1.png'),
      (DateTime(2026, 8, 20, 12), 'assets/images/theme2.png'),
      (DateTime(2026, 8, 20, 17), 'assets/images/theme3.png'),
      (DateTime(2026, 8, 20, 22), 'assets/images/theme4.png'),
    ];

    for (final (now, expectedAsset) in cases) {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) {
            return MaterialApp(
              home: Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: PrayerTimeCard(
                      prayerTimeService: const _FakePrayerTimeService(
                        _testPrayerTimes,
                      ),
                      now: () => now,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == expectedAsset,
        ),
        findsOneWidget,
      );
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('prayer card arrow opens prayer times route', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            routes: {
              RouteNames.prayerTimes: (_) => const Scaffold(
                body: Text('Prayer times destination'),
              ),
            },
            home: Scaffold(
              body: PrayerTimeCard(
                prayerTimeService: const _FakePrayerTimeService(
                  _testPrayerTimes,
                ),
                now: _noon,
              ),
            ),
          );
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pumpAndSettle();

    expect(find.text('Prayer times destination'), findsOneWidget);
  });
}

DateTime _noon() => DateTime(2026, 8, 20, 12);

class _FakePrayerTimeService implements PrayerTimeService {
  const _FakePrayerTimeService(this.times);

  final DailyPrayerTimes times;

  @override
  DailyPrayerTimes? cachedPrayerTimes(DateTime date) => times;

  @override
  Future<DailyPrayerTimes?> loadPrayerTimes(DateTime date) async => times;
}

const _testPrayerTimes = DailyPrayerTimes(
  dateKey: '2026-08-20',
  readableDate: '20 Aug 2026',
  hijriDate: '7 Safar 1448 Hijri',
  fajr: PrayerClockTime(hour: 4, minute: 30),
  sunrise: PrayerClockTime(hour: 5, minute: 40),
  dhuhr: PrayerClockTime(hour: 12, minute: 8),
  asr: PrayerClockTime(hour: 16, minute: 32),
  maghrib: PrayerClockTime(hour: 18, minute: 35),
  sunset: PrayerClockTime(hour: 18, minute: 35),
  isha: PrayerClockTime(hour: 19, minute: 55),
);
