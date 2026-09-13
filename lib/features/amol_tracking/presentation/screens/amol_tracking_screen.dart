import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/amol_tracking/data/datasources/amol_tracking_remote_data_source.dart';
import 'package:islami_app_noorify/features/amol_tracking/data/repositories/amol_tracking_repository_impl.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_item.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_pillar.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/usecases/delete_amol_item.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/usecases/get_amol_daily.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/usecases/log_amol_item.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/bloc/amol_daily/amol_daily_bloc.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_dashboard_screen.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/widgets/amol_shared_widgets.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

/// `pillarKey`s whose items may only be logged once their prayer window has
/// started — Fard, Sunnah, Witr and Nafl salat. Quran/Hadith/Quiz/Nafl & more
/// have no time gate.
const _timeGatedPillarKeys = {'fardh_prayer', 'sunnah_witr', 'nafl_salat'};

/// English title -> the pillar key `GET /amol/tracker/daily` uses, so a
/// caller (e.g. [HomeProgressSection]'s tiles) can still ask for a category
/// to open expanded by its familiar display name.
const _pillarKeyByTitle = {
  'Fardh Prayer': 'fardh_prayer',
  'Sunnah and Witr': 'sunnah_witr',
  'Nafl Salat': 'nafl_salat',
  'Quran': 'quran',
  'Hadith': 'hadith',
  'Quiz': 'quiz',
  'Nafl & more': 'nafl_and_more',
};

/// Server `pillarKey` -> the (English) title key [AppText.categoryLabel]
/// already knows how to localize.
const _pillarTitleKeyByKey = {
  'fardh_prayer': 'Fardh Prayer',
  'sunnah_witr': 'Sunnah and Witr',
  'nafl_salat': 'Nafl Salat',
  'quran': 'Quran',
  'hadith': 'Hadith',
  'quiz': 'Quiz',
  'nafl_and_more': 'Nafl & more',
};

class AmolTrackingScreen extends StatefulWidget {
  const AmolTrackingScreen({
    super.key,
    this.pointLabel = 'Point : 30/40',
    this.progressLabel = '86 %',
    this.progress = .86,
    this.initialExpandedCategory = 'Fardh Prayer',
    this.now,
  });

  final String pointLabel;
  final String progressLabel;
  final double progress;
  final String? initialExpandedCategory;
  final DateTime Function()? now;

  @override
  State<AmolTrackingScreen> createState() => _AmolTrackingScreenState();
}

class _AmolTrackingScreenState extends State<AmolTrackingScreen> {
  late final DateTime _today = (widget.now ?? DateTime.now)();
  late String? _expandedPillarKey =
      _pillarKeyByTitle[widget.initialExpandedCategory] ??
      widget.initialExpandedCategory;
  late final AmolDailyBloc _bloc =
      AmolDailyBloc(
          GetAmolDaily(
            AmolTrackingRepositoryImpl(AmolTrackingRemoteDataSourceImpl()),
          ),
          LogAmolItem(
            AmolTrackingRepositoryImpl(AmolTrackingRemoteDataSourceImpl()),
          ),
          DeleteAmolItem(
            AmolTrackingRepositoryImpl(AmolTrackingRemoteDataSourceImpl()),
          ),
        )
        ..add(LoadAmolDaily(_isoDate(_today)));

  DailyPrayerTimes? _prayerTimes;
  late final StreamSubscription<String> _logFailureSub;

  static String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatPercentage(num percentage) {
    final isWhole = percentage % 1 == 0;
    return '${percentage.toStringAsFixed(isWhole ? 0 : 1)} %';
  }

  @override
  void initState() {
    super.initState();
    _logFailureSub = _bloc.logFailures.listen((message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    });
    unawaited(_loadPrayerTimes());
  }

