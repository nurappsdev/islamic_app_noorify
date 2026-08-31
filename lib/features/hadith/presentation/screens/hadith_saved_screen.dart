import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_book_catalog.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_bookmark_store.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_bottom_nav.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// "Saved Hadith" list, reached from index 2 ("Saved") of the Hadith navigation
/// bar. Shows every hadith the user has bookmarked from the reader.
class HadithSavedScreen extends StatefulWidget {
  const HadithSavedScreen({super.key});

  @override
  State<HadithSavedScreen> createState() => _HadithSavedScreenState();
}

class _HadithSavedScreenState extends State<HadithSavedScreen> {
  final _store = HadithBookmarkStore();
  final _searchController = TextEditingController();

  List<HadithBookmark> _bookmarks = const [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim().toLowerCase()),
    );
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _store.all();
    if (mounted) {
      setState(() {
        _bookmarks = items;
        _loading = false;
      });
    }
  }

  Future<void> _remove(HadithBookmark bookmark) async {
    await _store.remove(bookmark.bookSlug, bookmark.hadithNo);
    await _load();
  }

  Future<void> _open(HadithBookmark bookmark) async {
    await Navigator.of(context).pushNamed(
      RouteNames.hadithBookReader,
      arguments: bookmark.bookSlug,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final isBangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;

    final visible = _query.isEmpty
        ? _bookmarks
        : _bookmarks.where((b) {
            final book = HadithBookCatalog.bySlug(b.bookSlug);
            final haystack = [
              b.displayTitle,
              b.titleAr,
              b.titleBn,
              if (book != null) book.titleEn,
              if (book != null) book.titleBn,
              'hadith ${b.hadithNo}',
            ].join(' ').toLowerCase();
            return haystack.contains(_query);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 6.h),
                _Header(title: appText.savedHadithTitle),
                SizedBox(height: 18.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _SearchField(
                    controller: _searchController,
                    hint: appText.searchHere,
                  ),
                ),
                SizedBox(height: 14.h),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColor.primary,
                          ),
                        )
                      : visible.isEmpty
                      ? _EmptyState(
                          message: _bookmarks.isEmpty
                              ? appText.noSavedHadithMessage
                              : appText.noResultsFound,
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 96.h),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final bookmark = visible[index];
                            final book = HadithBookCatalog.bySlug(
                              bookmark.bookSlug,
                            );
                            final bookTitle = book == null
                                ? ''
                                : (isBangla ? book.titleBn : book.titleEn);
                            return _SavedHadithCard(
                              bookmark: bookmark,
                              bookTitle: bookTitle,
                              hadithNoLabel: appText.hadithNoLabel,
                              onTap: () => _open(bookmark),
                              onRemove: () => _remove(bookmark),
                            );
                          },
                        ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: HadithBottomNav(selectedIndex: 2),
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 14.w),
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
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColor.authLogo,
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 13.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColor.authHint, fontSize: 13.sp),
        isDense: true,
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18.sp,
          color: AppColor.authHint,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.r),
          borderSide: const BorderSide(color: Color(0xFFE3E7D3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.r),
          borderSide: const BorderSide(color: AppColor.primary),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 64.sp,
            color: const Color(0xFFCBD16B),
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF989898),
              fontSize: 13.sp,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedHadithCard extends StatelessWidget {
  const _SavedHadithCard({
    required this.bookmark,
    required this.bookTitle,
    required this.hadithNoLabel,
    required this.onTap,
    required this.onRemove,
  });

  final HadithBookmark bookmark;
  final String bookTitle;
  final String hadithNoLabel;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (bookTitle.isNotEmpty) bookTitle,
      '$hadithNoLabel : ${bookmark.hadithNo}',
    ].join('  ·  ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          height: 76.h,
          padding: EdgeInsets.fromLTRB(12.w, 0, 6.w, 0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE3E7D3)),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF9BAE6C),
                ),
                child: Text(
                  '${bookmark.hadithNo}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookmark.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF2C3320),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFA1AD59),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.bookmark_rounded,
                  size: 20.sp,
                  color: const Color(0xFF8B9A4B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
