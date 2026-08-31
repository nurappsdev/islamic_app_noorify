import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_bookmark_store.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_book.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_bookmark_sheet.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_book_reference.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_entry.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_book/hadith_book_bloc.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// Reads a single hadith e-book.
///
/// On first open the book is parsed from its bundled source file into the local
/// SQLite database ("download"); every later open reads straight from there and
/// works offline. Provided with a [HadithBookBloc] by the route.
///
/// Once downloaded the book is read one hadith per page: swipe right-to-left for
/// the next hadith, left-to-right for the previous one. A right-side drawer
/// lists every hadith and jumps straight to the tapped one.
class HadithBookReaderScreen extends StatefulWidget {
  const HadithBookReaderScreen({super.key, required this.book});

  final HadithBook book;

  @override
  State<HadithBookReaderScreen> createState() => _HadithBookReaderScreenState();
}

class _HadithBookReaderScreenState extends State<HadithBookReaderScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openIndex() => _scaffoldKey.currentState?.openEndDrawer();

  Future<void> _showBookmarkSheet(HadithEntry entry) async {
    final appText = AppText.forLanguage(
      context.read<LanguageBloc>().state.language,
    );
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HadithBookmarkSheet(
        appText: appText,
        bookmark: HadithBookmark(
          bookSlug: widget.book.slug,
          hadithNo: entry.hadithNo,
          titleAr: entry.titleAr,
          titleBn: entry.titleBn,
          savedAt: DateTime.now(),
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appText.hadithBookmarkAdded),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }

  void _goToHadith(int index) {
    _scaffoldKey.currentState?.closeEndDrawer();
    if (!_pageController.hasClients) {
      setState(() => _currentPage = index);
      return;
    }
    _pageController.jumpToPage(index);
    setState(() => _currentPage = index);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final isBangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    final title = isBangla ? widget.book.titleBn : widget.book.titleEn;

    return BlocConsumer<HadithBookBloc, HadithBookState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status != HadithBookStatus.ready && _currentPage != 0) {
          setState(() => _currentPage = 0);
        }
      },
      builder: (context, state) {
        final isReady = state.status == HadithBookStatus.ready;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          endDrawerEnableOpenDragGesture: isReady,
          endDrawer: isReady && state.entries.isNotEmpty
              ? _HadithIndexDrawer(
                  bookTitle: title,
                  entries: state.entries,
                  reference: state.reference,
                  isBangla: isBangla,
                  currentIndex: _currentPage,
                  appText: appText,
                  onSelect: _goToHadith,
                )
              : null,
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 6.h),
                _ReaderHeader(
                  title: title,
                  counter: isReady && state.entries.isNotEmpty
                      ? '${_currentPage + 1} / ${state.entries.length}'
                      : null,
                  onOpenIndex: isReady && state.entries.isNotEmpty
                      ? _openIndex
                      : null,
                  onBookmark: isReady && state.entries.isNotEmpty
                      ? () => _showBookmarkSheet(state.entries[_currentPage])
                      : null,
                ),
                Expanded(
                  child: switch (state.status) {
                    HadithBookStatus.checking => const Center(
                      child: CircularProgressIndicator(color: AppColor.primary),
                    ),
                    HadithBookStatus.needsDownload => _DownloadPrompt(
                      book: widget.book,
                      appText: appText,
                    ),
                    HadithBookStatus.downloading => _DownloadingView(
                      state: state,
                      appText: appText,
                    ),
                    HadithBookStatus.failed => _FailedView(
                      message: state.errorMessage,
                      appText: appText,
                    ),
                    HadithBookStatus.ready => _HadithPager(
                      controller: _pageController,
                      entries: state.entries,
                      appText: appText,
                      bookSlug: widget.book.slug,
                      onPageChanged: (i) =>
                          setState(() => _currentPage = i),
                    ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({
    required this.title,
    this.counter,
    this.onOpenIndex,
    this.onBookmark,
  });

  final String title;
  final String? counter;
  final VoidCallback? onOpenIndex;
  final VoidCallback? onBookmark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Row(
        children: [
          SizedBox(width: 14.w),
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFCBD16B),
              foregroundColor: const Color(0xFF303629),
              minimumSize: Size(38.r, 38.r),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColor.authLogo,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (counter != null)
                  Text(
                    counter!,
                    style: TextStyle(
                      color: const Color(0xFF9BA85B),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          if (onBookmark != null) ...[
            IconButton(
              onPressed: onBookmark,
              tooltip: AppText.of(context).hadithBookmark,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFEDF1DE),
                foregroundColor: const Color(0xFF4C5A34),
                minimumSize: Size(38.r, 38.r),
              ),
              icon: const Icon(Icons.bookmark_border_rounded, size: 18),
            ),
            SizedBox(width: 6.w),
          ],
          if (onOpenIndex != null)
            IconButton(
              onPressed: onOpenIndex,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFEDF1DE),
                foregroundColor: const Color(0xFF4C5A34),
                minimumSize: Size(38.r, 38.r),
              ),
              icon: const Icon(Icons.menu_book_rounded, size: 17),
            )
          else
            SizedBox(width: 38.r),
          SizedBox(width: 14.w),
        ],
      ),
    );
  }
}

