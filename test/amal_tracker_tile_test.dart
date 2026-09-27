import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/home/presentation/utils/amol_track_card_utils.dart';
import 'package:islami_app_noorify/shared/widgets/amal_tracker_tile.dart';

void main() {
  testWidgets('keeps the Amol track hierarchy usable at narrow and wide widths', (
    tester,
  ) async {
    const title =
        'Complete all daily morning and evening Islamic activities and track your progress every day with care';

    for (final width in [280.0, 560.0]) {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, _) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: AmalTrackerTile(
                    title: truncateWords(title, 15),
                    userName: 'Rajib Ahmed',
                    monthLabel: 'Sep 2026',
                    subtitle: 'Point : 0/40',
                    progressLabel: '0 %',
                    progress: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Rajib Ahmed'), findsOneWidget);
      expect(find.text('Sep 2026'), findsOneWidget);
      expect(AmalTrackerTile.radius, lessThan(28.r));
      expect(AmalTrackerTile.verticalPadding, lessThan(12.h));
      expect(tester.takeException(), isNull);
    }
  });
}
