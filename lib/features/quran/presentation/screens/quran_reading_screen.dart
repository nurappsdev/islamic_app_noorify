import '../widgets/quran_tafsir_content.dart';
import '../../data/services/quran_reader_service.dart';
import '../widgets/quran_surah_heading.dart';
import '../widgets/quran_filter_sheet.dart';
import '../widgets/quran_modal.dart';
import '../widgets/quran_share.dart';
import '../widgets/quran_download_sheet.dart';
import '../widgets/quran_reading_layout.dart';
import '../widgets/quran_page_viewport.dart';
import '../widgets/quran_reading_text.dart';
import '../widgets/quran_ayah_details_sheet.dart';
import '../../data/services/quran_audio_downloader.dart';
import '../bloc/ayah_audio/ayah_audio_bloc.dart';
import '../bloc/ayah_bookmark/ayah_bookmark_bloc.dart';
import '../bloc/reciter/reciter_bloc.dart';
import '../bloc/surah_audio_download/surah_audio_download_bloc.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';
import '../../data/services/quran_content_service.dart';
import '../../data/services/quran_local_store.dart';
import '../../domain/arabic_font.dart';
import '../../domain/quran_ayah.dart';
import '../../domain/surah_detail.dart';
import '../../domain/translation_edition.dart';
import '../bloc/quran_reading_cubit.dart';
import '../bloc/quran_translation/quran_translation_bloc.dart';
import '../bloc/surah_playback/surah_playback_bloc.dart';
import '../quran_route_args.dart';
import '../widgets/quran_design.dart';
import '../widgets/quran_player_widgets.dart';
import '../widgets/quran_shimmer.dart';
import '../widgets/quran_sheets.dart';

class QuranReadingScreen extends StatelessWidget {
  const QuranReadingScreen({
    super.key,
    required this.args,
    this.contentService,
    this.tafsirService,
  });
  final QuranContentService? contentService;
  final QuranReaderService? tafsirService;
  final SurahRouteArgs args;
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => QuranReadingCubit(
          surahNo: args.surahNo,
          startAyah: args.paraNumber == null
              ? 1
              : (args.paraStartAyah ?? args.ayahNo),
          endAyah: args.endAyah,
          service: contentService,
        ),
      ),
      BlocProvider(
        create: (context) {
          final lang = context.read<LanguageBloc>().state.language;
          return QuranTranslationBloc(
              initial: lang,
              contentService: contentService,
            )
            ..add(LoadTranslationPreference(lang))
            ..add(const LoadTranslationEditions());
        },
      ),
    ],
    child: _ReaderBody(args: args, tafsirService: tafsirService),
  );
}

