import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import '../../data/services/quran_local_store.dart';
import '../quran_text.dart';
import '../widgets/dashboard/quran_dashboard_charts.dart';
import '../widgets/dashboard/quran_dashboard_header.dart';
import '../widgets/dashboard/quran_dashboard_legend.dart';
import '../widgets/dashboard/quran_period_dropdown.dart';
import '../widgets/dashboard/quran_stat_cards.dart';

export '../widgets/dashboard/quran_period_dropdown.dart'
    show QuranDashboardPeriod, QuranHistoryPeriod;

/// Quran module reading dashboard screen.
///
/// Features:
/// - Header with circular back button and Dashboard title.
/// - Filter row with "My Position", "My Nearest Or Competitor" toggle, and
///   the period dropdown filter (Daily / Weekly / Monthly + 12-month picker).
/// - Modular chart component displaying Weekly, Monthly, or Daily views.
/// - Summary cards with dashed borders for total reading time and most read surah.
class QuranDashboardScreen extends StatefulWidget {
  const QuranDashboardScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<QuranDashboardScreen> createState() => _QuranDashboardScreenState();
}

class _QuranDashboardScreenState extends State<QuranDashboardScreen> {
  QuranDashboardPeriod _period = QuranDashboardPeriod.weekly;
  DateTime? _month;
  bool _showCompetitor = true;

  final ScrollController _monthlyScrollController = ScrollController();
  double _monthlyScrollProgress = 0.0;

  // Stat values initialized to the design spec with real store fallback
  // Placeholder figures until reading time is tracked; the most read Surah
  // comes from the reading history when there is one.
  static const _totalReadingTime = Duration(hours: 132, minutes: 32);
  static const _mostReadSurahTime = Duration(hours: 13, minutes: 32);
  ({int number, String name}) _mostReadSurah = (number: 55, name: 'Ar-Rahman');

  @override
  void initState() {
    super.initState();
    _monthlyScrollController.addListener(_onMonthlyScroll);
    _loadStoreData();
  }

  @override
  void dispose() {
    _monthlyScrollController.removeListener(_onMonthlyScroll);
    _monthlyScrollController.dispose();
    super.dispose();
  }

  void _onMonthlyScroll() {
    if (!_monthlyScrollController.hasClients) return;
    final maxScroll = _monthlyScrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      if (_monthlyScrollProgress != 0) {
        setState(() => _monthlyScrollProgress = 0);
      }
      return;
    }
    final progress = (_monthlyScrollController.offset / maxScroll).clamp(
      0.0,
      1.0,
    );
    if ((progress - _monthlyScrollProgress).abs() > 0.005) {
      setState(() => _monthlyScrollProgress = progress);
    }
  }

  Future<void> _loadStoreData() async {
    try {
      final store = await QuranLocalStore.create();
      final history = await store.history();
      if (history.isNotEmpty && mounted) {
        final surahCounts = <int, int>{};
        final names = <int, String>{};
        for (final entry in history) {
          surahCounts[entry.surahNo] = (surahCounts[entry.surahNo] ?? 0) + 1;
          if (entry.surahName.isNotEmpty) {
            names[entry.surahNo] = entry.surahName;
          }
        }
        if (surahCounts.isNotEmpty) {
          final top = surahCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          setState(() {
            _mostReadSurah = (number: top, name: names[top] ?? '');
          });
        }
      }
    } catch (_) {}
  }

  void _selectFilter(QuranDashboardPeriod period, {DateTime? month}) {
    setState(() {
      _period = period;
      _month = month;
    });
  }

  void _setCompetitor(bool value) {
    setState(() => _showCompetitor = value);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final t = QuranText.of(context);

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8.h),

              // 1. Top Header: Back circle button and centered Dashboard title
              QuranDashboardHeader(
                title: appText.dashboard.isNotEmpty
                    ? appText.dashboard
                    : 'Dashboard',
                onBack: widget.onBack,
              ),

              SizedBox(height: 18.h),

              // 2. Legends & Period Filter Dropdown (matching Hadith dashboard)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QuranLegendDot(
                          color: const Color(0xFF5D7858),
                          label: appText.myPosition.isNotEmpty
                              ? appText.myPosition
                              : 'My Position',
                        ),
                        SizedBox(height: 6.h),
                        QuranLegendToggle(
                          color: const Color(0xFF8F9F4A),
                          label: appText.myNearestOrCompetitor.isNotEmpty
                              ? appText.myNearestOrCompetitor
                              : 'My Nearest Or Competitor',
                          value: _showCompetitor,
                          onChanged: _setCompetitor,
                        ),
                      ],
                    ),
                  ),
                  QuranPeriodDropdown(
                    period: _period,
                    month: _month,
                    labelFor: (p) => switch (p) {
                      QuranDashboardPeriod.daily =>
                        appText.daily.isNotEmpty ? appText.daily : 'Daily',
                      QuranDashboardPeriod.weekly =>
                        appText.weekly.isNotEmpty ? appText.weekly : 'Weekly',
                      QuranDashboardPeriod.monthly =>
                        appText.monthly.isNotEmpty
                            ? appText.monthly
                            : 'Monthly',
                    },
                    onChanged: _selectFilter,
                  ),
                ],
              ),

              SizedBox(height: 18.h),

              // 3. Main Chart Canvas
              // Height follows the width, so the chart keeps its shape on
              // every phone size.
              AspectRatio(aspectRatio: 1.4, child: _buildChart(context)),

              SizedBox(height: 24.h),

              // 4. Summary Card 1: Total Quran Reading time
              QuranTotalReadingTimeCard(
                readingTime: t.duration(_totalReadingTime),
                label: t.totalReadingTime,
              ),

              SizedBox(height: 16.h),

              // 5. Summary Card 2: Most Reading Sura
              QuranMostReadingSurahCard(
                surahName: t.surahTitle(
                  t.surahName(_mostReadSurah.number, _mostReadSurah.name),
                ),
                time: t.duration(_mostReadSurahTime),
                label: t.mostReadSurah,
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    switch (_period) {
      case QuranDashboardPeriod.weekly:
        return QuranWeeklyChart(showCompetitor: _showCompetitor);

      case QuranDashboardPeriod.monthly:
        return QuranMonthlyChart(
          controller: _monthlyScrollController,
          scrollProgress: _monthlyScrollProgress,
          showCompetitor: _showCompetitor,
        );

      case QuranDashboardPeriod.daily:
        return QuranDailyChart(showCompetitor: _showCompetitor);
    }
  }
}
