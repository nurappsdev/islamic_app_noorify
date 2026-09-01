import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/zikr/data/zikr_catalog.dart';

/// Green gradient header shared by the Zikr dashboard and the "New Zikr" screen:
/// back button + centred title, the Bismillah calligraphy, and the (mock)
/// "Total Zikr" count. [trailing] is placed below the count (the dashboard uses
/// it for the "Last Zikr" and "Prayer Zikr" pills).
class ZikrGradientHeader extends StatelessWidget {
  const ZikrGradientHeader({
    super.key,
    required this.title,
    this.trailing,
    this.total,
  });

  final String title;
  final Widget? trailing;

  /// The number shown under "Total Zikr". Defaults to the mock dashboard total.
  final int? total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FA45C), Color(0xFF4F7A43)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 20.h),
          child: Column(
            children: [
              SizedBox(
                height: 40.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEDE7A6),
                          foregroundColor: AppColor.authLogo,
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Image.asset(
                'assets/images/bismillah.png',
                height: 26.h,
                fit: BoxFit.contain,
                color: Colors.white,
              ),
              SizedBox(height: 16.h),
              Text(
                AppText.of(context).zikrTotalZikr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .9),
                  fontSize: 14.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                ZikrCatalog.formatIndian(total ?? ZikrCatalog.mockTotalCount),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (trailing != null) ...[SizedBox(height: 16.h), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
