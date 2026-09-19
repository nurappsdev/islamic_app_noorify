import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_details.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_detail/hadith_detail_bloc.dart';

/// Route arguments for [HadithDetailScreen].
class HadithDetailArgs {
  const HadithDetailArgs({required this.subCategoryId, this.title});

  final String subCategoryId;
  final String? title;
}

/// The hadiths of one sub-category (`GET /hadiths?subCategoryId=...`).
///
/// Reached by tapping a row on [HadithSubCategoryScreen]. Each hadith is a
/// card with its Arabic text, Bangla translation, reference (takhrij), grade
/// and source, paginated with shimmer placeholders.
class HadithDetailScreen extends StatelessWidget {
  const HadithDetailScreen({
    super.key,
    required this.subCategoryId,
    this.subCategoryName,
  });

  final String subCategoryId;
  final String? subCategoryName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HadithDetailBloc(
        GetHadithDetails(
          HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl()),
        ),
      )..add(LoadHadithDetails(subCategoryId)),
      child: _HadithDetailView(
        subCategoryId: subCategoryId,
        title: subCategoryName,
      ),
    );
  }
}

class _HadithDetailView extends StatefulWidget {
  const _HadithDetailView({required this.subCategoryId, this.title});

  final String subCategoryId;
  final String? title;

  @override
  State<_HadithDetailView> createState() => _HadithDetailViewState();
}

class _HadithDetailViewState extends State<_HadithDetailView> {
  /// How close to the end of the list (in logical pixels) the next page
  /// starts loading.
  static const _loadMoreThreshold = 400.0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      // The bloc ignores this while a page is loading or after the last one.
      context.read<HadithDetailBloc>().add(const LoadMoreHadithDetails());
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<HadithDetailBloc>().state;
    // A first page too short to scroll would never fire the scroll listener,
    // so keep pulling pages until the list overflows (or runs out).
    if (state.status == HadithDetailStatus.success &&
        state.hasMore &&
        !state.isLoadingMore &&
        state.loadMoreFailure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        if (_scrollController.position.maxScrollExtent <= 0) {
          context.read<HadithDetailBloc>().add(const LoadMoreHadithDetails());
        }
      });
    }

    final title = (widget.title ?? '').isNotEmpty
        ? widget.title!
        : appText.categoryHadith;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            _Header(title: title),
            SizedBox(height: 12.h),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
                children: [
                  if (state.isLoading)
                    const _HadithSkeletons(count: 2)
                  else if (state.status == HadithDetailStatus.failure) ...[
                    _Message(state.failure?.message ?? ''),
                    TextButton(
                      onPressed: () => context.read<HadithDetailBloc>().add(
                        LoadHadithDetails(widget.subCategoryId),
                      ),
                      child: Text(appText.tryAgain),
                    ),
                  ] else if (state.hadiths.isEmpty)
                    _Message(appText.noResultsFound)
                  else ...[
                    for (final hadith in state.hadiths) ...[
                      _HadithCard(hadith: hadith),
                      SizedBox(height: 14.h),
                    ],
                    if (state.isLoadingMore) const _HadithSkeletons(count: 1),
                    if (state.loadMoreFailure != null) ...[
                      _Message(state.loadMoreFailure!.message),
                      TextButton(
                        onPressed: () => context.read<HadithDetailBloc>().add(
                          const LoadMoreHadithDetails(),
                        ),
                        child: Text(appText.tryAgain),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 14.w, right: 10.w),
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFCBD16B),
                foregroundColor: const Color(0xFF303629),
                minimumSize: Size(38.r, 38.r),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF2C3320),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 40.h),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13.sp, color: const Color(0xFF5D6B44)),
      ),
    );
  }
}

/// Shimmer placeholders shaped like [_HadithCard].
class _HadithSkeletons extends StatelessWidget {
  const _HadithSkeletons({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE3ECC5),
      highlightColor: const Color(0xFFF6F9EC),
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            Container(
              height: 340.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            SizedBox(height: 14.h),
          ],
        ],
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({required this.hadith});

  final HadithDetail hadith;

  static const _ink = Color(0xFF283016);
  static const _muted = Color(0xFF5D6B44);
  static const _tint = Color(0xFFE6EFE3);

  @override
  Widget build(BuildContext context) {
    final grade = hadith.gradeBangla.isNotEmpty
        ? hadith.gradeBangla
        : hadith.grade;
    final source = hadith.sourceBangla.isNotEmpty
        ? hadith.sourceBangla
        : hadith.sourceEnglish;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE3E7D3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF008000),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${hadith.hadithNumber}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (hadith.titleBangla.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                hadith.titleBangla,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ],
            if (hadith.textArabic.isNotEmpty) ...[
              SizedBox(height: 14.h),
              Text(
                hadith.textArabic,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 20.sp, height: 2.0, color: _ink),
              ),
            ],
            if (hadith.narrator.isNotEmpty) ...[
              SizedBox(height: 14.h),
              Text(
                hadith.narrator,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B9A4B),
                ),
              ),
            ],
            if (hadith.textBangla.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                hadith.textBangla,
                style: TextStyle(fontSize: 14.sp, height: 1.7, color: _ink),
              ),
            ],
            if (hadith.takhrij.isNotEmpty) ...[
              SizedBox(height: 14.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: _tint,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFD5E2D0)),
                ),
                child: Text(
                  hadith.takhrij,
                  style: TextStyle(fontSize: 12.5.sp, height: 1.6, color: _ink),
                ),
              ),
            ],
            SizedBox(height: 14.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: _tint,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Wrap(
                spacing: 12.w,
                runSpacing: 8.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (grade.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008000),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        grade,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (source.isNotEmpty) _FooterText(source),
                  if (hadith.authorBangla.isNotEmpty)
                    _FooterText(hadith.authorBangla),
                  if (hadith.sectionNameBangla.isNotEmpty)
                    _FooterText(hadith.sectionNameBangla),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  const _FooterText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.sp,
        height: 1.4,
        color: const Color(0xFF5D6B44),
      ),
    );
  }
}
