import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/app_route_observer.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:islami_app_noorify/features/quran/domain/juz_summary.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_summary.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/juz_list/juz_list_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/last_read/last_read_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_list/surah_list_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/quran_format_helpers.dart';
import 'package:islami_app_noorify/features/quran/presentation/quran_route_args.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_shimmer.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  // TabController is framework-required local state (needs a TickerProvider
  // from this State); it holds no app data, so it stays outside the Bloc.
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() =>
      context.read<LastReadBloc>().add(const LoadLastRead());

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
                  child: Column(
                    children: [
                      _TopBar(appText: appText),
                      SizedBox(height: 14.h),
                      _LastReadCard(appText: appText),
                      SizedBox(height: 8.h),
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColor.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColor.primary,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: [
                          Tab(text: appText.tabSurah),
                          Tab(text: appText.tabPara),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        _SurahTabView(),
                        _ParaTabView(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: HomeBottomNav(selectedIndex: 1),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.appText});

  final AppText appText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                appText.hifjoQuranTitle,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18.sp,
                color: Colors.black54,
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(RouteNames.quranBookmarks),
                  icon: Icon(
                    Icons.bookmark_border_rounded,
                    color: AppColor.primary,
                    size: 20.sp,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColor.primary,
                    size: 20.sp,
                  ),
                  onSelected: (value) {
                    final route = value == 'history'
                        ? RouteNames.quranReadingHistory
                        : RouteNames.quranBookmarks;
                    Navigator.of(context).pushNamed(route);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'history',
                      child: Text(appText.readingHistoryTitle),
                    ),
                    PopupMenuItem(
                      value: 'bookmarks',
                      child: Text(appText.bookmarksTitle),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LastReadCard extends StatelessWidget {
  const _LastReadCard({required this.appText});

  final AppText appText;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LastReadBloc, LastReadState>(
      builder: (context, state) {
        final lastRead = state.entry;
        return GestureDetector(
          onTap: lastRead == null
              ? null
              : () => Navigator.of(context).pushNamed(
                  RouteNames.quranSurahDetail,
                  arguments: SurahRouteArgs(
                    surahNo: lastRead.surahNo,
                    surahName: lastRead.surahName,
                  ),
                ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8FA05C), Color(0xFF56682F)],
              ),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22.r),
              child: Stack(
                children: [
                  Positioned(
                    right: -8.w,
                    bottom: -14.h,
                    child: Opacity(
                      opacity: .22,
                      child: Image.asset(
                        'assets/images/Quran.png',
                        height: 110.h,
                        fit: BoxFit.contain,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 15.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                appText.lastReadLabel,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (lastRead != null)
                            GestureDetector(
                              onTap: () => Navigator.of(context).pushNamed(
                                RouteNames.quranReadingHistory,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    appText.viewReadingHistory,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 12.sp,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 30.h),
                      Text(
                        lastRead?.surahName ?? appText.hifjoQuranTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        lastRead != null
                            ? '${appText.ayahNoLabel}: ${lastRead.ayahNo}'
                            : appText.startReadingPrompt,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.number,
    required this.title,
    this.subtitleLeft,
    this.subtitleRight,
    this.trailingArabic,
    required this.onTap,
  });

  final int number;
  final String title;
  final String? subtitleLeft;
  final String? subtitleRight;
  final String? trailingArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC9D89A), width: 1.4),
              ),
              child: Text(
                '$number',
                style: TextStyle(
                  color: AppColor.primary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                  if (subtitleLeft != null) ...[
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            subtitleLeft!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        if (subtitleRight != null) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Text(
                            subtitleRight!,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (trailingArabic != null) ...[
              SizedBox(width: 10.w),
              Text(
                trailingArabic!,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingOrError extends StatelessWidget {
  const _LoadingOrError({required this.message, required this.actionLabel, required this.onRetry});

  final String message;
  final String actionLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13.sp),
          ),
          SizedBox(height: 12.h),
          TextButton(onPressed: onRetry, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _SurahTabView extends StatelessWidget {
  const _SurahTabView();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocProvider(
      create: (_) => SurahListBloc()..add(const LoadSurahs()),
      child: BlocBuilder<SurahListBloc, SurahListState>(
        builder: (context, state) {
          if (state.isLoading && state.surahs.isEmpty) {
            return const SurahListShimmer();
          }
          if (state.hasError && state.surahs.isEmpty) {
            return _LoadingOrError(
              message: appText.quranLoadError,
              actionLabel: appText.tryAgain,
              onRetry: () =>
                  context.read<SurahListBloc>().add(const LoadSurahs()),
            );
          }
          return _PaginatedList<SurahSummary>(
            items: state.surahs,
            itemBuilder: (context, surah) => _ListRow(
              number: surah.number,
              title: surah.name,
              subtitleLeft: revelationPlaceLabel(
                appText,
                surah.revelationPlace,
              ),
              subtitleRight: '${surah.totalAyah} ${appText.ayahWord}',
              trailingArabic: surah.nameArabic,
              onTap: () => Navigator.of(context).pushNamed(
                RouteNames.quranSurahDetail,
                arguments: SurahRouteArgs(
                  surahNo: surah.number,
                  surahName: surah.name,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ParaTabView extends StatelessWidget {
  const _ParaTabView();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocProvider(
      create: (_) => JuzListBloc()..add(const LoadJuzList()),
      child: BlocBuilder<JuzListBloc, JuzListState>(
        builder: (context, state) {
          if (state.isLoading && state.juzs.isEmpty) {
            return const SurahListShimmer();
          }
          if (state.hasError && state.juzs.isEmpty) {
            return _LoadingOrError(
              message: appText.quranLoadError,
              actionLabel: appText.tryAgain,
              onRetry: () =>
                  context.read<JuzListBloc>().add(const LoadJuzList()),
            );
          }
          return _PaginatedList<JuzSummary>(
            items: state.juzs,
            itemBuilder: (context, juz) {
              final surahName = state.surahNames[juz.startSurahNo] ?? '';
              return _ListRow(
                number: juz.number,
                title: '${appText.juzWord} ${juz.number}',
                subtitleLeft:
                    '${appText.startsLabel}: $surahName ${juz.startAyah}',
                onTap: () => Navigator.of(context).pushNamed(
                  RouteNames.quranJuzReader,
                  arguments: juz.number,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Renders [items] 10 at a time, revealing the next 10 automatically (with
/// a brief loading row) as the user scrolls near the bottom, instead of
/// mounting the whole list at once.
class _PaginatedList<T> extends StatefulWidget {
  const _PaginatedList({
    required this.items,
    required this.itemBuilder,
    this.pageSize = 10,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final int pageSize;

  @override
  State<_PaginatedList<T>> createState() => _PaginatedListState<T>();
}

class _PaginatedListState<T> extends State<_PaginatedList<T>> {
  final ScrollController _scrollController = ScrollController();
  late int _visibleCount = _initialVisibleCount;
  bool _isLoadingMore = false;

  int get _initialVisibleCount =>
      widget.items.length < widget.pageSize
      ? widget.items.length
      : widget.pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _PaginatedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      _visibleCount = _initialVisibleCount;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || _visibleCount >= widget.items.length) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 200) return;
    setState(() => _isLoadingMore = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _visibleCount = (_visibleCount + widget.pageSize).clamp(
          0,
          widget.items.length,
        );
        _isLoadingMore = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.items.take(_visibleCount).toList();
    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(0, 4.h, 0, 100.h),
      itemCount: visibleItems.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Color(0xFFE3ECC5)),
      itemBuilder: (context, index) {
        if (index >= visibleItems.length) {
          return const SurahListRowShimmer();
        }
        return widget.itemBuilder(context, visibleItems[index]);
      },
    );
  }
}
