import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/state/amol_daily_store.dart';
import 'package:tuhfatul_muslim/features/hadith/data/hadith_bookmark_store.dart';
import 'package:tuhfatul_muslim/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/hadith/data/models/hadith_book.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/widgets/hadith_bookmark_sheet.dart';
import 'package:tuhfatul_muslim/features/hadith/data/models/hadith_book_reference.dart';
import 'package:tuhfatul_muslim/features/hadith/data/models/hadith_entry.dart';
import 'package:tuhfatul_muslim/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_library_book.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_detail_page.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/bloc/hadith_book/hadith_book_bloc.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/core/localization/localized_failure_message.dart';
import 'package:tuhfatul_muslim/core/theme/app_typography.dart';

/// Route arguments for [HadithBookReaderScreen]: the book, and optionally the
/// hadith to open at.
class HadithReaderArgs {
  const HadithReaderArgs({required this.slug, this.hadithNo});

  final String slug;
  final int? hadithNo;
}

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
  const HadithBookReaderScreen({
    super.key,
    required this.book,
    this.initialHadithNo,
  });

  final HadithBook book;

  /// Hadith to open at (e.g. from the Saved screen); the first one if null.
  final int? initialHadithNo;

  @override
  State<HadithBookReaderScreen> createState() => _HadithBookReaderScreenState();
}

