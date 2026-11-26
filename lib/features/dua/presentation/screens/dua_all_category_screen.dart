import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/localization/localization_context.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_home_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_category_tile.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bottom_nav.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_page_header.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_responsive.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_shimmer.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_status_view.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// Browse-all categories for the Dua flow (design `devImg/img_2.png`),
/// reached from the "Duas Category" section's "See All" on
/// [DuaDashboardScreen].
class DuaAllCategoryScreen extends StatelessWidget {
  const DuaAllCategoryScreen({
    super.key,
    this.selectMode = false,
    this.selectedId,
    this.repository,
  });

  /// Test seam; the app's own [duaRepository] is used when it is left out.

  /// When true, tapping a card returns that category to the caller instead
  /// of opening its Dua list. Used by the Create Plan sheet.
  final DuaRepository? repository;

  /// When true, tapping a card returns that category to the caller instead
  /// of opening its Dua list. Used by the Create Plan sheet.
  final bool selectMode;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DuaHomeCubit(repository ?? duaRepository)..load(),
      child: _DuaAllCategoryView(
        selectMode: selectMode,
        selectedId: selectedId,
      ),
    );
  }
}

class _DuaAllCategoryView extends StatefulWidget {
  const _DuaAllCategoryView({
    required this.selectMode,
    required this.selectedId,
  });

  final bool selectMode;
  final String? selectedId;

  @override
  State<_DuaAllCategoryView> createState() => _DuaAllCategoryViewState();
}

class _DuaAllCategoryViewState extends State<_DuaAllCategoryView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DuaCategoryModel> _filtered(
    List<DuaCategoryModel> categories,
    AppLanguage language,
  ) {
    if (_query.isEmpty) return categories;
    final query = _query.toLowerCase();
    return [
      for (final category in categories)
        if (category.name.resolve(language).toLowerCase().contains(query))
          category,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final language = context.appLanguage;
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
                  return const DuaCategoryGridShimmer();
                }
                if (state.status == DuaLoadStatus.failure) {
                  return DuaErrorRetry(
                    message: state.error ?? '',
                    onRetry: () => context.read<DuaHomeCubit>().load(),
                  );
                }

                final categories = state.categories;
                final filtered = _filtered(categories, language);
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    0,
                    16.w,
                    widget.selectMode ? 24.h : 96.h + bottomInset,
                  ),
                  children: [
                    DuaContentColumn(
                      children: [
                        SizedBox(height: 6.h),
                        DuaPageHeader(
                          title: appText.duaAllCategoryTitle,
                          showBack: false,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          context.localizedDigits(
                            '${appText.duaTotalCategoryLabel} ( ${categories.length} )',
                          ),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: context.inkColor(Color(0xFF5D6B44)),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        // A search box as wide as the whole grid reads as a
                        // mistake; it keeps a form's width and sits left, under
                        // the count it filters.
                        _SearchWidth(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _query = value.trim()),
                            decoration: InputDecoration(
                              hintText: appText.duaSearchCategoryHint,
                              hintStyle: TextStyle(
                                color: AppColor.authHint,
                                fontSize: 13.sp,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColor.authIcon,
                              ),
                              filled: true,
                              fillColor: context.surfaceColor(Colors.white),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24.r),
                                borderSide: BorderSide(
                                  color: context.lineColor(
                                    AppColor.authFieldBorder,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24.r),
                                borderSide: BorderSide(
                                  color: context.lineColor(
                                    AppColor.authFieldBorder,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24.r),
                                borderSide: const BorderSide(
                                  color: AppColor.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 18.h),
                        if (filtered.isEmpty)
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
                          DuaTileGrid(
                            itemCount: filtered.length,
                            // `.w`, not `.h`: see the note in the dashboard's
                            // grid - height units do not follow the text's
                            // growth, so a tablet overflowed the tile.
                            tileExtent: 150.w,
                            spacing: 12.w,
                            runSpacing: 12.h,
                            itemBuilder: (context, index) => DuaCategoryTile(
                              category: filtered[index],
                              index: index,
                              selected: widget.selectedId == filtered[index].id,
                              onTap: widget.selectMode
                                  ? () => Navigator.of(
                                      context,
                                    ).pop(filtered[index])
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          if (!widget.selectMode)
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
}

/// Keeps the category search box to a form's width and aligned left, so it
/// does not stretch across a desktop grid.
class _SearchWidth extends StatelessWidget {
  const _SearchWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: DuaLayout.maxForm),
      child: child,
    ),
  );
}