class _ReaderBody extends StatefulWidget {
  const _ReaderBody({required this.args, this.tafsirService});
  final SurahRouteArgs args;
  final QuranReaderService? tafsirService;
  @override
  State<_ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends State<_ReaderBody> {
  final _elapsed = Stopwatch()..start();
  final _seconds = ValueNotifier<int>(0);
  late final Timer _timer;
  int _bookmarkRevision = 0;
  bool _showTafsir = false;
  bool _tafsirBangla = true;
  int? _recordedAyah;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _seconds.value = _elapsed.elapsed.inSeconds,
    );
    context.read<SurahPlaybackBloc>().add(SetActiveAyah(widget.args.ayahNo));
  }

  @override
  void dispose() {
    _elapsed.stop();
    _timer.cancel();
    _seconds.dispose();
    super.dispose();
  }

  void _record(int ayah, String name) {
    if (name.isEmpty || _recordedAyah == ayah) return;
    _recordedAyah = ayah;
    QuranLocalStore.create()
        .then(
          (store) => store.recordSurahOpened(
            surahNo: widget.args.surahNo,
            surahName: name,
            ayahNo: ayah,
          ),
        )
        .catchError((Object _) {});
  }

  Future<void> _jump() async {
    final reader = context.read<QuranReadingCubit>();
    final result = await showQuranModal<SurahRouteArgs>(
      context,
      QuranFilterSheet(
        service: reader.contentService,
        initial: SurahRouteArgs(
          surahNo: widget.args.surahNo,
          surahName: reader.state.surah?.name ?? widget.args.surahName,
          ayahNo: context.read<SurahPlaybackBloc>().state.currentAyahNo.clamp(
            reader.startAyah,
            reader.lastAyah,
          ),
          paraNumber: widget.args.paraNumber,
          paraStartAyah: reader.startAyah,
          endAyah: widget.args.endAyah,
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (result.surahNo == widget.args.surahNo &&
        result.paraNumber == widget.args.paraNumber &&
        result.endAyah == widget.args.endAyah) {
      context.read<SurahPlaybackBloc>().add(SetActiveAyah(result.ayahNo));
      await reader.load(from: result.ayahNo);
    } else {
      Navigator.pushReplacementNamed(
        context,
        RouteNames.quranSurahDetail,
        arguments: result,
      );
    }
  }

  Future<void> _menu(String action) async {
    final reader = context.read<QuranReadingCubit>();
    final prefs = context.read<QuranTranslationBloc>();
    if (action == 'view') {
      prefs.add(SetShowTranslation(!prefs.state.showTranslation));
      return;
    }
    if (action == 'text') {
      showQuranReaderSettingsSheet(context, bloc: prefs);
      return;
    }
    if (action == 'download') {
      showQuranDownload(context);
      return;
    }
    if (reader.state.ayahs.isEmpty) return;
    final number = action == 'bookmark'
        ? 1
        : context.read<SurahPlaybackBloc>().state.currentAyahNo.clamp(
            reader.state.from,
            reader.state.to,
          );
    try {
      final ayah =
          reader.state.ayahs.where((a) => a.ayahNumber == number).firstOrNull ??
          await reader.contentService.loadAyah(
            widget.args.surahNo,
            number,
            translation: reader.state.translation,
          );
      if (!mounted) return;
      if (action == 'translate') {
        await _showAyah(ayah);
        return;
      }
      if (action == 'share') {
        await shareQuranAyah(
          context,
          ayah,
          translation: reader.state.translation,
          surahName: reader.state.surah?.name ?? '',
        );
      }
      if (action == 'bookmark') {
        final store = await QuranLocalStore.create();
        await store.toggleBookmark(
          surahNo: widget.args.surahNo,
          ayahNo: 1,
          surahName: reader.state.surah?.name ?? '',
          snippet: ayah.textArabic,
        );
        final saved = await store.isBookmarked(widget.args.surahNo, 1);
        if (mounted) {
          setState(() => _bookmarkRevision++);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                saved ? 'Surah bookmarked' : 'Surah bookmark removed',
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load ayah. Please try again.'),
          ),
        );
      }
    }
  }

  // Widget _surahNavigation() => FutureBuilder<List<SurahSummary>>(
  //   future: _catalog ??= context
  //       .read<QuranReadingCubit>()
  //       .contentService
  //       .loadSurahs(),
  //   builder: (context, snapshot) {
  //     if (snapshot.hasError) {
  //       return TextButton(
  //         onPressed: () => setState(() => _catalog = null),
  //         child: const Text('Retry Surah navigation'),
  //       );
  //     }
  //     if (!snapshot.hasData) return const SizedBox.shrink();
  //     final all = snapshot.requireData;
  //     final index = all.indexWhere((s) => s.number == widget.args.surahNo);
  //     if (index < 0) return const SizedBox.shrink();
  //     final reader = context.read<QuranReadingCubit>();
  //     return Column(
  //       children: [
  //         for (final target in [
  //           if (reader.state.from == 1 && index > 0) index - 1,
  //           if (reader.state.to == reader.lastAyah && index + 1 < all.length)
  //             index + 1,
  //         ])
  //           Padding(
  //             padding: const EdgeInsets.symmetric(vertical: 18),
  //             child: QuranSurahComponent(
  //               surah: all[target],
  //               label: target < index ? 'Previous Surah' : 'Next Surah',
  //               onTap: () => Navigator.pushReplacementNamed(
  //                 context,
  //                 RouteNames.quranSurahDetail,
  //                 arguments: SurahRouteArgs(
  //                   surahNo: all[target].number,
  //                   surahName: all[target].name,
  //                 ),
  //               ),
  //             ),
  //           ),
  //       ],
  //     );
  //   },
  // );

  Future<void> _showAyah(QuranAyah ayah) async {
    final state = context.read<QuranReadingCubit>().state;
    context.read<SurahPlaybackBloc>().add(SetActiveAyah(ayah.ayahNumber));
    final reciter = context.read<ReciterBloc>();
    final download = context.read<SurahAudioDownloadBloc>();
    final preferences = context.read<QuranTranslationBloc>();
    await showQuranModal<void>(
      context,
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: reciter),
          BlocProvider.value(value: download),
          BlocProvider(
            create: (_) => AyahAudioBloc(downloader: QuranAudioDownloader()),
          ),
          BlocProvider(
            create: (_) => AyahBookmarkBloc(
              surahNo: ayah.surahNumber,
              ayahNo: ayah.ayahNumber,
              surahName: state.surah?.name ?? '',
              snippet:
                  ayah.translations[state.translation]?.text ?? ayah.textArabic,
            )..add(const LoadBookmarkStatus()),
          ),
        ],
        child: QuranAyahDetails(
          surah: ayah.surahNumber,
          ayah: ayah.ayahNumber,
          translation:
              preferences.state.ayahOverrides[ayah.ayahNumber] ==
                  AppLanguage.english
              ? 20
              : preferences.state.ayahOverrides[ayah.ayahNumber] ==
                    AppLanguage.bangla
              ? 161
              : state.translation,
          service: context.read<QuranReadingCubit>().contentService,
          surahName: state.surah?.name ?? '',
          onTranslationSelected: (resource) => preferences.add(
            SetAyahTranslationLang(
              ayah.ayahNumber,
              resource == 161 ? AppLanguage.bangla : AppLanguage.english,
            ),
          ),
          onTafsir: (bangla) {
            Navigator.of(context).pop();
            setState(() {
              _showTafsir = true;
              _tafsirBangla = bangla;
            });
          },
          totalAyah: state.surah?.totalAyah ?? ayah.ayahNumber,
        ),
      ),
    );
    if (mounted) setState(() => _bookmarkRevision++);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<QuranTranslationBloc, QuranTranslationState>(
          listenWhen: (p, c) =>
              p.selectedEditionId != c.selectedEditionId ||
              (!p.loaded && c.loaded),
          listener: (context, state) {
            final reader = context.read<QuranReadingCubit>();
            reader.load(
              from: reader.state.surah == null
                  ? widget.args.ayahNo
                  : reader.state.from,
              translation: resourceIdForEdition(state.selectedEditionId),
            );
          },
        ),
        BlocListener<SurahPlaybackBloc, SurahPlaybackState>(
          listenWhen: (p, c) => p.currentAyahNo != c.currentAyahNo,
          listener: (context, state) {
            final reader = context.read<QuranReadingCubit>();
            final ayah = state.currentAyahNo;
            if (ayah < reader.startAyah || ayah > reader.lastAyah) {
              if (widget.args.paraNumber != null && ayah > reader.lastAyah) {
                context.read<SurahPlaybackBloc>().add(const PauseSurah());
              }
              return;
            }
            _record(ayah, reader.state.surah?.name ?? '');
            if (ayah < reader.state.from || ayah > reader.state.to) {
              reader.load(from: ayah);
            }
          },
        ),
        BlocListener<QuranReadingCubit, QuranReadingState>(
          listenWhen: (p, c) => !c.loading && !c.error,
          listener: (context, state) {
            final playback = context.read<SurahPlaybackBloc>();
            if (playback.state.currentAyahNo < state.from ||
                playback.state.currentAyahNo > state.to) {
              playback.add(SetActiveAyah(state.from));
            }
            _record(
              playback.state.currentAyahNo.clamp(state.from, state.to),
              state.surah?.name ?? '',
            );
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: context.pageColor(Colors.white),
        body: BlocBuilder<QuranReadingCubit, QuranReadingState>(
          builder: (context, state) {
            final reader = context.read<QuranReadingCubit>();
            final prefs = context.watch<QuranTranslationBloc>().state;
            final active = context
                .watch<SurahPlaybackBloc>()
                .state
                .currentAyahNo;
            final surah = state.surah;
            final opening = state.from == 1;
            final detail = surah == null
                ? null
                : SurahDetail(
                    number: surah.number,
                    name: surah.name,
                    nameArabic: surah.nameArabic,
                    translation: surah.translation,
                    revelationPlace: surah.revelationPlace,
                    totalAyah: surah.totalAyah,
                    arabicAyahs: const [],
                    englishAyahs: const [],
                    bengaliAyahs: const [],
                  );
            return QuranSurahBackdrop(
              visible: opening && surah != null,
              child: QuranReadingLayout(
                extension: _showTafsir
                    ? QuranTafsirContent(
                        key: ValueKey(
                          'tafsir-${state.pageNumber}-$_tafsirBangla',
                        ),
                        ayahs: state.ayahs,
                        isBangla: _tafsirBangla,
                        readerService: widget.tafsirService,
                        onClose: () => setState(() => _showTafsir = false),
                      )
                    : null,
                top: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: context
                            .surfaceColor(quranPale)
                            .withValues(alpha: .96),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: _jump,
                            style: TextButton.styleFrom(
                              foregroundColor: context.inkColor(Colors.black87),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            ),
                            child: Text(
                              'Page ${state.ayahs.isEmpty ? '–' : state.ayahs.first.pageNumber} ⌄',
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: _jump,
                              child: Text(
                                'Surah:  ${surah?.name ?? widget.args.surahName}  ⌄',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Filter Quran',
                            visualDensity: VisualDensity.compact,
                            onPressed: _jump,
                            icon: const Icon(
                              Icons.tune,
                              size: 20,
                              color: quranInk,
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Quran actions',
                            icon: const Icon(Icons.more_vert, color: quranInk),
                            onSelected: _menu,
                            itemBuilder: (_) => [
                              for (final item in [
                                (
                                  'view',
                                  Icons.view_agenda_outlined,
                                  'View in ayat',
                                ),
                                (
                                  'bookmark',
                                  Icons.bookmark_border,
                                  'Book Mark Surah',
                                ),
                                ('text', Icons.text_fields, 'Change text'),
                                ('share', Icons.share_outlined, 'Share'),
                                ('translate', Icons.translate, 'Translate'),
                                (
                                  'download',
                                  Icons.download_outlined,
                                  'Tajweed / Download Quran',
                                ),
                              ])
                                PopupMenuItem(
                                  value: item.$1,
                                  child: Row(
                                    children: [
                                      Icon(item.$2, size: 19, color: quranInk),
                                      const SizedBox(width: 14),
                                      Flexible(child: Text(item.$3)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
                      decoration: BoxDecoration(
                        color: context.surfaceColor(quranPale),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(5),
                        ),
                      ),
                      child: ValueListenableBuilder<int>(
                        valueListenable: _seconds,
                        builder: (context, seconds, _) => Text(
                          '${appText.yourReadingTimeIs} ${seconds ~/ 60} min ${seconds % 60} sec',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 2,
                      child: state.loading && state.ayahs.isNotEmpty
                          ? const LinearProgressIndicator(minHeight: 2)
                          : null,
                    ),
                    if (state.error && state.ayahs.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => reader.load(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Could not load page. Retry'),
                      ),
                  ],
                ),
                page: state.loading && state.ayahs.isEmpty
                    ? const FullSurahShimmer()
                    : state.error && state.ayahs.isEmpty
                    ? QuranRetry(onRetry: () => reader.load())
                    : state.ayahs.isEmpty
                    ? const Center(child: Text('No ayahs available'))
                    : QuranPageViewport(
                        pageNumber: state.pageNumber!,
                        showHeader: !opening,
                        header: opening && surah != null
                            ? QuranSurahHeading(
                                surah: surah,
                                showBismillah:
                                    state.bismillahPre ||
                                    widget.args.surahNo == 1,
                              )
                            : null,
                        busy: state.loading,
                        onNext: state.to < reader.lastAyah ? reader.next : null,
                        onPrevious: state.from > reader.startAyah
                            ? reader.previous
                            : null,
                        footer: OutlinedButton(
                          key: const ValueKey('quran-toggle-tafsir'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: context.surfaceColor(Colors.white),
                            foregroundColor: quranInk,
                            side: const BorderSide(color: quranBorder),
                            elevation: 2,
                          ),
                          onPressed: () => setState(() {
                            _showTafsir = !_showTafsir;
                            _tafsirBangla =
                                prefs.surahLang == AppLanguage.bangla;
                          }),
                          child: Text(
                            _showTafsir
                                ? 'Close tafsir'
                                : appText.viewQuranTafsir,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (prefs.showTranslation)
                              for (final ayah in state.ayahs)
                                InkWell(
                                  onTap: () => _showAyah(ayah),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (prefs.showArabic)
                                          QuranReadingText(
                                            ayahs: [ayah],
                                            active: active,
                                            scale: prefs.arabicFontScale * 1.25,
                                            font: arabicFontById(
                                              prefs.arabicFontFamily,
                                            ),
                                            onTap: _showAyah,
                                          ),
                                        const SizedBox(height: 12),
                                        Text(
                                          ayah
                                                  .translations[state
                                                      .translation]
                                                  ?.text ??
                                              'Translation unavailable for this ayah',
                                          style: TextStyle(
                                            fontSize:
                                                15 * prefs.translationFontScale,
                                            height: 1.6,
                                          ),
                                        ),
                                        Text(
                                          '${ayah.verseKey} · Para ${ayah.paraNumber} · Page ${ayah.pageNumber}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: quranInk,
                                          ),
                                        ),
                                        const Divider(color: quranBorder),
                                      ],
                                    ),
                                  ),
                                )
                            else
                              QuranReadingText(
                                ayahs: state.ayahs,
                                active: active,
                                scale: prefs.arabicFontScale,
                                font: arabicFontById(prefs.arabicFontFamily),
                                onTap: (ayah) {
                                  context.read<SurahPlaybackBloc>().add(
                                    SetActiveAyah(ayah.ayahNumber),
                                  );
                                  _showAyah(ayah);
                                },
                              ),
                            // if (widget.args.paraNumber == null)
                            //   _surahNavigation(),
                          ],
                        ),
                      ),
                bottom: detail == null
                    ? const SizedBox.shrink()
                    : QuranPlaybackAudioGate(
                        detail: detail,
                        child: QuranNowPlayingBar(
                          key: ValueKey(_bookmarkRevision),
                          detail: detail,
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
