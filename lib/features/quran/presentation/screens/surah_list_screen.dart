import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_summary.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_list/surah_list_bloc.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SurahSummary> _filter(List<SurahSummary> surahs) {
    if (_query.isEmpty) return surahs;
    return surahs
        .where(
          (surah) =>
              surah.name.toLowerCase().contains(_query) ||
              surah.translation.toLowerCase().contains(_query),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/quranBack.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
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
                          appText.surahsTitle,
                          style: TextStyle(
                            color: AppColor.primary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 13.sp),
                    decoration: InputDecoration(
                      hintText: appText.searchSurah,
                      hintStyle: TextStyle(
                        color: const Color(0xFFB8B8B8),
                        fontSize: 13.sp,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColor.primary,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: const BorderSide(color: Color(0xFFDDE8C1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: const BorderSide(color: Color(0xFFDDE8C1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: const BorderSide(color: AppColor.primary),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: BlocBuilder<SurahListBloc, SurahListState>(
                      builder: (context, state) {
                        if (state.isLoading && state.surahs.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColor.primary,
                            ),
                          );
                        }
                        if (state.hasError && state.surahs.isEmpty) {
                          return _ErrorRetry(
                            message: appText.quranLoadError,
                            actionLabel: appText.tryAgain,
                            onRetry: () => context.read<SurahListBloc>().add(
                              const LoadSurahs(),
                            ),
                          );
                        }
                        final surahs = _filter(state.surahs);
                        return ListView.separated(
                          padding: EdgeInsets.only(bottom: 20.h),
                          itemCount: surahs.length,
                          separatorBuilder: (_, _) => SizedBox(height: 9.h),
                          itemBuilder: (context, index) {
                            final surah = surahs[index];
                            return _SurahTile(
                              surah: surah,
                              ayahWord: appText.ayahWord,
                              onTap: () => Navigator.of(context).pushNamed(
                                RouteNames.quranSurahDetail,
                                arguments: surah.number,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({
    required this.message,
    required this.actionLabel,
    required this.onRetry,
  });

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

class _SurahTile extends StatelessWidget {
  const _SurahTile({
    required this.surah,
    required this.ayahWord,
    required this.onTap,
  });

  final SurahSummary surah;
  final String ayahWord;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .85),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFDDE8C1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17.r,
                backgroundColor: const Color(0xFFDFE9B9),
                child: Text(
                  '${surah.number}',
                  style: TextStyle(color: AppColor.primary, fontSize: 12.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(surah.name, style: TextStyle(fontSize: 15.sp)),
                    SizedBox(height: 3.h),
                    Text(
                      surah.translation,
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
              Text(
                '${surah.totalAyah} $ayahWord',
                style: TextStyle(color: AppColor.primary, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
