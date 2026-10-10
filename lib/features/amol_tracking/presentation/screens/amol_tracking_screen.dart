import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/widgets/login_required_dialog.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/datasources/amol_tracking_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/repositories/amol_tracking_repository_impl.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pillar.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/delete_amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/get_amol_daily.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/log_amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/bloc/amol_daily/amol_daily_bloc.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/screens/amol_dashboard_screen.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/state/amol_daily_store.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_localized_format.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_shared_widgets.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_time_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';
import 'package:tuhfatul_muslim/core/auth/auth_feature.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_context.dart';

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
  'Zikr': 'zikr',
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
  'zikr': 'Zikr',
  'nafl_and_more': 'Nafl & more',
};

/// The sections [AmolTrackingScreen] can bring into focus.
enum AmalSection {
  fardhPrayer('fardh_prayer'),
  sunnahWitr('sunnah_witr'),
  naflSalat('nafl_salat'),
  quran('quran'),
  hadith('hadith'),
  quiz('quiz'),
  zikr('zikr'),
  naflAndMore('nafl_and_more');

  const AmalSection(this.pillarKey);

  /// The `pillarKey` `GET /amol/tracker/daily` uses for this section.
  final String pillarKey;

  /// Resolves a display name (`'Hadith'`, `'Nafl & more'`, ...) or a pillar
  /// key; `null` for anything the tracker has no section for.
  static AmalSection? tryParse(String? value) {
    final key = _pillarKeyByTitle[value] ?? value;
    for (final section in values) {
      if (section.pillarKey == key) return section;
    }
    return null;
  }
}

class AmolTrackingScreen extends StatefulWidget {
  const AmolTrackingScreen({
    super.key,
    this.pointLabel = 'Point : 30/40',
    this.progressLabel = '86 %',
    this.progress = .86,
    this.initialExpandedCategory = 'Fardh Prayer',
    this.selectedPrayer,
    this.selectedSection,
    this.selectedItemKey,
    this.now,
    @visibleForTesting this.bloc,
  });

  final String pointLabel;
  final String progressLabel;
  final double progress;
  final String? initialExpandedCategory;

  /// A section to open as a floating,
  /// focused card while every other section is blurred and dimmed behind it.
  /// It is expanded too, and overrides [initialExpandedCategory].
  final AmalSection? selectedSection;

  /// A Fardh prayer to bring into view once the day has loaded, e.g. `"Fajr"`
  /// (matched case-insensitively; `"Magrib"` and `"Maghrib"` both work).
  final String? selectedPrayer;

  /// The exact checklist item to bring to the centre and highlight once the
  /// day has loaded - its `itemKey` (`fajr`, `fajr_sunnah`, `sadaqah`, ...),
  /// inside [selectedSection].
  final String? selectedItemKey;
  final DateTime Function()? now;

  /// Replaces the screen's own bloc (which it would create and load itself).
  final AmolDailyBloc? bloc;

  @override
  State<AmolTrackingScreen> createState() => _AmolTrackingScreenState();
}

