import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/delete_hadith_plan.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_plans.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/update_hadith_plan.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_plan_actions/hadith_plan_actions_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_plans/hadith_plans_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_detail_screen.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_bottom_nav.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_plan_dialogs.dart';

/// How close to the end of the list (in logical pixels) the next page starts
/// loading.
const _loadMoreThreshold = 240.0;

/// Hadith reading planner, reached from index 1 ("Planner") of the Hadith
/// navigation bar.
///
/// "My Plan" lists the user's plans that are in progress
/// (`GET /hadiths/plans?status=in_progress`), 10 per page, each with its name,
/// hadith count and progress; it starts on [_EmptyPlans] when there are none.
/// "My Complete" lists the same, but with `status=completed`. The "Create
/// Plan" action opens the create form, and "My Plan" reloads when a plan has
/// been created.
///
/// On a plan, "Get Start" opens the plan's hadiths ([HadithDetailScreen]) and
/// the ⋮ menu offers Edit (name and target days, `PATCH`), Delete (`DELETE`,
/// after a confirmation) and Complete (`PATCH {status: "completed"}`, after a
/// confirmation); both lists reload after any of the three, since Complete
/// moves the plan from one to the other.
class HadithPlannerScreen extends StatelessWidget {
  const HadithPlannerScreen({super.key, this.repository});

  /// Where plans come from and go to; the real API unless a test supplies one.
  final HadithLibraryRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repo =
        repository ??
        HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl());
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              HadithPlansBloc(GetHadithPlans(repo), status: 'in_progress')
                ..add(const LoadHadithPlans()),
        ),
        BlocProvider(
          create: (_) => HadithCompletedPlansBloc(GetHadithPlans(repo))
            ..add(const LoadHadithPlans()),
        ),
        BlocProvider(
          create: (_) => HadithPlanActionsBloc(
            UpdateHadithPlan(repo),
            DeleteHadithPlan(repo),
          ),
        ),
      ],
      child: const _HadithPlannerView(),
    );
  }
}

class _HadithPlannerView extends StatefulWidget {
  const _HadithPlannerView();

  @override
  State<_HadithPlannerView> createState() => _HadithPlannerViewState();
}