class _HadithPager extends StatelessWidget {
  const _HadithPager({
    required this.controller,
    required this.entries,
    required this.appText,
    required this.bookSlug,
    required this.onPageChanged,
  });

  final PageController controller;
  final List<HadithEntry> entries;
  final AppText appText;
  final String bookSlug;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      onPageChanged: onPageChanged,
      itemCount: entries.length,
      itemBuilder: (context, index) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
        child: _HadithCard(
          entry: entries[index],
          appText: appText,
          bookSlug: bookSlug,
          isLast: index == entries.length - 1,
        ),
      ),
    );
  }
}

class _HadithIndexDrawer extends StatelessWidget {
  const _HadithIndexDrawer({
    required this.bookTitle,
    required this.entries,
    required this.reference,
    required this.isBangla,
    required this.currentIndex,
    required this.appText,
    required this.onSelect,
  });

  final String bookTitle;
  final List<HadithEntry> entries;
  final HadithBookReference? reference;
  final bool isBangla;
  final int currentIndex;
  final AppText appText;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookTitle,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C3320),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${entries.length} ${appText.categoryHadith}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF9BA85B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE3E7D3)),
            if (reference != null)
              _BookReferenceTile(
                reference: reference!,
                isBangla: isBangla,
                appText: appText,
              ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final selected = index == currentIndex;
                  final label = entry.titleBn.isNotEmpty
                      ? entry.titleBn
                      : entry.titleAr;
                  return InkWell(
                    onTap: () => onSelect(index),
                    child: Container(
                      color: selected
                          ? const Color(0xFFEDF1DE)
                          : Colors.transparent,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 11.h,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26.r,
                            height: 26.r,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColor.primary
                                  : const Color(0xFF8B9A4B),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${entry.hadithNo}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                height: 1.4,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: const Color(0xFF2C3320),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Collapsible "Book reference" panel in the drawer — the book's author,
/// translator, editors, publisher and year, parsed from its bundled
/// reference file.
class _BookReferenceTile extends StatelessWidget {
  const _BookReferenceTile({
    required this.reference,
    required this.isBangla,
    required this.appText,
  });

  final HadithBookReference reference;
  final bool isBangla;
  final AppText appText;

  @override
  Widget build(BuildContext context) {
    final year = [
      reference.yearGregorian,
      if (reference.yearHijri.isNotEmpty) '${reference.yearHijri} AH',
    ].where((v) => v.isNotEmpty).join(' / ');

    final rows = <(String, String)>[
      (
        appText.hadithRefAuthor,
        isBangla ? reference.authorBn : reference.authorAr,
      ),
      (
        appText.hadithRefTranslator,
        isBangla ? reference.translatorBn : reference.translatorAr,
      ),
      (
        appText.hadithRefEditors,
        isBangla ? reference.editorsBn : reference.editorsAr,
      ),
      (appText.hadithRefPublisher, reference.publisher),
      (appText.hadithRefYear, year),
    ].where((r) => r.$2.trim().isNotEmpty).toList();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
        childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        leading: Icon(
          Icons.info_outline_rounded,
          size: 18.sp,
          color: const Color(0xFF9BA85B),
        ),
        title: Text(
          appText.hadithBookRef,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3320),
          ),
        ),
        children: [
          for (final row in rows)
            Padding(
              padding: EdgeInsets.only(bottom: 9.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.$1,
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9BA85B),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    row.$2,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.45,
                      color: const Color(0xFF3B4430),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DownloadPrompt extends StatelessWidget {
  const _DownloadPrompt({required this.book, required this.appText});

  final HadithBook book;
  final AppText appText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(22.r),
            decoration: const BoxDecoration(
              color: Color(0xFFEDF1DE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 48.sp,
              color: AppColor.primary,
            ),
          ),
          SizedBox(height: 22.h),
          Text(
            appText.hadithBookDownloadTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C3320),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            appText.hadithBookDownloadBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5.sp,
              height: 1.5,
              color: const Color(0xFF5D6B44),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${book.hadithCount} ${appText.categoryHadith}',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF9BA85B),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 26.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: FilledButton.icon(
              onPressed: () =>
                  context.read<HadithBookBloc>().add(const DownloadHadithBook()),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(appText.hadithBookDownloadAction),
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                textStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadingView extends StatelessWidget {
  const _DownloadingView({required this.state, required this.appText});

  final HadithBookState state;
  final AppText appText;

  @override
  Widget build(BuildContext context) {
    final percent = state.progress == null
        ? null
        : (state.progress! * 100).round();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            percent == null
                ? '${appText.hadithBookDownloading} …'
                : '${appText.hadithBookDownloading}  $percent%',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3320),
            ),
          ),
          SizedBox(height: 14.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 8.h,
              backgroundColor: const Color(0xFFEDEFE0),
              valueColor: const AlwaysStoppedAnimation(AppColor.primary),
            ),
          ),
          if (state.total > 0) ...[
            SizedBox(height: 10.h),
            Text(
              '${state.done} / ${state.total}',
              style: TextStyle(
                fontSize: 11.sp,
                color: const Color(0xFF7A8368),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({required this.message, required this.appText});

  final String? message;
  final AppText appText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 42.sp,
            color: const Color(0xFFC15B4B),
          ),
          SizedBox(height: 14.h),
          Text(
            message ?? 'Download failed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: const Color(0xFF5D6B44)),
          ),
          SizedBox(height: 20.h),
          OutlinedButton(
            onPressed: () =>
                context.read<HadithBookBloc>().add(const DownloadHadithBook()),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4C5A34),
              side: const BorderSide(color: Color(0xFF9BAE6C)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
            child: Text(appText.tryAgain),
          ),
        ],
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({
    required this.entry,
    required this.appText,
    required this.bookSlug,
    this.isLast = false,
  });

  final HadithEntry entry;
  final AppText appText;
  final String bookSlug;
  final bool isLast;

  /// The whole hadith (title, Arabic, narrator, translation, reference) as
  /// plain text for the clipboard.
  String get _plainText {
    final buffer = StringBuffer();
    final title = entry.titleBn.isNotEmpty ? entry.titleBn : entry.titleAr;
    if (title.isNotEmpty) buffer.writeln('${entry.hadithNo}. $title');
    if (entry.arabicText.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(entry.arabicText);
    }
    if (entry.banglaNarrator.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(entry.banglaNarrator);
    }
    if (entry.banglaText.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(entry.banglaText);
    }
    if (entry.referencesText.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('${appText.hadithBookReference}: ${entry.referencesText}');
    }
    return buffer.toString().trim();
  }

  String get _shareSubject =>
      entry.titleBn.isNotEmpty ? entry.titleBn : entry.titleAr;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _plainText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(appText.hadithCopied),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: _plainText,
        subject: _shareSubject,
        sharePositionOrigin: box != null && box.hasSize
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      ),
    );
  }

  /// Bottom sheet with "Copy" and "Share to another app" for this hadith.
  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE3C4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 6.h),
            ListTile(
              leading: const Icon(
                Icons.copy_rounded,
                color: Color(0xFF4C5A34),
              ),
              title: Text(appText.hadithCopy),
              onTap: () {
                Navigator.pop(sheetContext);
                _copy(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.ios_share_rounded,
                color: Color(0xFF4C5A34),
              ),
              title: Text(appText.hadithShare),
              onTap: () {
                Navigator.pop(sheetContext);
                _share(context);
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9EF),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE3E7D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30.r,
                height: 30.r,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B9A4B),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${entry.hadithNo}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    entry.titleBn.isNotEmpty ? entry.titleBn : entry.titleAr,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C3320),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _BookmarkButton(
                key: ValueKey('hadith-bookmark-$bookSlug-${entry.hadithNo}'),
                bookSlug: bookSlug,
                entry: entry,
                appText: appText,
              ),
              SizedBox(width: 6.w),
              Builder(
                builder: (buttonContext) => _CopyButton(
                  tooltip: appText.hadithCopy,
                  onTap: () => _showActions(buttonContext),
                ),
              ),
            ],
          ),
          SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.arabicText.isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  Text(
                    entry.arabicText,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 17.sp,
                      height: 1.9,
                      color: const Color(0xFF283016),
                    ),
                  ),
                ],
                if (entry.banglaNarrator.isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  Text(
                    entry.banglaNarrator,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4C5A34),
                    ),
                  ),
                ],
                if (entry.banglaText.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    entry.banglaText,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.75,
                      color: const Color(0xFF3B4430),
                    ),
                  ),
                ],
                if (entry.referencesText.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF0DC),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '${appText.hadithBookReference}: ${entry.referencesText}',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        height: 1.5,
                        color: const Color(0xFF5D6B44),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isLast) ...[
            SizedBox(height: 18.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_double_arrow_left_rounded,
                  size: 15.sp,
                  color: const Color(0xFF9BA85B),
                ),
                SizedBox(width: 6.w),
                Text(
                  appText.hadithSwipeNext,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    color: const Color(0xFF9BA85B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BookmarkButton extends StatefulWidget {
  const _BookmarkButton({
    super.key,
    required this.bookSlug,
    required this.entry,
    required this.appText,
  });

  final String bookSlug;
  final HadithEntry entry;
  final AppText appText;

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton> {
  final _store = HadithBookmarkStore();
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _store.isSingleBookmarked(
      widget.bookSlug,
      widget.entry.hadithNo,
    );
    if (mounted) setState(() => _bookmarked = value);
  }

  Future<void> _toggle() async {
    final nowOn = await _store.toggleSingle(
      HadithBookmark(
        bookSlug: widget.bookSlug,
        hadithNo: widget.entry.hadithNo,
        titleAr: widget.entry.titleAr,
        titleBn: widget.entry.titleBn,
        savedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() => _bookmarked = nowOn);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowOn
              ? widget.appText.hadithBookmarkAdded
              : widget.appText.hadithBookmarkRemoved,
        ),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.appText.hadithBookmark,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(9.r),
        child: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: _bookmarked
                ? const Color(0xFF8B9A4B)
                : const Color(0xFFECF0DC),
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: const Color(0xFFDCE3C4)),
          ),
          child: Icon(
            _bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            size: 15.sp,
            color: _bookmarked ? Colors.white : const Color(0xFF4C5A34),
          ),
        ),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9.r),
        child: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: const Color(0xFFECF0DC),
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: const Color(0xFFDCE3C4)),
          ),
          child: Icon(
            Icons.copy_rounded,
            size: 15.sp,
            color: const Color(0xFF4C5A34),
          ),
        ),
      ),
    );
  }
}
