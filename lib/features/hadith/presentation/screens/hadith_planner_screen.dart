import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_bottom_nav.dart';

/// Hadith reading planner, reached from index 1 ("Planner") of the Hadith
/// navigation bar.
///
/// "My Plan" starts empty (see [_EmptyPlans]); the "Create Plan" action adds a
/// mock plan so the populated list state is reachable. "Complete Plan" shows a
/// static list of finished plans.
class HadithPlannerScreen extends StatefulWidget {
  const HadithPlannerScreen({super.key});

  @override
  State<HadithPlannerScreen> createState() => _HadithPlannerScreenState();
}

class _HadithPlannerScreenState extends State<HadithPlannerScreen> {
  bool _showCompletedPlans = false;
  final List<_HadithPlan> _myPlans = [];

  static const _hadithCounts = [7, 19, 12, 25];

  static const _completedPlans = <_HadithPlan>[
    _HadithPlan(title: 'Plan 1', hadithCount: 7),
    _HadithPlan(title: 'Plan 2', hadithCount: 19),
  ];

  Future<void> _createPlan() async {
    final result = await Navigator.of(
      context,
    ).pushNamed(RouteNames.hadithCreatePlan);
    if (!mounted || result is! String) return;
    final name = result.trim();
    final next = _myPlans.length + 1;
    setState(() {
      _myPlans.add(
        _HadithPlan(
          title: name.isEmpty ? 'Plan $next' : name,
          hadithCount: _hadithCounts[(next - 1) % _hadithCounts.length],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
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
                      : _myPlans.isEmpty
                      ? Transform.translate(
                          offset: Offset(0, -34.h),
                          child: const _EmptyPlans(),
                        )
                      : _PlanList(
                          plans: _myPlans,
                          trailingBuilder: (_) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton(
                                onPressed: () {},
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFDDE8BA),
                                  foregroundColor: const Color(0xFF303629),
                                  minimumSize: Size(89.w, 36.h),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                                child: Text(
                                  appText.getStart,
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Icons.more_vert_rounded,
                                color: Colors.black,
                                size: 20.sp,
                              ),
                            ],
                          ),
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
                right: 58.w,
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

class _HadithPlan {
  const _HadithPlan({required this.title, required this.hadithCount});

  final String title;
  final int hadithCount;
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
                      color: const Color(0xFFDDE8C1),
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
            color: selected ? const Color(0xFFDDE8BA) : Colors.transparent,
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
                      color: const Color(0xFF84945F),
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
                    color: const Color(0xFF84945F),
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
  const _PlanList({required this.plans, required this.trailingBuilder});

  final List<_HadithPlan> plans;
  final Widget Function(_HadithPlan plan) trailingBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 96.h),
      itemCount: plans.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) => _PlanCard(
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
        border: Border.all(color: const Color(0xFFDDE8C1)),
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
                  style: TextStyle(
                    color: const Color(0xFF332B57),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 7.h),
                Text(
                  '${plan.hadithCount} ${appText.categoryHadith}',
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
        color: const Color(0xFFDDE8BA),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        Icons.menu_book_outlined,
        color: const Color(0xFF5F6E3E),
        size: 24.sp,
      ),
    );
  }
}
