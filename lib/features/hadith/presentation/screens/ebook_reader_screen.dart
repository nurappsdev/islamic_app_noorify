import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/ebook.dart';

/// Reads a downloaded e-book PDF inside the app, one page at a time.
///
/// Swipe right-to-left for the next page and left-to-right for the previous
/// one (or use the arrows / slider below); pinch to zoom into a page. The page
/// you stop on is remembered and reopened next time.
class EbookReaderScreen extends StatefulWidget {
  const EbookReaderScreen({
    super.key,
    required this.ebook,
    required this.filePath,
  });

  final Ebook ebook;
  final String filePath;

  @override
  State<EbookReaderScreen> createState() => _EbookReaderScreenState();
}

class _EbookReaderScreenState extends State<EbookReaderScreen> {
  static const _pageTurn = Duration(milliseconds: 300);

  PdfController? _controller;
  int _totalPages = 0;
  bool _failed = false;

  /// While the slider is being dragged, the page it points at.
  double? _dragPage;

  String get _lastPageKey => 'ebook_last_page_${widget.ebook.id}';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    var initial = 1;
    try {
      initial =
          (await SharedPreferences.getInstance()).getInt(_lastPageKey) ?? 1;
    } catch (_) {
      // Start from the first page.
    }
    if (!mounted) return;
    setState(() {
      _controller = PdfController(
        document: PdfDocument.openFile(widget.filePath),
        initialPage: initial < 1 ? 1 : initial,
      );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _rememberPage(int page) async {
    try {
      await (await SharedPreferences.getInstance()).setInt(_lastPageKey, page);
    } catch (_) {
      // Not remembered; reading is unaffected.
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            _Header(
              title: widget.ebook.title,
              counter: controller == null || _totalPages == 0
                  ? null
                  : ValueListenableBuilder<int>(
                      valueListenable: controller.pageListenable,
                      builder: (_, page, _) => Text(
                        '$page / $_totalPages',
                        style: TextStyle(
                          color: const Color(0xFF9BA85B),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 6.h),
            Expanded(
              child: controller == null
                  ? const _Loading()
                  : PdfView(
                      controller: controller,
                      scrollDirection: Axis.horizontal,
                      pageSnapping: true,
                      backgroundDecoration: BoxDecoration(
                        color: context.surfaceColor(const Color(0xFFF0F3E4)),
                      ),
                      onDocumentLoaded: (document) =>
                          setState(() => _totalPages = document.pagesCount),
                      onDocumentError: (_) => setState(() => _failed = true),
                      onPageChanged: _rememberPage,
                      builders: PdfViewBuilders<DefaultBuilderOptions>(
                        options: const DefaultBuilderOptions(),
                        documentLoaderBuilder: (_) => const _Loading(),
                        pageLoaderBuilder: (_) => const _Loading(),
                        errorBuilder: (_, _) => _Failed(
                          message: AppText.of(context).ebookOpenFailed,
                        ),
                      ),
                    ),
            ),
            if (controller != null && _totalPages > 0 && !_failed)
              _PageBar(
                controller: controller,
                totalPages: _totalPages,
                dragPage: _dragPage,
                onDrag: (value) => setState(() => _dragPage = value),
                onDragEnd: (value) {
                  setState(() => _dragPage = null);
                  controller.jumpToPage(value.round());
                },
                onPrevious: () => controller.previousPage(
                  duration: _pageTurn,
                  curve: Curves.easeOut,
                ),
                onNext: () => controller.nextPage(
                  duration: _pageTurn,
                  curve: Curves.easeOut,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.counter});

  final String title;
  final Widget? counter;

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.inkColor(const Color(0xFF2C3320)),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ?counter,
              ],
            ),
          ),
          SizedBox(width: 16.w),
        ],
      ),
    );
  }
}

class _PageBar extends StatelessWidget {
  const _PageBar({
    required this.controller,
    required this.totalPages,
    required this.dragPage,
    required this.onDrag,
    required this.onDragEnd,
    required this.onPrevious,
    required this.onNext,
  });

  final PdfController controller;
  final int totalPages;
  final double? dragPage;
  final ValueChanged<double> onDrag;
  final ValueChanged<double> onDragEnd;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: controller.pageListenable,
      builder: (context, page, _) {
        final value = (dragPage ?? page.toDouble()).clamp(
          1.0,
          totalPages.toDouble(),
        );
        return Padding(
          padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 8.h),
          child: Row(
            children: [
              IconButton(
                onPressed: page > 1 ? onPrevious : null,
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColor.primary,
              ),
              Expanded(
                child: totalPages > 1
                    ? Slider(
                        value: value,
                        min: 1,
                        max: totalPages.toDouble(),
                        divisions: totalPages - 1,
                        label: '${value.round()}',
                        activeColor: AppColor.primary,
                        onChanged: onDrag,
                        onChangeEnd: onDragEnd,
                      )
                    : const SizedBox.shrink(),
              ),
              IconButton(
                onPressed: page < totalPages ? onNext : null,
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColor.primary,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColor.primary));
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13.sp, color: const Color(0xFFC15B4B)),
      ),
    ),
  );
}
