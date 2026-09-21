import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/ebook.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_last_read.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_ebooks.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_last_read.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_library_books.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/ebooks/ebooks_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_last_read/hadith_last_read_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_library/hadith_library_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/ebook_detail_screen.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_detail_screen.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/ebook_cover.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_bottom_nav.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';
import 'package:shimmer/shimmer.dart';

/// Hadith library landing screen.
///
/// Reached from the "Let's Get Start" button on [HadithIntroScreen]. Shows a
/// summary header, the collection library and a shelf of e-books.
class HadithLibraryScreen extends StatelessWidget {
  const HadithLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = HadithLibraryRepositoryImpl(
      HadithLibraryRemoteDataSourceImpl(),
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              HadithLibraryBloc(GetHadithLibraryBooks(repository))
                ..add(const LoadHadithLibrary()),
        ),
        BlocProvider(
          create: (_) =>
              EbooksBloc(GetEbooks(repository))..add(const LoadEbooks()),
        ),
        BlocProvider(
          create: (_) =>
              HadithLastReadBloc(GetHadithLastRead(repository))
                ..add(const LoadHadithLastRead()),
        ),
      ],
      child: const _HadithLibraryView(),
    );
  }
}

class _HadithLibraryView extends StatelessWidget {
  const _HadithLibraryView();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: 92.h + bottomInset),
            children: [
              _HadithHeader(appText: appText),
              SizedBox(height: 22.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _SectionTitle(
                  appText.hadithLibrary,
                  onSeeAll: () => Navigator.of(
                    context,
                  ).pushNamed(RouteNames.hadithLibraryList),
                ),
              ),
              SizedBox(height: 14.h),
              _CollectionShelf(appText: appText),
              SizedBox(height: 26.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _SectionTitle(appText.hadithEbook),
              ),
              SizedBox(height: 14.h),
              const _EbookShelf(),
            ],
          ),
          const SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: HadithBottomNav(selectedIndex: 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _HadithHeader extends StatelessWidget {
  const _HadithHeader({required this.appText});

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
          padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 22.h),
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
                      appText.categoryHadith,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Image.asset(
                'assets/images/bismillah.png',
                height: 26.h,
                fit: BoxFit.contain,
                color: Colors.white,
              ),
              SizedBox(height: 16.h),
              Text(
                appText.hadithTotalHadith,
                style: TextStyle(
                  color: context.inkColor(Colors.white.withValues(alpha: .9)),
                  fontSize: 14.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                _headerTotal(context),
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

/// The header's total across every collection the API returned; a dash while
/// loading or if the request failed.
String _headerTotal(BuildContext context) {
  final state = context.watch<HadithLibraryBloc>().state;
  if (state.status != HadithLibraryStatus.success) return '—';
  return formatHadithCount(state.totalHadiths);
}

/// Horizontal shelf of the API-backed hadith collections, with loading,
/// error (retry) and empty states.
/// Height of the collection shelf: just tall enough for a card with a
/// two-line title, so cards have no dead space at the bottom.
double get _collectionShelfHeight => 150.h;

class _CollectionShelf extends StatelessWidget {
  const _CollectionShelf({required this.appText});

  final AppText appText;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HadithLibraryBloc>().state;
    if (state.isLoading) return const _CollectionShelfSkeleton();
    if (state.status == HadithLibraryStatus.failure) {
      return _ShelfMessage(
        message: state.failure?.message ?? '',
        actionLabel: appText.tryAgain,
        onAction: () =>
            context.read<HadithLibraryBloc>().add(const LoadHadithLibrary()),
      );
    }
    if (state.books.isEmpty) {
      return _ShelfMessage(message: appText.hadithBookComingSoon);
    }
    return SizedBox(
      height: _collectionShelfHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: state.books.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (context, index) =>
            _CollectionCard(book: state.books[index], appText: appText),
      ),
    );
  }
}

class _CollectionShelfSkeleton extends StatelessWidget {
  const _CollectionShelfSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _collectionShelfHeight,
      child: Shimmer.fromColors(
        baseColor: context.surfaceColor(Color(0xFFE3ECC5)),
        highlightColor: context.surfaceColor(Color(0xFFF6F9EC)),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: 2,
          separatorBuilder: (_, _) => SizedBox(width: 12.w),
          itemBuilder: (_, _) => Container(
            width: 218.w,
            decoration: BoxDecoration(
              color: context.surfaceColor(Colors.white),
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShelfMessage extends StatelessWidget {
  const _ShelfMessage({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: context.inkColor(Color(0xFF5D6B44)),
            ),
          ),
          if (onAction != null) ...[
            SizedBox(height: 8.h),
            TextButton(onPressed: onAction, child: Text(actionLabel ?? '')),
          ],
        ],
      ),
    );
  }
}

class _LastReadPill extends StatelessWidget {
  const _LastReadPill({required this.appText});

  final AppText appText;

  @override
  Widget build(BuildContext context) {
    final isBangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    final lastRead = context.watch<HadithLastReadBloc>().state.lastRead;
    final label = lastRead == null
        ? '—'
        : '${lastRead.source(bangla: isBangla)} ( ${lastRead.hadithNumber} )';

    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 8.w, 8.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.lineColor(Colors.white.withValues(alpha: .55)),
        ),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        children: [
          Text(
            '${appText.hadithLastRead} :  ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
            ),
          ),
          InkWell(
            onTap: lastRead == null
                ? null
                : () => _openLastRead(context, lastRead, isBangla),
            customBorder: const CircleBorder(),
            child: Container(
              width: 30.r,
              height: 30.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.lineColor(Colors.white.withValues(alpha: .7)),
                ),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the sub-category the last-read hadith belongs to, then refreshes the
/// pill since reading there may have moved the last-read hadith.
Future<void> _openLastRead(
  BuildContext context,
  HadithLastRead lastRead,
  bool isBangla,
) async {
  final bloc = context.read<HadithLastReadBloc>();
  await Navigator.of(context).pushNamed(
    RouteNames.hadithDetail,
    arguments: HadithDetailArgs(
      subCategoryId: lastRead.subCategoryId,
      title: lastRead.subCategoryName(bangla: isBangla),
    ),
  );
  if (!bloc.isClosed) bloc.add(const LoadHadithLastRead());
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        GestureDetector(
          onTap: onSeeAll,
          behavior: HitTestBehavior.opaque,
          child: Text(
            AppText.of(context).seeAll,
            style: TextStyle(
              color: context.inkColor(Colors.black),
              fontSize: 12.sp,
            ),
          ),
        ),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.book, required this.appText});

  final HadithLibraryBook book;
  final AppText appText;

  @override
  Widget build(BuildContext context) {
    final isBangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    final localized = isBangla ? book.titleBn : book.titleEn;
    final title = localized.isEmpty ? book.titleEn : localized;

    return Container(
      width: 218.w,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9F1C4), Color(0xFFD3E2A0)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.lineColor(Color(0xFFC4D68A))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: context.surfaceColor(Colors.white),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 17.sp,
                  color: context.inkColor(Color(0xFF5F7A43)),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => openHadithLibraryBook(context, book),
                iconAlignment: IconAlignment.end,
                icon: Icon(Icons.north_east_rounded, size: 13.sp),
                label: Text(appText.explore),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.inkColor(Color(0xFF4C5A34)),
                  side: BorderSide(color: context.lineColor(Color(0xFF9BAE6C))),
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  minimumSize: Size(0, 30.h),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: TextStyle(fontSize: 12.sp),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
            ],
          ),
          // The title takes whatever height is left, so the button below is
          // always pinned to the bottom edge instead of leaving a gap.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: context.inkColor(Color(0xFF2C3320)),
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => openAllHadithsOfBook(context, book),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F7A43),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                minimumSize: Size(0, 34.h),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${appText.hadithTotalHadith} : ${formatHadithCount(book.totalHadiths)}',
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal shelf of the API-backed e-books (`GET /ebooks`), with loading,
/// error (retry) and empty states. Tapping a book opens its detail screen.
class _EbookShelf extends StatelessWidget {
  const _EbookShelf();

