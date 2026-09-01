import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/zikr/data/zikr_catalog.dart';
import 'package:islami_app_noorify/features/zikr/presentation/widgets/zikr_bottom_nav.dart';
import 'package:islami_app_noorify/features/zikr/presentation/widgets/zikr_gradient_header.dart';
import 'package:islami_app_noorify/features/zikr/presentation/zikr_route_args.dart';

/// Zikr dashboard — the home of the Zikr flow, reached from "Let's Get Start"
/// on [ZikrIntroScreen].
///
/// UI only: the totals and the "My Created Zikr" card are mock data. Tapping a
/// zikr opens [ZikrCounterScreen]; the `+` button opens the "New Zikr" screen.
class ZikrDashboardScreen extends StatelessWidget {
  const ZikrDashboardScreen({super.key});

  void _openCounter(BuildContext context, ZikrCounterArgs args) {
    Navigator.of(context).pushNamed(RouteNames.zikrCounter, arguments: args);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: 150.h + bottomInset),
            children: [
              ZikrGradientHeader(
                title: appText.zikrTitle,
                trailing: Column(
                  children: [
                    _LastZikrPill(
                      appText: appText,
                      onTap: () => _openCounter(
                        context,
                        ZikrCounterArgs.fromItem(ZikrCatalog.mockLastZikr),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        for (
                          var i = 0;
                          i < ZikrCatalog.prayerPresets.length;
                          i++
                        ) ...[
                          if (i > 0) SizedBox(width: 12.w),
                          Expanded(
                            child: _PresetPill(
                              preset: ZikrCatalog.prayerPresets[i],
                              onTap: () => _openCounter(
                                context,
                                ZikrCounterArgs.fromPreset(
                                  ZikrCatalog.prayerPresets[i],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 22.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Text(
                  appText.zikrMyCreatedZikr,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _CreatedZikrCard(
                  preset: ZikrCatalog.createdSample,
                  appText: appText,
                  onOpenItem: (item) =>
                      _openCounter(context, ZikrCounterArgs.fromItem(item)),
                  onGetStart: () => _openCounter(
                    context,
                    ZikrCounterArgs.fromPreset(ZikrCatalog.createdSample),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 24.w,
            bottom: 74.h + bottomInset,
            child: _AddButton(
              onTap: () =>
                  Navigator.of(context).pushNamed(RouteNames.zikrCreate),
            ),
          ),
          const SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ZikrBottomNav(selectedIndex: 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastZikrPill extends StatelessWidget {
  const _LastZikrPill({required this.appText, required this.onTap});

  final AppText appText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 8.h, 8.w, 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: .55)),
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          children: [
            Text(
              '${appText.zikrLastZikr}   ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
            Expanded(
              child: Text(
                ZikrCatalog.mockLastZikr.arabic,
                style: TextStyle(color: Colors.white, fontSize: 15.sp),
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              '${ZikrCatalog.mockLastZikrDone}/'
              '${ZikrCatalog.mockLastZikr.target}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .9),
                fontSize: 12.sp,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 30.r,
              height: 30.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .7)),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({required this.preset, required this.onTap});

  final ZikrPreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 10.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: Colors.white.withValues(alpha: .35)),
            ),
            child: Text(
              preset.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          preset.formula,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .85),
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}

class _CreatedZikrCard extends StatelessWidget {
  const _CreatedZikrCard({
    required this.preset,
    required this.appText,
    required this.onOpenItem,
    required this.onGetStart,
  });

  final ZikrPreset preset;
  final AppText appText;
  final ValueChanged<ZikrItem> onOpenItem;
  final VoidCallback onGetStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE8C4),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFC7D6A6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preset.name,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3C4A28),
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (final item in preset.items)
                InkWell(
                  onTap: () => onOpenItem(item),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 9.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFFCBD9AF)),
                    ),
                    child: Text(
                      item.labelWithTarget,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF3C4A28),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onGetStart,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9AAA63),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: Text(
                appText.zikrGetStart,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF9AAA63),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Icon(Icons.add_rounded, color: Colors.white, size: 26.sp),
        ),
      ),
    );
  }
}
