import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_planner_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_login_dialog.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_plan_create_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bottom_nav.dart';

/// Dua planner (design `devImg/img_7.png`), reached from index 3 ("Planner")
/// of [DuaBottomNav].
///
/// "My Plan" and "Complete Plan" are each loaded from
/// `GET /duas/planner/plans?status=...`.
class DuaPlannerScreen extends StatefulWidget {
  const DuaPlannerScreen({super.key});

  @override
  State<DuaPlannerScreen> createState() => _DuaPlannerScreenState();
}

class _DuaPlannerScreenState extends State<DuaPlannerScreen> {
  static const _loadMoreThreshold = 200.0;

  late final DuaPlannerCubit _cubit = DuaPlannerCubit(duaRepository);
  final _scrollController = ScrollController();

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
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _cubit.loadMore();
    }
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
    if (created == true) await _cubit.selectTab(0);
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
                        selected: state.tab,
                        onChanged: _cubit.selectTab,
                      ),
                      _PlannerCalendar(
                        totalLabel: context.localized(
                          LocalizedText(
                            en: 'Total plan ${context.localizedDigits('${state.plans.length}')}',
                            bn: 'মোট পরিকল্পনা ${context.localizedDigits('${state.plans.length}')}',
                          ),
                        ),
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFA7B45B),
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

  Widget _buildBody(AppText appText, DuaPlannerState state) {
    if (state.status == DuaPlannerStatus.loading && state.plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.plans.isEmpty) {
      // A scrollable empty state, not a bare Center, so the RefreshIndicator
      // above still has something to pull against.
      return LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, -20.h),
                  child: _EmptyPlans(message: appText.noPlansYetMessage),
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
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 96.h),
      itemCount: state.plans.length + (showLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        if (index >= state.plans.length) {
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
        return _PlanCard(plan: state.plans[index], serial: index + 1);
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.serial});
  final DuaPlan plan;
  final int serial;

  String _dateLabel(BuildContext context, String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return context.localizedDigits(
      MaterialLocalizations.of(context).formatMediumDate(date),
    );
  }

  Future<void> _menu(BuildContext context) async {
    final appText = AppText.readOf(context);
    final action = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(400, 200, 12, 0),
      color: context.surfaceColor(Colors.white),
      items: [
        PopupMenuItem(value: 'edit', child: Text(appText.duaSavedEdit)),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            appText.duaSavedDelete,
            style: TextStyle(color: context.inkColor(Colors.red)),
          ),
        ),
      ],
    );
    if (!context.mounted || action == null) return;
    final cubit = context.read<DuaPlannerCubit>();
    if (action == 'edit') {
      await _openEdit(context, cubit);
    } else {
      final yes = await _confirmDelete(context);
      if (yes == true) await cubit.delete(plan.id);
    }
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
      detail = await duaRepository.getPlanDetail(plan.id);
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
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DuaPlanCreateScreen(editPlan: detail)),
    );
    await cubit.load();
  }

  Future<bool?> _confirmDelete(BuildContext context) =>
      showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const _DeletePlanSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final colors = [
      const Color(0xFFFFD9E7),
      const Color(0xFFFFE4A5),
      const Color(0xFFB9EDFF),
      const Color(0xFFD2F6A6),
    ];
    final cardColor = colors[(serial - 1) % colors.length];
    return InkWell(
      borderRadius: BorderRadius.circular(22.r),
      onTap: () => Navigator.of(
        context,
      ).pushNamed(RouteNames.duaPlanDetail, arguments: DuaPlanDetailArgs(plan)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: .45),
              blurRadius: 12.r,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46.r,
              height: 46.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .7),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: const Color(0xFFA7B45B),
                size: 25.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 15.sp,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                      color: context.textInkColor(const Color(0xFF2C3320)),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${context.localizedDigits('${plan.completedDuas}/${plan.totalDuas}')} '
                    '${appText.duaTotalDuaLabel.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textInkColor(const Color(0xFFD45D78)),
                    ),
                  ),
                  if (plan.startDate.isNotEmpty || plan.endDate.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Text(
                      [
                        if (plan.startDate.isNotEmpty)
                          '${context.localized(const LocalizedText(en: 'Start', bn: 'শুরু'))}: ${_dateLabel(context, plan.startDate)}',
                        if (plan.endDate.isNotEmpty)
                          '${context.localized(const LocalizedText(en: 'End', bn: 'শেষ'))}: ${_dateLabel(context, plan.endDate)}',
                      ].join('  •  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        color: context.textInkColor(const Color(0xFF6F6F6F)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => _menu(context),
              constraints: BoxConstraints.tightFor(width: 32.r, height: 32.r),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .34),
              ),
              icon: Icon(
                Icons.more_vert_rounded,
                size: 19.sp,
                color: context.textInkColor(const Color(0xFF8B8B8B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class _PlannerCalendar extends StatelessWidget {
  const _PlannerCalendar({required this.totalLabel});

  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDay = today.subtract(const Duration(days: 3));
    final localizations = MaterialLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  localizations.formatMonthYear(today),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: context.textInkColor(const Color(0xFF202020)),
                  ),
                ),
              ),
              _CalendarArrow(icon: Icons.chevron_left_rounded),
              SizedBox(width: 7.w),
              _CalendarArrow(icon: Icons.chevron_right_rounded),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              for (var index = 0; index < 7; index++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: _PlannerDay(
                      date: firstDay.add(Duration(days: index)),
                      selected: firstDay.add(Duration(days: index)) == today,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 14.h, left: 2.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    totalLabel,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textInkColor(const Color(0xFF303030)),
                    ),
                  ),
                ),
                Container(
                  width: 31.r,
                  height: 31.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8E6),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    size: 19.sp,
                    color: const Color(0xFFA7B45B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarArrow extends StatelessWidget {
  const _CalendarArrow({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 30.r,
    height: 30.r,
    decoration: const BoxDecoration(
      color: Color(0xFFF2F7E2),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 19.sp, color: const Color(0xFFA7B45B)),
  );
}

class _PlannerDay extends StatelessWidget {
  const _PlannerDay({required this.date, required this.selected});

  final DateTime date;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(vertical: 7.h),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFDDEAB6)
            : context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFEAF0D4)),
      ),
      child: Column(
        children: [
          Text(
            localizations.narrowWeekdays[date.weekday % 7],
            style: TextStyle(fontSize: 9.sp, color: const Color(0xFF9CA66A)),
          ),
          SizedBox(height: 3.h),
          Text(
            context.localizedDigits('${date.day}'),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: context.textInkColor(const Color(0xFF585E3D)),
            ),
          ),
          const Spacer(),
          Container(
            width: 4.r,
            height: 4.r,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF9DC73B)
                  : const Color(0xFFDFE2D8),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerTabs extends StatelessWidget {
  const _PlannerTabs({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(18.r),
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
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22.r),
      child: Container(
        height: 42.h,
        alignment: Alignment.center,
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFA7B45B) : Colors.transparent,
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : context.textInkColor(const Color(0xFF303629)),
          ),
        ),
      ),
    );
  }
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
