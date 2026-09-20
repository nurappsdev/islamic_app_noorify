import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/dua/data/dua_catalog.dart';
import 'package:islami_app_noorify/features/dua/presentation/dua_route_args.dart';
import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_bottom_nav.dart';
import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_item_tile.dart';

/// Dua group detail (design `devImg/img_4.png`), reached by tapping
/// "Explore" on a [DuaFeatured] card (the dashboard row or
/// [DuaFeaturedScreen]).
///
/// UI only: the "Last read" pill and the "All dua" list are mock data from
/// [DuaCatalog].
class DuaGroupScreen extends StatelessWidget {
  const DuaGroupScreen({super.key, required this.featured});

  final DuaFeatured featured;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final duas = DuaCatalog.groupDuas;

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: 150.h + bottomInset),
            children: [
              _GroupHeader(featured: featured, appText: appText),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appText.duaAllDuaTitle,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pushNamed(
                        RouteNames.duaGroupAllDua,
                        arguments: featured,
                      ),
                      child: Text(
                        appText.seeAll,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.inkColor(Color(0xFF6B7A4A)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    for (var i = 0; i < duas.length; i++) ...[
                      DuaItemTile(
                        name: duas[i].name,
                        onTap: () => Navigator.of(context).pushNamed(
                          RouteNames.duaReader,
                          arguments: DuaReaderArgs(
                            featured: featured,
                            detail: duas[i],
                          ),
                        ),
                      ),
                      if (i != duas.length - 1) SizedBox(height: 10.h),
                    ],
                  ],
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

/// Green gradient header: back button + title, Bismillah, the group's name
/// and dua count, and the mock "Last read" pill.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.featured, required this.appText});

  final DuaFeatured featured;
  final AppText appText;

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
                          backgroundColor: context.surfaceColor(
                            Color(0xFFEDE7A6),
                          ),
                          foregroundColor: context.inkColor(AppColor.authLogo),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                        ),
                      ),
                    ),
                    Text(
                      featured.groupLabel,
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
                featured.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '${featured.totalDua}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16.h),
              _LastReadPill(appText: appText),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastReadPill extends StatelessWidget {
  const _LastReadPill({required this.appText});

  final AppText appText;

  @override
  Widget build(BuildContext context) {
    final index = DuaCatalog.mockLastReadIndex.toString().padLeft(2, '0');
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 8.w, 8.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.lineColor(Colors.white.withValues(alpha: .55)),
        ),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${appText.duaLastRead} :  ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
          Text(
            'Dua ( $index )',
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
          ),
          SizedBox(width: 8.w),
          Container(
            width: 26.r,
            height: 26.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.lineColor(Colors.white.withValues(alpha: .7)),
              ),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
        ],
      ),
    );
  }
}