  Future<void> _loadPrayerTimes() async {
    try {
      final service = await AladhanPrayerTimeService.create();
      final cached = service.cachedPrayerTimes(_today);
      if (mounted && cached != null) setState(() => _prayerTimes = cached);

      final fresh = await service.loadPrayerTimes(_today);
      if (mounted && fresh != null) setState(() => _prayerTimes = fresh);
    } catch (_) {
      // Times stay null; the gate below allows tracking when they're
      // unavailable rather than blocking the user on our own load failure.
    }
  }

  /// The earliest clock time [pillarKey]/[itemKey] may be logged at, or
  /// `null` when that item isn't time-gated. Sunnah prayers share their
  /// Fard's start; Witr and Tahajjud open at Isha; Ishraq/Chasht open at
  /// sunrise; Awabin opens at Maghrib.
  PrayerClockTime? _gateStart(
    String pillarKey,
    String itemKey,
    DailyPrayerTimes times,
  ) {
    if (!_timeGatedPillarKeys.contains(pillarKey)) return null;
    switch (itemKey) {
      case 'fajr':
      case 'fajr_sunnah':
        return times.fajr;
      case 'dhuhr':
      case 'dhuhr_sunnah':
        return times.dhuhr;
      case 'asr':
      case 'asr_sunnah':
        return times.asr;
      case 'maghrib':
      case 'maghrib_sunnah':
      case 'awabin':
        return times.maghrib;
      case 'isha':
      case 'isha_sunnah':
      case 'witr':
      case 'tahajjud':
        return times.isha;
      case 'ishraq':
      case 'chasht':
        return times.sunrise;
      default:
        return null;
    }
  }

  void _onItemTap(String pillarKey, AmolItem item) {
    if (_bloc.state.loggingItemKey != null) return;

    if (_bloc.state.isItemChecked(item.itemKey, item.isCompleted)) {
      _bloc.add(
        UncheckAmolDailyItem(
          logDate: _isoDate(_today),
          pillarKey: pillarKey,
          itemKey: item.itemKey,
        ),
      );
      return;
    }

    final times = _prayerTimes;
    if (times != null) {
      final gate = _gateStart(pillarKey, item.itemKey, times);
      if (gate != null) {
        final now = (widget.now ?? DateTime.now)();
        final gateTime = DateTime(
          _today.year,
          _today.month,
          _today.day,
          gate.hour,
          gate.minute,
        );
        if (now.isBefore(gateTime)) {
          _showPrayerNotStartedAlert();
          return;
        }
      }
    }

    _bloc.add(
      LogAmolDailyItem(
        logDate: _isoDate(_today),
        pillarKey: pillarKey,
        itemKey: item.itemKey,
      ),
    );
  }

