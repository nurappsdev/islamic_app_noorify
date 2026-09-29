import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_reading_dashboard.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_reading_progress.dart';

import '../../quran_text.dart';
import 'quran_stat_cards.dart';

const _olive = Color(0xFF5D7858);
const _ink = Color(0xFF222222);
const _muted = Color(0xFF8B9875);

/// The reading dashboard's summary (`GET /quran/reading/dashboard`): today's
/// goal, the week's figures, overall completion and plans, and where to
/// continue. Every value is the API's own.
class QuranReadingSummary extends StatelessWidget {
  const QuranReadingSummary({
    super.key,
    required this.dashboard,
    required this.onContinue,
  });

  final QuranReadingDashboard dashboard;
  final ValueChanged<QuranAyahPosition> onContinue;

  @override
  Widget build(BuildContext context) {
    final t = QuranText.of(context);
    final today = dashboard.today;
    final totals = dashboard.week.totals;
    final completion = dashboard.completion;
    final next = dashboard.continueFrom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuranDashedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Title(t.todaysReading),
              SizedBox(height: 10.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  key: const ValueKey('quran-today-progress'),
                  value: today.percentage.clamp(0, 100) / 100,
                  minHeight: 8,
                  color: _olive,
                  backgroundColor: const Color(0xFFE9F0D2),
                ),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 4.h,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _Value(t.readOfGoal(today.readMinutes, today.goalMinutes)),
                  _Value(t.percent(today.percentage)),
                ],
              ),
              SizedBox(height: 4.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 4.h,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _Muted(
                    today.isGoalMet
                        ? t.dailyGoalMet
                        : t.minutesLeft(today.remainingMinutes),
                  ),
                  _Muted(t.pointsOf(today.points, today.maxPoints)),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // The last 7 days.
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: t.streak,
                value: t.days(totals.currentStreak),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _Stat(
                label: t.averagePerDay,
                value: t.minutes(totals.averageMinutesPerDay),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _Stat(
                label: t.goalDays,
                value: t.ofTotal(
                  totals.daysGoalMet,
                  dashboard.week.days.length,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        QuranDashedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _Title(t.quranCompletion)),
                  _Value(t.percent(completion.percentage)),
                ],
              ),
              SizedBox(height: 10.h),
              _Row(
                t.surah,
                t.ofTotal(completion.surahsCompleted, completion.totalSurahs),
              ),
              _Row(
                t.para,
                t.ofTotal(completion.parasCompleted, completion.totalParas),
              ),
              _Row(t.plansInProgress, t.n(dashboard.plans.inProgress)),
              _Row(t.plansCompleted, t.n(dashboard.plans.completed)),
            ],
          ),
        ),
        if (next != null) ...[
          SizedBox(height: 12.h),
          FilledButton.icon(
            key: const ValueKey('quran-dashboard-continue'),
            onPressed: () => onContinue(next),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9EAA52),
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28.r),
              ),
            ),
            icon: const Icon(Icons.menu_book_rounded),
            label: Text(
              '${t.continueReading} · '
              '${t.surahName(next.surahNumber, next.surahNameEnglish)} '
              '${t.n(next.surahNumber)}:${t.n(next.ayahNumber)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      color: context.inkColor(_ink),
    ),
  );
}

class _Value extends StatelessWidget {
  const _Value(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      color: context.inkColor(_olive),
    ),
  );
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(fontSize: 12.sp, color: context.inkColor(_muted)),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 3.h),
    child: Row(
      children: [
        Expanded(child: _Muted(label)),
        _Value(value),
      ],
    ),
  );
}

/// A small figure with its label, sized by its content.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
    decoration: BoxDecoration(
      color: context.surfaceColor(const Color(0xFFF3F6E7)),
      borderRadius: BorderRadius.circular(14.r),
    ),
    child: Column(
      children: [
        FittedBox(fit: BoxFit.scaleDown, child: _Value(value)),
        SizedBox(height: 4.h),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.sp, color: context.inkColor(_muted)),
        ),
      ],
    ),
  );
}