class _HadithPlannerViewState extends State<_HadithPlannerView> {
  bool _showCompletedPlans = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      // Whichever tab is on screen; the bloc ignores this while a page is
      // loading or after the last one.
      if (_showCompletedPlans) {
        context.read<HadithCompletedPlansBloc>().add(
          const LoadMoreHadithPlans(),
        );
      } else {
        context.read<HadithPlansBloc>().add(const LoadMoreHadithPlans());
      }
    }
  }

  Future<void> _createPlan() async {
    final bloc = context.read<HadithPlansBloc>();
    final result = await Navigator.of(
      context,
    ).pushNamed(RouteNames.hadithCreatePlan);
    // A name comes back when a plan was created: show it in the list.
    if (result is String && !bloc.isClosed) {
      bloc.add(const LoadHadithPlans());
    }
  }

  /// "Get Start": opens the plan's hadiths. The plan's own hadiths endpoint
  /// (`GET /hadiths/plans/{id}/hadiths`) comes back without the hadith
  /// content, so this opens the same book + category through the public
  /// hadiths list instead (`GET /hadiths?bookId=...&categoryId=...`), which
  /// is what the plan was created from. Reading there moves the plan's
  /// progress, so the list reloads when the user comes back.
  Future<void> _openPlan(_HadithPlan plan) async {
    final id = plan.id;
    final bookId = plan.bookId;
    final categoryId = plan.categoryId;
    if (id == null || bookId == null || categoryId == null) return;
    final bloc = context.read<HadithPlansBloc>();
    await Navigator.of(context).pushNamed(
      RouteNames.hadithDetail,
      arguments: HadithDetailArgs(
        bookId: bookId,
        categoryId: categoryId,
        title: plan.title,
      ),
    );
    if (!bloc.isClosed) bloc.add(const LoadHadithPlans());
  }

  /// ⋮ > Edit: asks for the new name and target days, then saves only what
  /// changed (sending the unchanged name back could clash with itself).
  Future<void> _editPlan(_HadithPlan plan) async {
    final id = plan.id;
    if (id == null) return;
    final actions = context.read<HadithPlanActionsBloc>();
    final edit = await showEditPlanDialog(
      context,
      name: plan.title,
      targetDays: plan.targetDays,
    );
    if (edit == null) return;
    final name = edit.name == plan.title ? null : edit.name;
    final days = edit.targetDays == plan.targetDays ? null : edit.targetDays;
    if (name == null && days == null) return;
    actions.add(EditHadithPlanRequested(id, name: name, targetDays: days));
  }

  /// ⋮ > Delete: after a confirmation.
  Future<void> _deletePlan(_HadithPlan plan) async {
    final id = plan.id;
    if (id == null) return;
    final actions = context.read<HadithPlanActionsBloc>();
    final confirmed = await showDeletePlanDialog(context, name: plan.title);
    if (confirmed) actions.add(DeleteHadithPlanRequested(id));
  }

  /// ⋮ > Complete: after a confirmation (`PATCH {status: "completed"}`) — the
  /// plan leaves "My Plan" and shows up under "My Complete".
  Future<void> _completePlan(_HadithPlan plan) async {
    final id = plan.id;
    if (id == null) return;
    final actions = context.read<HadithPlanActionsBloc>();
    final confirmed = await showCompletePlanDialog(context, name: plan.title);
    if (confirmed) actions.add(CompleteHadithPlanRequested(id));
  }

  /// An edit, a delete or a complete has finished: reload both lists on
  /// success (a complete moves the plan between them) and, for a complete,
  /// switch to "My Complete" so the plan is right there; say why on failure
  /// (e.g. "A plan with this name already exists").
  void _onActionResult(BuildContext context, HadithPlanActionsState state) {
    if (state.status == HadithPlanActionStatus.success) {
      context.read<HadithPlansBloc>().add(const LoadHadithPlans());
      context.read<HadithCompletedPlansBloc>().add(const LoadHadithPlans());
      if (state.kind == HadithPlanActionKind.complete) {
        setState(() => _showCompletedPlans = true);
      }
    } else if (state.status == HadithPlanActionStatus.failure) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.failure?.message ?? '')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HadithPlanActionsBloc, HadithPlanActionsState>(
      listener: _onActionResult,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _PlanTabs(
                  showCompletedPlans: _showCompletedPlans,
                  onTabChanged: (value) =>
                      setState(() => _showCompletedPlans = value),
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: _showCompletedPlans
                      ? _CompletedPlans(controller: _scrollController)
                      : _MyPlans(
                          controller: _scrollController,
                          onGetStart: _openPlan,
                          onEdit: _editPlan,
                          onDelete: _deletePlan,
                          onComplete: _completePlan,
                        ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: HadithBottomNav(selectedIndex: 1),
            ),
            if (!_showCompletedPlans)
              Positioned(
                // In line with the right edge of the plan cards (16.w).
                right: 16.w,
                bottom: 104.h,
                child: FilledButton.icon(
                  onPressed: _createPlan,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA1AD59),
                    foregroundColor: Colors.white,
                    minimumSize: Size(127.w, 48.h),
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  icon: Icon(Icons.edit_outlined, size: 20.sp),
                  label: Text(
                    appText.createPlan,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
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

/// The "My Plan" tab: the user's in-progress plans from the API, with loading,
/// error (retry) and empty states. Pages are loaded as the list nears its end.
class _MyPlans extends StatelessWidget {
  const _MyPlans({
    required this.controller,
    required this.onGetStart,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
  });

  final ScrollController controller;

  /// "Get Start" on a plan: open its hadiths.
  final ValueChanged<_HadithPlan> onGetStart;

  /// ⋮ > Edit, ⋮ > Delete and ⋮ > Complete on a plan.
  final ValueChanged<_HadithPlan> onEdit;
  final ValueChanged<_HadithPlan> onDelete;
  final ValueChanged<_HadithPlan> onComplete;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<HadithPlansBloc>().state;

    if (state.isLoading) {
      return const _PlanSkeletonList();
    }
    if (state.status == HadithPlansStatus.failure) {
      return _PlanMessage(
        message: state.failure?.message ?? '',
        actionLabel: appText.tryAgain,
        onAction: () =>
            context.read<HadithPlansBloc>().add(const LoadHadithPlans()),
      );
    }
    if (state.plans.isEmpty) {
      return Transform.translate(
        offset: Offset(0, -34.h),
        child: const _EmptyPlans(),
      );
    }

    // A page too short to scroll (or scrolling less than the load-more
    // distance) would never fire the scroll listener, so keep pulling pages
    // until the list is long enough to scroll on its own (or runs out).
    if (state.hasMore &&
        !state.isLoadingMore &&
        state.loadMoreFailure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || !controller.hasClients) return;
        if (controller.position.maxScrollExtent <= _loadMoreThreshold) {
          context.read<HadithPlansBloc>().add(const LoadMoreHadithPlans());
        }
      });
    }

    return _PlanList(
      controller: controller,
      plans: [
        for (final plan in state.plans)
          _HadithPlan(
            id: plan.id,
            bookId: plan.bookId,
            categoryId: plan.categoryIds.firstOrNull,
            title: plan.name,
            hadithCount: plan.totalHadiths,
            percentage: plan.percentage,
            targetDays: plan.targetDays,
          ),
      ],
      trailingBuilder: (plan) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: () => onGetStart(plan),
            style: FilledButton.styleFrom(
              backgroundColor: context.surfaceColor(Color(0xFFDDE8BA)),
              foregroundColor: context.inkColor(Color(0xFF303629)),
              minimumSize: Size(89.w, 36.h),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(appText.getStart, style: TextStyle(fontSize: 12.sp)),
          ),
          SizedBox(width: 2.w),
          _PlanMenu(
            onEdit: () => onEdit(plan),
            onDelete: () => onDelete(plan),
            onComplete: () => onComplete(plan),
          ),
        ],
      ),
      footer: state.isLoadingMore
          ? const _PlanSkeletons(count: 1)
          : state.loadMoreFailure == null
          ? null
          : _PlanMessage(
              message: state.loadMoreFailure!.message,
              actionLabel: appText.tryAgain,
              onAction: () => context.read<HadithPlansBloc>().add(
                const LoadMoreHadithPlans(),
              ),
            ),
    );
  }
}

