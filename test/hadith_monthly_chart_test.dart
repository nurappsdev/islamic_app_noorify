import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_dashboard_charts.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Guards the geometry the Hadith dashboard's monthly filter relies on: it
/// reuses the Dua dashboard's [DuaMonthlyBarChart], but inside its own 250.h
/// chart box and with six 5-day rows rather than Dua's four week rows, and it
/// feeds the tooltip its own wording. A value as long as `Time : 90 min`
/// overflowed the card, which is why the rows pass the bare `90 min`.
void main() {
  testWidgets('six monthly rows fit the hadith chart box without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bloc = LanguageBloc(
      initialLanguage: AppLanguage.english,
      persist: (_) async {},
    );
    addTearDown(bloc.close);

    // The six 5-day groups a 30-day hadith window produces.
    const bars = [
      DuaChartBar(label: '1-5', mine: 12, competitor: 20),
      DuaChartBar(label: '6-10', mine: 45, competitor: 30),
      DuaChartBar(label: '11-15', mine: 0, competitor: 5),
      DuaChartBar(label: '16-20', mine: 90, competitor: 60),
      DuaChartBar(label: '21-25', mine: 33, competitor: 0),
      DuaChartBar(label: '26-30', mine: 7, competitor: 70),
    ];

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                // The same box hadith_dashboard_screen.dart wraps its chart in.
                child: SizedBox(
                  height: 250.h,
                  child: DuaMonthlyBarChart(
                    bars: bars,
                    tooltipBuilder: (i, bar) => DuaChartTooltip(
                      title: bar.title,
                      lines: [
                        DuaTooltipLine.metric(
                          color: DuaChartColors.mine,
                          text: 'My Position',
                          value: '${bar.mine} min',
                        ),
                        const DuaTooltipLine.note('Point : 4'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    // Every group drew a row, newest group on top.
    expect(find.text('26-30'), findsOneWidget);
    expect(find.text('1-5'), findsOneWidget);
    final top = tester.getCenter(find.text('26-30')).dy;
    final bottom = tester.getCenter(find.text('1-5')).dy;
    expect(top, lessThan(bottom));

    // Tapping a row opens its card.
    await tester.tap(find.text('16-20'));
    await tester.pumpAndSettle();
    expect(find.text('90 min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
