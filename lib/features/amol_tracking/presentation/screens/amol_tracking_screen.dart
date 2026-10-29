import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/widgets/login_required_dialog.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/datasources/amol_tracking_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/repositories/amol_tracking_repository_impl.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_tracking_day.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pillar.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_prayer_gate.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/delete_amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/get_amol_daily.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/log_amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/bloc/amol_daily/amol_daily_bloc.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/screens/amol_dashboard_screen.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/state/amol_daily_store.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/state/amol_day_clock.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_localized_format.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_shared_widgets.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_time_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/core/auth/auth_feature.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_context.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

/// `pillarKey`s whose items open another feature screen instead of being
/// ticked here (see [_AmolTrackingScreenState._onItemTap]) — their rows show
/// a navigation arrow instead of a checkbox.
const _navigablePillarKeys = {'quran', 'hadith', 'quiz', 'tasbih', 'dua'};

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
  'Zikr': 'tasbih',
  'Nafl & more': 'nafl_and_more',
};

/// The sections [AmolTrackingScreen] can bring into focus.
enum AmalSection {
  fardhPrayer('fardh_prayer'),
  sunnahWitr('sunnah_witr'),
  naflSalat('nafl_salat'),
  quran('quran'),
  hadith('hadith'),
  quiz('quiz'),

  /// The server's pillarKey for Zikr is `tasbih`, not `zikr`.
  zikr('tasbih'),
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// The day being tracked: the device's own calendar day, which turns over
  /// at midnight (see [AmolDayClock]). Everything logged from this screen
  /// carries it, so a tap that lands after the rollover belongs to the new
  /// day and the day just closed is left as it was.
  late DateTime _today;
  late String? _focusedPillarKey = widget.selectedSection?.pillarKey;
  late String? _expandedPillarKey =
      _focusedPillarKey ??
      _pillarKeyByTitle[widget.initialExpandedCategory] ??
      widget.initialExpandedCategory;

  /// Flips true once the screen has arrived and the target has landed at the
  /// top, so the focus effect animates in on a settled screen instead of
  /// firing before the data or the target is in place.
  bool _focusActive = false;
  bool _revealStarted = false;

  /// The list's own controller, so the reveal can scroll it to the target.
  final ScrollController _scroll = ScrollController();

  /// Drives the entrance of the sections - each one a beat after the one
  /// above it - while the list travels down to the target.
  late final AnimationController _stagger = AnimationController(
    vsync: this,
    duration: _StaggerSlot.total,
  );

  /// Blank space kept below the last section for this visit only, so a target
  /// near the bottom can still come to rest at the very top of the viewport.
  /// The server's order, the store and Hive are never touched.
  double _tailSpace = 0;

  final Map<String, GlobalKey> _slotKeys = {};

