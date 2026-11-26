import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_home_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bottom_nav.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_category_tile.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_featured_card.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_page_header.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_responsive.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_shimmer.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_status_view.dart';

/// Dua dashboard (design `devImg/img_4.png`) — reached from "Let's Get Start"
/// on [DuaIntroScreen].
///
/// Shows a Featured Dua row (`GET /duas/featured`) and a preview of the Dua
/// categories grid (`GET /duas/categories`); both sections' "See All" open
/// the full lists on [DuaFeaturedScreen] / [DuaAllCategoryScreen].
class DuaDashboardScreen extends StatelessWidget {
  const DuaDashboardScreen({super.key, this.repository});

  /// Test seam; the app's own [duaRepository] is used when it is left out.
  final DuaRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DuaHomeCubit(repository ?? duaRepository)..load(),
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
          SafeArea(
            bottom: false,
            child: BlocBuilder<DuaHomeCubit, DuaHomeState>(
              builder: (context, state) {
                if (state.status == DuaLoadStatus.loading ||
                    state.status == DuaLoadStatus.initial) {
                  return const DuaDashboardShimmer();
                }
                if (state.status == DuaLoadStatus.failure) {
                  return DuaErrorRetry(
                    message: state.error ?? '',
                    onRetry: () => context.read<DuaHomeCubit>().load(),
                  );
                }

                final featured = state.featured;
                final categories = state.categories;

                return RefreshIndicator(
                  onRefresh: () => context.read<DuaHomeCubit>().load(),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16.w,
                      0,
                      16.w,
                      150.h + bottomInset,
                    ),
                    children: [
                      DuaContentColumn(
                        children: [
                          SizedBox(height: 6.h),
                          DuaPageHeader(
                            title: appText.duaIntroTitle,
                            // Dua Home is the one screen in the feature that
                            // keeps a back action — it is the way out of Dua, to
                            // the app's own Home. The other bottom-nav
                            // destinations are siblings of this one and show
                            // none. The nav replaces routes rather than stacking
                            // them, so a plain pop leaves Dua.
                            onBack: () => Navigator.maybePop(context),
                          ),
                          SizedBox(height: 18.h),
                          _SectionHeader(
                            title: appText.duaFeaturedTitle,
                            onSeeAll: () => Navigator.of(
                              context,
                            ).pushNamed(RouteNames.duaFeatured),
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
                            // The row keeps scrolling horizontally on a browser,
                            // but a 250.w card leaves most of a desktop window
                            // empty, so the cards take a share of the real width
                            // instead - still showing that more follow.
                            DuaWidthBuilder(
                              builder: (context, width, wide) {
                                final cardWidth = wide
                                    ? (width.clamp(0.0, DuaLayout.maxContent) -
                                              60) /
                                          3
                                    : 250.w;
                                return SizedBox(
                                  // `.w`, not `.h`: ScreenUtil scales width and text but not
                                  // height, so a fixed `.h` box kept its phone height while its
                                  // text grew and overflowed on a tablet. The browser has scaling
                                  // off, so both read the same number there.
                                  height: wide ? 168.w : 150.w,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: featured.length,
                                    separatorBuilder: (_, _) =>
                                        SizedBox(width: 12.w),
                                    itemBuilder: (context, index) => SizedBox(
                                      width: cardWidth,
                                      child: DuaFeaturedCard(
                                        featured: featured[index],
                                        onExplore: () =>
                                            Navigator.of(context).pushNamed(
                                              RouteNames.duaReader,
                                              arguments: DuaReaderArgs.real(
                                                featured[index],
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          SizedBox(height: 22.h),
                          _SectionHeader(
                            title: appText.duaCategoryTitle,
                            italic: true,
                            onSeeAll: () => Navigator.of(
                              context,
                            ).pushNamed(RouteNames.duaAllCategory),
                          ),
                          SizedBox(height: 12.h),
                          if (categories.isEmpty)
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
                            // A preview of the full list: two complete rows,
                            // however many columns the window fits, so a wide
                            // browser does not show a half-empty last row.
                            DuaWidthBuilder(
                              builder: (context, width, wide) {
                                final preview = categories
                                    .take(DuaLayout.columns(width) * 2)
                                    .toList();
                                return DuaTileGrid(
                                  itemCount: preview.length,
                                  // `.w`, not `.h`: ScreenUtil scales width and text but not
                                  // height, so a fixed `.h` box kept its phone height while its
                                  // text grew and overflowed on a tablet. The browser has scaling
                                  // off, so both read the same number there.
                                  tileExtent: 150.w,
                                  spacing: 12.w,
                                  runSpacing: 12.h,
                                  itemBuilder: (context, index) =>
                                      DuaCategoryTile(
                                        category: preview[index],
                                        index: index,
                                      ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DuaBottomNav(selectedIndex: 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
    this.italic = false,
  });

  final String title;
  final VoidCallback onSeeAll;

  /// `true` for "Duas Category" — italic serif like the page title and the
  /// featured card's heading (design `devImg/img_16.png`); "Featured Dua"
  /// stays upright.
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Flexible, not fixed: at 320px the title and "See All" together
        // were 9px wider than the row.
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
        SizedBox(width: 8.w),
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
