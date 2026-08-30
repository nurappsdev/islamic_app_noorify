import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_book_catalog.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_database.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_book.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// Hadith library landing screen.
///
/// Reached from the "Let's Get Start" button on [HadithIntroScreen]. Shows a
/// summary header, the collection library and a shelf of e-books.
class HadithLibraryScreen extends StatelessWidget {
  const HadithLibraryScreen({super.key});

  static const _collections = <_HadithCollection>[
    _HadithCollection(name: 'Sahih  Bukhari', total: 1327),
    _HadithCollection(name: 'Riadus salehin', total: 761),
    _HadithCollection(name: 'Sahih Muslim', total: 1172),
    _HadithCollection(name: 'Abu Dawud', total: 940),
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Colors.white,
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
              SizedBox(
                height: 150.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _collections.length,
                  separatorBuilder: (_, _) => SizedBox(width: 12.w),
                  itemBuilder: (context, index) => _CollectionCard(
                    collection: _collections[index],
                    appText: appText,
                  ),
                ),
              ),
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
              child: HomeBottomNav(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HadithCollection {
  const _HadithCollection({required this.name, required this.total});

  final String name;
  final int total;
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
                          backgroundColor: const Color(0xFFEDE7A6),
                          foregroundColor: AppColor.authLogo,
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
                  color: Colors.white.withValues(alpha: .9),
                  fontSize: 14.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '1,76,337',
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
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 8.w, 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: .55)),
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
              'Riadus -Salehin ( 71 )',
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
            ),
          ),
          Container(
            width: 30.r,
            height: 30.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .7)),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
        ],
      ),
    );
  }
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
            style: TextStyle(color: Colors.black, fontSize: 12.sp),
          ),
        ),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection, required this.appText});

  final _HadithCollection collection;
  final AppText appText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210.w,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE8AE),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7.r),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF9BAE6C)),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  size: 18.sp,
                  color: const Color(0xFF5F6E3E),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(
                  RouteNames.hadithCategory,
                  arguments: collection.name,
                ),
                iconAlignment: IconAlignment.end,
                icon: Icon(Icons.north_east_rounded, size: 14.sp),
                label: Text(appText.explore),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4C5A34),
                  side: const BorderSide(color: Color(0xFF9BAE6C)),
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  minimumSize: Size(0, 32.h),
                  textStyle: TextStyle(fontSize: 12.sp),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            collection.name,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3320),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${appText.hadithTotalHadith} : ${collection.total}',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF5D6B44),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal shelf of hadith e-books. Tracks which books are already saved on
/// the device so a downloaded book shows an "offline" badge and opens straight
/// into the reader.
class _EbookShelf extends StatefulWidget {
  const _EbookShelf();

  @override
  State<_EbookShelf> createState() => _EbookShelfState();
}

class _EbookShelfState extends State<_EbookShelf> {
  Set<String> _downloaded = const {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final slugs = await HadithDatabase().downloadedSlugs();
    if (mounted) setState(() => _downloaded = slugs);
  }

  Future<void> _open(HadithBook book) async {
    if (!book.isAvailable) {
      final appText = AppText.forLanguage(
        context.read<LanguageBloc>().state.language,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appText.hadithBookComingSoon)),
      );
      return;
    }
    await Navigator.of(
      context,
    ).pushNamed(RouteNames.hadithBookReader, arguments: book.slug);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final books = HadithBookCatalog.all;
    return SizedBox(
      height: 208.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: books.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (context, index) => _EbookCard(
          book: books[index],
          downloaded: _downloaded.contains(books[index].slug),
          onTap: () => _open(books[index]),
        ),
      ),
    );
  }
}

class _EbookCard extends StatelessWidget {
  const _EbookCard({
    required this.book,
    required this.downloaded,
    required this.onTap,
  });

  final HadithBook book;
  final bool downloaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final isBangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    final title = isBangla ? book.titleBn : book.titleEn;

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
              child: Stack(
                children: [
                  Container(
                    width: 128.w,
                    height: 140.h,
                    color: const Color(0xFFF0F3E4),
                    child: Opacity(
                      opacity: book.isAvailable ? 1 : .45,
                      child: Image.asset(
                        'assets/images/book.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6.h,
                    right: 6.w,
                    child: _StatusBadge(
                      book: book,
                      downloaded: downloaded,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C3320),
                height: 1.3,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              book.isAvailable
                  ? '${book.hadithCount} ${appText.categoryHadith}'
                  : appText.hadithBookComingSoon,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.sp,
                color: const Color(0xFF9BA85B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.book, required this.downloaded});

  final HadithBook book;
  final bool downloaded;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color bg) = switch ((book.isAvailable, downloaded)) {
      (false, _) => (Icons.lock_outline_rounded, const Color(0xFF9AA37E)),
      (true, true) => (Icons.check_rounded, const Color(0xFF5F8B3E)),
      (true, false) => (Icons.download_rounded, const Color(0xFF7C8A48)),
    };
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(icon, size: 13.sp, color: Colors.white),
    );
  }
}