  GlobalKey _slotKey(String pillarKey) =>
      _slotKeys.putIfAbsent(pillarKey, GlobalKey.new);

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
        // The Fajr-aware initial load below may reuse the shared checklist.
        initialDashboard: _sharedToday(),
      ));

  AmolDailyDashboard? _sharedToday() {
    final shared = AmolDailyStore.instance.value;
    return shared != null && shared.dateIso == isoDate(_today) ? shared : null;
  }

  /// Today's prayer times, used only to gate a prayer tick to its own
  /// time — never to decide which day this is.
  DailyPrayerTimes? _prayerTimes;
  late final StreamSubscription<String> _logFailureSub;

  /// The screen follows the app-wide day unless the caller supplies its own
  /// clock (tests), which keeps it in full control of the date.
  bool get _followsDayClock => widget.now == null;

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

  static String _formatPercentage(num percentage) {
    final isWhole = percentage % 1 == 0;
    return '${percentage.toStringAsFixed(isWhole ? 0 : 1)} %';
  }

  @override
  void initState() {
    super.initState();
    _today = amolTrackingDate(_now());
    if (_followsDayClock) {
      WidgetsBinding.instance.addObserver(this);
      AmolDayClock.instance.addListener(_onDayChanged);
    }
    // Quran reading can change while this screen remains in the navigation
    // stack. Its offline projection lives in the shared daily store, while
    // this screen owns a separate bloc, so keep the two views connected
    // instead of waiting for the user to leave and open this screen again.
    // A caller-provided bloc is deliberately isolated (including widget
    // tests), so it remains entirely under that caller's control.
    if (_ownsBloc) {
      AmolDailyStore.instance.addListener(_onSharedDailyChanged);
      _onSharedDailyChanged();
    }
    _logFailureSub = _bloc.logFailures.listen((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.of(context).failureUnknown)),
      );
    });
    _refreshTrackingDay(load: true);
    unawaited(_refreshPrayerTimes());
  }

  /// Midnight: the checklist on screen is yesterday's, so it is replaced by
  /// the new day's — empty, zero points — without the user doing anything.
  void _onDayChanged() => _refreshTrackingDay();

  /// A device that slept through midnight is caught here, before the user
  /// can tick anything against the day that has ended.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_followsDayClock) return;
    AmolDayClock.instance.refresh();
    _refreshTrackingDay();
    unawaited(_refreshPrayerTimes());
  }

  void _onSharedDailyChanged() {
    if (!mounted) return;
    final shared = AmolDailyStore.instance.value;
    if (shared == null || shared.dateIso != isoDate(_today)) return;
    _bloc.add(UseAmolDailyDashboard(shared));
  }

  DateTime _now() => (widget.now ?? DateTime.now)();

  /// Rotates the screen onto the day it is now, loading it from zero when
  /// that has changed. Nothing is carried over: the bloc drops the ticks
  /// held for the old day and the shared checklist follows.
  void _refreshTrackingDay({bool load = false}) {
    final trackingDate = amolTrackingDate(_now());
    final changed = trackingDate != _today;
    if (changed) setState(() => _today = trackingDate);
    if (changed || load) {
      // A new day is loaded openly (the shimmer), since every row on screen
      // belongs to the day that has just closed.
      _bloc.add(LoadAmolDaily(isoDate(_today), silent: !changed));
      if (changed) unawaited(AmolDailyStore.instance.load());
    }
  }

  /// Fast: short enough to feel immediate, long enough to read as a scroll
  /// rather than a jump.
  static const _scrollDuration = Duration(milliseconds: 420);
  static const _settlePause = Duration(milliseconds: 90);

  /// What is left above the target once it lands, so the focused card's lift
  /// and shadow aren't clipped by the top edge of the list.
  double get _topGap => 10.h;

  /// Runs once, when the day's checklist first has data: waits for the screen
  /// to finish arriving, then plays the staggered entrance while the list
  /// scrolls down to the target, and only then lets the focus effect play.
  /// Nothing here fires before the target is laid out.
  void _beginReveal() {
    if (_revealStarted) return;
    _revealStarted = true;
    if (_focusedPillarKey == null && _selectedItemKey == null) {
      // Opened without a target: the sections stagger in where they are and
      // the list stays at the top.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _stagger.forward();
      });
      return;
    }
    unawaited(_runReveal());
  }

  Future<void> _runReveal() async {
    await _routeSettled();
    if (!mounted) return;
    // The expanded section is laid out for good by the end of the next frame.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final slot = _revealSlotKey();
    await _makeRoomAbove(slot);
    if (!mounted) return;
    // Both start together, so the wave running down the list and the travel
    // of the list itself read as one movement.
    unawaited(_stagger.forward());
    await _scrollToTop(slot);
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

  /// The section the reveal brings to the top: the focused one, or the one
  /// holding the selected item. Its key sits on [_StaggerSlot]'s outer
  /// padding, which the entrance never transforms, so it still measures
  /// truthfully while that animation is playing.
  GlobalKey? _revealSlotKey() {
    final pillarKey =
        _focusedPillarKey ??
        (_selectedItemKey == null ? null : _anchorPillarKey);
    return pillarKey == null ? null : _slotKeys[pillarKey];
  }

  /// The scroll offset that leaves [slot] at the top of the list, or `null`
  /// while it isn't on screen to be measured.
  double? _offsetToTop(GlobalKey? slot) {
    final box = slot?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !_scroll.hasClients) return null;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return null;
    return viewport.getOffsetToReveal(box, 0).offset - _topGap;
  }

  /// One of the last sections can only reach the top if something follows it,
  /// so the list grows by exactly what the scroll would fall short of.
  Future<void> _makeRoomAbove(GlobalKey? slot) async {
    final offset = _offsetToTop(slot);
    if (offset == null) return;
    final missing = offset - _scroll.position.maxScrollExtent;
    if (missing <= 1) return;
    setState(() => _tailSpace = missing);
    // The spacer is in place, and measurable, by the end of the next frame.
    await WidgetsBinding.instance.endOfFrame;
  }

  /// Scrolls [slot] up to the top of the list - fast, and smoothly eased.
  Future<void> _scrollToTop(GlobalKey? slot) async {
    final offset = _offsetToTop(slot);
    if (offset == null || !_scroll.hasClients) return;
    final position = _scroll.position;
    final target = offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < 1) return;
    await _scroll.animateTo(
      target,
      duration: _scrollDuration,
      curve: Curves.easeOutCubic,
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
    // After the frame, so the section is expanded and its slot has moved.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final slot = _slotKeys[pillarKey];
      await _makeRoomAbove(slot);
      if (mounted) await _scrollToTop(slot);
    });
  }

  /// Today's prayer times for the tick gate. Only times fetched for this
  /// very day are used, so a stale set can never gate a tick.
  Future<void> _refreshPrayerTimes() async {
    final today = amolTrackingDate(_now());
    try {
      final service = await AladhanPrayerTimeService.create();
      final cached = service.cachedPrayerTimes(today);
      if (mounted && cached != null) setState(() => _prayerTimes = cached);

      final fresh = await service.loadPrayerTimes(today);
      if (mounted && fresh != null) setState(() => _prayerTimes = fresh);
    } catch (_) {
      // Times stay null; the gate allows tracking when they're unavailable
      // rather than blocking the user on our own load failure.
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
    // Only a repeat tap on this very item is ignored; every other row stays
    // live, so ticking several things offline keeps all of them.
    if (_bloc.state.loggingItemKeys.contains(item.itemKey)) return;
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
      if (!mounted) return;
      final shared = AmolDailyStore.instance.value;
      if (shared != null && shared.dateIso == isoDate(_today)) {
        _bloc.add(UseAmolDailyDashboard(shared));
      } else {
        _reload();
      }
      return;
    }
    // Zikr (`tasbih`) and Dua are logged by adding an entry (e.g. "100
    // zikr", "5 minutes") inside those features, not by a plain tick here -
    // there's no generic "add an entry" UI in this tracker. Tapping opens the
    // feature's main screen directly, and the day is reloaded on return so
    // entries logged meanwhile show up checked.
    if (pillarKey == 'tasbih' || pillarKey == 'dua') {
      await Navigator.of(
        context,
      ).pushNamed(pillarKey == 'tasbih' ? RouteNames.zikr : RouteNames.dua);
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
          logDate: isoDate(_today),
          pillarKey: pillarKey,
          itemKey: item.itemKey,
        ),
      );
      return;
    }

    final times = _prayerTimes;
    if (times != null) {
      if (!canLogAmolPrayerItem(
        now: _now(),
        trackingDate: _today,
        pillarKey: pillarKey,
        itemKey: item.itemKey,
        times: times,
      )) {
        _showPrayerNotStartedAlert(item);
        return;
      }
    }

    _didChangeTracking = true;
    _bloc.add(
      LogAmolDailyItem(
        logDate: isoDate(_today),
        pillarKey: pillarKey,
        itemKey: item.itemKey,
      ),
    );
  }

  Future<bool> _confirmUntrack(AmolItem item) async {
    final appText = AppText.readOf(context);
    final name = _localizedItemName(context, item);
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

  void _showPrayerNotStartedAlert(AmolItem item) {
    final appText = AppText.readOf(context);
    final name = _localizedItemName(context, item);
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .45),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: _PrayerNotStartedCard(
          message: appText.amolPrayerTimeNotStarted.replaceAll('{name}', name),
          okLabel: appText.ok,
        ),
      ),
    );
  }

  void _toggleCategory(String pillarKey) {
    setState(() {
      _expandedPillarKey = _expandedPillarKey == pillarKey ? null : pillarKey;
    });
  }

  void _reload() => _bloc.add(LoadAmolDaily(isoDate(_today)));

  /// Pull-to-refresh: reloads the day. When a dashboard is already showing,
  /// the reload is silent (no shimmer flash) — the [RefreshIndicator]'s own
  /// spinner is the only loading feedback.
  Future<void> _onRefresh() async {
    final future = _bloc.stream.firstWhere(
      (s) =>
          s.status == AmolDailyStatus.success ||
          s.status == AmolDailyStatus.failure,
    );
    _bloc.add(LoadAmolDaily(isoDate(_today), silent: _bloc.state.hasData));
    await future;
  }

  @override
  void dispose() {
    if (_followsDayClock) {
      WidgetsBinding.instance.removeObserver(this);
      AmolDayClock.instance.removeListener(_onDayChanged);
    }
    _stagger.dispose();
    _scroll.dispose();
    _logFailureSub.cancel();
    if (_ownsBloc) {
      AmolDailyStore.instance.removeListener(_onSharedDailyChanged);
    }
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
              ? formatAmolPoints(0, 0, appText, languageOf(context))
              : formatAmolPoints(
                  dashboard.summary.totalEarnedPoints,
                  dashboard.summary.totalPossiblePoints,
                  appText,
                  languageOf(context),
                );
          final progress = dashboard == null
              ? 0.0
              : (dashboard.completionPercentage / 100).clamp(0, 1).toDouble();
          final progressLabel = context.localizedDigits(
            dashboard == null
                ? _formatPercentage(0)
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
                  Padding(
                    padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 0),
                    child: AmolSummaryCard(
                      pointLabel: pointLabel,
                      progressLabel: progressLabel,
                      progress: progress,
                    ),
                  ),
                  Expanded(
                    // Every section is laid out (not lazily built) so the slide
                    // can measure one that starts off screen.
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(15.w, 18.h, 15.w, 14.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                              for (final (index, pillar)
                                  in dashboard.pillars.indexed)
                                _StaggerSlot(
                                  key: _slotKey(pillar.pillarKey),
                                  animation: _stagger,
                                  index: index,
                                  child: _FocusableSection(
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
                                          _expandedPillarKey ==
                                          pillar.pillarKey,
                                      onToggleExpanded: () =>
                                          _toggleCategory(pillar.pillarKey),
                                      loggingItemKeys: state.loggingItemKeys,
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
                            if (_tailSpace > 0) SizedBox(height: _tailSpace),
                          ],
                        ),
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

/// The item's display name straight from the API: [AmolItem.titleBn] in
/// Bangla, [AmolItem.title] (English) otherwise — falling back to the other
/// field when the chosen one is empty, so a sparse response never shows a
/// blank row.
String _localizedItemName(BuildContext context, AmolItem item) =>
    _localizedOf(context, item.title, item.titleBn);

/// Same choice as [_localizedItemName], for a pillar's own title.
String _localizedPillarTitle(BuildContext context, AmolPillar pillar) =>
    _localizedOf(context, pillar.title, pillar.titleBn);

String _localizedOf(BuildContext context, String english, String bangla) {
  final isBangla = languageOf(context) == AppLanguage.bangla;
  final primary = isBangla ? bangla : english;
  final fallback = isBangla ? english : bangla;
  return primary.isNotEmpty ? primary : fallback;
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
  'quran_tilawat': _ItemIcon(Icons.menu_book_outlined, Color(0xFFFF8A50)),
  'hadith_reading': _ItemIcon(Icons.local_library, Color(0xFFFF8A50)),
  'daily_quiz': _ItemIcon(Icons.quiz_outlined, Color(0xFFFFC83D)),
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
        padding: EdgeInsets.fromLTRB(14.w, 18.h, 14.w, 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              // Title, mark and the expand arrow all sit together on this
              // one line.
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  fractionLabel,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.inkColor(Colors.black54),
                  ),
                ),
                SizedBox(width: 10.w),
                Icon(
                  expanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                  size: 22.sp,
                  color: context.inkColor(Color(0xFF7E8C61)),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            _ProgressBar(progress: progress),
          ],
        ),
      ),
    );
  }
}