/// The "My Complete" tab: the user's completed plans from the API
/// (`status=completed`), with loading, error (retry) and empty states. Pages
/// are loaded as the list nears its end. No ⋮ menu — Edit, Delete and
/// Complete only apply to a plan still in progress.
class _CompletedPlans extends StatelessWidget {
  const _CompletedPlans({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<HadithCompletedPlansBloc>().state;

    if (state.isLoading) {
      return const _PlanSkeletonList();
    }
    if (state.status == HadithPlansStatus.failure) {
      return _PlanMessage(
        message: state.failure?.message ?? '',
        actionLabel: appText.tryAgain,
        onAction: () => context.read<HadithCompletedPlansBloc>().add(
          const LoadHadithPlans(),
        ),
      );
    }
    if (state.plans.isEmpty) {
      return Transform.translate(
        offset: Offset(0, -34.h),
        child: Text(
          appText.noCompletedPlansMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF989898),
            fontSize: 13.sp,
            height: 1.35,
          ),
        ),
      );
    }

    // A page too short to scroll (or scrolling less than the load-more
    // distance) would never fire the scroll listener, so keep pulling pages
    // until the list is long enough to scroll on its own (or runs out).
    if (state.hasMore &&
        !state.isLoadingMore &&
        state.loadMoreFailure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || !controller.hasClients) return;
        if (controller.position.maxScrollExtent <= _loadMoreThreshold) {
          context.read<HadithCompletedPlansBloc>().add(
            const LoadMoreHadithPlans(),
          );
        }
      });
    }

    return _PlanList(
      controller: controller,
      plans: [
        for (final plan in state.plans)
          _HadithPlan(
            id: plan.id,
            title: plan.name,
            hadithCount: plan.totalHadiths,
            percentage: plan.percentage,
            targetDays: plan.targetDays,
          ),
      ],
      trailingBuilder: (_) => Text(
        appText.planStatusComplete,
        style: TextStyle(
          color: const Color(0xFFA1AD59),
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      footer: state.isLoadingMore
          ? const _PlanSkeletons(count: 1)
          : state.loadMoreFailure == null
          ? null
          : _PlanMessage(
              message: state.loadMoreFailure!.message,
              actionLabel: appText.tryAgain,
              onAction: () => context.read<HadithCompletedPlansBloc>().add(
                const LoadMoreHadithPlans(),
              ),
            ),
    );
  }
}

