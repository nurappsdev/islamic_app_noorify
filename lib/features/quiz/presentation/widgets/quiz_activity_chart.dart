import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_formatters.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_segmented_tabs.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_status_view.dart';

/// Which per-day figure the chart shows.
enum _Metric { score, accuracy, points, minutes }

/// The range's days as bars of one per-day figure the server computed.
class QuizActivityChart extends StatefulWidget {
  const QuizActivityChart({super.key, required this.days});

  final List<QuizDashboardDayMetric> days;

  @override
  State<QuizActivityChart> createState() => _QuizActivityChartState();
}

class _QuizActivityChartState extends State<QuizActivityChart> {
  _Metric _metric = _Metric.score;

  /// The day's figure, or `null` where the server has none (accuracy for
  /// legacy attempts).
  num? _value(QuizDashboardDayMetric day) => switch (_metric) {
    _Metric.score => day.averageScorePercentage,
    _Metric.accuracy => day.accuracyPercentage,
    _Metric.points => day.totalPoints,
    _Metric.minutes => day.totalMinutes,
  };

  String _format(num value) => switch (_metric) {
    _Metric.score || _Metric.accuracy => formatPercent(value),
    _Metric.points || _Metric.minutes => formatPoints(value),
  };

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final days = widget.days;
    final hasActivity = days.any((day) => day.attempts > 0);
    final isPercent = _metric == _Metric.score || _metric == _Metric.accuracy;
    final max = isPercent
        ? 100
        : days.fold<num>(0, (m, d) => (_value(d) ?? 0) > m ? _value(d)! : m);
    // Few enough bars to label each with its day of the month.
    final labelEach = days.length <= 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(appText.dailyActivity, style: TextStyle(fontSize: 18.sp)),
        SizedBox(height: 8.h),
        QuizSegmentedTabs(
          fontSize: 11.sp,
          selectedIndex: _metric.index,
          onChanged: (i) => setState(() => _metric = _Metric.values[i]),
          labels: [
            appText.scoreLabel,
            appText.accuracy,
            appText.pointsWord,
            appText.minutesLabel,
          ],
        ),
        SizedBox(height: 10.h),
        if (!hasActivity)
          QuizStatusView(message: appText.noQuizActivity)
        else
          SizedBox(
            height: 150.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in days)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1.w),
                      child: _Bar(
                        fraction: max == 0
                            ? 0
                            : ((_value(day) ?? 0) / max).clamp(0, 1).toDouble(),
                        valueLabel: labelEach && _value(day) != null
                            ? context.localizedDigits(_format(_value(day)!))
                            : null,
                        dayLabel: labelEach
                            ? context.localizedDigits(
                                '${int.tryParse(day.date.split('-').last) ?? ''}',
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.valueLabel,
    required this.dayLabel,
  });

  final double fraction;
  final String? valueLabel;
  final String? dayLabel;

  @override
  Widget build(BuildContext context) {
    final muted = context.inkColor(Color(0xFF56614F));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (valueLabel != null)
          Text(
            valueLabel!,
            maxLines: 1,
            style: TextStyle(fontSize: 8.sp, color: muted),
          ),
        SizedBox(height: 2.h),
        Flexible(
          child: FractionallySizedBox(
            heightFactor: fraction == 0 ? .02 : fraction,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.surfaceColor(const Color(0xFF5D896D)),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: const SizedBox(width: double.infinity),
            ),
          ),
        ),
        if (dayLabel != null) ...[
          SizedBox(height: 3.h),
          Text(
            dayLabel!,
            style: TextStyle(fontSize: 9.sp, color: muted),
          ),
        ],
      ],
    );
  }
}
