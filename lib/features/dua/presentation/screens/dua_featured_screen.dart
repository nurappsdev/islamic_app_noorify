import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_home_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_featured_card.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bottom_nav.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_page_header.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_responsive.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_shimmer.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_status_view.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// Browse-all featured Dua list (design `devImg/img_3.png`), reached from the
/// "Featured Dua" section's "See All" on [DuaDashboardScreen].
class DuaFeaturedScreen extends StatelessWidget {
  const DuaFeaturedScreen({super.key, this.repository});

  /// Test seam; the app's own [duaRepository] is used when it is left out.
  final DuaRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DuaHomeCubit(repository ?? duaRepository)..load(),
      child: const _DuaFeaturedView(),
    );
  }
}

class _DuaFeaturedView extends StatelessWidget {
  const _DuaFeaturedView();

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
                  return const DuaListShimmer(cardHeight: 140);
                }
                if (state.status == DuaLoadStatus.failure) {
                  return DuaErrorRetry(
                    message: state.error ?? '',
                    onRetry: () => context.read<DuaHomeCubit>().load(),
                  );
                }

                final featured = state.featured;
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    0,
                    16.w,
                    96.h + bottomInset,
                  ),
                  children: [
                    DuaContentColumn(
                      children: [
                        SizedBox(height: 6.h),
                        DuaPageHeader(
                          title: appText.duaFeaturedTitle,
                          showBack: false,
                        ),
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
                        if (featured.isEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 24.h),
                            child: Text(
                              appText.noResultsFound,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: context.inkColor(Color(0xFF5D6B44)),
                              ),
                            ),
                          )
                        else
                          // One card per row on a phone; two abreast once the
                          // window is wide, rather than one 1100px-wide card.
                          DuaWidthBuilder(
                            builder: (context, width, wide) {
                              if (!wide) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (
                                      var i = 0;
                                      i < featured.length;
                                      i++
                                    ) ...[
                                      SizedBox(
                                        // `.w`, not `.h`: ScreenUtil scales width and text but not
                                        // height, so a fixed `.h` box kept its phone height while its
                                        // text grew and overflowed on a tablet. The browser has scaling
                                        // off, so both read the same number there.
                                        height: duaScaledExtent(context, 140.w),
                                        child: _card(context, featured[i]),
                                      ),
                                      if (i != featured.length - 1)
                                        SizedBox(height: 12.h),
                                    ],
                                  ],
                                );
                              }
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: featured.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: DuaLayout.listColumns(width),
                                  // ScreenUtil units for the same reason as the phone
                                  // column above: a raw 168 is right on the browser but
                                  // too short on a tablet, where the text scales up. On
                                  // the browser the card's type grew with the window, so
                                  // the row grows by the same factor.
                                  mainAxisExtent: duaScaledExtent(
                                    context,
                                    168.w,
                                  ),
                                  crossAxisSpacing: 16.w,
                                  mainAxisSpacing: 16.w,
                                ),
                                itemBuilder: (context, index) =>
                                    _card(context, featured[index]),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DuaBottomNav(selectedIndex: 1),
            ),
          ),
        ],
      ),
    );
  }

  /// One featured card, used by both the phone column and the wide grid.
  Widget _card(BuildContext context, DuaFeaturedModel featured) =>
      DuaFeaturedCard(
        featured: featured,
        onExplore: () => Navigator.of(context).pushNamed(
          RouteNames.duaReader,
          arguments: DuaReaderArgs.real(featured),
        ),
      );
}
