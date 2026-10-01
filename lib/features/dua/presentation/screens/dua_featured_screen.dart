import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/dua_catalog.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_featured_card.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_page_header.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// Browse-all featured Dua list (design `devImg/img_3.png`), reached from the
/// "Featured Dua" section's "See All" on [DuaDashboardScreen].
class DuaFeaturedScreen extends StatelessWidget {
  const DuaFeaturedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final featured = DuaCatalog.featured;

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          children: [
            SizedBox(height: 6.h),
            DuaPageHeader(title: appText.duaFeaturedTitle),
            SizedBox(height: 16.h),
            Text(
              context.localizedDigits(
                '${appText.duaTotalFeaturedLabel} ( ${featured.length} )',
              ),
              style: TextStyle(
                fontSize: 13.sp,
                color: context.inkColor(Color(0xFF5D6B44)),
              ),
            ),
            SizedBox(height: 14.h),
            for (var i = 0; i < featured.length; i++) ...[
              SizedBox(
                height: 140.h,
                child: DuaFeaturedCard(
                  featured: featured[i],
                  onExplore: () => Navigator.of(
                    context,
                  ).pushNamed(RouteNames.duaGroup, arguments: featured[i]),
                ),
              ),
              if (i != featured.length - 1) SizedBox(height: 12.h),
            ],
          ],
        ),
      ),
    );
  }
}
