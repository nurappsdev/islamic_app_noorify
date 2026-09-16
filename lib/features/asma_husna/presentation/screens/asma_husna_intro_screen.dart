import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/asma_husna/presentation/bloc/asma_husna_bloc.dart';
import 'package:islami_app_noorify/features/asma_husna/presentation/widgets/asma_name_card.dart';
import 'package:islami_app_noorify/features/asma_husna/presentation/widgets/asma_name_detail_sheet.dart';
import 'package:islami_app_noorify/features/dua/presentation/widgets/dua_page_header.dart';

/// Asmaul-Husna landing screen (design `img_26.png`): the "99 names" hadith,
/// a link to the full list, and a preview of the first name. Tapping
/// "See All" or the search field opens [AsmaHusnaListScreen].
class AsmaHusnaIntroScreen extends StatelessWidget {
  const AsmaHusnaIntroScreen({super.key});

  void _openAllNames(BuildContext context) =>
      Navigator.of(context).pushNamed(RouteNames.asmaAll);

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9EC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCFDF7), Color(0xFFEFF2DA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: DuaPageHeader(
                  title: appText.asmaHusnaTitle,
                  action: IconButton(
                    onPressed: () {},
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColor.authLogo,
                      side: const BorderSide(color: Color(0xFFDCE3BE)),
                      minimumSize: Size(38.r, 38.r),
                    ),
                    icon: const Icon(Icons.access_time, size: 18),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
                  children: [
                    Text(
                      appText.asmaHusnaHadithNarrator,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF4B5540),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      appText.asmaHusnaHadithArabic,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3E6B2E),
                        height: 1.9,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      appText.asmaHusnaHadithTranslation,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF4B5540),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      appText.asmaHusnaSourcesLabel,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColor.authLogo,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    _BulletLine(text: appText.asmaHusnaSourceBukhari),
                    _BulletLine(text: appText.asmaHusnaSourceMuslim),
                    SizedBox(height: 8.h),
                    Text(
                      appText.asmaHusnaAgreedNote,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        color: const Color(0xFF6B7659),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          appText.asmaHusnaNamesCount,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        InkWell(
                          onTap: () => _openAllNames(context),
                          child: Text(
                            appText.seeAll,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColor.authLogo,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    GestureDetector(
                      onTap: () => _openAllNames(context),
                      child: AbsorbPointer(
                        child: TextField(
                          style: TextStyle(fontSize: 13.sp),
                          decoration: InputDecoration(
                            hintText: appText.searchHere,
                            hintStyle: TextStyle(
                              color: AppColor.authHint,
                              fontSize: 13.sp,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppColor.authIcon,
                              size: 20.sp,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 14.h,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28.r),
                              borderSide: const BorderSide(
                                color: Color(0xFFE3E7D3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    BlocBuilder<AsmaHusnaBloc, AsmaHusnaState>(
                      builder: (context, state) {
                        if (state.status == AsmaHusnaStatus.loading ||
                            state.status == AsmaHusnaStatus.initial) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (state.status == AsmaHusnaStatus.failure ||
                            state.names.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final first = state.names.first;
                        final audioUrl = first.audioUrl;
                        return AsmaNameCard(
                          name: first,
                          isPlaying:
                              state.playingId == first.id && !state.isBuffering,
                          isBuffering:
                              state.playingId == first.id && state.isBuffering,
                          onTogglePlay: audioUrl == null || audioUrl.isEmpty
                              ? null
                              : () => context.read<AsmaHusnaBloc>().add(
                                  TogglePlayAsmaAudio(
                                    nameId: first.id,
                                    audioUrl: audioUrl,
                                  ),
                                ),
                          onShowDetails: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AsmaNameDetailSheet(name: first),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(fontSize: 12.5.sp, color: const Color(0xFF6B7659)),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: const Color(0xFF6B7659),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
