import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/hadith/data/ebook_downloader.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/ebook.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/bloc/ebook_download/ebook_download_bloc.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/screens/ebook_reader_screen.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/widgets/ebook_cover.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:url_launcher/url_launcher.dart';

/// One e-book: cover, title, author, language, publisher and reference, with a
/// button that downloads the PDF onto the device, then reads it in the app.
///
/// Reached by tapping a book on the e-book shelf of [HadithLibraryScreen].
class EbookDetailScreen extends StatelessWidget {
  const EbookDetailScreen({super.key, required this.ebook});

  final Ebook ebook;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _WebEbookDetailScreen(ebook: ebook);
    return BlocProvider(
      create: (_) =>
          EbookDownloadBloc(ebook, EbookDownloader())
            ..add(const CheckEbookDownload()),
      child: _EbookDetailView(ebook: ebook),
    );
  }
}

/// Browsers cannot save a PDF to the app documents directory or render it
/// through the native file reader. Open the publisher's URL in a new browser
/// context instead; downloading/caching remains unchanged on mobile.
class _WebEbookDetailScreen extends StatelessWidget {
  const _WebEbookDetailScreen({required this.ebook});

  final Ebook ebook;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(ebook.pdfFileUrl);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this e-book.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      appBar: AppBar(
        title: Text(ebook.title),
        backgroundColor: Colors.transparent,
        foregroundColor: context.inkColor(const Color(0xFF2C3320)),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150.w,
                height: 210.h,
                child: EbookCover(url: ebook.coverImageUrl),
              ),
              SizedBox(height: 20.h),
              Text(
                ebook.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 18.h),
              FilledButton.icon(
                onPressed: ebook.pdfFileUrl.isEmpty
                    ? null
                    : () => _open(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open e-book'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EbookDetailView extends StatelessWidget {
  const _EbookDetailView({required this.ebook});

  final Ebook ebook;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final details = <(String, String)>[
      (appText.languageTitle, _localizedLanguage(appText, ebook.language)),
      (appText.hadithRefPublisher, ebook.publisher),
      (appText.hadithBookReference, ebook.reference),
    ].where((row) => row.$2.trim().isNotEmpty).toList();

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            _Header(title: appText.hadithEbook),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
                child: Column(
                  children: [
                    Container(
                      width: 176.w,
                      height: 244.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: EbookCover(url: ebook.coverImageUrl),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      ebook.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: context.inkColor(const Color(0xFF2C3320)),
                      ),
                    ),
                    if (ebook.author.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        ebook.author,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: context.textInkColor(const Color(0xFF8B9A4B)),
                        ),
                      ),
                    ],
                    if (details.isNotEmpty) ...[
                      SizedBox(height: 22.h),
                      _DetailsCard(rows: details),
                    ],
                    SizedBox(height: 26.h),
                    _DownloadButton(ebook: ebook),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The backend sends the book's language as a single English word
/// (`"English"`); show it in the app's language. Anything else (a language the
/// app has no name for) is shown as the backend sent it.
String _localizedLanguage(AppText appText, String language) {
  switch (language.trim().toLowerCase()) {
    case 'english' || 'en':
      return appText.english;
    case 'bangla' || 'bengali' || 'bn':
      return appText.bangla;
    default:
      return language;
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
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.inkColor(const Color(0xFF2C3320)),
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(const Color(0xFFF7F9EF)),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: context.lineColor(const Color(0xFFE3E7D3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in rows)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.$1,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: context.textInkColor(const Color(0xFF9BA85B)),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    row.$2,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.45,
                      color: context.inkColor(const Color(0xFF3B4430)),
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

/// Download → progress → "Open book" (reads the PDF in [EbookReaderScreen]),
/// driven by [EbookDownloadBloc].
class _DownloadButton extends StatelessWidget {
  const _DownloadButton({required this.ebook});

  final Ebook ebook;

  void _open(BuildContext context, String path) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EbookReaderScreen(ebook: ebook, filePath: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<EbookDownloadBloc>().state;

    ButtonStyle style() => FilledButton.styleFrom(
      backgroundColor: AppColor.primary,
      foregroundColor: Colors.white,
      minimumSize: Size(double.infinity, 50.h),
      textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26.r)),
    );

    switch (state.status) {
      case EbookDownloadStatus.checking:
        return SizedBox(height: 50.h);
      case EbookDownloadStatus.downloading:
        final percent = state.progress == null
            ? null
            : (state.progress! * 100).round();
        return Column(
          children: [
            Text(
              percent == null
                  ? '${appText.hadithBookDownloading} …'
                  : context.localizedDigits(
                      '${appText.hadithBookDownloading}  $percent%',
                    ),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: context.inkColor(const Color(0xFF2C3320)),
              ),
            ),
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: LinearProgressIndicator(
                value: state.progress,
                minHeight: 8.h,
                backgroundColor: context.surfaceColor(const Color(0xFFEDEFE0)),
                valueColor: const AlwaysStoppedAnimation(AppColor.primary),
              ),
            ),
          ],
        );
      case EbookDownloadStatus.downloaded:
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16.sp,
                  color: AppColor.primary,
                ),
                SizedBox(width: 6.w),
                Text(
                  appText.ebookDownloaded,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: context.inkColor(const Color(0xFF5D6B44)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            FilledButton.icon(
              onPressed: () => _open(context, state.filePath!),
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: Text(appText.ebookOpen),
              style: style(),
            ),
          ],
        );
      case EbookDownloadStatus.failed:
        return Column(
          children: [
            Text(
              appText.ebookDownloadFailed,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: const Color(0xFFC15B4B),
              ),
            ),
            SizedBox(height: 12.h),
            FilledButton.icon(
              onPressed: () => context.read<EbookDownloadBloc>().add(
                const StartEbookDownload(),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(appText.tryAgain),
              style: style(),
            ),
          ],
        );
      case EbookDownloadStatus.idle:
        return FilledButton.icon(
          onPressed: () =>
              context.read<EbookDownloadBloc>().add(const StartEbookDownload()),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text(appText.hadithBookDownloadAction),
          style: style(),
        );
    }
  }
}