enum _FocusMode { none, focused, dimmed }

/// One section in the list. On arrival each slot fades, lifts and settles a
/// beat after the one above it, so the list reads as one quick wave running
/// from the top down to the target the screen is scrolling to.
class _StaggerSlot extends StatelessWidget {
  const _StaggerSlot({
    super.key,
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;

  /// Place in the list, which is what delays this slot's own entrance.
  final int index;
  final Widget child;

  /// One slot's entrance, and the delay between two neighbours.
  static const _span = Duration(milliseconds: 300);
  static const _step = Duration(milliseconds: 45);

  /// Long enough for the eight sections the API sends to enter in turn.
  static const total = Duration(milliseconds: 300 + 45 * 7);

  @override
  Widget build(BuildContext context) {
    final span = _span.inMilliseconds / total.inMilliseconds;
    final start = math.min(
      index * _step.inMilliseconds / total.inMilliseconds,
      1 - span,
    );
    // The padding stays outside the transform on purpose: the screen measures
    // this slot through its key while the entrance is still playing.
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: AnimatedBuilder(
        animation: animation,
        // The section itself is built once; only the transform changes.
        child: child,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(
            ((animation.value - start) / span).clamp(0.0, 1.0),
          );
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 24.h * (1 - t)),
              child: Transform.scale(
                alignment: Alignment.topCenter,
                scale: .97 + .03 * t,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pops the focused section forward (scale + shadow) and pushes the rest
/// behind a blur, fade and soft white gradient. Every change animates.
class _FocusableSection extends StatelessWidget {
  const _FocusableSection({
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
    required this.loggingItemKeys,
    required this.completionOverrides,
    required this.onItemTap,
    this.anchorItemKey,
    this.anchorKey,
    this.highlightAnchor = false,
  });

  final AmolPillar pillar;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  /// Items with a request in flight. Nothing is drawn for them — it only
  /// stops the same row being tapped twice.
  final Set<String> loggingItemKeys;
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
    return _AccordionCard(
      expanded: expanded,
      child: Column(
        children: [
          _AccordionHeader(
            title: _localizedPillarTitle(context, pillar),
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
                        isLogging: loggingItemKeys.contains(
                          pillar.items[i].itemKey,
                        ),
                        isChecked:
                            completionOverrides[pillar.items[i].itemKey] ??
                            pillar.items[i].isCompleted,
                        isNavigable: _navigablePillarKeys.contains(
                          pillar.pillarKey,
                        ),
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
    this.isNavigable = false,
  });

  /// The item the user came here for: softly tinted so it reads as selected.
  final bool highlighted;

  final AmolItem item;

  /// A request for this item is in flight. It changes nothing on screen: the
  /// row already shows the state the user chose, and it stays that way.
  final bool isLogging;
  final bool isChecked;
  final VoidCallback onTap;

  /// True for an item that opens another feature screen on tap (Quran,
  /// Hadith, Quiz) rather than being ticked here — it shows a navigation
  /// arrow instead of a checkbox.
  final bool isNavigable;

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
              // A navigable item (Quran, Hadith, Quiz, Zikr, Dua) shows a
              // chevron instead of a checkmark circle, so a done one gets a
              // faint tint here instead - otherwise it would look identical
              // to one still unplayed.
              : isNavigable && isChecked
              ? context
                    .surfaceColor(const Color(0xFFDDEBB5))
                    .withValues(alpha: .25)
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
                _localizedItemName(context, item),
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
            if (isNavigable)
              Icon(
                Icons.chevron_right,
                size: 22.sp,
                color: context.inkColor(const Color(0xFFB7BBA0)),
              )
            else
              _CompletionCircle(isCompleted: isChecked),
          ],
        ),
      ),
    );
  }
}

/// The mark at the end of a checklist row: ticked, or not.
///
/// There is deliberately nothing in between — no spinner, no second shade of
/// tick, no "waiting to sync" badge. A tick the server has already recorded,
/// one still on its way, and one saved on the device while offline all look
/// exactly the same, because to the user they are the same: it is done. The
/// only thing that ever changes this mark is the user tapping it.
class _CompletionCircle extends StatelessWidget {
  const _CompletionCircle({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
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

/// The "this prayer's time hasn't started yet" alert: a rounded card with a
/// floating clock badge, matching [showLoginRequiredDialog]'s card style
/// instead of a bare [AlertDialog].
class _PrayerNotStartedCard extends StatelessWidget {
  const _PrayerNotStartedCard({required this.message, required this.okLabel});

  final String message;
  final String okLabel;

  @override
  Widget build(BuildContext context) {
    final ink = context.inkColor(const Color(0xFF2A331C));
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 320.w),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: EdgeInsets.only(top: 34.h),
                padding: EdgeInsets.fromLTRB(22.w, 48.h, 22.w, 20.h),
                decoration: BoxDecoration(
                  color: context.surfaceColor(Colors.white),
                  borderRadius: BorderRadius.circular(26.r),
                  boxShadow: [
                    BoxShadow(
                      color: amolOlive.withValues(alpha: .3),
                      blurRadius: 28.r,
                      offset: Offset(0, 12.h),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.sp,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          minimumSize: Size.fromHeight(46.h),
                          backgroundColor: amolOlive,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          okLabel,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 68.w,
                height: 68.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFFC5D077), amolOlive],
                  ),
                  border: Border.all(
                    color: context.surfaceColor(Colors.white),
                    width: 5.r,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: amolOlive.withValues(alpha: .45),
                      blurRadius: 16.r,
                      offset: Offset(0, 7.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.access_time_filled_rounded,
                  color: Colors.white,
                  size: 32.sp,
                ),
              ),
            ],
          ),
        ),
      ),
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
