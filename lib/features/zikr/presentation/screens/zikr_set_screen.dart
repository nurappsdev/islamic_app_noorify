import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/zikr/data/zikr_catalog.dart';
import 'package:islami_app_noorify/features/zikr/presentation/zikr_route_args.dart';

/// The zikr set being built (design `devImg/img_16.png`).
///
/// Reached with "Create" from [ZikrCreateScreen]; shows every zikr added so far.
/// "Add More" returns to [ZikrCreateScreen] carrying the current set;
/// "Let's Get Start" opens the counter with the whole sequence.
class ZikrSetScreen extends StatelessWidget {
  const ZikrSetScreen({super.key, required this.items});

  final List<ZikrItem> items;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            SizedBox(
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
                          foregroundColor: const Color(0xFF303629),
                          minimumSize: Size(38.r, 38.r),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    appText.zikrNewTitle,
                    style: TextStyle(
                      color: const Color(0xFF2C3320),
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                children: [
                  for (final item in items) ...[
                    _ZikrRow(item: item),
                    SizedBox(height: 12.h),
                  ],
                  SizedBox(height: 4.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed(
                        RouteNames.zikrCreate,
                        arguments: items,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.authLogo,
                        side: const BorderSide(color: Color(0xFFC7D6A6)),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                      child: Text(
                        appText.zikrAddMore,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h + bottomInset),
              child: SizedBox(
                width: double.infinity,
                height: 54.h,
                child: FilledButton(
                  onPressed: items.isEmpty
                      ? null
                      : () => Navigator.of(context).pushNamed(
                          RouteNames.zikrCounter,
                          arguments: ZikrCounterArgs(
                            title: items.length == 1
                                ? items.first.name
                                : appText.zikrTitle,
                            items: items,
                          ),
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: Text(
                    appText.zikrIntroStartButton,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
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

class _ZikrRow extends StatelessWidget {
  const _ZikrRow({required this.item});

  final ZikrItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7EA),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 15.sp,
                color: const Color(0xFF6B7358),
              ),
            ),
          ),
          Text(
            '(${item.target})',
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF6B7358),
            ),
          ),
        ],
      ),
    );
  }
}