class _AmolTrackingScreenState extends State<AmolTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final DateTime _today = (widget.now ?? DateTime.now)();
  late String? _focusedPillarKey = widget.selectedSection?.pillarKey;
  late String? _expandedPillarKey =
      _focusedPillarKey ??
      _pillarKeyByTitle[widget.initialExpandedCategory] ??
      widget.initialExpandedCategory;

  /// Flips true once the screen has arrived and the target is centred, so the
  /// focus effect animates in on a settled screen instead of firing before the
  /// data or the target is in place.
  bool _focusActive = false;
  final GlobalKey _focusedAnchor = GlobalKey();
  bool _revealStarted = false;

  /// The section shown first for this visit only. A pure display choice: the
  /// server's order, the store and Hive are never touched, and a screen opened
  /// without a target keeps the original order.
  String? _movedToTop;

  /// Drives the slide of the sections when [_movedToTop] takes the first place.
  late final AnimationController _reorder = AnimationController(
    vsync: this,
    duration: _reorderDuration,
  );

  /// Where each section is drawn at the start of the slide, relative to its
  /// final place (`0` = already there).
  final Map<String, double> _slideFrom = {};
  final Map<String, GlobalKey> _slotKeys = {};

  GlobalKey _slotKey(String pillarKey) =>
      _slotKeys.putIfAbsent(pillarKey, GlobalKey.new);

  /// [pillars] with the section moved to the top first and the others left in
  /// their relative order.
  List<AmolPillar> _displayOrder(List<AmolPillar> pillars) {
    final top = _movedToTop;
    final index = top == null
        ? -1
        : pillars.indexWhere((p) => p.pillarKey == top);
    if (index <= 0) return pillars;
    return [pillars[index], ...pillars.take(index), ...pillars.skip(index + 1)];
  }

  /// Set once the user ticks or unticks an item, so leaving the screen
  /// refreshes the Home cards that show the same data.
  bool _didChangeTracking = false;
  late final bool _ownsBloc = widget.bloc == null;
  late final AmolDailyBloc _bloc =
      widget.bloc ??
      (AmolDailyBloc(
        GetAmolDaily(
          AmolTrackingRepositoryImpl(AmolTrackingRemoteDataSourceImpl()),
        ),
        LogAmolItem(
          AmolTrackingRepositoryImpl(AmolTrackingRemoteDataSourceImpl()),
        ),
        DeleteAmolItem(
          AmolTrackingRepositoryImpl(AmolTrackingRemoteDataSourceImpl()),
        ),
        // Today's checklist is already loaded for the Home cards: show it at
        // once, then refresh it quietly, instead of opening on placeholders.
        initialDashboard: _sharedToday(),
      )..add(LoadAmolDaily(_isoDate(_today), silent: true)));

  AmolDailyDashboard? _sharedToday() {
    final shared = AmolDailyStore.instance.value;
    return shared != null && shared.dateIso == _isoDate(_today) ? shared : null;
  }

  DailyPrayerTimes? _prayerTimes;
  late final StreamSubscription<String> _logFailureSub;

  /// The item to centre and highlight, if the caller named one. Cleared when
  /// the user moves focus to another section.
  late String? _selectedItemKey =
      widget.selectedItemKey ?? _prayerItemKey(widget.selectedPrayer);
  final GlobalKey _selectedItemAnchor = GlobalKey();

  /// The section the selected item belongs to.
  String get _anchorPillarKey =>
      widget.selectedSection?.pillarKey ?? 'fardh_prayer';

  static String? _prayerItemKey(String? name) {
    final key = name?.trim().toLowerCase();
    if (key == null || key.isEmpty) return null;
    return key == 'magrib' ? 'maghrib' : key;
  }

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
    _logFailureSub = _bloc.logFailures.listen((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.of(context).failureUnknown)),
      );
    });
    unawaited(_loadPrayerTimes());
  }

  static const _reorderDuration = Duration(milliseconds: 620);
  static const _centerDuration = Duration(milliseconds: 560);
  static const _settlePause = Duration(milliseconds: 90);

  /// Runs once, when the day's checklist first has data: waits for the screen
  /// to finish arriving, centres the target, and only then lets the focus
  /// effect play. Nothing here fires before the target is in place.
  void _beginReveal() {
    if (_revealStarted) return;
    _revealStarted = true;
    if (_focusedPillarKey == null && _selectedItemKey == null) return;
    unawaited(_runReveal());
  }

  Future<void> _runReveal() async {
    await _routeSettled();
    if (!mounted) return;
    // The expanded section is laid out for good by the end of the next frame.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final focused = _focusedPillarKey;
    if (focused != null) await _moveToTop(focused);
    if (!mounted) return;
    // At the top the target is normally on screen already; only an item deep in
    // a long section may still need bringing into view.
    final target = _targetContext();
    if (target != null && target.mounted && !_isFullyVisible(target)) {
      await _centerOn(target);
    }
    if (!mounted) return;
    await Future<void>.delayed(_settlePause);
    if (!mounted || _focusedPillarKey == null) return;
    setState(() => _focusActive = true);
  }

  /// Completes once this screen's arrival transition has finished (at once if
  /// it already has, or if it was not opened by a route transition).
  Future<void> _routeSettled() async {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.status == AnimationStatus.completed) {
      return;
    }
    final done = Completer<void>();
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (!done.isCompleted) done.complete();
      }
    }

    animation.addStatusListener(onStatus);
    try {
      // A transition that never reports back must not hold the reveal forever.
      await done.future.timeout(const Duration(milliseconds: 900));
    } on TimeoutException {
      // Carry on: the screen is up.
    } finally {
      animation.removeStatusListener(onStatus);
    }
  }

  /// The selected item's row, or the focused section when there is no item (or
  /// it isn't on screen).
  BuildContext? _targetContext() =>
      (_selectedItemKey == null ? null : _selectedItemAnchor.currentContext) ??
      _focusedAnchor.currentContext;

  /// Makes [pillarKey]'s section the first one, sliding it up while the
  /// sections it passes slide down. The new order and the start of the slide
  /// land in the same frame, so nothing jumps before it moves.
  Future<void> _moveToTop(String pillarKey) async {
    final pillars = _bloc.state.dashboard?.pillars;
    if (pillars == null) return;
    final index = pillars.indexWhere((p) => p.pillarKey == pillarKey);
    if (index <= 0) return;

    final targetBox = _slotBox(pillarKey);
    final firstBox = _slotBox(pillars.first.pillarKey);
    _slideFrom.clear();
    if (targetBox != null && firstBox != null) {
      final rise =
          targetBox.localToGlobal(Offset.zero).dy -
          firstBox.localToGlobal(Offset.zero).dy;
      _slideFrom[pillarKey] = rise;
      // Each section above it ends one target-height lower.
      for (final passed in pillars.take(index)) {
        _slideFrom[passed.pillarKey] = -targetBox.size.height;
      }
    }
    _reorder.value = 0;
    setState(() => _movedToTop = pillarKey);
    if (_slideFrom.isEmpty) return;
    try {
      await _reorder.forward().orCancel;
    } on TickerCanceled {
      // The screen was closed mid-slide.
    }
  }

  RenderBox? _slotBox(String pillarKey) {
    final box = _slotKeys[pillarKey]?.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  bool _isFullyVisible(BuildContext target) {
    final box = target.findRenderObject();
    final viewport = Scrollable.maybeOf(target)?.context.findRenderObject();
    if (box is! RenderBox || viewport is! RenderBox) return true;
    final item = box.localToGlobal(Offset.zero) & box.size;
    final view = viewport.localToGlobal(Offset.zero) & viewport.size;
    return item.top >= view.top && item.bottom <= view.bottom;
  }

  /// Scrolls [target] to the middle of the visible list.
  Future<void> _centerOn(BuildContext? target) async {
    if (target == null || !target.mounted) return;
    await Scrollable.ensureVisible(
      target,
      alignment: 0.5,
      duration: _centerDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  /// Tapping a dimmed section brings it to the front instead.
  void _focusSection(String pillarKey) {
    setState(() {
      _focusedPillarKey = pillarKey;
      _expandedPillarKey = pillarKey;
      // The item the caller named belonged to the section it named.
      if (pillarKey != _anchorPillarKey) _selectedItemKey = null;
    });
    // After the frame, so the section is expanded and its anchor has moved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_centerOn(_focusedAnchor.currentContext));
    });
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

  /// The sign-in prompt to show for a tick in [pillarKey]: prayers, Quran and
  /// Hadith name themselves; everything else is the general Amol tracker.
  String _loginFeatureFor(String pillarKey) => switch (pillarKey) {
    'fardh_prayer' || 'sunnah_witr' => AuthFeatures.salah,
    'quran' => AuthFeatures.quran,
    'hadith' => AuthFeatures.hadith,
    _ => AuthFeatures.amol,
  };

  Future<void> _onItemTap(String pillarKey, AmolItem item) async {
    if (_bloc.state.loggingItemKey != null) return;
    // Quiz is never ticked here: its check comes from the server once a quiz
    // is completed. Tapping it just opens the Quiz section (no login check,
    // no dialog, no tracking); on return the day is reloaded so a quiz
    // finished meanwhile shows up checked.
    if (pillarKey == 'quiz') {
      await Navigator.of(context).pushNamed(RouteNames.winQuiz);
      if (mounted) _reload();
      return;
    }
    // Quran and Hadith can't be ticked by hand either: their check comes from
    // actually reading in those features. Tapping (checked or not) opens the
    // feature's main screen directly - no login check, no confirm dialog, no
    // log/uncheck API call - and the day is reloaded on return so reading done
    // meanwhile shows up checked.
    if (pillarKey == 'quran' || pillarKey == 'hadith') {
      await Navigator.of(
        context,
      ).pushNamed(pillarKey == 'quran' ? RouteNames.quran : RouteNames.hadith);
      if (mounted) _reload();
      return;
    }

    // Viewing is public, but logging / unchecking (POST / DELETE) needs the
    // login token.
    if (!await requireLogin(context, feature: _loginFeatureFor(pillarKey))) {
      return;
    }
    if (!mounted) return;

    if (_bloc.state.isItemChecked(item.itemKey, item.isCompleted)) {
      // Tracked -> untracked is destructive, so confirm first. Cancelling
      // leaves the checkbox and the server untouched.
      final confirmed = await _confirmUntrack(item);
      if (!mounted || !confirmed) return;
      _didChangeTracking = true;
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

    _didChangeTracking = true;
    _bloc.add(
      LogAmolDailyItem(
        logDate: _isoDate(_today),
        pillarKey: pillarKey,
        itemKey: item.itemKey,
      ),
    );
  }

  Future<bool> _confirmUntrack(AmolItem item) async {
    final appText = AppText.readOf(context);
    final name = _localizedItemName(appText, item);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appText.amolUntrackTitle),
        content: Text(appText.amolUntrackMessage.replaceAll('{name}', name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appText.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(appText.yes),
          ),
        ],
      ),
    );
    return confirmed == true;
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
    _reorder.dispose();
    _logFailureSub.cancel();
    if (_ownsBloc) _bloc.close();
    if (_didChangeTracking) {
      // After the frame, so Home cards don't rebuild mid-teardown.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => AmolDailyStore.instance.load(),
      );
    }
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
          final pointLabel = dashboard == null
              ? widget.pointLabel == 'Point : 30/40'
                    ? formatAmolPoints(30, 40, appText, languageOf(context))
                    : context.localizedDigits(widget.pointLabel)
              : formatAmolPoints(
                  dashboard.summary.totalEarnedPoints,
                  dashboard.summary.totalPossiblePoints,
                  appText,
                  languageOf(context),
                );
          final progress = dashboard == null
              ? widget.progress
              : (dashboard.completionPercentage / 100).clamp(0, 1).toDouble();
          final progressLabel = context.localizedDigits(
            dashboard == null
                ? widget.progressLabel
                : _formatPercentage(dashboard.completionPercentage),
          );

          if (dashboard != null) _beginReveal();
          // A section the server didn't send would leave everything dimmed with
          // nothing in front, so it isn't focused at all.
          final focusedKey =
              dashboard != null &&
                  dashboard.pillars.any((p) => p.pillarKey == _focusedPillarKey)
              ? _focusedPillarKey
              : null;

          return Scaffold(
            backgroundColor: context.pageColor(Colors.white),
            body: SafeArea(
              child: Column(
                children: [
                  AmolHeader(title: appText.amolTracking),
                  Expanded(
                    // Every section is laid out (not lazily built) so the slide
                    // can measure one that starts off screen.
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 14.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AmolSummaryCard(
                            pointLabel: pointLabel,
                            progressLabel: progressLabel,
                            progress: progress,
                          ),
                          SizedBox(height: 18.h),
                          Text(
                            context.localizedDigits(
                              formatAmolDate(_today, appText),
                            ),
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: context.inkColor(Colors.black),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          if (dashboard != null)
                            for (final pillar in _displayOrder(
                              dashboard.pillars,
                            ))
                              _ReorderSlot(
                                key: _slotKey(pillar.pillarKey),
                                animation: _reorder,
                                slideFrom: _slideFrom[pillar.pillarKey] ?? 0,
                                isMover: pillar.pillarKey == _movedToTop,
                                child: _FocusableSection(
                                  key: pillar.pillarKey == focusedKey
                                      ? _focusedAnchor
                                      : null,
                                  mode: focusedKey == null || !_focusActive
                                      ? _FocusMode.none
                                      : pillar.pillarKey == focusedKey
                                      ? _FocusMode.focused
                                      : _FocusMode.dimmed,
                                  onTapWhenDimmed: () =>
                                      _focusSection(pillar.pillarKey),
                                  child: _PillarRow(
                                    pillar: pillar,
                                    expanded:
                                        _expandedPillarKey == pillar.pillarKey,
                                    onToggleExpanded: () =>
                                        _toggleCategory(pillar.pillarKey),
                                    loggingItemKey: state.loggingItemKey,
                                    completionOverrides:
                                        state.completionOverrides,
                                    anchorItemKey:
                                        pillar.pillarKey == _anchorPillarKey
                                        ? _selectedItemKey
                                        : null,
                                    anchorKey: _selectedItemAnchor,
                                    highlightAnchor: _focusActive,
                                    onItemTap: (item) =>
                                        _onItemTap(pillar.pillarKey, item),
                                  ),
                                ),
                              )
                          else if (state.status == AmolDailyStatus.failure)
                            _LoadFailedNotice(onRetry: _reload)
                          else
                            const _PillarListShimmer(),
                        ],
                      ),
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
            ColoredBox(color: context.surfaceColor(Color(0xFFDDE0D0))),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: ColoredBox(color: context.surfaceColor(amolOlive)),
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
                          color: context.inkColor(Colors.black54),
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
              color: context.inkColor(Color(0xFF7E8C61)),
            ),
          ],
        ),
      ),
    );
  }
}

