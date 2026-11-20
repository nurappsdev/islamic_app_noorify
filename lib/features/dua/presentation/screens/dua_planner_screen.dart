import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_planner_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_login_dialog.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_plan_create_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bottom_nav.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_shimmer.dart';

/// Dua planner (design `devImg/img_7.png`), reached from index 3 ("Planner")
/// of [DuaBottomNav].
///
/// "My Plan" and "Complete Plan" are each loaded from
/// `GET /duas/planner/plans?status=...`.
class DuaPlannerScreen extends StatefulWidget {
  const DuaPlannerScreen({super.key, this.repository});

  /// The feature's own [duaRepository] in the app; injectable so the screen
  /// can be rendered against a stand-in.
  final DuaRepository? repository;

  @override
  State<DuaPlannerScreen> createState() => _DuaPlannerScreenState();
}

class _DuaPlannerScreenState extends State<DuaPlannerScreen> {
  static const _loadMoreThreshold = 200.0;

  late final DuaRepository _repository = widget.repository ?? duaRepository;
  late final DuaPlannerCubit _cubit = DuaPlannerCubit(_repository);
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  /// The day the strip highlights; the list below shows the plans running on
  /// it.
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  bool _searchOpen = false;
  String _query = '';

  /// The card the user tapped last — only that one shows "Explore now".
  String? _expandedPlanId;

