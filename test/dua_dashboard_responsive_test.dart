import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_reading_dashboard_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_analytics_dashboard_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// A full answer, so every part of the page has something to lay out.
/// The names and titles are deliberately long: a layout that survives
/// these survives the real ones.
final _sample = <String, dynamic>{
  'timeframe': 'daily',
  'date': '2026-11-21',
  'overview': {
    'totalDuasRecited': 148,
    'dailyTargetText': '35/40',
    'totalReadingTimeFormatted': '744h 45m',
    'myPositionPercentage': 68,
    'competitorPercentage': 32,
    'comparison': {
      'me': {
        'name': 'Muhammad Nizamuddin Al-Hasani',
        'readingTimeFormatted': '1h 14m',
        'pointsText': 'Point : 6/10',
      },
      'rival': {
        'name': 'Labib Al Mahmud Chowdhury',
        'readingTimeFormatted': '1h 19m',
        'pointsText': 'Point : 7/10',
      },
    },
  },
  'today': {'duasReadCount': 35, 'readMinutes': 23, 'isGoalMet': true},
  'weeklyActivity': {
    'days': [
      for (final day in ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'])
        {
          'dayOfWeek': day,
          'date': '2026-11-15',
          'readMinutes': 45,
          'duasCount': 8,
          'my': {
            'name': 'Muhammad Nizamuddin Al-Hasani',
            'readingTimeFormatted': '45 min',
            'pointsText': 'Point : 4/10',
          },
          'rival': {
            'name': 'Labib Al Mahmud Chowdhury',
            'readingTimeFormatted': '38 min',
            'pointsText': 'Point : 3/10',
          },
        },
    ],
  },
  'monthlyActivity': {
    'periods': [
      for (final label in ['1-6', '7-13', '14-20', '21-27', '28-31'])
        {
          'label': label,
          'my': {
            'name': 'Muhammad Nizamuddin Al-Hasani',
            'readingTimeFormatted': '1h 16m',
            'pointsText': 'Point : 6/10',
          },
          'rival': {
            'name': 'Labib Al Mahmud Chowdhury',
            'readingTimeFormatted': '42 min',
            'pointsText': 'Point : 4/10',
          },
        },
    ],
  },
  'recentRecitations': [
    {
      'duaId': 'a',
      'title': 'Protection & Ruqyah Duas For The Morning',
      'category': 'Falaq, Nas & Ayat al-Kursi Protection Duas',
      'readCount': 10,
      'timeAgoText': '17 Aug At 5:35 AM',
    },
  ],
};

class _Repo extends Fake implements DuaRepository {
  @override
  Future<DuaReadingDashboard> getReadingDashboard({
    required String timeframe,
    String? date,
  }) async =>
      DuaReadingDashboard.fromJson({..._sample, 'timeframe': timeframe});
}

/// The widths the page has to survive: a small phone, the design size, a
/// large phone, and the 600-wide column `WebMobileCanvas` caps the browser
/// at.
const _widths = <double>[320, 360, 375, 430, 600];

void main() {
  /// Lays the dashboard out at [width].
  ///
  /// [webUnits] mirrors `main_app.dart`'s `enableScaleWH: () => !kIsWeb`:
  /// on the browser ScreenUtil stops scaling, so `.w`/`.h`/`.sp` become raw
  /// design numbers and a narrow window no longer shrinks the content.
  Future<void> pumpAt(
    WidgetTester tester,
    double width, {
    required bool webUnits,
    DuaDashboardTimeframe timeframe = DuaDashboardTimeframe.daily,
  }) async {
    tester.view.physicalSize = Size(width * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        enableScaleWH: () => !webUnits,
        enableScaleText: () => !webUnits,
        builder: (context, child) => BlocProvider(
          create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
          child: MaterialApp(
            home: DuaAnalyticsDashboardScreen(repository: _Repo()),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    if (timeframe != DuaDashboardTimeframe.daily) {
      await tester.tap(find.byType(PopupMenuButton<DuaDashboardTimeframe>));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .text(
              timeframe == DuaDashboardTimeframe.weekly ? 'Weekly' : 'Monthly',
            )
            .last,
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }
  }

  /// The overflow a RenderFlex reports, if the layout broke.
  String? overflowAt(WidgetTester tester, double width, bool webUnits) {
    final error = tester.takeException();
    if (error == null) return null;
    return 'width=$width webUnits=$webUnits: $error';
  }

  for (final webUnits in [false, true]) {
    final mode = webUnits ? 'web units (no ScreenUtil scaling)' : 'mobile';

    group('the dashboard lays out on $mode', () {
      for (final width in _widths) {
        testWidgets('daily at ${width.toInt()}px', (tester) async {
          await pumpAt(tester, width, webUnits: webUnits);
          expect(overflowAt(tester, width, webUnits), isNull);
        });

        testWidgets('weekly at ${width.toInt()}px', (tester) async {
          await pumpAt(
            tester,
            width,
            webUnits: webUnits,
            timeframe: DuaDashboardTimeframe.weekly,
          );
          expect(overflowAt(tester, width, webUnits), isNull);
        });

        testWidgets('monthly at ${width.toInt()}px', (tester) async {
          await pumpAt(
            tester,
            width,
            webUnits: webUnits,
            timeframe: DuaDashboardTimeframe.monthly,
          );
          expect(overflowAt(tester, width, webUnits), isNull);
        });
      }
    });
  }
}