  static double get _height => 208.h;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<EbooksBloc>().state;
    if (state.isLoading) return const _EbookShelfSkeleton();
    if (state.status == EbooksStatus.failure) {
      return _ShelfMessage(
        message: state.failure?.message ?? '',
        actionLabel: appText.tryAgain,
        onAction: () => context.read<EbooksBloc>().add(const LoadEbooks()),
      );
    }
    if (state.ebooks.isEmpty) {
      return _ShelfMessage(message: appText.hadithBookComingSoon);
    }
    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: state.ebooks.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (context, index) => _EbookCard(
          ebook: state.ebooks[index],
          onTap: () => _openEbook(context, state.ebooks[index]),
        ),
      ),
    );
  }
}

/// Opens the e-book's detail screen (where the PDF can be downloaded).
void _openEbook(BuildContext context, Ebook ebook) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => EbookDetailScreen(ebook: ebook)),
  );
}

class _EbookShelfSkeleton extends StatelessWidget {
  const _EbookShelfSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _EbookShelf._height,
      child: Shimmer.fromColors(
        baseColor: context.surfaceColor(const Color(0xFFE3ECC5)),
        highlightColor: context.surfaceColor(const Color(0xFFF6F9EC)),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: 3,
          separatorBuilder: (_, _) => SizedBox(width: 12.w),
          itemBuilder: (_, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 128.w,
                height: 140.h,
                decoration: BoxDecoration(
                  color: context.surfaceColor(Colors.white),
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: 100.w,
                height: 12.h,
                color: context.surfaceColor(Colors.white),
              ),
              SizedBox(height: 6.h),
              Container(
                width: 70.w,
                height: 10.h,
                color: context.surfaceColor(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EbookCard extends StatelessWidget {
  const _EbookCard({required this.ebook, required this.onTap});

  final Ebook ebook;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 128.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                width: 128.w,
                height: 140.h,
                color: context.surfaceColor(const Color(0xFFF0F3E4)),
                child: EbookCover(url: ebook.coverImageUrl),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              ebook.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: context.inkColor(const Color(0xFF2C3320)),
                height: 1.3,
              ),
            ),
            if (ebook.author.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                ebook.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: const Color(0xFF9BA85B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
