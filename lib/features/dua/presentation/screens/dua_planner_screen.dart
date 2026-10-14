import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_planner_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_login_dialog.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_plan_create_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bottom_nav.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_plan_status_badge.dart';

/// Dua planner (design `devImg/img_7.png`), reached from index 2 ("Planner")
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
    // The route is registered via `_page()` (always `Route<void>`, same as
    // every other screen-with-a-result in this app's router), so the result
    // isn't typed here either — the tab reload below doesn't need it.
    await Navigator.of(context).pushNamed(RouteNames.duaPlanCreate);
    if (!mounted) return;
    await _cubit.selectTab(0);
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
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                    icon: Icon(Icons.edit_outlined, size: 18.sp),
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
                    child: DuaBottomNav(selectedIndex: 2),
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
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 96.h),
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
        return _PlanCard(plan: state.plans[index]);
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final DuaPlan plan;

  Future<void> _menu(BuildContext context) async {
    final appText = AppText.readOf(context);
    final action = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(400, 200, 12, 0),
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
    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: () => Navigator.of(
        context,
      ).pushNamed(RouteNames.duaPlanDetail, arguments: DuaPlanDetailArgs(plan)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(color: context.lineColor(const Color(0xFFD5E59B))),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23.r,
              backgroundColor: const Color(0xFFA5B657),
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
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.inkColor(const Color(0xFF2C3320)),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    context.localizedDigits(
                      '${plan.completedDuas}/${plan.totalDuas} '
                      '${appText.duaTotalDuaLabel.toLowerCase()}',
                    ),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFA5B657),
                    ),
                  ),
                ],
              ),
            ),
            // Its own middle column, between the name/progress and the
            // 3-dot menu — not squeezed next to the title.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: DuaPlanStatusBadge(status: plan.status),
            ),
            IconButton(
              onPressed: () => _menu(context),
              icon: Icon(
                Icons.more_vert,
                size: 20.sp,
                color: context.inkColor(const Color(0xFFA5B657)),
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
          style: const TextStyle(color: Color(0xFF8B956D)),
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
            color: context.inkColor(const Color(0xFF879260)),
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
  Widget build(BuildContext context) => Row(
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
  );
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
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 42.h,
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      decoration: BoxDecoration(
        color: context.surfaceColor(
          selected ? const Color(0xFFE1E56A) : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: context.inkColor(const Color(0xFF303629)),
        ),
      ),
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
              color: const Color(0xFFDDE8BA),
              size: 88.sp,
            ),
            Positioned(
              top: 30.h,
              child: Text(
                '?',
                style: TextStyle(
                  color: context.inkColor(const Color(0xFF84945F)),
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
          color: context.inkColor(const Color(0xFF5D6B44)),
          fontSize: 13.sp,
          height: 1.4,
        ),
      ),
    ],
  );
}
