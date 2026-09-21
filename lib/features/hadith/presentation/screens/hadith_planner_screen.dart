import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_plans.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_plans/hadith_plans_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_bottom_nav.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';

/// How close to the end of the list (in logical pixels) the next page starts
/// loading.
const _loadMoreThreshold = 240.0;

/// Hadith reading planner, reached from index 1 ("Planner") of the Hadith
/// navigation bar.
///
/// "My Plan" lists the user's plans that are in progress
/// (`GET /hadiths/plans?status=in_progress`), 10 per page, each with its name,
/// hadith count and progress; it starts on [_EmptyPlans] when there are none.
/// The "Create Plan" action opens the create form, and the list reloads when
/// a plan has been created. "Complete Plan" still shows a static list.
class HadithPlannerScreen extends StatelessWidget {
  const HadithPlannerScreen({super.key, this.getPlans});

  /// Where the plans come from; the real API unless a test supplies one.
  final GetHadithPlans? getPlans;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HadithPlansBloc(
        getPlans ??
            GetHadithPlans(
              HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl()),
            ),
        status: 'in_progress',
      )..add(const LoadHadithPlans()),
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

  static const _completedPlans = <_HadithPlan>[
    _HadithPlan(title: 'Plan 1', hadithCount: 7),
    _HadithPlan(title: 'Plan 2', hadithCount: 19),
  ];

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
      // The bloc ignores this while a page is loading or after the last one.
      context.read<HadithPlansBloc>().add(const LoadMoreHadithPlans());
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

  @override
  Widget build(BuildContext context) {
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
                      ? _PlanList(
                          plans: _completedPlans,
                          trailingBuilder: (_) => Text(
                            appText.planStatusComplete,
                            style: TextStyle(
                              color: const Color(0xFFA1AD59),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : _MyPlans(controller: _scrollController),
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
  const _MyPlans({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<HadithPlansBloc>().state;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
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
            title: plan.name,
            hadithCount: plan.totalHadiths,
            percentage: plan.percentage,
          ),
      ],
      trailingBuilder: (_) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: () {},
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
          SizedBox(width: 8.w),
          Icon(
            Icons.more_vert_rounded,
            color: context.inkColor(Colors.black),
            size: 20.sp,
          ),
        ],
      ),
      footer: state.isLoadingMore
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: const Center(child: CircularProgressIndicator()),
            )
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

class _HadithPlan {
  const _HadithPlan({
    required this.title,
    required this.hadithCount,
    this.percentage,
  });

  final String title;
  final int hadithCount;

  /// How much of the plan has been read (`0..100`); null when unknown.
  final double? percentage;
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
