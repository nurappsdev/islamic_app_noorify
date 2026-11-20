import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_category_duas_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_item_tile.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_page_header.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_shimmer.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_status_view.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';

/// API-backed list for a category selected from the Dua dashboard or the full
/// category screen. Its layout follows `devImg/img_6.png`.
class DuaCategoryDuasScreen extends StatelessWidget {
  const DuaCategoryDuasScreen({super.key, required this.category});

  final DuaCategoryModel category;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => DuaCategoryDuasCubit(duaRepository)..load(category),
    child: _DuaCategoryDuasView(category: category),
  );
}

class _DuaCategoryDuasView extends StatefulWidget {
  const _DuaCategoryDuasView({required this.category});

  final DuaCategoryModel category;

  @override
  State<_DuaCategoryDuasView> createState() => _DuaCategoryDuasViewState();
}

class _DuaCategoryDuasViewState extends State<_DuaCategoryDuasView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreIfNeeded);
  }

  void _loadMoreIfNeeded() {
    if (_scrollController.position.extentAfter > 280) return;
    context.read<DuaCategoryDuasCubit>().loadMore(widget.category);
  }

  void _onSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<DuaCategoryDuasCubit>().load(
        widget.category,
        searchTerm: value,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: BlocBuilder<DuaCategoryDuasCubit, DuaCategoryDuasState>(
          builder: (context, state) {
            if (state.status == DuaCategoryDuasStatus.initial ||
                state.status == DuaCategoryDuasStatus.loading) {
              return const DuaListShimmer();
            }
            if (state.status == DuaCategoryDuasStatus.failure) {
              return DuaErrorRetry(
                message: state.error ?? '',
                onRetry: () =>
                    context.read<DuaCategoryDuasCubit>().load(widget.category),
              );
            }

            final duas = state.duas;
            final total = state.total == 0 ? state.duas.length : state.total;
            return ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
              children: [
                SizedBox(height: 6.h),
                DuaPageHeader(title: appText.duaAllDuaTitle),
                SizedBox(height: 16.h),
                Text(
                  context.localizedDigits(
                    '${appText.duaTotalDuaLabel} ( $total )',
                  ),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: context.inkColor(const Color(0xFF5D6B44)),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: appText.searchHere,
                    hintStyle: TextStyle(
                      color: AppColor.authHint,
                      fontSize: 13.sp,
                    ),
                    filled: true,
                    fillColor: context.surfaceColor(Colors.white),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: _searchBorder(context),
                    enabledBorder: _searchBorder(context),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: const BorderSide(color: AppColor.primary),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                if (duas.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 24.h),
                    child: Text(
                      appText.noResultsFound,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: context.inkColor(const Color(0xFF5D6B44)),
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < duas.length; i++) ...[
                    DuaItemTile(
                      index: i,
                      name: context.localized(duas[i].title),
                      subtitle: context.localized(duas[i].translation),
                      onTap: () => Navigator.of(context).pushNamed(
                        RouteNames.duaReader,
                        arguments: DuaReaderArgs.real(duas[i]),
                      ),
                    ),
                    if (i != duas.length - 1) SizedBox(height: 10.h),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  OutlineInputBorder _searchBorder(BuildContext context) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(24.r),
    borderSide: BorderSide(color: context.lineColor(AppColor.authFieldBorder)),
  );
}