enum _FocusMode { none, focused, dimmed }

/// One section in the list. While the section moved to the top slides into
/// place it is drawn [slideFrom] pixels from where it now sits, easing to `0`;
/// the sections it passes fade slightly so the two don't fight over the space.
/// The bottom padding is the gap between sections.
class _ReorderSlot extends StatelessWidget {
  const _ReorderSlot({
    super.key,
    required this.animation,
    required this.slideFrom,
    required this.isMover,
    required this.child,
  });

  final Animation<double> animation;
  final double slideFrom;
  final bool isMover;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      // The section itself is built once; only the transform changes per frame.
      child: Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: child,
      ),
      builder: (context, child) {
        final t = animation.value;
        final dy = slideFrom * (1 - Curves.easeInOutCubic.transform(t));
        final passed = !isMover && slideFrom != 0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Opacity(
            opacity: passed ? 1 - .4 * math.sin(math.pi * t) : 1,
            child: child,
          ),
        );
      },
    );
  }
}

/// Pops the focused section forward (scale + shadow) and pushes the rest
/// behind a blur, fade and soft white gradient. Every change animates.
class _FocusableSection extends StatelessWidget {
  const _FocusableSection({
    super.key,
    required this.mode,
    required this.onTapWhenDimmed,
    required this.child,
  });

