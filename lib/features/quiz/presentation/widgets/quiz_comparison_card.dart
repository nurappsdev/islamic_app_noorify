import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_formatters.dart';

const _aheadColor = Color(0xFF20C664);
const _behindColor = Color(0xFFC90009);

/// The users of a quiz comparison, ranked and marked as the server sent them,
/// with the server's difference between them.
class QuizComparisonCard extends StatelessWidget {
  const QuizComparisonCard({super.key, required this.comparison});

  final QuizComparison comparison;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final difference = comparison.difference;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFDFE9B9)),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.w,
            children: [
              Text(
                appText.quizComparisonTitle,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
              ),
              Text(
                context.localizedDigits(
                  '${comparison.from} – ${comparison.to}',
                ),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: context.inkColor(Color(0xFF56614F)),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          for (final user in comparison.users) ...[
            _ComparedUserRow(user: user),
            SizedBox(height: 8.h),
          ],
          if (comparison.otherUser == null)
            Text(appText.noCompetitorYet, style: TextStyle(fontSize: 12.sp)),
          if (difference != null) _DifferenceRow(difference: difference),
        ],
      ),
    );
  }
}

class _ComparedUserRow extends StatelessWidget {
  const _ComparedUserRow({required this.user});

  final QuizComparedUser user;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final totals = user.dashboard.totals;
    final stats =
        '${appText.attemptsLabel} ${totals.attempts} · '
        '${appText.accuracy} '
        '${formatOptional(totals.accuracyPercentage, formatPercent)} · '
        '${formatPoints(totals.totalMinutes)} ${appText.minutesLabel}';
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.surfaceColor(
          user.isCurrentUser ? const Color(0xFFF2F6E7) : Colors.transparent,
        ),
        border: Border.all(color: context.lineColor(Color(0xFFF2F6E7))),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.localizedDigits('#${user.rank}'),
                style: TextStyle(color: AppColor.primary, fontSize: 14.sp),
              ),
              SizedBox(width: 8.w),
              _Avatar(name: user.name, url: user.avatarUrl, size: 34.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                    if (user.isCurrentUser) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          appText.youLabel,
                          style: TextStyle(color: Colors.white, fontSize: 9.sp),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                context.localizedDigits(
                  '${formatPoints(user.totalPoints)} ${appText.pointsWord}',
                ),
                style: TextStyle(color: AppColor.primary, fontSize: 12.sp),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            context.localizedDigits(stats),
            style: TextStyle(
              fontSize: 10.sp,
              color: context.inkColor(Color(0xFF56614F)),
            ),
          ),
          if (user.dashboard.days.length > 1) ...[
            SizedBox(height: 6.h),
            _MiniActivity(days: user.dashboard.days),
          ],
        ],
      ),
    );
  }
}

/// The user's points day by day, as small bars.
class _MiniActivity extends StatelessWidget {
  const _MiniActivity({required this.days});

  final List<QuizDashboardDayMetric> days;

  @override
  Widget build(BuildContext context) {
    final max = days.fold<num>(
      0,
      (m, d) => d.totalPoints > m ? d.totalPoints : m,
    );
    return SizedBox(
      height: 18.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final day in days)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: .5.w),
                child: FractionallySizedBox(
                  heightFactor: max == 0
                      ? .08
                      : (day.totalPoints / max).clamp(.08, 1).toDouble(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.surfaceColor(
                        day.attempts > 0
                            ? const Color(0xFFA1AD59)
                            : const Color(0xFFE2E2E2),
                      ),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DifferenceRow extends StatelessWidget {
  const _DifferenceRow({required this.difference});

  final QuizComparisonDifference difference;

  static String _signed(num value, String Function(num) format) =>
      '${value > 0 ? '+' : ''}${format(value)}';

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final color = difference.isAhead ? _aheadColor : _behindColor;
    final parts = [
      '${_signed(difference.totalPoints, formatPoints)} ${appText.pointsWord}',
      '${_signed(difference.attempts, formatPoints)} ${appText.attemptsLabel}',
      '${_signed(difference.totalMinutes, formatPoints)} '
          '${appText.minutesLabel}',
      '${_signed(difference.correctPercentage, formatPercent)} '
          '${appText.correctPercentageLabel}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              difference.isAhead
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              size: 18.sp,
              color: context.inkColor(color),
            ),
            SizedBox(width: 6.w),
            Text(
              difference.isAhead ? appText.aheadLabel : appText.behindLabel,
              style: TextStyle(fontSize: 12.sp, color: context.inkColor(color)),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          context.localizedDigits(parts.join(' · ')),
          style: TextStyle(
            fontSize: 10.sp,
            color: context.inkColor(Color(0xFF56614F)),
          ),
        ),
      ],
    );
  }
}

/// [url]'s image, or [name]'s initials when there is none or it fails.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.url, required this.size});

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.substring(0, 1).toUpperCase())
        .take(2)
        .join();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.surfaceColor(const Color(0xFFB9C36E)),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(color: Colors.white, fontSize: size * .38),
      ),
    );
    final uri = url == null ? null : Uri.tryParse(url!);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        uri.toString(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
