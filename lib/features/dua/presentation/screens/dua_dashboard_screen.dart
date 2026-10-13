import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_home_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bottom_nav.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_category_tile.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_featured_card.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_page_header.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_status_view.dart';

/// Dua dashboard (design `devImg/img_4.png`) — reached from "Let's Get Start"
/// on [DuaIntroScreen].
///
/// Shows a Featured Dua row (`GET /duas/featured`) and a preview of the Dua
/// categories grid (`GET /duas/categories`); both sections' "See All" open
/// the full lists on [DuaFeaturedScreen] / [DuaAllCategoryScreen].
class DuaDashboardScreen extends StatelessWidget {
  const DuaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DuaHomeCubit(duaRepository)..load(),
      child: const _DuaDashboardView(),
    );
  }
}

class _DuaDashboardView extends StatelessWidget {
  const _DuaDashboardView();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: Stack(
        children: [
          BlocBuilder<DuaHomeCubit, DuaHomeState>(
            builder: (context, state) {
              if (state.status == DuaLoadStatus.loading ||
                  state.status == DuaLoadStatus.initial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == DuaLoadStatus.failure) {
                return DuaErrorRetry(
                  message: state.error ?? '',
                  onRetry: () => context.read<DuaHomeCubit>().load(),
                );
              }

              final featured = state.featured;
              final dashboardCategories = state.categories.take(6).toList();

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  0,
                  16.w,
                  150.h + bottomInset,
                ),
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
                  if (featured.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Text(
                        appText.noResultsFound,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: context.inkColor(Color(0xFF5D6B44)),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 150.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        separatorBuilder: (_, _) => SizedBox(width: 12.w),
                        itemBuilder: (context, index) => SizedBox(
                          width: 250.w,
                          child: DuaFeaturedCard(
                            featured: featured[index],
                            onExplore: () => Navigator.of(context).pushNamed(
                              RouteNames.duaReader,
                              arguments: DuaReaderArgs.real(featured[index]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 22.h),
                  _SectionHeader(
                    title: appText.duaCategoryTitle,
                    onSeeAll: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.duaAllCategory),
                  ),
                  SizedBox(height: 12.h),
                  if (dashboardCategories.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Text(
                        appText.noResultsFound,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: context.inkColor(Color(0xFF5D6B44)),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dashboardCategories.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisExtent: 96.h,
                        crossAxisSpacing: 10.w,
                        mainAxisSpacing: 10.h,
                      ),
                      itemBuilder: (context, index) =>
                          DuaCategoryTile(category: dashboardCategories[index]),
                    ),
                ],
              );
            },
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