  final _FocusMode mode;
  final VoidCallback onTapWhenDimmed;
  final Widget child;

  static const _duration = Duration(milliseconds: 560);
  static const _dimBlur = 1.0;
  static const _dimOpacity = .78;

  @override
  Widget build(BuildContext context) {
    final focused = mode == _FocusMode.focused;
    final dimmed = mode == _FocusMode.dimmed;
    final radius = BorderRadius.circular(16.r);

    Widget content = AnimatedContainer(
      duration: _duration,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          if (focused)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 22.r,
              spreadRadius: 1.r,
              offset: Offset(0, 8.h),
            ),
        ],
      ),
      child: child,
    );

    content = TweenAnimationBuilder<double>(
      // A light blur: the other sections stay readable behind the focused one.
      tween: Tween(end: dimmed ? _dimBlur : 0),
      duration: _duration,
      curve: Curves.easeInOutCubic,
      child: Stack(
        children: [
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: _duration,
                opacity: dimmed ? 1 : 0,
                curve: Curves.easeInOutCubic,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        context
                            .surfaceColor(Colors.white)
                            .withValues(alpha: 0.08),
                        context
                            .surfaceColor(const Color(0xFFDCEBBB))
                            .withValues(alpha: 0.28),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      builder: (context, sigma, child) => sigma < 0.05
          ? child!
          : ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: sigma,
                sigmaY: sigma,
                tileMode: TileMode.decal,
              ),
              child: child,
            ),
    );

    return AnimatedScale(
      scale: focused ? 1.03 : 1,
      duration: _duration,
      curve: Curves.easeInOutCubic,
      child: AnimatedOpacity(
        duration: _duration,
        opacity: dimmed ? _dimOpacity : 1,
        child: dimmed
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTapWhenDimmed,
                child: AbsorbPointer(child: content),
              )
            : content,
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
        color: context.surfaceColor(
          expanded ? const Color(0xFFF7F7E7) : Colors.white,
        ),
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
    this.anchorItemKey,
    this.anchorKey,
    this.highlightAnchor = false,
  });

  final AmolPillar pillar;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final String? loggingItemKey;
  final Map<String, bool> completionOverrides;
  final ValueChanged<AmolItem> onItemTap;

  /// The item (if any) that [anchorKey] should be attached to, so the screen
  /// can scroll it into view.
  final String? anchorItemKey;
  final GlobalKey? anchorKey;

  /// Whether the anchored item is shown highlighted (once the focus effect has
  /// played).
  final bool highlightAnchor;

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
            fractionLabel: context.localizedDigits(pillar.formattedSubtext),
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
                    KeyedSubtree(
                      key:
                          anchorItemKey != null &&
                              pillar.items[i].itemKey == anchorItemKey
                          ? anchorKey
                          : null,
                      child: _AmolItemRow(
                        item: pillar.items[i],
                        highlighted:
                            highlightAnchor &&
                            anchorItemKey != null &&
                            pillar.items[i].itemKey == anchorItemKey,
                        isLogging: loggingItemKey == pillar.items[i].itemKey,
                        isChecked:
                            completionOverrides[pillar.items[i].itemKey] ??
                            pillar.items[i].isCompleted,
                        onTap: () => onItemTap(pillar.items[i]),
                      ),
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
    this.highlighted = false,
  });

  /// The item the user came here for: softly tinted so it reads as selected.
  final bool highlighted;

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: highlighted
              ? context
                    .surfaceColor(const Color(0xFFDDEBB5))
                    .withValues(alpha: .55)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              width: 30.r,
              height: 30.r,
              decoration: BoxDecoration(
                color: context.surfaceColor(Colors.white),
                borderRadius: BorderRadius.circular(9.r),
              ),
              child: Icon(
                iconSpec.icon,
                color: context.inkColor(iconSpec.color),
                size: 17.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                _localizedItemName(AppText.of(context), item),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: context.inkColor(Colors.black),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: context.surfaceColor(Color(0xFFDDEBB5)),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                context.localizedDigits(
                  '+${_formatPoints(isChecked ? item.points : item.maxPoints)}',
                ),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: context.inkColor(Color(0xFF5F6B45)),
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
        child: Padding(
          padding: EdgeInsets.all(5),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.inkColor(amolOlive),
          ),
        ),
      );
    }
    if (isCompleted) {
      return Container(
        width: 26.r,
        height: 26.r,
        decoration: BoxDecoration(
          color: context.surfaceColor(amolOlive),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, size: 15.sp, color: Colors.white),
      );
    }
    return Container(
      width: 26.r,
      height: 26.r,
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        shape: BoxShape.circle,
        border: Border.all(
          color: context.lineColor(Color(0xFFDADDC6)),
          width: 1.4,
        ),
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
      baseColor: context.surfaceColor(Color(0xFFE3ECC5)),
      highlightColor: context.surfaceColor(Color(0xFFF6F9EC)),
      child: Column(
        children: [
          for (var i = 0; i < _itemCount; i++) ...[
            Container(
              height: 62.h,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: context.surfaceColor(Colors.white),
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
                      color: context.surfaceColor(Colors.white),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    height: 7.h,
                    decoration: BoxDecoration(
                      color: context.surfaceColor(Colors.white),
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
  const _LoadFailedNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        children: [
          Text(
            appText.failureUnknown,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: context.inkColor(Colors.black54),
            ),
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
                  color: context.surfaceColor(
                    Colors.white.withValues(alpha: .18),
                  ),
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
