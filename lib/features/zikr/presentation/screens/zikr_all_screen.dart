import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/zikr/data/zikr_catalog.dart';
import 'package:islami_app_noorify/features/zikr/presentation/widgets/zikr_bottom_nav.dart';
import 'package:islami_app_noorify/features/zikr/presentation/zikr_route_args.dart';

/// Browse-all list for the Zikr flow, reached from the grid icon in
/// [ZikrBottomNav]. Tapping a zikr opens [ZikrCounterScreen].
class ZikrAllScreen extends StatelessWidget {
  const ZikrAllScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 92.h + bottomInset),
            children: [
              SizedBox(height: 6.h),
              SizedBox(
                height: 44.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
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
                    Text(
                      appText.zikrAllTitle,
                      style: TextStyle(
                        color: AppColor.authLogo,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              for (final item in ZikrCatalog.all) ...[
                _ZikrTile(
                  item: item,
                  onTap: () => Navigator.of(context).pushNamed(
                    RouteNames.zikrCounter,
                    arguments: ZikrCounterArgs.fromItem(item),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
            ],
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
    );
  }
}

class _ZikrTile extends StatelessWidget {
  const _ZikrTile({required this.item, required this.onTap});

  final ZikrItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 12.w, 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9EF),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE3E7D3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.arabic,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: const Color(0xFF283016),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    item.transliteration,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF5D6B44),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFECF0DC),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${item.target}x',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4C5A34),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF9BA85B),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
