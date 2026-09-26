import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/app_palette.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';
import 'package:islami_app_noorify/features/home/domain/entities/pillar_card.dart';
import 'package:islami_app_noorify/features/home/presentation/bloc/home_dashboard/home_dashboard_bloc.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_calendar_card.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_shimmer.dart';
import 'package:islami_app_noorify/features/qiblah_compass/domain/qiblah_bearing.dart';
import 'package:islami_app_noorify/features/qiblah_compass/presentation/screens/qiblah_compass_screen.dart';
import 'package:islami_app_noorify/features/qiblah_compass/presentation/widgets/qiblah_compass_dial.dart';
import 'package:islami_app_noorify/features/qiblah_compass/presentation/widgets/qiblah_heading_listener.dart';

/// Fallback bearing (degrees clockwise from true north) shown before the
/// dashboard API's `kiblahAngle` has loaded.
const _fallbackQiblahAngle = 270.0;

/// `kiblahAngle` arrives pre-formatted, e.g. `"Kiblah 277.6° West"` — build
/// the same shape locally for the fallback shown before it has loaded.
String _fallbackQiblahLabel(AppText appText, double angle) {
  final normalized = angle % 360;
  final direction = normalized >= 180
      ? appText.compassDirectionWest
      : appText.compassDirectionEast;
  return '${appText.kiblahLabel} ${angle.round()}° $direction';
}

/// Server `pillarKey` -> the (English) title key [AppText.categoryLabel]
/// already knows how to localize. `nafl_and_more` isn't here: it drives the
/// full-width card below the grid instead of a grid tile.
const _pillarTitleKeyByKey = {
  'fardh_prayer': 'Fardh Prayer',
  'sunnah_witr': 'Sunnah and Witr',
  'quran': 'Quran',
  'zikr': 'Zikr',
  'hadith': 'Hadith',
  'quiz': 'Quiz',
};

const _naflAndMorePillarKey = 'nafl_and_more';

/// Pillars whose server `formattedSubtext` is a duration (e.g. `"1hr 37min"`)
/// but which the home grid shows as `points/maxPoints`.
const _pointsSubtextPillarKeys = {'quran', 'hadith'};

