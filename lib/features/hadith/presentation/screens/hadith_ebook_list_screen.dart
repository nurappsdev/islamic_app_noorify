import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/ebook.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_ebooks.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/ebooks/ebooks_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/ebook_detail_screen.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/ebook_cover.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';

/// Full e-book list.
///
/// Reached from the "See All" action next to the E-book section on
/// [HadithLibraryScreen]. Tapping a book opens its [EbookDetailScreen].
class HadithEbookListScreen extends StatelessWidget {
  const HadithEbookListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EbooksBloc(
        GetEbooks(
          HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl()),
        ),
      )..add(const LoadEbooks()),
      child: const _HadithEbookListView(),
    );
  }
}

class _HadithEbookListView extends StatefulWidget {
  const _HadithEbookListView();

  @override
  State<_HadithEbookListView> createState() => _HadithEbookListViewState();
}

class _HadithEbookListViewState extends State<_HadithEbookListView> {
  String _query = '';

  bool _matches(Ebook ebook) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return ebook.title.toLowerCase().contains(query) ||
        ebook.author.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<EbooksBloc>().state;
    final ebooks = state.ebooks.where(_matches).toList();
    return HadithListScaffold(
      title: appText.hadithEbook,
      onSearchChanged: (value) => setState(() => _query = value),
      children: [
        if (state.isLoading)
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (state.status == EbooksStatus.failure) ...[
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: Text(
              state.failure?.message ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: context.inkColor(const Color(0xFF5D6B44)),
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.read<EbooksBloc>().add(const LoadEbooks()),
            child: Text(appText.tryAgain),
          ),
        ] else if (ebooks.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: Text(
              appText.hadithBookComingSoon,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: context.inkColor(const Color(0xFF5D6B44)),
              ),
            ),
          )
        else
          for (final ebook in ebooks) ...[
            _EbookRow(ebook: ebook),
            SizedBox(height: 14.h),
          ],
      ],
    );
  }
}

class _EbookRow extends StatelessWidget {
  const _EbookRow({required this.ebook});

  final Ebook ebook;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EbookDetailScreen(ebook: ebook),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: context.surfaceColor(const Color(0xFFF0F3E4)),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: SizedBox(
                width: 72.w,
                height: 96.h,
                child: EbookCover(url: ebook.coverImageUrl),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ebook.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: context.inkColor(const Color(0xFF2C3320)),
                    ),
                  ),
                  if (ebook.author.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      ebook.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.inkColor(const Color(0xFF5D6B44)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20.sp,
              color: context.inkColor(const Color(0xFF5D6B44)),
            ),
          ],
        ),
      ),
    );
  }
}
