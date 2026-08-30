import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_book.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_entry.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_book/hadith_book_bloc.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// Reads a single hadith e-book.
///
/// On first open the book is parsed from its bundled source file into the local
/// SQLite database ("download"); every later open reads straight from there and
/// works offline. Provided with a [HadithBookBloc] by the route.
class HadithBookReaderScreen extends StatelessWidget {
  const HadithBookReaderScreen({super.key, required this.book});

  final HadithBook book;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final isBangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    final title = isBangla ? book.titleBn : book.titleEn;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            _ReaderHeader(title: title),
            Expanded(
              child: BlocBuilder<HadithBookBloc, HadithBookState>(
                builder: (context, state) => switch (state.status) {
                  HadithBookStatus.checking => const Center(
                    child: CircularProgressIndicator(color: AppColor.primary),
                  ),
                  HadithBookStatus.needsDownload => _DownloadPrompt(
                    book: book,
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
                  HadithBookStatus.ready => _HadithListView(
                    entries: state.entries,
                    appText: appText,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({required this.title});

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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 60.w),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColor.authLogo,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
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

class _HadithListView extends StatelessWidget {
  const _HadithListView({required this.entries, required this.appText});

  final List<HadithEntry> entries;
  final AppText appText;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
      itemCount: entries.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) =>
          _HadithCard(entry: entries[index], appText: appText),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({required this.entry, required this.appText});

  final HadithEntry entry;
  final AppText appText;

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
                child: Text(
                  entry.titleBn.isNotEmpty ? entry.titleBn : entry.titleAr,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C3320),
                  ),
                ),
              ),
            ],
          ),
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
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
    );
  }
}