class _HadithBookReaderScreenState extends State<HadithBookReaderScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pageController = PageController();
  final _totalReadingMinutes = ValueNotifier<int?>(null);
  final _sessionSeconds = ValueNotifier<int>(0);
  final _readingStopwatch = Stopwatch();
  late final Timer _readingTimer;
  late final AppLifecycleListener _readingLifecycle;
  late final HadithLibraryRepositoryImpl _readingRepository =
      HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl());
  final Map<int, String> _serverHadithIds = {};
  final Map<int, int> _unmappedSeconds = {};
  final Map<String, int> _dwellSeconds = {};
  final Map<String, int> _pendingSeconds = {};
  final Set<String> _trackedHadithIds = {};
  Future<void> _reportQueue = Future.value();
  int _activeReadingSeconds = 0;
  int _lastMinuteReportAt = 0;
  int? _currentHadithNo;
  bool _leaving = false;
  int _currentPage = 0;

  /// Consumed once the book is ready and the page has been jumped to.
  late int? _pendingHadithNo = widget.initialHadithNo;

  @override
  void initState() {
    super.initState();
    _readingStopwatch.start();
    _readingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onReadingTick(),
    );
    _readingLifecycle = AppLifecycleListener(
      onHide: _readingStopwatch.stop,
      onShow: _readingStopwatch.start,
    );
    _loadTotalReadingMinutes();
    unawaited(_loadServerHadithIds());
  }

  @override
  void dispose() {
    _readingLifecycle.dispose();
    _readingTimer.cancel();
    _readingStopwatch.stop();
    _flushPendingSeconds();
    _totalReadingMinutes.dispose();
    _sessionSeconds.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadTotalReadingMinutes() async {
    final today = DateTime.now();
    final result = await _readingRepository.getReadingHistory(
      from: _dateKey(today),
      to: _dateKey(today),
    );
    if (!mounted) return;
    result.fold(
      (_) => _totalReadingMinutes.value ??= 0,
      (history) =>
          _totalReadingMinutes.value = history.totals.totalMinutes.floor(),
    );
  }

  void _onReadingTick() {
    if (!_readingStopwatch.isRunning) return;
    _sessionSeconds.value = _readingStopwatch.elapsed.inSeconds;
    final hadithNo = _currentHadithNo;
    if (hadithNo == null) return;
    _activeReadingSeconds++;
    final hadithId = _serverHadithIds[hadithNo];
    if (hadithId == null || hadithId.isEmpty) {
      _unmappedSeconds[hadithNo] = (_unmappedSeconds[hadithNo] ?? 0) + 1;
    } else {
      _addReadingSecond(hadithId);
    }

    // Report each reader-minute as one batch. Every Hadith that has been read
    // for at least 30 seconds joins the batch, and keeps its own dwell time
    // when the user swipes away and later returns.
    while (_activeReadingSeconds - _lastMinuteReportAt >= 60) {
      _lastMinuteReportAt += 60;
      _queuePendingReadingTime();
    }
  }

  void _addReadingSecond(String hadithId, [int seconds = 1]) {
    final dwell = (_dwellSeconds[hadithId] ?? 0) + seconds;
    _dwellSeconds[hadithId] = dwell;
    _pendingSeconds[hadithId] = (_pendingSeconds[hadithId] ?? 0) + seconds;
    if (dwell >= 30) _trackedHadithIds.add(hadithId);
  }

  /// Loads every Hadith ID from the matching online book once. The local
  /// reader contains only `hadithNo`, while the tracking API needs server IDs.
  Future<void> _loadServerHadithIds() async {
    final booksResult = await _readingRepository.getBooks();
    final books = booksResult.fold<List<HadithLibraryBook>?>(
      (_) => null,
      (value) => value,
    );
    if (books == null) return;
    final book = _matchingRemoteBook(books);
    if (book == null) return;

    var pageNumber = 1;
    var hasMore = true;
    final ids = <int, String>{};
    while (hasMore) {
      final pageResult = await _readingRepository.getHadiths(
        bookId: book.id,
        page: pageNumber,
        limit: 100,
      );
      final page = pageResult.fold<HadithDetailPage?>(
        (_) => null,
        (value) => value,
      );
      if (page == null) break;
      for (final hadith in page.hadiths) {
        if (hadith.id.isNotEmpty && hadith.hadithNumber > 0) {
          ids[hadith.hadithNumber] = hadith.id;
        }
      }
      hasMore = page.hasMore;
      pageNumber++;
    }
    if (!mounted) return;
    _serverHadithIds.addAll(ids);
    _moveMappedSecondsIntoTracking();
  }

  void _moveMappedSecondsIntoTracking() {
    final mapped = <int>[];
    for (final entry in _unmappedSeconds.entries) {
      final hadithId = _serverHadithIds[entry.key];
      if (hadithId == null || hadithId.isEmpty) continue;
      _addReadingSecond(hadithId, entry.value);
      mapped.add(entry.key);
    }
    for (final hadithNo in mapped) {
      _unmappedSeconds.remove(hadithNo);
    }
  }

  HadithLibraryBook? _matchingRemoteBook(List<HadithLibraryBook> books) {
    final titleOrAuthorMatch = books.where((book) {
      return _matchesText(book.titleEn, widget.book.titleEn) ||
          _matchesText(book.titleBn, widget.book.titleBn) ||
          _sharesDistinctiveWord(book.titleEn, widget.book.titleEn) ||
          _sharesDistinctiveWord(book.titleBn, widget.book.titleBn) ||
          _matchesText(book.authorEn, widget.book.authorEn);
    }).toList();
    if (titleOrAuthorMatch.length == 1) return titleOrAuthorMatch.single;

    final sameCount = books
        .where((book) => book.totalHadiths == widget.book.hadithCount)
        .toList();
    final candidates = sameCount.where((book) {
      return _matchesText(book.titleEn, widget.book.titleEn) ||
          _matchesText(book.titleBn, widget.book.titleBn) ||
          _matchesText(book.authorEn, widget.book.authorEn);
    }).toList();
    if (candidates.length == 1) return candidates.single;
    return sameCount.length == 1 ? sameCount.single : null;
  }

  bool _matchesText(String first, String second) {
    final normalizedFirst = first.toLowerCase().replaceAll(
      RegExp(r'[\s\-_–—()]'),
      '',
    );
    final normalizedSecond = second.toLowerCase().replaceAll(
      RegExp(r'[\s\-_–—()]'),
      '',
    );
    return normalizedFirst.length > 3 &&
        normalizedSecond.length > 3 &&
        (normalizedFirst.contains(normalizedSecond) ||
            normalizedSecond.contains(normalizedFirst));
  }

  /// Titles from the bundled book and API are not always word-for-word the
  /// same (for example “40 Hadith An-Nawawi” vs “Nawawi's Forty Hadith”).
  bool _sharesDistinctiveWord(String first, String second) {
    Set<String> words(String value) => value
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9\u0980-\u09ff]+'))
        .where(
          (word) =>
              word.length >= 4 &&
              word != 'hadith' &&
              word != 'imam' &&
              word != 'হাদিস' &&
              word != 'ইমাম',
        )
        .toSet();
    final firstWords = words(first);
    return firstWords.any(words(second).contains);
  }

  void _queuePendingReadingTime() {
    _moveMappedSecondsIntoTracking();
    final pending = <String, int>{
      for (final entry in _pendingSeconds.entries)
        if (_trackedHadithIds.contains(entry.key) && entry.value > 0)
          entry.key: entry.value,
    };
    if (pending.isEmpty) return;
    for (final hadithId in pending.keys) {
      _pendingSeconds.remove(hadithId);
    }
    _reportQueue = _reportQueue.then((_) async {
      final result = await _readingRepository.trackReading(
        hadithIds: pending.keys.toList(growable: false),
        seconds: pending.values.fold(0, (sum, value) => sum + value),
        completed: false,
        date: _dateKey(DateTime.now()),
      );
      result.fold((_) {}, (_) {
        unawaited(AmolDailyStore.instance.load());
        unawaited(_loadTotalReadingMinutes());
      });
    });
  }

  void _flushPendingSeconds() {
    _queuePendingReadingTime();
  }

  void _leaveReader() {
    if (_leaving) return;
    _leaving = true;
    _readingStopwatch.stop();
    _readingTimer.cancel();
    _flushPendingSeconds();
    Navigator.of(context).pop();
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveReader();
      },
      child: BlocConsumer<HadithBookBloc, HadithBookState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status != HadithBookStatus.ready && _currentPage != 0) {
            setState(() => _currentPage = 0);
          }
          if (state.status == HadithBookStatus.ready &&
              state.entries.isNotEmpty) {
            _currentHadithNo = state.entries[_currentPage].hadithNo;
          }
          final pending = _pendingHadithNo;
          if (state.status == HadithBookStatus.ready && pending != null) {
            _pendingHadithNo = null;
            final index = state.entries.indexWhere(
              (e) => e.hadithNo == pending,
            );
            if (index >= 0) {
              // The pager is built by this same state change; jump after it.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _goToHadith(index);
              });
            }
          }
        },
        builder: (context, state) {
          final isReady = state.status == HadithBookStatus.ready;
          // A bloc may already be ready when this reader is opened, in which
          // case its listener has no transition to observe.
          if (isReady && state.entries.isNotEmpty && _currentHadithNo == null) {
            _currentHadithNo = state.entries[_currentPage].hadithNo;
          }
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: context.pageColor(Colors.white),
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
                    isBangla: isBangla,
                    totalReadingMinutes: _totalReadingMinutes,
                    sessionSeconds: _sessionSeconds,
                    onBack: _leaveReader,
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
                        child: CircularProgressIndicator(
                          color: AppColor.primary,
                        ),
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
                        bookName: title,
                        onPageChanged: (i) {
                          _currentHadithNo = state.entries[i].hadithNo;
                          setState(() => _currentPage = i);
                        },
                      ),
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({
    required this.title,
    required this.isBangla,
    required this.totalReadingMinutes,
    required this.sessionSeconds,
    required this.onBack,
    this.counter,
    this.onOpenIndex,
    this.onBookmark,
  });

  final String title;
  final bool isBangla;
  final ValueListenable<int?> totalReadingMinutes;
  final ValueListenable<int> sessionSeconds;
  final VoidCallback onBack;
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
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFCBD16B),
              foregroundColor: context.onLightInkColor(Color(0xFF303629)),
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
                    color: context.textInkColor(AppColor.authLogo),
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (counter != null)
                  Text(
                    context.localizedDigits(counter!),
                    style: TextStyle(
                      color: context.textInkColor(const Color(0xFF9BA85B)),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 5.w),
          _ReaderTimerCircle(seconds: sessionSeconds),
          SizedBox(width: 5.w),
          ValueListenableBuilder<int?>(
            valueListenable: totalReadingMinutes,
            builder: (context, minutes, _) {
              final text = minutes == null
                  ? '–'
                  : context.localizedDigits('$minutes');
              return Container(
                key: const ValueKey('hadith-reader-minutes'),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: context.surfaceColor(const Color(0xFFEDF1DE)),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFF9BA85B).withValues(alpha: .45),
                  ),
                ),
                child: Text(
                  isBangla ? '$text মি' : '${text}m',
                  style: TextStyle(
                    color: context.inkColor(const Color(0xFF4C5A34)),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 8.w),
          if (onBookmark != null) ...[
            IconButton(
              onPressed: onBookmark,
              tooltip: AppText.of(context).hadithBookmark,
              style: IconButton.styleFrom(
                backgroundColor: context.surfaceColor(Color(0xFFEDF1DE)),
                foregroundColor: context.inkColor(Color(0xFF4C5A34)),
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
                backgroundColor: context.surfaceColor(Color(0xFFEDF1DE)),
                foregroundColor: context.inkColor(Color(0xFF4C5A34)),
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

/// One reader-wide clock: it follows the whole book-reading session, not an
/// individual hadith card.
class _ReaderTimerCircle extends StatelessWidget {
  const _ReaderTimerCircle({required this.seconds});

  final ValueListenable<int> seconds;

  static String _clock(int seconds) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(seconds ~/ 60)}:${two(seconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: seconds,
      builder: (context, value, _) => Container(
        key: const ValueKey('hadith-book-reader-timer'),
        width: 34.r,
        height: 34.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.surfaceColor(const Color(0xFFF5F6EA)),
          border: Border.all(
            color: const Color(0xFF9BA85B).withValues(alpha: .6),
          ),
        ),
        child: Text(
          context.localizedDigits(_clock(value)),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.inkColor(const Color(0xFF4C5A34)),
            fontSize: 8.5.sp,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
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
    required this.bookName,
    required this.onPageChanged,
  });

  final PageController controller;
  final List<HadithEntry> entries;
  final AppText appText;
  final String bookSlug;
  final String bookName;
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
          bookName: bookName,
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
      backgroundColor: context.surfaceColor(Colors.white),
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
                      color: context.inkColor(Color(0xFF2C3320)),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    context.localizedDigits(
                      '${entries.length} ${appText.categoryHadith}',
                    ),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textInkColor(const Color(0xFF9BA85B)),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.lineColor(Color(0xFFE3E7D3))),
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
                      color: context.surfaceColor(
                        selected ? const Color(0xFFEDF1DE) : Colors.transparent,
                      ),
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
                              context.localizedDigits('${entry.hadithNo}'),
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
                                color: context.inkColor(Color(0xFF2C3320)),
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
            color: context.inkColor(Color(0xFF2C3320)),
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
                      color: context.textInkColor(const Color(0xFF9BA85B)),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    row.$2,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.45,
                      color: context.inkColor(Color(0xFF3B4430)),
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
            decoration: BoxDecoration(
              color: context.surfaceColor(Color(0xFFEDF1DE)),
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
              color: context.inkColor(Color(0xFF2C3320)),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            appText.hadithBookDownloadBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5.sp,
              height: 1.5,
              color: context.inkColor(Color(0xFF5D6B44)),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            context.localizedDigits(
              '${book.hadithCount} ${appText.categoryHadith}',
            ),
            style: TextStyle(
              fontSize: 12.sp,
              color: context.textInkColor(const Color(0xFF9BA85B)),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 26.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: FilledButton.icon(
              onPressed: () => context.read<HadithBookBloc>().add(
                const DownloadHadithBook(),
              ),
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
                : context.localizedDigits(
                    '${appText.hadithBookDownloading}  $percent%',
                  ),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: context.inkColor(Color(0xFF2C3320)),
            ),
          ),
          SizedBox(height: 14.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 8.h,
              backgroundColor: context.surfaceColor(Color(0xFFEDEFE0)),
              valueColor: const AlwaysStoppedAnimation(AppColor.primary),
            ),
          ),
          if (state.total > 0) ...[
            SizedBox(height: 10.h),
            Text(
              context.localizedDigits('${state.done} / ${state.total}'),
              style: TextStyle(
                fontSize: 11.sp,
                color: context.inkColor(Color(0xFF7A8368)),
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
            message == null
                ? appText.failureDownloadFailed
                : localizeFailureMessage(message!),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: context.inkColor(Color(0xFF5D6B44)),
            ),
          ),
          SizedBox(height: 20.h),
          OutlinedButton(
            onPressed: () =>
                context.read<HadithBookBloc>().add(const DownloadHadithBook()),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.inkColor(Color(0xFF4C5A34)),
              side: BorderSide(color: context.lineColor(Color(0xFF9BAE6C))),
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

class _HadithCard extends StatefulWidget {
  const _HadithCard({
    required this.entry,
    required this.appText,
    required this.bookSlug,
    required this.bookName,
    this.isLast = false,
  });

  final HadithEntry entry;
  final AppText appText;
  final String bookSlug;
  final String bookName;
  final bool isLast;

  @override
  State<_HadithCard> createState() => _HadithCardState();
}

class _HadithCardState extends State<_HadithCard> {
  static const _reportEmail = 'report.tuhfatulmuslim@gmail.com';

  final GlobalKey _boundaryKey = GlobalKey();

  HadithEntry get entry => widget.entry;
  AppText get appText => widget.appText;

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

  /// Just the Bangla narrator and translation.
  String get _translationText {
    final buffer = StringBuffer();
    if (entry.banglaNarrator.isNotEmpty) buffer.writeln(entry.banglaNarrator);
    if (entry.banglaText.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln(entry.banglaText);
    }
    return buffer.toString().trim();
  }

  String get _shareSubject =>
      entry.titleBn.isNotEmpty ? entry.titleBn : entry.titleAr;

  Rect? get _originRect {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _copyValue(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    _toast(appText.hadithCopied);
  }

  Future<void> _shareScreenshot() async {
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/hadith_${widget.bookSlug}_${entry.hadithNo}.png',
      );
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: _shareSubject,
          sharePositionOrigin: _originRect,
        ),
      );
    } catch (_) {
      _toast(appText.hadithShareFailed);
    }
  }

  Future<void> _report() async {
    final book = widget.bookName.isNotEmpty ? widget.bookName : widget.bookSlug;
    final subject =
        '${appText.hadithReport}: $book — '
        '${appText.categoryHadith} ${entry.hadithNo}';
    final body =
        '${appText.hadithReportMessage}'
        '${appText.hadithBookReference}: $book\n'
        '${appText.categoryHadith}: ${entry.hadithNo}\n\n'
        '$_plainText';
    final uri = Uri.parse(
      'mailto:$_reportEmail'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) _toast(appText.hadithReportFailed);
    } catch (_) {
      _toast(appText.hadithReportFailed);
    }
  }

  /// Bottom sheet with the per-hadith copy / share / report actions.
  void _showActions(BuildContext buttonContext) {
    showModalBottomSheet<void>(
      context: buttonContext,
      backgroundColor: context.surfaceColor(Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        Widget tile({
          required IconData icon,
          required String label,
          required VoidCallback onTap,
          Color color = const Color(0xFF4C5A34),
        }) {
          return ListTile(
            leading: Icon(icon, color: context.inkColor(color)),
            title: Text(
              label,
              style: TextStyle(color: context.inkColor(color)),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              onTap();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.surfaceColor(Color(0xFFDCE3C4)),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 6.h),
              if (entry.banglaText.isNotEmpty ||
                  entry.banglaNarrator.isNotEmpty)
                tile(
                  icon: Icons.translate_rounded,
                  label: appText.hadithCopyTranslation,
                  onTap: () => _copyValue(_translationText),
                ),
              if (entry.arabicText.isNotEmpty)
                tile(
                  icon: Icons.menu_book_rounded,
                  label: appText.hadithCopyArabic,
                  onTap: () => _copyValue(entry.arabicText),
                ),
              tile(
                icon: Icons.copy_rounded,
                label: appText.hadithCopyFull,
                onTap: () => _copyValue(_plainText),
              ),
              tile(
                icon: Icons.ios_share_rounded,
                label: appText.hadithShareScreenshot,
                onTap: _shareScreenshot,
              ),
              tile(
                icon: Icons.flag_outlined,
                label: appText.hadithReport,
                color: const Color(0xFFC15B4B),
                onTap: _report,
              ),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                decoration: BoxDecoration(
                  color: context.surfaceColor(Color(0xFFF7F9EF)),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: context.lineColor(Color(0xFFE3E7D3)),
                  ),
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
                            context.localizedDigits('${entry.hadithNo}'),
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
                              entry.titleBn.isNotEmpty
                                  ? entry.titleBn
                                  : entry.titleAr,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w700,
                                color: context.inkColor(Color(0xFF2C3320)),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 74.w),
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
                                fontFamily: 'Noorehuda',
                                fontFamilyFallback: appFontFamilyFallback,
                                fontSize: 17.sp,
                                height: 1.9,
                                color: context.inkColor(Color(0xFF283016)),
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
                                color: context.inkColor(Color(0xFF4C5A34)),
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
                                color: context.inkColor(Color(0xFF3B4430)),
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
                                color: context.surfaceColor(Color(0xFFECF0DC)),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '${appText.hadithBookReference}: ${entry.referencesText}',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  height: 1.5,
                                  color: context.inkColor(Color(0xFF5D6B44)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              top: 8.h,
              end: 12.w,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BookmarkButton(
                    key: ValueKey(
                      'hadith-bookmark-${widget.bookSlug}-${entry.hadithNo}',
                    ),
                    bookSlug: widget.bookSlug,
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
            ),
          ],
        ),
        if (!widget.isLast) ...[
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
                  color: context.textInkColor(const Color(0xFF9BA85B)),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
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
            color: context.surfaceColor(
              _bookmarked ? const Color(0xFF8B9A4B) : const Color(0xFFECF0DC),
            ),
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: context.lineColor(Color(0xFFDCE3C4))),
          ),
          child: Icon(
            _bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            size: 15.sp,
            color: context.inkColor(
              _bookmarked ? Colors.white : const Color(0xFF4C5A34),
            ),
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
            color: context.surfaceColor(Color(0xFFECF0DC)),
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: context.lineColor(Color(0xFFDCE3C4))),
          ),
          child: Icon(
            Icons.more_vert_rounded,
            size: 15.sp,
            color: context.inkColor(Color(0xFF4C5A34)),
          ),
        ),
      ),
    );
  }
}
