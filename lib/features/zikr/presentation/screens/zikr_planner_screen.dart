import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/zikr/presentation/widgets/zikr_bottom_nav.dart';

/// Zikr planner (design `devImg/img_20.png`), reached from index 1 ("Planner")
/// of [ZikrBottomNav].
///
/// UI only. Every tab starts empty; "Create Plan" opens the New Zikr flow.
class ZikrPlannerScreen extends StatefulWidget {
  const ZikrPlannerScreen({super.key});

  @override
  State<ZikrPlannerScreen> createState() => _ZikrPlannerScreenState();
}

class _ZikrPlannerScreenState extends State<ZikrPlannerScreen> {
  int _tab = 0; // 0 = My Plan, 1 = Search Plan, 2 = Complete Plan

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 6.h),
                _PlannerTabs(
                  labels: [
                    appText.myPlan,
                    appText.searchPlan,
                    appText.completePlan,
                  ],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                if (_tab == 1) ...[
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: appText.searchPlan,
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: const BorderSide(color: Color(0xFFDDE8C1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: const BorderSide(color: AppColor.primary),
                        ),
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, -20.h),
                      child: _EmptyPlans(message: appText.noPlansYetMessage),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 24.w,
              bottom: 78.h + bottomInset,
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(RouteNames.zikrCreate),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9AAA63),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
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
                child: ZikrBottomNav(selectedIndex: 1),
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
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFDDE8C1)),
        ),
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
      child: Container(
        height: 42.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF9AAA63) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDDE8BA) : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF303629),
            ),
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
  Widget build(BuildContext context) {
    return Column(
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
                    color: const Color(0xFF84945F),
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                top: 16.h,
                left: 4.w,
                child: Icon(
                  Icons.wb_sunny_outlined,
                  color: const Color(0xFF84945F),
                  size: 24.sp,
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
            color: const Color(0xFF5B9BD5),
            fontSize: 13.sp,
            height: 1.4,
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFF5B9BD5),
          ),
        ),
      ],
    );
  }
}