  @override
  void initState() {
    super.initState();
    _cubit.load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _cubit.loadMore();
    }
  }

  /// Both filters are local, as the spec requires: changing the date or
  /// typing in the search field never costs a request.
  ///
  /// The date filter belongs to "My Plan" only — a completed plan ended
  /// before today by definition, so filtering the "Complete Plan" tab by the
  /// selected day would always leave it empty.
  List<DuaPlan> _visiblePlans(DuaPlannerState state) {
    final query = _query.trim().toLowerCase();
    final byDate = state.tab == 0;
    return [
      for (final plan in state.plans)
        if ((!byDate || _runsOnSelectedDate(plan)) &&
            (query.isEmpty || plan.name.toLowerCase().contains(query)))
          plan,
    ];
  }

  /// A plan runs on the selected day when the day sits inside its start/end
  /// boundaries; a missing boundary is open ended on that side.
  bool _runsOnSelectedDate(DuaPlan plan) {
    final start = DateTime.tryParse(plan.startDate);
    final end = DateTime.tryParse(plan.endDate);
    if (start != null && DateUtils.dateOnly(start).isAfter(_selectedDate)) {
      return false;
    }
    if (end != null && DateUtils.dateOnly(end).isBefore(_selectedDate)) {
      return false;
    }
    return true;
  }

  void _selectDate(DateTime date) {
    if (date == _selectedDate) return;
    setState(() => _selectedDate = date);
    // The strip shows the selected day with three on either side; ask for
    // that window's dots, which is a no-op once they are known.
    _cubit.loadCalendar(
      date.subtract(const Duration(days: 3)),
      date.add(const Duration(days: 3)),
    );
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  _PlannerDayStatuses _statusesOf(DuaPlannerState state) => _PlannerDayStatuses(
    plans: state.plans,
    calendar: state.calendar,
    track: state.tab == 0,
  );

  /// The "Select Date" sheet behind the header icon (`devImg/img_37.png`).
  Future<void> _pickMonth() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectDateSheet(
        initialDate: _selectedDate,
        statuses: _statusesOf(_cubit.state),
        onMonthShown: (from, to) => _cubit.loadCalendar(from, to),
      ),
    );
    if (picked != null && mounted) _selectDate(DateUtils.dateOnly(picked));
  }

  Future<void> _createPlan() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: .93,
        child: const DuaPlanCreateScreen(embedded: true),
      ),
    );
    if (!mounted) return;
    if (created == true) await _cubit.refreshAll(tab: 0);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<DuaPlannerCubit, DuaPlannerState>(
        listenWhen: (previous, current) =>
            previous.error != current.error &&
            current.error?.contains('AuthenticationRequiredException') == true,
        listener: (context, _) => showDuaLoginRequiredDialog(context),
        child: Scaffold(
          backgroundColor: context.pageColor(Colors.white),
          body: SafeArea(
            child: Stack(
              children: [
                BlocBuilder<DuaPlannerCubit, DuaPlannerState>(
                  builder: (context, state) => Column(
                    children: [
                      SizedBox(height: 10.h),
                      _PlannerTabs(
                        labels: [appText.myPlan, appText.completePlan],
                        counts: [
                          state.counts['in_progress'],
                          state.counts['completed'],
                        ],
                        selected: state.tab,
                        onChanged: _cubit.selectTab,
                      ),
                      _PlannerCalendar(
                        statuses: _statusesOf(state),
                        selectedDate: _selectedDate,
                        onDateSelected: _selectDate,
                        onPickMonth: _pickMonth,
                      ),
                      _PlannerSearchRow(
                        totalLabel: _totalPlanLabel(
                          context,
                          _visiblePlans(state).length,
                        ),
                        controller: _searchController,
                        open: _searchOpen,
                        onToggle: _toggleSearch,
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _cubit.load,
                          child: _buildBody(appText, state),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 20.w,
                  bottom: 78.h + bottomInset,
                  child: FilledButton.icon(
                    onPressed: _createPlan,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.surfaceColor(Colors.white),
                      foregroundColor: context.textInkColor(
                        const Color(0xFF444444),
                      ),
                      // The design floats this pill over the list.
                      elevation: 6,
                      shadowColor: Colors.black.withValues(alpha: .18),
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                    icon: Container(
                      width: 20.r,
                      height: 20.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.surfaceColor(const Color(0xFFA7B45B)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 15.sp,
                      ),
                    ),
                    label: Text(
                      appText.createPlan,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: DuaBottomNav(selectedIndex: 3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "Total plan 04" — how many plans run on the selected date, after the
  /// search filter.
  String _totalPlanLabel(BuildContext context, int total) {
    final count = context.localizedDigits(total.toString().padLeft(2, '0'));
    return context.localized(
      LocalizedText(en: 'Total plan $count', bn: 'মোট পরিকল্পনা $count'),
    );
  }

  Widget _buildBody(AppText appText, DuaPlannerState state) {
    if (state.status == DuaPlannerStatus.loading && state.plans.isEmpty) {
      return const DuaListShimmer(showHeader: false, cardHeight: 92);
    }
    final plans = _visiblePlans(state);
    if (plans.isEmpty &&
        state.status == DuaPlannerStatus.failure &&
        state.plans.isEmpty) {
      return _PlannerError(
        message: state.error ?? '',
        onRetry: () => _cubit.load(),
      );
    }
    if (plans.isEmpty) {
      // A scrollable empty state, not a bare Center, so the RefreshIndicator
      // above still has something to pull against.
      final message = state.plans.isEmpty
          ? appText.noPlansYetMessage
          : _query.trim().isNotEmpty
          ? context.localized(
              const LocalizedText(
                en: 'No plan matches your search.',
                bn: 'আপনার খোঁজার সাথে মেলে এমন কোনো প্ল্যান নেই।',
              ),
            )
          : context.localized(
              const LocalizedText(
                en: 'No plan runs on this day.',
                bn: 'এই দিনে চলছে এমন কোনো প্ল্যান নেই।',
              ),
            );
      return LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, -20.h),
                  child: _EmptyPlans(message: message),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final showLoadingMore = state.loadingMore;
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      // Room for the floating "Create Plan" button and the bottom nav.
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 150.h),
      itemCount: plans.length + (showLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        if (index >= plans.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: const Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        final plan = plans[index];
        return _PlanCard(
          repository: _repository,
          plan: plan,
          serial: index + 1,
          expanded: plan.id == _expandedPlanId,
          onTap: () => setState(
            () => _expandedPlanId = plan.id == _expandedPlanId ? null : plan.id,
          ),
        );
      },
    );
  }
}

/// "Total plan 04" with the design's search affordance: tapping the magnifier
/// expands a field beside the label (`devImg/img_36.png`) that filters the
/// loaded plans locally.
class _PlannerSearchRow extends StatelessWidget {
  const _PlannerSearchRow({
    required this.totalLabel,
    required this.controller,
    required this.open,
    required this.onToggle,
    required this.onChanged,
  });

  final String totalLabel;
  final TextEditingController controller;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      totalLabel,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13.sp,
        color: context.textInkColor(const Color(0xFF303030)),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 0, 16.w, 10.h),
      child: Row(
        children: [
          if (open) label else Expanded(child: label),
          if (open) ...[
            SizedBox(width: 12.w),
            Expanded(
              child: SizedBox(
                height: 38.h,
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  autofocus: true,
                  style: TextStyle(fontSize: 13.sp),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: context.localized(
                      const LocalizedText(
                        en: 'Search plans',
                        bn: 'প্ল্যান খুঁজুন',
                      ),
                    ),
                    hintStyle: TextStyle(
                      fontSize: 12.sp,
                      color: context.textInkColor(const Color(0xFFA9A9A9)),
                    ),
                    filled: true,
                    fillColor: context.surfaceColor(Colors.white),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    suffixIcon: IconButton(
                      onPressed: onToggle,
                      icon: Icon(
                        Icons.search_rounded,
                        size: 19.sp,
                        color: context.inkColor(const Color(0xFFA7B45B)),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99.r),
                      borderSide: BorderSide(
                        color: context.lineColor(const Color(0xFFE2E8D0)),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99.r),
                      borderSide: BorderSide(
                        color: context.lineColor(const Color(0xFFA7B45B)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(width: 10.w),
            InkWell(
              onTap: onToggle,
              customBorder: const CircleBorder(),
              child: Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: context.surfaceColor(const Color(0xFFF4F8E6)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 19.sp,
                  color: context.inkColor(const Color(0xFFA7B45B)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.repository,
    required this.plan,
    required this.serial,
    required this.expanded,
    required this.onTap,
  });
  final DuaRepository repository;
  final DuaPlan plan;
  final int serial;

  /// Tapping a card reveals its "Explore now" button, as the flow describes.
  final bool expanded;
  final VoidCallback onTap;

  /// A short localized date for the compact schedule chips.
  String? _dateLabel(BuildContext context, String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return null;
    return context.localizedDigits(
      MaterialLocalizations.of(context).formatShortMonthDay(date),
    );
  }

  Future<void> _openPlanSettings(BuildContext context) async {
    final action = await showModalBottomSheet<_PlanSettingsAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PlanSettingsSheet(remindersOn: plan.reminderEnabled),
    );
    if (!context.mounted || action == null) return;
    final cubit = context.read<DuaPlannerCubit>();
    switch (action) {
      case _PlanSettingsAction.edit:
        await _openEdit(context, cubit);
        return;
      case _PlanSettingsAction.info:
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _PlanInfoSheet(plan: plan, repository: repository),
        );
        return;
      case _PlanSettingsAction.reminders:
        await _toggleReminders(context, cubit);
        return;
      case _PlanSettingsAction.delete:
        final yes = await _confirmDelete(context);
        if (yes == true) await cubit.delete(plan.id);
        return;
    }
  }

  /// "Pause reminders" / "Resume reminders" — `PATCH` with nothing but
  /// `reminderEnabled`, then a reload so the sheet reopens in the new state.
  Future<void> _toggleReminders(
    BuildContext context,
    DuaPlannerCubit cubit,
  ) async {
    final enabled = !plan.reminderEnabled;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repository.setPlanReminder(plan.id, enabled: enabled);
    } catch (error) {
      if (error is AuthenticationRequiredException) {
        if (context.mounted) await showDuaLoginRequiredDialog(context);
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('$error')));
      return;
    }
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          context.localized(
            enabled
                ? const LocalizedText(
                    en: 'Reminders resumed.',
                    bn: 'রিমাইন্ডার আবার চালু হয়েছে।',
                  )
                : const LocalizedText(
                    en: 'Reminders paused.',
                    bn: 'রিমাইন্ডার বন্ধ রাখা হয়েছে।',
                  ),
          ),
        ),
      ),
    );
    await cubit.refreshAll();
  }

  /// Loads the plan's full detail (duas, days, status) so the edit screen
  /// can be pre-filled, then opens it.
  Future<void> _openEdit(BuildContext context, DuaPlannerCubit cubit) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    DuaPlanDetail? detail;
    Object? error;
    try {
      detail = await repository.getPlanDetail(plan.id);
    } catch (e) {
      error = e;
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close the spinner
    if (error is AuthenticationRequiredException) {
      await showDuaLoginRequiredDialog(context);
      return;
    }
    if (detail == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
      return;
    }
    final updated = await _showPlanDialog(context, editPlan: detail);
    if (updated == true) await cubit.refreshAll();
  }

  Future<bool?> _showPlanDialog(
    BuildContext context, {
    DuaPlanDetail? editPlan,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: .93,
      child: DuaPlanCreateScreen(embedded: true, editPlan: editPlan),
    ),
  );

  Future<bool?> _confirmDelete(BuildContext context) =>
      showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const _DeletePlanSheet(),
      );

  @override
  Widget build(BuildContext context) {
    // Background / accent pairs, cycled per card as in `devImg/img_22.png`.
    const palette = [
      (Color(0xFFFFE1EA), Color(0xFFE2708F)),
      (Color(0xFFFFE6B2), Color(0xFFE09A2B)),
      (Color(0xFFCCEDFF), Color(0xFF55A6CC)),
      (Color(0xFFD9EFA8), Color(0xFF7E9440)),
    ];
    final (cardColor, accent) = palette[(serial - 1) % palette.length];
    final startDate = _dateLabel(context, plan.startDate);
    final endDate = _dateLabel(context, plan.endDate);
    final dateChip = startDate != null
        ? '${context.localized(const LocalizedText(en: 'Start date', bn: 'শুরুর তারিখ'))} $startDate'
        : endDate != null
        ? '${context.localized(const LocalizedText(en: 'End date', bn: 'শেষ তারিখ'))} $endDate'
        : null;
    return InkWell(
      borderRadius: BorderRadius.circular(24.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(13.w, 12.h, 13.w, 12.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(cardColor),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: context.surfaceColor(cardColor.withValues(alpha: .45)),
              blurRadius: 12.r,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: context.surfaceColor(Colors.white),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  // The design's raised-hands mark; Material's closest glyph.
                  child: Icon(
                    Icons.volunteer_activism_outlined,
                    color: context.inkColor(const Color(0xFF6B7A3A)),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plan.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 17.sp,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w700,
                                color: context.textInkColor(
                                  const Color(0xFF2C3320),
                                ),
                              ),
                            ),
                          ),
                          if (dateChip != null) ...[
                            SizedBox(width: 7.w),
                            _PlanDateChip(label: dateChip, accent: accent),
                          ],
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        context.localized(
                          LocalizedText(
                            en:
                                'Added ${context.localizedDigits('${plan.totalDuas}')} '
                                'Dua into this plan',
                            bn:
                                'এই প্ল্যানে ${context.localizedDigits('${plan.totalDuas}')} '
                                'টি দোয়া যুক্ত আছে',
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: context.textInkColor(accent),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: () => _openPlanSettings(context),
                  constraints: BoxConstraints.tightFor(
                    width: 28.r,
                    height: 28.r,
                  ),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: context.surfaceColor(
                      accent.withValues(alpha: .62),
                    ),
                    shape: const CircleBorder(),
                  ),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 16.sp,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (expanded) ...[
              SizedBox(height: 14.h),
              Align(
                alignment: Alignment.centerRight,
                child: _ExploreNowButton(
                  accent: accent,
                  onTap: () => Navigator.of(context).pushNamed(
                    RouteNames.duaPlanDetail,
                    arguments: DuaPlanDetailArgs(plan),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The design's "Explore now ↗" pill: it opens the plan's dua checklist and
/// counter screen.
class _ExploreNowButton extends StatelessWidget {
  const _ExploreNowButton({required this.accent, required this.onTap});

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99.r),
      child: Ink(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 6.w, 6.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(const Color(0xFFA9C95F)),
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.localized(
                const LocalizedText(en: 'Explore now', bn: 'এখনই দেখুন'),
              ),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: context.textInkColor(const Color(0xFF2F3A17)),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 24.r,
              height: 24.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.surfaceColor(Colors.white),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_outward_rounded,
                size: 14.sp,
                color: context.inkColor(const Color(0xFF6C8032)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The design's "Start date 14 May" pill, sitting beside the plan name.
class _PlanDateChip extends StatelessWidget {
  const _PlanDateChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: context.surfaceColor(Colors.white.withValues(alpha: .85)),
      borderRadius: BorderRadius.circular(99.r),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: TextStyle(
        fontSize: 9.sp,
        fontWeight: FontWeight.w600,
        color: context.textInkColor(accent),
      ),
    ),
  );
}

/// "Plan info" — the plan's streaks, completion rate and recent days, from
/// `GET /duas/planner/plans/{id}/history`.
class _PlanInfoSheet extends StatefulWidget {
  const _PlanInfoSheet({required this.plan, required this.repository});

  final DuaPlan plan;
  final DuaRepository repository;

  @override
  State<_PlanInfoSheet> createState() => _PlanInfoSheetState();
}

class _PlanInfoSheetState extends State<_PlanInfoSheet> {
  DuaPlanHistory? _history;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final history = await widget.repository.getPlanHistory(widget.plan.id);
      if (mounted) setState(() => _history = history);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: .9.sh),
      padding: EdgeInsets.fromLTRB(22.w, 10.h, 22.w, 20.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: context.lineColor(const Color(0xFFD6D4D3)),
                  borderRadius: BorderRadius.circular(99.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              widget.plan.name,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 21.sp,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                color: context.textInkColor(const Color(0xFF2C3320)),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              context.localized(
                const LocalizedText(
                  en: 'History & streaks',
                  bn: 'ইতিহাস ও ধারাবাহিকতা',
                ),
              ),
              style: TextStyle(
                fontSize: 12.sp,
                color: context.textInkColor(const Color(0xFF85906A)),
              ),
            ),
            SizedBox(height: 18.h),
            if (_error != null)
              Text(
                '$_error',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.textInkColor(const Color(0xFFCB4A4A)),
                ),
              )
            else if (history == null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 28.h),
                child: const Center(child: CircularProgressIndicator()),
              )
            else ...[
              Row(
                children: [
                  _PlanStat(
                    label: context.localized(
                      const LocalizedText(
                        en: 'Current streak',
                        bn: 'চলমান ধারা',
                      ),
                    ),
                    value: context.localizedDigits('${history.currentStreak}'),
                  ),
                  SizedBox(width: 10.w),
                  _PlanStat(
                    label: context.localized(
                      const LocalizedText(
                        en: 'Longest streak',
                        bn: 'দীর্ঘতম ধারা',
                      ),
                    ),
                    value: context.localizedDigits('${history.longestStreak}'),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  _PlanStat(
                    label: context.localized(
                      const LocalizedText(
                        en: 'Days completed',
                        bn: 'সম্পন্ন দিন',
                      ),
                    ),
                    value: context.localizedDigits(
                      '${history.completedDays}/${history.scheduledDays}',
                    ),
                  ),
                  SizedBox(width: 10.w),
                  _PlanStat(
                    label: context.localized(
                      const LocalizedText(
                        en: 'Completion rate',
                        bn: 'সম্পন্নের হার',
                      ),
                    ),
                    value:
                        '${context.localizedDigits(history.completionRate.round().toString())}%',
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Text(
                context.localized(
                  const LocalizedText(
                    en: 'Recent activity',
                    bn: 'সাম্প্রতিক কার্যক্রম',
                  ),
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textInkColor(const Color(0xFF3B4526)),
                ),
              ),
              SizedBox(height: 8.h),
              // Newest first, and only the days the plan was scheduled on.
              for (final day
                  in history.days.reversed
                      .where((day) => day.isScheduled && !day.isFuture)
                      .take(10))
                _PlanHistoryRow(day: day),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanStat extends StatelessWidget {
  const _PlanStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(const Color(0xFFF4F8E6)),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 19.sp,
              fontWeight: FontWeight.w700,
              color: context.textInkColor(const Color(0xFF55632C)),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: context.textInkColor(const Color(0xFF85906A)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PlanHistoryRow extends StatelessWidget {
  const _PlanHistoryRow({required this.day});

  final DuaPlanHistoryDay day;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(day.date);
    final label = date == null
        ? day.date
        : context.localizedDigits(
            MaterialLocalizations.of(context).formatMediumDate(date),
          );
    final done = day.isCompleted;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Container(
            width: 8.r,
            height: 8.r,
            decoration: BoxDecoration(
              color: context.surfaceColor(
                done ? const Color(0xFF5FBD2F) : const Color(0xFFE35D5D),
              ),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: context.textInkColor(const Color(0xFF4A5230)),
              ),
            ),
          ),
          Text(
            context.localizedDigits('${day.completedDuas}/${day.totalDuas}'),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: context.textInkColor(
                done ? const Color(0xFF55632C) : const Color(0xFFB06262),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four options the three-dot menu offers.
enum _PlanSettingsAction { edit, info, reminders, delete }

class _PlanSettingsSheet extends StatelessWidget {
  const _PlanSettingsSheet({required this.remindersOn});

  /// Whether the plan's reminders are on, which is what the third tile
  /// offers to change.
  final bool remindersOn;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: BoxConstraints(maxHeight: .9.sh),
    padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 18.h),
    decoration: BoxDecoration(
      color: context.surfaceColor(Colors.white),
      borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
    ),
    child: SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: context.lineColor(const Color(0xFFD6D4D3)),
              borderRadius: BorderRadius.circular(99.r),
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.localized(
                    const LocalizedText(
                      en: 'Plan Settings',
                      bn: 'প্ল্যান সেটিংস',
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 25.sp,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    color: context.textInkColor(const Color(0xFFA7B45B)),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: context.surfaceColor(
                    const Color(0xFFF5F5F5),
                  ),
                ),
                icon: Icon(
                  Icons.close_rounded,
                  size: 20.sp,
                  color: context.textInkColor(const Color(0xFF777777)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _PlanSettingsTile(
            icon: Icons.edit_note_rounded,
            iconColor: const Color(0xFFF0A40C),
            iconBackground: const Color(0xFFFFF8E7),
            title: context.localized(
              const LocalizedText(
                en: 'Edit plan details',
                bn: 'প্ল্যান সম্পাদনা করুন',
              ),
            ),
            subtitle: context.localized(
              const LocalizedText(
                en: 'Reminders & schedule',
                bn: 'রিমাইন্ডার ও সময়সূচি',
              ),
            ),
            onTap: () => Navigator.pop(context, _PlanSettingsAction.edit),
          ),
          SizedBox(height: 10.h),
          _PlanSettingsTile(
            icon: Icons.insights_rounded,
            iconColor: const Color(0xFF71873A),
            iconBackground: const Color(0xFFF3F9DD),
            title: context.localized(
              const LocalizedText(en: 'Plan info', bn: 'প্ল্যানের তথ্য'),
            ),
            subtitle: context.localized(
              const LocalizedText(
                en: 'History & streaks',
                bn: 'ইতিহাস ও ধারাবাহিকতা',
              ),
            ),
            onTap: () => Navigator.pop(context, _PlanSettingsAction.info),
          ),
          SizedBox(height: 10.h),
          _PlanSettingsTile(
            icon: remindersOn
                ? Icons.notifications_off_outlined
                : Icons.notifications_active_outlined,
            iconColor: const Color(0xFF65B5D8),
            iconBackground: const Color(0xFFE8F7FF),
            title: context.localized(
              remindersOn
                  ? const LocalizedText(
                      en: 'Pause reminders',
                      bn: 'রিমাইন্ডার বন্ধ রাখুন',
                    )
                  : const LocalizedText(
                      en: 'Resume reminders',
                      bn: 'রিমাইন্ডার চালু করুন',
                    ),
            ),
            subtitle: context.localized(
              remindersOn
                  ? const LocalizedText(
                      en: 'Stop notifications for this plan',
                      bn: 'এই প্ল্যানের নোটিফিকেশন বন্ধ থাকবে',
                    )
                  : const LocalizedText(
                      en: 'Start notifications again',
                      bn: 'আবার নোটিফিকেশন পাঠানো হবে',
                    ),
            ),
            onTap: () => Navigator.pop(context, _PlanSettingsAction.reminders),
          ),
          SizedBox(height: 10.h),
          _PlanSettingsTile(
            icon: Icons.delete_outline_rounded,
            iconColor: const Color(0xFFFF4E50),
            iconBackground: const Color(0xFFFFE7E8),
            title: context.localized(
              const LocalizedText(en: 'Delete plan', bn: 'প্ল্যান মুছুন'),
            ),
            subtitle: context.localized(
              const LocalizedText(
                en: 'Permanently remove plan',
                bn: 'প্ল্যানটি স্থায়ীভাবে মুছুন।',
              ),
            ),
            color: const Color(0xFFFF4E50),
            onTap: () => Navigator.pop(context, _PlanSettingsAction.delete),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: context.surfaceColor(const Color(0xFFA7B45B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
              child: Text(
                AppText.of(context).commonDone,
                style: TextStyle(fontSize: 17.sp, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PlanSettingsTile extends StatelessWidget {
  const _PlanSettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19.r),
      child: Ink(
        padding: EdgeInsets.all(13.r),
        decoration: BoxDecoration(
          color: color == null
              ? context.surfaceColor(Colors.white)
              : context.surfaceColor(color!.withValues(alpha: .035)),
          borderRadius: BorderRadius.circular(19.r),
          border: color == null
              ? null
              : Border.all(
                  color: context.lineColor(color!.withValues(alpha: .22)),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .025),
              blurRadius: 16.r,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45.r,
              height: 45.r,
              decoration: BoxDecoration(
                color: context.surfaceColor(iconBackground),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                icon,
                color: context.inkColor(iconColor),
                size: 24.sp,
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color:
                          color ??
                          context.textInkColor(const Color(0xFF222222)),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: color == null
                          ? context.textInkColor(const Color(0xFF777777))
                          : context.inkColor(color!),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color == null
                  ? context.inkColor(const Color(0xFFAAAAAA))
                  : context.inkColor(color!),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DeletePlanSheet extends StatelessWidget {
  const _DeletePlanSheet();
  @override
  Widget build(BuildContext context) => _SheetShell(
    title: AppText.of(context).duaDeletePlanTitle,
    child: Column(
      children: [
        Icon(
          Icons.delete_outline,
          color: context.inkColor(Colors.red),
          size: 45.sp,
        ),
        SizedBox(height: 20.h),
        Text(
          AppText.of(context).duaDeletePlanMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.textInkColor(const Color(0xFF8B956D)),
          ),
        ),
        SizedBox(height: 90.h),
        _SheetButtons(
          cancel: () => Navigator.pop(context, false),
          confirm: () => Navigator.pop(context, true),
          confirmText: AppText.of(context).duaYesDelete,
          danger: true,
        ),
      ],
    ),
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.surfaceColor(const Color(0xFFDCE6BE)),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    ),
    padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17.sp,
            color: context.textInkColor(const Color(0xFF879260)),
          ),
        ),
        SizedBox(height: 20.h),
        child,
      ],
    ),
  );
}

class _SheetButtons extends StatelessWidget {
  const _SheetButtons({
    required this.cancel,
    required this.confirm,
    required this.confirmText,
    this.danger = false,
  });
  final VoidCallback cancel, confirm;
  final String confirmText;
  final bool danger;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: cancel,
          child: Text(AppText.of(context).duaCancel),
        ),
      ),
      SizedBox(width: 8.w),
      Expanded(
        child: FilledButton(
          onPressed: confirm,
          style: FilledButton.styleFrom(
            backgroundColor: context.surfaceColor(
              danger ? Colors.red.shade700 : const Color(0xFFA5B657),
            ),
          ),
          child: Text(confirmText),
        ),
      ),
    ],
  );
}

/// The planner's week strip. The arrows step one week back or forward with no
/// end stop, and each day's dot comes from
/// `GET /duas/reading/calendar?from=...&to=...`: green once that day's duas
/// were all done, red once a day a plan was running on has passed without
/// that, grey for today-still-pending and for future days.
class _PlannerCalendar extends StatelessWidget {
  const _PlannerCalendar({
    required this.statuses,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPickMonth,
  });

  final _PlannerDayStatuses statuses;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPickMonth;

  static List<DateTime> visibleDates(DateTime selected) => [
    for (var offset = -3; offset <= 3; offset++)
      selected.add(Duration(days: offset)),
  ];

  /// One week back or forward, as far as the user cares to go — what the
  /// plans cover only decides the dots and the list below, not where the
  /// strip may travel.
  void _moveWeek(int direction) =>
      onDateSelected(selectedDate.add(Duration(days: 7 * direction)));

  @override
  Widget build(BuildContext context) {
    final dates = visibleDates(selectedDate);
    final localizations = MaterialLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 10.h),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                // "October, 2026" — the design's comma, on the locale's own
                // month/year wording.
                localizations
                    .formatMonthYear(selectedDate)
                    .replaceFirst(' ', ', '),
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w500,
                  color: context.textInkColor(const Color(0xFF202020)),
                ),
              ),
              SizedBox(width: 6.w),
              IconButton(
                onPressed: onPickMonth,
                visualDensity: VisualDensity.compact,
                constraints: BoxConstraints.tightFor(width: 30.r, height: 30.r),
                padding: EdgeInsets.zero,
                tooltip: context.localized(
                  const LocalizedText(
                    en: 'Jump to a month',
                    bn: 'অন্য মাসে যান',
                  ),
                ),
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 17.sp,
                  color: context.inkColor(const Color(0xFFA7B45B)),
                ),
              ),
              const Spacer(),
              _CalendarArrow(
                icon: Icons.chevron_left_rounded,
                onTap: () => _moveWeek(-1),
              ),
              SizedBox(width: 7.w),
              _CalendarArrow(
                icon: Icons.chevron_right_rounded,
                onTap: () => _moveWeek(1),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final date in dates)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.5.w),
                    child: _PlannerDay(
                      date: date,
                      selected: date == selectedDate,
                      status: statuses.of(date),
                      onTap: () => onDateSelected(date),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _DayStatus { none, done, missed }

/// Reading status per day, shared by the week strip and the "Select Date"
/// sheet: green once `GET /duas/reading/calendar` reports the day's goal met,
/// red once a day a plan was running on has passed without that.
class _PlannerDayStatuses {
  const _PlannerDayStatuses({
    required this.plans,
    required this.calendar,
    required this.track,
  });

  final List<DuaPlan> plans;
  final Map<String, DuaCalendarDay> calendar;

  /// Completed plans can no longer be missed, so their tab shows no colour.
  final bool track;

  _DayStatus of(DateTime date) {
    if (!track) return _DayStatus.none;
    final day = calendar[_plannerApiDate(date)];
    if (day != null && day.isGoalMet) return _DayStatus.done;
    final today = DateUtils.dateOnly(DateTime.now());
    if (date.isBefore(today) && insidePlan(date)) return _DayStatus.missed;
    return _DayStatus.none;
  }

  /// A day only counts as missed when one of the plans was actually running
  /// on it — the reading calendar itself has no notion of a schedule.
  bool insidePlan(DateTime date) {
    for (final plan in plans) {
      final start = DateTime.tryParse(plan.startDate);
      final end = DateTime.tryParse(plan.endDate);
      if (start != null && DateUtils.dateOnly(start).isAfter(date)) continue;
      if (end != null && DateUtils.dateOnly(end).isBefore(date)) continue;
      return true;
    }
    return false;
  }
}

/// The "Select Date" sheet of `devImg/img_37.png`: month and year wheels over
/// the whole month, each day carrying the same green/red reading dot the week
/// strip shows, and a round check to confirm.
class _SelectDateSheet extends StatefulWidget {
  const _SelectDateSheet({
    required this.initialDate,
    required this.statuses,
    required this.onMonthShown,
  });

  final DateTime initialDate;
  final _PlannerDayStatuses statuses;

  /// Asks the screen for the dots of a month the sheet scrolled to.
  final void Function(DateTime from, DateTime to) onMonthShown;

  @override
  State<_SelectDateSheet> createState() => _SelectDateSheetState();
}

class _SelectDateSheetState extends State<_SelectDateSheet> {
  static const _yearSpan = 5;
  static const _itemExtent = 42.0;

  late DateTime _selected = DateUtils.dateOnly(widget.initialDate);
  late int _month = _selected.month;
  late int _year = _selected.year;
  late final _firstYear = widget.initialDate.year - _yearSpan;
  late final FixedExtentScrollController _monthWheel =
      FixedExtentScrollController(initialItem: _month - 1);
  late final FixedExtentScrollController _yearWheel =
      FixedExtentScrollController(initialItem: _year - _firstYear);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestMonth());
  }

  @override
  void dispose() {
    _monthWheel.dispose();
    _yearWheel.dispose();
    super.dispose();
  }

  void _requestMonth() {
    final first = DateTime(_year, _month);
    widget.onMonthShown(first, DateTime(_year, _month + 1, 0));
  }

  void _showMonth({int? month, int? year}) {
    setState(() {
      _month = month ?? _month;
      _year = year ?? _year;
    });
    _requestMonth();
  }

  /// The days of the shown month, padded with nulls so the first one falls
  /// under its weekday (the grid starts on Sunday, like the week strip).
  List<DateTime?> get _cells {
    final first = DateTime(_year, _month);
    final length = DateUtils.getDaysInMonth(_year, _month);
    return [
      for (var i = 0; i < first.weekday % 7; i++) null,
      for (var day = 1; day <= length; day++) DateTime(_year, _month, day),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final today = DateUtils.dateOnly(DateTime.now());

    return Container(
      constraints: BoxConstraints(maxHeight: .9.sh),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.surfaceColor(const Color(0xFFF7FAEE)),
            context.surfaceColor(const Color(0xFFE4EFCD)),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 18.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: context.lineColor(const Color(0xFFC3D197)),
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42.r,
                      height: 42.r,
                      decoration: BoxDecoration(
                        color: context.surfaceColor(const Color(0xFFE9F2D2)),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        size: 22.sp,
                        color: context.inkColor(const Color(0xFF7E9440)),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 9.r,
                        height: 9.r,
                        decoration: BoxDecoration(
                          color: context.surfaceColor(const Color(0xFFF0922B)),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.localized(
                          const LocalizedText(
                            en: 'Select Date',
                            bn: 'তারিখ বাছুন',
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 22.sp,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          color: context.textInkColor(const Color(0xFF2F3A17)),
                        ),
                      ),
                      Text(
                        context.localized(
                          const LocalizedText(
                            en: 'Select date to filter your plan',
                            bn: 'প্ল্যান ফিল্টার করতে তারিখ বাছুন',
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: context.textInkColor(const Color(0xFF7D8A5D)),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: context.surfaceColor(Colors.white),
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18.sp,
                    color: context.textInkColor(const Color(0xFF6C7A4A)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _MonthYearWheels(
              monthController: _monthWheel,
              yearController: _yearWheel,
              month: _month,
              year: _year,
              firstYear: _firstYear,
              yearCount: _yearSpan * 2 + 1,
              itemExtent: _itemExtent,
              monthLabel: (month) => localizations
                  .formatMonthYear(DateTime(_year, month))
                  .split(' ')
                  .first,
              onMonth: (month) => _showMonth(month: month),
              onYear: (year) => _showMonth(year: year),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                for (var weekday = 0; weekday < 7; weekday++)
                  Expanded(
                    child: Center(
                      child: Text(
                        localizations.narrowWeekdays[weekday],
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.textInkColor(const Color(0xFF8A9A61)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: .95,
              children: [
                for (final date in _cells)
                  if (date == null)
                    const SizedBox.shrink()
                  else
                    _SelectDateCell(
                      date: date,
                      selected: date == _selected,
                      isToday: date == today,
                      status: widget.statuses.of(date),
                      onTap: () => setState(() => _selected = date),
                    ),
              ],
            ),
            SizedBox(height: 14.h),
            // The design's round confirm button.
            Material(
              color: context.surfaceColor(Colors.white),
              shape: const CircleBorder(),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: .15),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context, _selected),
                child: SizedBox(
                  width: 62.r,
                  height: 62.r,
                  child: Icon(
                    Icons.check_rounded,
                    size: 28.sp,
                    color: context.inkColor(const Color(0xFF6C8032)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sheet's two wheels, sharing one highlighted centre band.
class _MonthYearWheels extends StatelessWidget {
  const _MonthYearWheels({
    required this.monthController,
    required this.yearController,
    required this.month,
    required this.year,
    required this.firstYear,
    required this.yearCount,
    required this.itemExtent,
    required this.monthLabel,
    required this.onMonth,
    required this.onYear,
  });

  final FixedExtentScrollController monthController, yearController;
  final int month, year, firstYear, yearCount;
  final double itemExtent;
  final String Function(int month) monthLabel;
  final ValueChanged<int> onMonth, onYear;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
    decoration: BoxDecoration(
      color: context.surfaceColor(Colors.white),
      borderRadius: BorderRadius.circular(22.r),
    ),
    child: SizedBox(
      height: itemExtent * 5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: itemExtent,
            decoration: BoxDecoration(
              color: context.surfaceColor(const Color(0xFFEFF5DF)),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _PickerWheel(
                  controller: monthController,
                  itemCount: 12,
                  itemExtent: itemExtent,
                  selectedIndex: month - 1,
                  labelOf: (index) => monthLabel(index + 1),
                  onSelected: (index) => onMonth(index + 1),
                ),
              ),
              Expanded(
                child: _PickerWheel(
                  controller: yearController,
                  itemCount: yearCount,
                  itemExtent: itemExtent,
                  selectedIndex: year - firstYear,
                  labelOf: (index) =>
                      context.localizedDigits('${firstYear + index}'),
                  onSelected: (index) => onYear(firstYear + index),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// One day of the sheet's month grid.
class _SelectDateCell extends StatelessWidget {
  const _SelectDateCell({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.status,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool isToday;
  final _DayStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (status) {
      _DayStatus.done => const Color(0xFF5FBD2F),
      _DayStatus.missed => const Color(0xFFE35D5D),
      _DayStatus.none => null,
    };
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? context.surfaceColor(const Color(0xFFA7B45B))
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: !selected && isToday
                  ? Border.all(
                      color: context.lineColor(const Color(0xFFA7B45B)),
                    )
                  : null,
            ),
            child: Text(
              context.localizedDigits('${date.day}'),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : context.textInkColor(dotColor ?? const Color(0xFF4A5726)),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 5.r,
            child: dotColor == null
                ? null
                : Container(
                    width: 5.r,
                    height: 5.r,
                    decoration: BoxDecoration(
                      color: context.surfaceColor(dotColor),
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PickerWheel extends StatelessWidget {
  const _PickerWheel({
    required this.controller,
    required this.itemCount,
    required this.itemExtent,
    required this.selectedIndex,
    required this.labelOf,
    required this.onSelected,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final double itemExtent;
  final int selectedIndex;
  final String Function(int index) labelOf;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => ListWheelScrollView.useDelegate(
    controller: controller,
    itemExtent: itemExtent,
    physics: const FixedExtentScrollPhysics(),
    onSelectedItemChanged: onSelected,
    childDelegate: ListWheelChildBuilderDelegate(
      childCount: itemCount,
      builder: (context, index) {
        final isSelected = index == selectedIndex;
        return Center(
          child: Text(
            labelOf(index),
            style: TextStyle(
              fontSize: isSelected ? 18.sp : 14.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: context.textInkColor(
                isSelected ? const Color(0xFF2F3A17) : const Color(0xFF9AA77A),
              ),
            ),
          ),
        );
      },
    ),
  );
}

String _plannerApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class _CalendarArrow extends StatelessWidget {
  const _CalendarArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Ink(
        width: 30.r,
        height: 30.r,
        decoration: BoxDecoration(
          color: context.surfaceColor(const Color(0xFFF2F7E2)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 19.sp,
          color: context.inkColor(const Color(0xFFA7B45B)),
        ),
      ),
    ),
  );
}

/// "Sun ... Sat" the way the design spells them. [MaterialLocalizations]
/// only offers single-letter narrow names, and the app ships its own
/// English/Bangla wording anyway.
const _shortWeekdays = [
  LocalizedText(en: 'Sun', bn: 'রবি'),
  LocalizedText(en: 'Mon', bn: 'সোম'),
  LocalizedText(en: 'Tue', bn: 'মঙ্গল'),
  LocalizedText(en: 'Wed', bn: 'বুধ'),
  LocalizedText(en: 'Thu', bn: 'বৃহঃ'),
  LocalizedText(en: 'Fri', bn: 'শুক্র'),
  LocalizedText(en: 'Sat', bn: 'শনি'),
];

class _PlannerDay extends StatelessWidget {
  const _PlannerDay({
    required this.date,
    required this.selected,
    required this.status,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final _DayStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (status) {
      _DayStatus.done => const Color(0xFF5FBD2F),
      _DayStatus.missed => const Color(0xFFE35D5D),
      _DayStatus.none =>
        selected ? const Color(0xFF6E7A45) : const Color(0xFFDFE2D8),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        // The design lifts the selected day above the rest of the strip.
        margin: EdgeInsets.symmetric(vertical: selected ? 0 : 5.h),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(
            selected ? const Color(0xFFCADF8E) : Colors.white,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: context.lineColor(
              selected ? const Color(0xFFBBD177) : const Color(0xFFECF0DD),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                context.localized(_shortWeekdays[date.weekday % 7]),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: context.textInkColor(
                    selected
                        ? const Color(0xFF55632C)
                        : const Color(0xFF9CA66A),
                  ),
                ),
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              context.localizedDigits('${date.day}'),
              style: TextStyle(
                fontSize: selected ? 17.sp : 15.sp,
                fontWeight: FontWeight.w700,
                color: context.textInkColor(
                  selected ? const Color(0xFF46531F) : const Color(0xFF585E3D),
                ),
              ),
            ),
            SizedBox(height: selected ? 9.h : 7.h),
            Container(
              width: 5.r,
              height: 5.r,
              decoration: BoxDecoration(
                color: context.surfaceColor(dotColor),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannerTabs extends StatelessWidget {
  const _PlannerTabs({
    required this.labels,
    required this.counts,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;

  /// Plan totals per tab; a null entry hides the count.
  final List<int?> counts;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 16.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _PlannerTab(
                label: labels[i],
                count: i < counts.length ? counts[i] : null,
                selected: i == selected,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlannerTab extends StatelessWidget {
  const _PlannerTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = this.count;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22.r),
      child: Container(
        height: 46.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? context.surfaceColor(const Color(0xFFA7B45B))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: selected ? 'serif' : null,
                  fontStyle: selected ? FontStyle.italic : FontStyle.normal,
                  fontSize: selected ? 18.sp : 15.sp,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : context.textInkColor(const Color(0xFF303629)),
                ),
              ),
            ),
            SizedBox(width: 7.w),
            if (selected)
              Container(
                width: 6.r,
                height: 6.r,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              )
            else if (count != null)
              Text(
                context.localizedDigits(count.toString().padLeft(2, '0')),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.textInkColor(const Color(0xFFA0A0A0)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A failed load — a dead session, say — says so and offers a retry, rather
/// than looking like a tab with no plans in it.
class _PlannerError extends StatelessWidget {
  const _PlannerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 46.sp,
                    color: context.inkColor(const Color(0xFFBCC5A0)),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    context.localized(
                      const LocalizedText(
                        en: 'The plans could not be loaded.',
                        bn: 'প্ল্যানগুলো আনা যায়নি।',
                      ),
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      color: context.textInkColor(const Color(0xFF5D6B44)),
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: context.textInkColor(const Color(0xFF9AA77A)),
                      ),
                    ),
                  ],
                  SizedBox(height: 14.h),
                  FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.surfaceColor(
                        const Color(0xFFA7B45B),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                    child: Text(
                      context.localized(
                        const LocalizedText(en: 'Try again', bn: 'আবার চেষ্টা'),
                      ),
                      style: TextStyle(fontSize: 13.sp, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyPlans extends StatelessWidget {
  const _EmptyPlans({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 110.w,
        height: 96.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.sticky_note_2_rounded,
              color: context.surfaceColor(const Color(0xFFDDE8BA)),
              size: 88.sp,
            ),
            Positioned(
              top: 30.h,
              child: Text(
                '?',
                style: TextStyle(
                  color: context.textInkColor(const Color(0xFF84945F)),
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 12.h),
      Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.textInkColor(const Color(0xFF5D6B44)),
          fontSize: 13.sp,
          height: 1.4,
        ),
      ),
    ],
  );
}
