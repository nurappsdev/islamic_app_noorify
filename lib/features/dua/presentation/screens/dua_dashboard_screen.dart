import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/dua/data/dua_catalog.dart';
import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_bottom_nav.dart';
import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_category_tile.dart';
import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_featured_card.dart';
import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_page_header.dart';

/// Dua dashboard (design `devImg/img_1.png`) — reached from "Let's Get Start"
/// on [DuaIntroScreen].
///
/// Shows a Featured Dua row and a preview of the Dua categories grid; both
/// sections' "See All" open the full lists on [DuaFeaturedScreen] /
/// [DuaAllCategoryScreen]. UI only: the featured cards and category tiles
/// come from the mock [DuaCatalog].
class DuaDashboardScreen extends StatelessWidget {
  const DuaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 150.h + bottomInset),
            children: [
              SizedBox(height: 6.h),
              DuaPageHeader(title: appText.duaIntroTitle),
              SizedBox(height: 18.h),
              _SectionHeader(
                title: appText.duaFeaturedTitle,
                onSeeAll: () =>
                    Navigator.of(context).pushNamed(RouteNames.duaFeatured),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                height: 150.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: DuaCatalog.featured.length,
                  separatorBuilder: (_, _) => SizedBox(width: 12.w),
                  itemBuilder: (context, index) => SizedBox(
                    width: 250.w,
                    child: DuaFeaturedCard(
                      featured: DuaCatalog.featured[index],
                      onExplore: () => Navigator.of(context).pushNamed(
                        RouteNames.duaGroup,
                        arguments: DuaCatalog.featured[index],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 22.h),
              _SectionHeader(
                title: appText.duaCategoryTitle,
                onSeeAll: () =>
                    Navigator.of(context).pushNamed(RouteNames.duaAllCategory),
              ),
              SizedBox(height: 12.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: DuaCatalog.dashboardCategories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisExtent: 96.h,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                ),
                itemBuilder: (context, index) => DuaCategoryTile(
                  category: DuaCatalog.dashboardCategories[index],
                ),
              ),
            ],
          ),
          const SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DuaBottomNav(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        InkWell(
          onTap: onSeeAll,
          child: Text(
            AppText.of(context).seeAll,
            style: TextStyle(
              fontSize: 12.sp,
              color: context.inkColor(Color(0xFF6B7A4A)),
            ),
          ),
        ),
      ],
    );
  }
}