String _formatPoints(num value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

String _pillarSubtext(PillarCard pillar) =>
    _pointsSubtextPillarKeys.contains(pillar.pillarKey)
    ? '${_formatPoints(pillar.points)}/${_formatPoints(pillar.maxPoints)}'
    : pillar.formattedSubtext;

class HomeProgressSection extends StatelessWidget {
  const HomeProgressSection({super.key});

  static const _items = [
    _ProgressItem('Fardh Prayer', '0/7', .72),
    _ProgressItem('Sunnah and Witr', '0/6', .78),
    _ProgressItem('Quran', '0/11', .62),
    _ProgressItem('Nafl Salat', '0/2.5', .70),
    _ProgressItem('Hadith', '0/8', .64),
    _ProgressItem('Quiz', '0/2.5', .76),
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final dashboardState = context.watch<HomeDashboardBloc>().state;
    if (dashboardState.isLoading) {
      return HomeProgressSectionShimmer(gridItemCount: _items.length);
    }

    final pillars = dashboardState.hasData
        ? dashboardState.dashboard!.pillarCards
        : null;

    final gridPillars = pillars
        ?.where((p) => p.pillarKey != _naflAndMorePillarKey)
        .toList();
    PillarCard? naflPillar;
    if (pillars != null) {
      for (final p in pillars) {
        if (p.pillarKey == _naflAndMorePillarKey) {
          naflPillar = p;
          break;
        }
      }
    }

    // The API's `kiblahAngle` arrives pre-formatted (e.g. "Kiblah 277.6°
    // West"), not a bare number, so it's shown as-is and only its numeric
    // bearing is pulled out for the dial.
    final rawKiblah = dashboardState.hasData
        ? dashboardState.dashboard!.userSummary.kiblahAngle
        : null;
    final qiblahAngle = parseQiblahBearing(rawKiblah) ?? _fallbackQiblahAngle;
    final qiblahLabel = (rawKiblah != null && rawKiblah.isNotEmpty)
        ? rawKiblah
        : _fallbackQiblahLabel(appText, qiblahAngle);

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gridPillars?.length ?? _items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 90.h,
            crossAxisSpacing: 11.w,
            mainAxisSpacing: 8.h,
          ),
          itemBuilder: (context, index) => gridPillars != null
              ? _PillarProgressCard(pillar: gridPillars[index])
              : _ProgressCard(item: _items[index]),
        ),
        SizedBox(height: 8.h),
        InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => _openAmolTracking(context, 'Nafl & more'),
          child: HomeCard(
            padding: EdgeInsets.symmetric(vertical: 13.h),
            child: Column(
              children: [
                Text(
                  appText.categoryNaflAndMore,
                  style: homeSerifStyle(context: context, fontSize: 12.sp),
                ),
                SizedBox(height: 6.h),
                _ProgressBar(
                  value: naflPillar == null
                      ? .58
                      : (naflPillar.percentage / 100).clamp(0, 1).toDouble(),
                ),
                SizedBox(height: 7.h),
                Text(
                  naflPillar?.formattedSubtext ?? '0/3',
                  style: homeSansStyle(context: context, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        _CompassCard(qiblahAngle: qiblahAngle, qiblahLabel: qiblahLabel),
        SizedBox(height: 8.h),
        const HomeCalendarCard(),
      ],
    );
  }
}

class _CompassCard extends StatelessWidget {
  const _CompassCard({required this.qiblahAngle, required this.qiblahLabel});

  final double qiblahAngle;
  final String qiblahLabel;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);

    return HomeCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appText.compassTitle,
                  style: homeSerifStyle(context: context, fontSize: 18.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  qiblahLabel,
                  style: homeSansStyle(context: context, fontSize: 13.sp),
                ),
                SizedBox(height: 14.h),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          QiblahCompassScreen(qiblahAngle: qiblahAngle),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    side: BorderSide(
                      color: context.lineColor(AppColor.primary),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 8.h,
                    ),
                    minimumSize: Size(0, 32.h),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      appText.viewFullScreen,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
          QiblahHeadingListener(
            builder: (context, access, heading, accuracy) => QiblahCompassDial(
              qiblahAngle: qiblahAngle,
              heading: access == QiblahAccess.ready ? (heading ?? 0) : 0,
              size: 150.w,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarProgressCard extends StatelessWidget {
  const _PillarProgressCard({required this.pillar});

  final PillarCard pillar;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final titleKey = _pillarTitleKeyByKey[pillar.pillarKey] ?? pillar.title;
    final progress = (pillar.percentage / 100).clamp(0, 1).toDouble();
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => _openAmolTracking(context, titleKey),
      child: HomeCard(
        padding: EdgeInsets.symmetric(vertical: 9.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                appText.categoryLabel(titleKey),
                style: homeSerifStyle(context: context, fontSize: 12.sp),
              ),
            ),
            SizedBox(height: 7.h),
            _ProgressBar(value: progress),
            SizedBox(height: 6.h),
            Text(
              _pillarSubtext(pillar),
              style: homeSansStyle(context: context, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }
}

void _openAmolTracking(BuildContext context, String category) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AmolTrackingScreen(
        selectedSection: AmalSection.tryParse(category),
        initialExpandedCategory: category,
      ),
    ),
  );
}

class _ProgressItem {
  const _ProgressItem(this.title, this.count, this.progress);

  final String title;
  final String count;
  final double progress;
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.item});

  final _ProgressItem item;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => _openAmolTracking(context, item.title),
      child: HomeCard(
        padding: EdgeInsets.symmetric(vertical: 9.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                appText.categoryLabel(item.title),
                style: homeSerifStyle(context: context, fontSize: 12.sp),
              ),
            ),
            SizedBox(height: 7.h),
            _ProgressBar(value: item.progress),
            SizedBox(height: 6.h),
            Text(
              item.count,
              style: homeSansStyle(context: context, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64.w,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: LinearProgressIndicator(
          minHeight: 4.h,
          value: value,
          backgroundColor: context.appPalette.progressTrack,
          valueColor: const AlwaysStoppedAnimation(Color(0xFF88936B)),
        ),
      ),
    );
  }
}