/// The initial-load placeholder for either tab: a scrollable column of
/// [_PlanSkeletons], padded like the real list ([_PlanList]).
class _PlanSkeletonList extends StatelessWidget {
  const _PlanSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 96.h),
      children: const [_PlanSkeletons(count: 5)],
    );
  }
}

/// Shimmer placeholders shaped like [_PlanCard], for the initial load or
/// while paging in more.
class _PlanSkeletons extends StatelessWidget {
  const _PlanSkeletons({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.surfaceColor(const Color(0xFFE3ECC5)),
      highlightColor: context.surfaceColor(const Color(0xFFF6F9EC)),
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(height: 12.h),
            const _PlanCardSkeleton(),
          ],
        ],
      ),
    );
  }
}

class _PlanCardSkeleton extends StatelessWidget {
  const _PlanCardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );

    return Container(
      height: 76.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(21.r),
      ),
      child: Row(
        children: [
          Container(
            width: 47.w,
            height: 47.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(120.w, 12.h),
                SizedBox(height: 10.h),
                bar(80.w, 10.h),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            width: 89.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanMessage extends StatelessWidget {
  const _PlanMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: context.inkColor(const Color(0xFF5D6B44)),
              ),
            ),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

/// A plan as a card shows it. [id] is null for the static "Complete Plan"
/// examples, which aren't real plans and can't be opened or changed.
class _HadithPlan {
  const _HadithPlan({
    required this.title,
    required this.hadithCount,
    this.id,
    this.bookId,
    this.categoryId,
    this.percentage,
    this.targetDays,
  });

  final String? id;
  final String title;
  final int hadithCount;

  /// The book and category "Get Start" opens (`GET
  /// /hadiths?bookId=...&categoryId=...`); null for the static "Complete
  /// Plan" examples, which can't be opened.
  final String? bookId;
  final String? categoryId;

  /// How much of the plan has been read (`0..100`); null when unknown.
  final double? percentage;

  /// Days the user aims to finish in; null when the plan has none.
  final int? targetDays;
}

enum _PlanAction { edit, delete, complete }

/// The ⋮ button of a plan: a menu with Edit, Delete and Complete entries,
/// each with its icon.
class _PlanMenu extends StatelessWidget {
  const _PlanMenu({
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    const deleteColor = Color(0xFFC15B4B);
    const completeColor = Color(0xFF008000);
    return PopupMenuButton<_PlanAction>(
      tooltip: '',
      padding: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      // A narrow, tall touch area instead of the default 48 x 48 icon button,
      // which would squeeze the plan name beside it.
      child: SizedBox(
        width: 24.w,
        height: 48.h,
        child: Icon(
          Icons.more_vert_rounded,
          color: context.inkColor(Colors.black),
          size: 20.sp,
        ),
      ),
      onSelected: (action) => switch (action) {
        _PlanAction.edit => onEdit(),
        _PlanAction.delete => onDelete(),
        _PlanAction.complete => onComplete(),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _PlanAction.edit,
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18.sp,
                color: const Color(0xFF4C5A34),
              ),
              SizedBox(width: 10.w),
              Text(appText.planEdit),
            ],
          ),
        ),
        PopupMenuItem(
          value: _PlanAction.complete,
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 18.sp,
                color: completeColor,
              ),
              SizedBox(width: 10.w),
              Text(
                appText.planComplete,
                style: const TextStyle(color: completeColor),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: _PlanAction.delete,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18.sp,
                color: deleteColor,
              ),
              SizedBox(width: 10.w),
              Text(
                appText.planDelete,
                style: const TextStyle(color: deleteColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanTabs extends StatelessWidget {
  const _PlanTabs({
    required this.showCompletedPlans,
    required this.onTabChanged,
  });

  final bool showCompletedPlans;
  final ValueChanged<bool> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(72.w, 7.h, 72.w, 0),
      child: SizedBox(
        height: 36.h,
        child: Row(
          children: [
            _PlanTab(
              label: appText.myPlan,
              selected: !showCompletedPlans,
              onPressed: () => onTabChanged(false),
            ),
            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 1.h,
                      color: context.surfaceColor(Color(0xFFDDE8C1)),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: _PlanTab(
                      label: appText.completePlan,
                      selected: showCompletedPlans,
                      onPressed: () => onTabChanged(true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTab extends StatelessWidget {
  const _PlanTab({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: 112.w,
          height: 36.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.surfaceColor(
              selected ? const Color(0xFFDDE8BA) : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  const _EmptyPlans();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100.w,
            height: 91.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.sticky_note_2_rounded,
                  color: const Color(0xFFDDE8BA),
                  size: 86.sp,
                ),
                Positioned(
                  top: 27.h,
                  child: Text(
                    '?',
                    style: TextStyle(
                      color: context.inkColor(Color(0xFF84945F)),
                      fontSize: 31.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  top: 18.h,
                  left: 6.w,
                  child: Icon(
                    Icons.wb_sunny_outlined,
                    color: context.inkColor(Color(0xFF84945F)),
                    size: 25.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 13.h),
          Text(
            AppText.of(context).noPlansYetMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF989898),
              fontSize: 13.sp,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({
    required this.plans,
    required this.trailingBuilder,
    this.controller,
    this.footer,
  });

  final List<_HadithPlan> plans;
  final Widget Function(_HadithPlan plan) trailingBuilder;

  /// Lets the screen see how far the list is scrolled, to load more.
  final ScrollController? controller;

  /// An extra row after the last plan (a spinner or a retry), if any.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final extra = footer;
    return ListView.separated(
      controller: controller,
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 96.h),
      itemCount: plans.length + (extra == null ? 0 : 1),
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) => index >= plans.length
          ? extra!
          : _PlanCard(
              plan: plans[index],
              trailing: trailingBuilder(plans[index]),
            ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.trailing});

  final _HadithPlan plan;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      height: 76.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
        borderRadius: BorderRadius.circular(21.r),
      ),
      child: Row(
        children: [
          const _PlanArtwork(),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.inkColor(Color(0xFF332B57)),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 7.h),
                Text(
                  // "46 Hadith", and how much is read: "46 Hadith · 2%".
                  '${formatHadithCount(plan.hadithCount)} '
                  '${appText.categoryHadith}'
                  '${plan.percentage == null ? '' : ' · ${plan.percentage!.round()}%'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF929BB6),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _PlanArtwork extends StatelessWidget {
  const _PlanArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 47.w,
      height: 47.w,
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFDDE8BA)),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        Icons.menu_book_outlined,
        color: context.inkColor(Color(0xFF5F6E3E)),
        size: 24.sp,
      ),
    );
  }
}