  void _showPrayerNotStartedAlert() {
    final appText = AppText.readOf(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(appText.amolPrayerTimeNotStarted),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(appText.ok),
          ),
        ],
      ),
    );
  }

  void _toggleCategory(String pillarKey) {
    setState(() {
      _expandedPillarKey = _expandedPillarKey == pillarKey ? null : pillarKey;
    });
  }

  void _reload() => _bloc.add(LoadAmolDaily(_isoDate(_today)));

  @override
  void dispose() {
    _logFailureSub.cancel();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<AmolDailyBloc, AmolDailyState>(
        builder: (context, state) {
          final dashboard = state.dashboard;
          final pointLabel = dashboard?.summary.pointsText ?? widget.pointLabel;
          final progress = dashboard == null
              ? widget.progress
              : (dashboard.completionPercentage / 100).clamp(0, 1).toDouble();
          final progressLabel = dashboard == null
              ? widget.progressLabel
              : _formatPercentage(dashboard.completionPercentage);

          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  AmolHeader(title: appText.amolTracking),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 14.h),
                      children: [
                        AmolSummaryCard(
                          pointLabel: pointLabel,
                          progressLabel: progressLabel,
                          progress: progress,
                        ),
                        SizedBox(height: 18.h),
                        Text(
                          formatAmolDate(_today, appText),
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        if (dashboard != null)
                          for (final pillar in dashboard.pillars) ...[
                            _PillarRow(
                              pillar: pillar,
                              expanded: _expandedPillarKey == pillar.pillarKey,
                              onToggleExpanded: () =>
                                  _toggleCategory(pillar.pillarKey),
                              loggingItemKey: state.loggingItemKey,
                              completionOverrides: state.completionOverrides,
                              onItemTap: (item) =>
                                  _onItemTap(pillar.pillarKey, item),
                            ),
                            SizedBox(height: 12.h),
                          ]
                        else if (state.status == AmolDailyStatus.failure)
                          _LoadFailedNotice(
                            message: state.errorMessage,
                            onRetry: _reload,
                          )
                        else
                          const _PillarListShimmer(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 12.h),
                    child: const _DashboardButton(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// `itemKey` -> the localized display name the app already ships. Falls
/// back to the server's own (English) [AmolItem.title] for anything new.
String _localizedItemName(AppText appText, AmolItem item) {
  switch (item.itemKey) {
    case 'fajr':
      return appText.salahFajr;
    case 'dhuhr':
      return appText.salahDuhr;
    case 'asr':
      return appText.salahAsr;
    case 'maghrib':
      return appText.salahMagrib;
    case 'isha':
      return appText.salahEsa;
    case 'fajr_sunnah':
      return appText.salahFajrSunnah;
    case 'dhuhr_sunnah':
      return appText.salahDuhrSunnah;
    case 'asr_sunnah':
      return appText.salahAsrSunnah;
    case 'maghrib_sunnah':
      return appText.salahMagribSunnah;
    case 'isha_sunnah':
      return appText.salahEsaSunnah;
    case 'witr':
      return appText.salahWitr;
    case 'tahajjud':
      return appText.naflTahajjud;
    case 'ishraq':
      return appText.naflIshraq;
    case 'chasht':
      return appText.naflChast;
    case 'awabin':
      return appText.naflAwabin;
    case 'quran_tilawat':
      return appText.infoQuranTilawat;
    case 'hadith_reading':
      return appText.infoHadithReading;
    case 'daily_quiz':
      return appText.infoGivingQuiz;
    case 'sadaqah':
      return appText.moreSadaqah;
    case 'roza_kaffarah':
      return appText.moreRozaKaffarah;
    case 'nafl_fasting':
      return appText.moreNaflFasting;
    case 'physical_exercise':
      return appText.morePhysicalExercise;
    case 'good_advice':
      return appText.moreGivenGoodAdvice;
    case 'skill_development':
      return appText.moreSkillDevelopment;
    default:
      return item.title;
  }
}

class _ItemIcon {
  const _ItemIcon(this.icon, this.color);

  final IconData icon;
  final Color color;
}

const _fallbackItemIcon = _ItemIcon(Icons.check_circle_outline, amolOlive);

/// `itemKey` -> the icon/color the app already uses for that action.
const _itemIconByKey = {
  'fajr': _ItemIcon(Icons.wb_twilight, Color(0xFFFFC83D)),
  'dhuhr': _ItemIcon(Icons.wb_sunny, Color(0xFFFFC83D)),
  'asr': _ItemIcon(Icons.sunny, Color(0xFFFFAA2C)),
  'maghrib': _ItemIcon(Icons.wb_twilight_outlined, Color(0xFFFF8E4A)),
  'isha': _ItemIcon(Icons.nights_stay, Color(0xFFEACB2B)),
  'fajr_sunnah': _ItemIcon(Icons.wb_twilight, Color(0xFFFFC83D)),
  'dhuhr_sunnah': _ItemIcon(Icons.wb_sunny, Color(0xFFFFC83D)),
  'asr_sunnah': _ItemIcon(Icons.sunny, Color(0xFFFFAA2C)),
  'maghrib_sunnah': _ItemIcon(Icons.wb_twilight_outlined, Color(0xFFFF8E4A)),
  'isha_sunnah': _ItemIcon(Icons.nights_stay, Color(0xFFEACB2B)),
  'witr': _ItemIcon(Icons.nightlight_round, Color(0xFFEACB2B)),
  'tahajjud': _ItemIcon(Icons.nights_stay, Color(0xFF7FA8C9)),
  'ishraq': _ItemIcon(Icons.wb_sunny, Color(0xFFFFC83D)),
  'chasht': _ItemIcon(Icons.wb_sunny, Color(0xFFFFC83D)),
  'awabin': _ItemIcon(Icons.wb_sunny, Color(0xFFFFC83D)),
  'quran_tilawat': _ItemIcon(Icons.auto_awesome, Color(0xFFFF8A50)),
  'hadith_reading': _ItemIcon(Icons.auto_awesome, Color(0xFFFF8A50)),
  'daily_quiz': _ItemIcon(Icons.quiz, Color(0xFFFFC83D)),
  'sadaqah': _ItemIcon(Icons.volunteer_activism, Color(0xFFE8916B)),
  'roza_kaffarah': _ItemIcon(Icons.handshake, Color(0xFF6FA8D8)),
  'nafl_fasting': _ItemIcon(Icons.self_improvement, Color(0xFFC9A227)),
  'physical_exercise': _ItemIcon(Icons.fitness_center, Color(0xFF4FB0C6)),
  'good_advice': _ItemIcon(Icons.campaign, Color(0xFF4FB0C6)),
  'skill_development': _ItemIcon(Icons.emoji_objects, Color(0xFFFFC83D)),
};

String _formatPoints(num value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: SizedBox(
        height: 7.h,
        child: Stack(
          children: [
            const ColoredBox(color: Color(0xFFDDE0D0)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: const ColoredBox(color: amolOlive),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccordionHeader extends StatelessWidget {
  const _AccordionHeader({
    required this.title,
    required this.progress,
    required this.fractionLabel,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final double progress;
  final String fractionLabel;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(child: _ProgressBar(progress: progress)),
                      SizedBox(width: 10.w),
                      Text(
                        fractionLabel,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Icon(
              expanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
              size: 20.sp,
              color: const Color(0xFF7E8C61),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: expanded ? const Color(0xFFF7F7E7) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: expanded
          ? child
          : CustomPaint(
              painter: _DashedCardBorderPainter(radius: 16.r),
              child: child,
            ),
    );
  }
}

/// One [AmolPillar] rendered as an accordion: header (title, progress,
/// `formattedSubtext` fraction) plus its [AmolItem]s when expanded. Every
/// pillar from the API — prayer, Quran, Hadith, Quiz, Nafl & more — uses
/// this same layout.
class _PillarRow extends StatelessWidget {
  const _PillarRow({
    required this.pillar,
    required this.expanded,
    required this.onToggleExpanded,
    required this.loggingItemKey,
    required this.completionOverrides,
    required this.onItemTap,
  });

  final AmolPillar pillar;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final String? loggingItemKey;
  final Map<String, bool> completionOverrides;
  final ValueChanged<AmolItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final titleKey = _pillarTitleKeyByKey[pillar.pillarKey] ?? pillar.title;
    return _AccordionCard(
      expanded: expanded,
      child: Column(
        children: [
          _AccordionHeader(
            title: appText.categoryLabel(titleKey),
            progress: (pillar.percentage / 100).clamp(0.0, 1.0).toDouble(),
            fractionLabel: pillar.formattedSubtext,
            expanded: expanded,
            onTap: onToggleExpanded,
          ),
          if (expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
              child: Column(
                children: [
                  for (var i = 0; i < pillar.items.length; i++) ...[
                    if (i != 0) SizedBox(height: 6.h),
                    _AmolItemRow(
                      item: pillar.items[i],
                      isLogging: loggingItemKey == pillar.items[i].itemKey,
                      isChecked: completionOverrides[pillar.items[i].itemKey] ??
                          pillar.items[i].isCompleted,
                      onTap: () => onItemTap(pillar.items[i]),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A single checklist item: icon, localized name, earned points and a
/// checkmark tied to [isChecked] (`isCompleted`, overridden by the bloc's
/// `completionOverrides` once the user has locally checked/unchecked it this
/// session, so a flaky `GET` can't silently flip it back). Tapping an
/// unchecked item logs it via `POST /amol/tracker/log-item` (subject to the
/// screen's prayer-time gate); tapping a checked item un-checks it via
/// `DELETE /amol/tracker/delete-item`. There's no per-option flow
/// (in-jama'at / alone / kaja) here.
class _AmolItemRow extends StatelessWidget {
  const _AmolItemRow({
    required this.item,
    required this.isLogging,
    required this.isChecked,
    required this.onTap,
  });

  final AmolItem item;
  final bool isLogging;
  final bool isChecked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconSpec = _itemIconByKey[item.itemKey] ?? _fallbackItemIcon;
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: isLogging ? null : onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          children: [
            Container(
              width: 30.r,
              height: 30.r,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9.r),
              ),
              child: Icon(iconSpec.icon, color: iconSpec.color, size: 17.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                _localizedItemName(AppText.of(context), item),
                style: TextStyle(fontSize: 13.sp, color: Colors.black),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFFDDEBB5),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '+${_formatPoints(item.points)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5F6B45),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            _CompletionCircle(isCompleted: isChecked, isLogging: isLogging),
          ],
        ),
      ),
    );
  }
}

class _CompletionCircle extends StatelessWidget {
  const _CompletionCircle({required this.isCompleted, this.isLogging = false});

  final bool isCompleted;
  final bool isLogging;

  @override
  Widget build(BuildContext context) {
    if (isLogging) {
      return SizedBox(
        width: 26.r,
        height: 26.r,
        child: const Padding(
          padding: EdgeInsets.all(5),
          child: CircularProgressIndicator(strokeWidth: 2, color: amolOlive),
        ),
      );
    }
    if (isCompleted) {
      return Container(
        width: 26.r,
        height: 26.r,
        decoration: const BoxDecoration(
          color: amolOlive,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, size: 15.sp, color: Colors.white),
      );
    }
    return Container(
      width: 26.r,
      height: 26.r,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDADDC6), width: 1.4),
      ),
      child: Icon(Icons.check, size: 13.sp, color: const Color(0xFFB7BBA0)),
    );
  }
}

class _PillarListShimmer extends StatelessWidget {
  const _PillarListShimmer();

  // Matches the 7 pillars `GET /amol/tracker/daily` normally returns
  // (Fardh Prayer, Sunnah and Witr, Nafl Salat, Quran, Hadith, Quiz,
  // Nafl & more).
  static const _itemCount = 7;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE3ECC5),
      highlightColor: const Color(0xFFF6F9EC),
      child: Column(
        children: [
          for (var i = 0; i < _itemCount; i++) ...[
            Container(
              height: 62.h,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    height: 7.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
            if (i != _itemCount - 1) SizedBox(height: 12.h),
          ],
        ],
      ),
    );
  }
}

class _LoadFailedNotice extends StatelessWidget {
  const _LoadFailedNotice({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        children: [
          Text(
            message ?? 'Something went wrong. Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: Colors.black54),
          ),
          SizedBox(height: 12.h),
          OutlinedButton(onPressed: onRetry, child: Text(appText.tryAgain)),
        ],
      ),
    );
  }
}

class _DashedCardBorderPainter extends CustomPainter {
  const _DashedCardBorderPainter({required this.radius});

  final double radius;
  static const _color = Color(0xFFC7D69C);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final outline = Path()..addRRect(rrect);
    final dashed = Path();
    const dashWidth = 5.0;
    const dashGap = 4.0;
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += dashWidth + dashGap;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = _color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedCardBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

class _DashboardButton extends StatelessWidget {
  const _DashboardButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30.r),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AmolDashboardScreen()),
        ),
        child: Container(
          height: 54.h,
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          decoration: BoxDecoration(
            color: const Color(0xFFA3B06B),
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppText.of(context).viewInDashboard,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                width: 26.r,
                height: 26.r,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 15.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
