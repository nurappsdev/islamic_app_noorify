import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/zikr/data/zikr_catalog.dart';
import 'package:tuhfatul_muslim/features/zikr/data/zikr_plan_model.dart';
import 'package:tuhfatul_muslim/features/zikr/data/zikr_planner_store.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/zikr_localized_name.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/zikr_route_args.dart';

/// Plan detail — reached by tapping a plan on [ZikrPlannerScreen] ("My Plan",
/// "Search Plan" or "Complete Plan").
///
/// Shows the plan's zikr and their progress, read live from
/// [ZikrPlannerStore]. Tapping a zikr (or "Get start" for the whole plan)
/// opens the existing [ZikrCounterScreen] — every tap there persists back to
/// this plan via its `plan:<planId>:<index>` tracking key, so progress here
/// updates immediately and survives navigation and app restart.
class ZikrPlanDetailScreen extends StatelessWidget {
  const ZikrPlanDetailScreen({super.key, required this.planId});

  final String planId;

  void _openEntry(BuildContext context, ZikrPlanModel plan, int index) {
    final appText = AppText.of(context);
    final entry = plan.items[index];
    Navigator.of(context).pushNamed(
      RouteNames.zikrCounter,
      arguments: ZikrCounterArgs(
        title: localizedSeedZikrName(appText, entry.nameKey) ?? entry.name,
        items: [_itemFor(appText, entry, planId, index)],
      ),
    );
  }

  void _openAll(BuildContext context, ZikrPlanModel plan) {
    final appText = AppText.of(context);
    Navigator.of(context).pushNamed(
      RouteNames.zikrCounter,
      arguments: ZikrCounterArgs(
        title: plan.name,
        items: [
          for (var i = 0; i < plan.items.length; i++)
            _itemFor(appText, plan.items[i], planId, i),
        ],
      ),
    );
  }

  static ZikrItem _itemFor(
    AppText appText,
    PlanZikrItem entry,
    String planId,
    int index,
  ) => ZikrItem(
    name: localizedSeedZikrName(appText, entry.nameKey) ?? entry.name,
    arabic: '',
    transliteration: entry.name,
    target: entry.target,
    trackingKey: 'plan:$planId:$index',
  );

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: ValueListenableBuilder<List<ZikrPlanModel>>(
          valueListenable: ZikrPlannerStore.instance,
          builder: (context, _, _) {
            final plan = ZikrPlannerStore.instance.byId(planId);
            if (plan == null) {
              return Column(
                children: [
                  _Header(title: appText.myPlan),
                  const Spacer(),
                  Center(child: Text(appText.noPlansYetMessage)),
                  const Spacer(),
                ],
              );
            }

            return Column(
              children: [
                _Header(title: plan.name),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.localizedDigits(
                                '${plan.durationDays} '
                                '${appText.zikrPlanDays}',
                              ),
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: context.inkColor(Color(0xFF9AA579)),
                              ),
                            ),
                          ),
                          if (plan.completed)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: context.surfaceColor(Color(0xFFDDE8BA)),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Text(
                                appText.zikrPlanComplete,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFA1AD59),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        context.localizedDigits(
                          '${plan.totalDone}/${plan.totalTarget}',
                        ),
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: context.inkColor(Color(0xFF2C3320)),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      for (var i = 0; i < plan.items.length; i++) ...[
                        _PlanDetailEntryRow(
                          entry: plan.items[i],
                          appText: appText,
                          onTap: () => _openEntry(context, plan, i),
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54.h,
                    child: FilledButton(
                      onPressed: plan.items.isEmpty
                          ? null
                          : () => _openAll(context, plan),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                      ),
                      child: Text(
                        appText.zikrGetStart,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFCBD16B),
                  foregroundColor: context.inkColor(Color(0xFF303629)),
                  minimumSize: Size(38.r, 38.r),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
              ),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.inkColor(AppColor.authLogo),
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanDetailEntryRow extends StatelessWidget {
  const _PlanDetailEntryRow({
    required this.entry,
    required this.appText,
    required this.onTap,
  });

  final PlanZikrItem entry;
  final AppText appText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = localizedSeedZikrName(appText, entry.nameKey) ?? entry.name;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(color: context.lineColor(Color(0xFFDDE3C6))),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          children: [
            Container(
              width: 34.r,
              height: 34.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.lineColor(Color(0xFFCBD9AF))),
              ),
              child: entry.isDone
                  ? Icon(
                      Icons.check_rounded,
                      size: 18.sp,
                      color: context.inkColor(Color(0xFF6E8B3D)),
                    )
                  : Icon(
                      Icons.self_improvement_rounded,
                      size: 18.sp,
                      color: context.inkColor(Color(0xFF6E8B3D)),
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: context.inkColor(Color(0xFF3D3170)),
                ),
              ),
            ),
            Text(
              context.localizedDigits('${entry.currentCount}/${entry.target}'),
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9AA579)),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.chevron_right_rounded,
              size: 18.sp,
              color: context.inkColor(Color(0xFF9BA85B)),
            ),
          ],
        ),
      ),
    );
  }
}
