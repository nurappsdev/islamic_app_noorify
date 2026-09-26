import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_dashboard_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/amal_tracker_card_content.dart';

const _footerGreen = Color(0xFF9DAA62);

/// Content layer for the Hadith-reading card. Draws no background of its own -
/// place it inside [HomeGradientShape]. Shares its header and title/counter
/// block with [AmalTrackerCardContent].
class HadithReadingCardContent extends StatelessWidget {
  const HadithReadingCardContent({
    super.key,
    this.percentage = 0,
    this.counter = '0/7',
    this.readingTimeLabel = '',
    this.onOpenDashboard,
  });

  /// 0-100.
  final num percentage;

  /// Points earned / max points, e.g. `0/7`.
  final String counter;

  /// Total reading time, e.g. `2 Hr 7 Min`. The footer is hidden when empty.
  final String readingTimeLabel;
  final VoidCallback? onOpenDashboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 28.h),
      child: Column(
        children: [
          ProgressHeaderWidget(
            percentage: percentage,
            onTap:
                onOpenDashboard ??
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HadithDashboardScreen(),
                  ),
                ),
          ),
          SizedBox(height: 26.h),
          PrayerSummaryWidget(title: 'Hadith Reading', counter: counter),
          const Spacer(),
          Image.asset('assets/hadithimg.png', height: 118.h),
          const Spacer(),
          if (readingTimeLabel.isNotEmpty)
            Text(
              'Total Hadith Reading Time $readingTimeLabel',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, color: _footerGreen),
            ),
        ],
      ),
    );
  }
}
