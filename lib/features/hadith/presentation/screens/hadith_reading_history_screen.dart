import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_read_records.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_read_records/hadith_read_records_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_read_record_row.dart';

/// How close to the end of the list (in logical pixels) the next page starts
/// loading.
const _loadMoreThreshold = 240.0;

/// Full reading-history list, reached from "See All" on [HadithDashboardScreen].
///
/// The user's reading history (`GET /hadiths/reading/recent`), 10 per page:
/// the next 10 load as the list nears its end, until there are no more.
class HadithReadingHistoryScreen extends StatelessWidget {
  const HadithReadingHistoryScreen({super.key, this.getRecords});

  /// Records per page of the full list.
  static const pageSize = 10;

  /// Where the records come from; the real API unless a test supplies one.
  final GetHadithReadRecords? getRecords;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HadithReadRecordsBloc(
        getRecords ??
            GetHadithReadRecords(
              HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl()),
            ),
        pageSize: pageSize,
      )..add(const LoadHadithReadRecords()),
      child: const _HadithReadingHistoryView(),
    );
  }
}

class _HadithReadingHistoryView extends StatefulWidget {
  const _HadithReadingHistoryView();

  @override
  State<_HadithReadingHistoryView> createState() =>
      _HadithReadingHistoryViewState();
}

class _HadithReadingHistoryViewState extends State<_HadithReadingHistoryView> {
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
      context.read<HadithReadRecordsBloc>().add(
        const LoadMoreHadithReadRecords(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 6.h),
            _Header(title: appText.readingHistoryTitle),
            SizedBox(height: 10.h),
            Expanded(child: _HadithRecordsList(controller: _scrollController)),
          ],
        ),
      ),
    );
  }
}

/// The paginated hadith reading history, with loading, error (retry) and empty
/// states, and a spinner / retry row at the bottom while the next page loads.
class _HadithRecordsList extends StatelessWidget {
  const _HadithRecordsList({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<HadithReadRecordsBloc>().state;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == HadithReadRecordsStatus.failure) {
      return _Message(
        message: state.failure?.message ?? '',
        actionLabel: appText.tryAgain,
        onAction: () => context.read<HadithReadRecordsBloc>().add(
          const LoadHadithReadRecords(),
        ),
      );
    }
    if (state.records.isEmpty) {
      return _Message(message: appText.noResultsFound);
    }

    // A page too short to scroll (or scrolling less than the load-more
    // distance) would never fire the scroll listener, so keep pulling pages
    // until the list is long enough to scroll on its own (or runs out).
    if (state.hasMore &&
        !state.isLoadingMore &&
        state.loadMoreFailure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || !controller.hasClients) return;
        if (controller.position.maxScrollExtent <= _loadMoreThreshold) {
          context.read<HadithReadRecordsBloc>().add(
            const LoadMoreHadithReadRecords(),
          );
        }
      });
    }

    final showFooter = state.isLoadingMore || state.loadMoreFailure != null;
    return ListView.separated(
      controller: controller,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
      itemCount: state.records.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, _) =>
          Divider(height: 22.h, color: context.lineColor(Color(0xFFEDEFE0))),
      itemBuilder: (context, index) {
        if (index < state.records.length) {
          return HadithReadRecordRow(record: state.records[index]);
        }
        return state.isLoadingMore
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: const Center(child: CircularProgressIndicator()),
              )
            : _Message(
                message: state.loadMoreFailure!.message,
                actionLabel: appText.tryAgain,
                onAction: () => context.read<HadithReadRecordsBloc>().add(
                  const LoadMoreHadithReadRecords(),
                ),
              );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: context.inkColor(const Color(0xFF5D6B44)),
            ),
          ),
          if (onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel ?? '')),
        ],
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
                  foregroundColor: context.inkColor(Color(0xFF303629)),
                  minimumSize: Size(38.r, 38.r),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: context.inkColor(AppColor.authLogo),
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
