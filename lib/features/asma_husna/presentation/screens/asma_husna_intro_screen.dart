import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/asma_husna/data/datasources/asma_husna_local_data_source.dart';
import 'package:tuhfatul_muslim/features/asma_husna/data/datasources/asma_husna_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/asma_husna/data/repositories/asma_husna_repository_impl.dart';
import 'package:tuhfatul_muslim/features/asma_husna/domain/usecases/get_asma_name_detail.dart';
import 'package:tuhfatul_muslim/features/asma_husna/presentation/bloc/asma_husna_bloc.dart';
import 'package:tuhfatul_muslim/features/asma_husna/presentation/bloc/asma_name_detail_bloc.dart';
import 'package:tuhfatul_muslim/features/asma_husna/presentation/screens/asma_name_detail_screen.dart';
import 'package:tuhfatul_muslim/features/asma_husna/presentation/widgets/asma_husna_shimmer.dart';
import 'package:tuhfatul_muslim/features/asma_husna/presentation/widgets/asma_name_card.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_page_header.dart';

/// Asmaul-Husna landing screen (design `img_26.png`): the "99 names" hadith,
/// a link to the full list, and an audio-capable name preview. Tapping
/// "See All" opens [AsmaHusnaListScreen].
class AsmaHusnaIntroScreen extends StatelessWidget {
  const AsmaHusnaIntroScreen({super.key});

  void _openAllNames(BuildContext context) =>
      Navigator.of(context).pushNamed(RouteNames.asmaAll);

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: context.pageColor(Color(0xFFF7F9EC)),
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
                child: DuaPageHeader(title: appText.asmaHusnaTitle),
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
                        color: context.inkColor(Color(0xFF4B5540)),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      appText.asmaHusnaHadithArabic,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Noorehuda',
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w700,
                        color: context.inkColor(Color(0xFF3E6B2E)),
                        height: 1.9,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      appText.asmaHusnaHadithTranslation,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontStyle: FontStyle.italic,
                        color: context.inkColor(Color(0xFF4B5540)),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      appText.asmaHusnaSourcesLabel,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: context.inkColor(AppColor.authLogo),
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
                        color: context.inkColor(Color(0xFF6B7659)),
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
                              color: context.inkColor(AppColor.authLogo),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    BlocBuilder<AsmaHusnaBloc, AsmaHusnaState>(
                      builder: (context, state) {
                        if (state.status == AsmaHusnaStatus.loading ||
                            state.status == AsmaHusnaStatus.initial) {
                          return const AsmaNameCardShimmer();
                        }
                        if (state.status == AsmaHusnaStatus.failure ||
                            state.names.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        // The API currently has no audio URL for the first
                        // entry (Allah). Prefer the first playable name here
                        // so the intro card's play button is usable.
                        var preview = state.names.first;
                        for (final name in state.names) {
                          if ((name.audioUrl ?? '').isNotEmpty) {
                            preview = name;
                            break;
                          }
                        }
                        final audioUrl = preview.audioUrl;
                        return AsmaNameCard(
                          name: preview,
                          isPlaying:
                              state.playingId == preview.id &&
                              !state.isBuffering,
                          isBuffering:
                              state.playingId == preview.id &&
                              state.isBuffering,
                          onTogglePlay: audioUrl == null || audioUrl.isEmpty
                              ? null
                              : () => context.read<AsmaHusnaBloc>().add(
                                  TogglePlayAsmaAudio(
                                    nameId: preview.id,
                                    audioUrl: audioUrl,
                                  ),
                                ),
                          onShowDetails: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => BlocProvider(
                                create: (_) => AsmaNameDetailBloc(
                                  GetAsmaNameDetail(
                                    AsmaHusnaRepositoryImpl(
                                      AsmaHusnaRemoteDataSourceImpl(),
                                      AsmaHusnaLocalDataSourceImpl(),
                                    ),
                                  ),
                                )..add(LoadAsmaNameDetail(preview.id)),
                                child: AsmaNameDetailScreen(name: preview),
                              ),
                            ),
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
            style: TextStyle(
              fontSize: 12.5.sp,
              color: context.inkColor(Color(0xFF6B7659)),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: context.inkColor(Color(0xFF6B7659)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
