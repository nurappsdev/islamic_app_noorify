import '../widgets/quran_player_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/domain/arabic_font.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/quran_translation/quran_translation_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_detail/surah_detail_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_playback/surah_playback_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/quran_format_helpers.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_sheets.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_shimmer.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_translation_switch.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_zoom_control.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/surah_hero_card.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';

class FullSurahScreen extends StatelessWidget {
  const FullSurahScreen({super.key, required this.surahNo});

  final int surahNo;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return BlocProvider(
      create: (context) {
        final uiLang = context.read<LanguageBloc>().state.language;
        return QuranTranslationBloc(initial: uiLang)
          ..add(LoadTranslationPreference(uiLang))
          ..add(const LoadTranslationEditions());
      },
      child: Builder(builder: (context) => _buildScaffold(context, appText)),
    );
  }

  Widget _buildScaffold(BuildContext context, AppText appText) {
    return Scaffold(
      backgroundColor: context.pageColor(Color(0xFFF4F7EA)),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8.h),
            SizedBox(
              height: 40.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 18.w),
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: context.surfaceColor(
                            Color(0xFFEDE7A6),
                          ),
                          foregroundColor: context.inkColor(AppColor.authLogo),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    appText.categoryQuran,
                    style: TextStyle(
                      color: context.inkColor(Color(0xFF6B7458)),
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 18.w),
                      child: IconButton(
                        onPressed: () => showQuranReaderSettingsSheet(
                          context,
                          bloc: context.read<QuranTranslationBloc>(),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: context.surfaceColor(
                            Color(0xFFEDE7A6),
                          ),
                          foregroundColor: context.inkColor(AppColor.authLogo),
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<SurahDetailBloc, SurahDetailState>(
                builder: (context, state) {
                  if (state.isLoading && state.detail == null) {
                    return const FullSurahShimmer();
                  }
                  if (state.hasError && state.detail == null) {
                    return Center(
                      child: Text(
                        appText.quranLoadError,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.inkColor(Colors.grey.shade700),
                          fontSize: 13.sp,
                        ),
                      ),
                    );
                  }
                  final detail = state.detail!;
                  final tState = context.watch<QuranTranslationBloc>().state;
                  final isBangla = tState.surahLang == AppLanguage.bangla;
                  final editionReady =
                      tState.usingCustomEdition &&
                      tState.editionTextSurahNo == detail.number;
                  final translations = editionReady
                      ? [
                          for (var i = 1; i <= detail.arabicAyahs.length; i++)
                            tState.surahEditionText[i] ?? '',
                        ]
                      : (isBangla ? detail.bengaliAyahs : detail.englishAyahs);
                  return QuranPlaybackAudioGate(
                    detail: detail,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 12.h),
                            children: [
                              SurahHeroCard(
                                appText: appText,
                                detail: detail,
                                actionLabel: appText.viewInAyat,
                                onAction: () => Navigator.maybePop(context),
                              ),
                              SizedBox(height: 10.h),
                              Center(
                                child: Text(
                                  context.localizedDigits(
                                    '${appText.yourReadingTimeIs} '
                                    '${formatReadingTime(appText, detail.arabicAyahs)}',
                                  ),
                                  style: TextStyle(
                                    color: AppColor.primary,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Row(
                                children: [
                                  Text(
                                    appText.quranTranslationLabel,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: context.inkColor(
                                        Color(0xFF6B7458),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const SurahTranslationSwitch(),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              const QuranZoomControl(),
                              SizedBox(height: 16.h),
                              _ContinuousAyahText(
                                arabicAyahs: detail.arabicAyahs,
                              ),
                              SizedBox(height: 16.h),
                              _CurrentAyahDetails(
                                surahNo: detail.number,
                                translations: translations,
                                isBangla: isBangla,
                              ),
                            ],
                          ),
                        ),
                        QuranNowPlayingBar(detail: detail),
                      ],
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

class _AyahRange {
  const _AyahRange(this.start, this.end);

  final int start;
  final int end;
}

class _ContinuousAyahText extends StatefulWidget {
  const _ContinuousAyahText({required this.arabicAyahs});

  final List<String> arabicAyahs;

  @override
  State<_ContinuousAyahText> createState() => _ContinuousAyahTextState();
}

class _ContinuousAyahTextState extends State<_ContinuousAyahText> {
  static const _readColor = Color(0xFFB9C79A);
  static final Color _highlightColor = AppColor.primary.withValues(alpha: .16);

  final GlobalKey _textKey = GlobalKey();

  String _segmentFor(int i) => '${widget.arabicAyahs[i]} ﴿${i + 1}﴾  ';

  List<_AyahRange> _buildRanges() {
    final ranges = <_AyahRange>[];
    var offset = 0;
    for (var i = 0; i < widget.arabicAyahs.length; i++) {
      final length = _segmentFor(i).length;
      ranges.add(_AyahRange(offset, offset + length));
      offset += length;
    }
    return ranges;
  }

  void _scrollToAyah(int ayahNo) {
    if (ayahNo < 1 || ayahNo > widget.arabicAyahs.length) return;
    final renderObject = _textKey.currentContext?.findRenderObject();
    if (renderObject is! RenderParagraph) return;
    final range = _buildRanges()[ayahNo - 1];
    final boxes = renderObject.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
    );
    if (boxes.isEmpty) return;
    final scrollableState = Scrollable.maybeOf(context);
    final viewportBox = scrollableState?.context.findRenderObject();
    if (scrollableState == null || viewportBox is! RenderBox) return;
    final position = scrollableState.position;
    final topLeft = renderObject.localToGlobal(
      Offset(0, boxes.first.toRect().top),
    );
    final localOffset = viewportBox.globalToLocal(topLeft);
    final target = (position.pixels + localOffset.dy - 140.h).clamp(
      0.0,
      position.maxScrollExtent,
    );
    position.animateTo(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final multiplier = context.select<QuranTranslationBloc, double>(
      (bloc) => bloc.state.arabicFontScale,
    );
    final arabicFont = context.select<QuranTranslationBloc, ArabicFont>(
      (bloc) => arabicFontById(bloc.state.arabicFontFamily),
    );
    return BlocConsumer<SurahPlaybackBloc, SurahPlaybackState>(
      listenWhen: (p, c) => p.currentAyahNo != c.currentAyahNo,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToAyah(state.currentAyahNo);
        });
      },
      builder: (context, playState) {
        final currentAyahNo = playState.currentAyahNo;
        return RichText(
          key: _textKey,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          text: TextSpan(
            style: arabicFont.apply(
              TextStyle(
                color: context.inkColor(Colors.black87),
                fontSize: 19.sp * multiplier,
                height: 2.0,
              ),
            ),
            children: [
              for (var i = 0; i < widget.arabicAyahs.length; i++)
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.arabicAyahs[i]} ',
                      style: i + 1 == currentAyahNo
                          ? TextStyle(
                              backgroundColor: context.surfaceColor(
                                _highlightColor,
                              ),
                              fontWeight: FontWeight.w600,
                            )
                          : i + 1 < currentAyahNo
                          ? TextStyle(color: context.inkColor(_readColor))
                          : null,
                    ),
                    TextSpan(
                      text: '﴿${i + 1}﴾  ',
                      style: TextStyle(
                        color: context.inkColor(
                          i + 1 < currentAyahNo ? _readColor : AppColor.primary,
                        ),
                        fontSize: 14.sp * multiplier,
                        backgroundColor: i + 1 == currentAyahNo
                            ? _highlightColor
                            : null,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CurrentAyahDetails extends StatelessWidget {
  const _CurrentAyahDetails({
    required this.surahNo,
    required this.translations,
    required this.isBangla,
  });

  final int surahNo;
  final List<String> translations;
  final bool isBangla;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final tState = context.watch<QuranTranslationBloc>().state;
    final multiplier = tState.translationFontScale;
    final showTranslation = tState.showTranslation;
    return BlocBuilder<SurahPlaybackBloc, SurahPlaybackState>(
      builder: (context, playState) {
        // currentAyahNo == 0 is the opening Bismillah; show ayah 1's details.
        final displayAyah = playState.currentAyahNo < 1
            ? 1
            : playState.currentAyahNo;
        final index = displayAyah - 1;
        final translation = index >= 0 && index < translations.length
            ? translations[index]
            : '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTranslation && translation.isNotEmpty)
              Text(
                translation,
                textAlign: TextAlign.left,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 13.sp * multiplier,
                  height: 1.4,
                  color: context.inkColor(Color(0xFF444444)),
                ),
              ),
            SizedBox(height: 6.h),
            GestureDetector(
              onTap: () =>
                  openTafsirSheet(context, '$surahNo:$displayAyah', isBangla),
              child: Text(
                appText.viewQuranTafsir,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColor.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
