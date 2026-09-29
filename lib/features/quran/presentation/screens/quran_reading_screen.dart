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
import '../bloc/tafsir/tafsir_bloc.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';
import '../../data/services/quran_content_service.dart';
import '../../data/services/quran_local_store.dart';
import '../../domain/arabic_font.dart';
import '../../domain/quran_ayah.dart';
import '../../domain/surah_detail.dart';
import '../../domain/translation_edition.dart';
import '../../data/repositories/quran_reading_repository_impl.dart';
import '../bloc/quran_reading_cubit.dart';
import '../controllers/quran_reading_tracker.dart';
import '../bloc/quran_translation/quran_translation_bloc.dart';
import '../bloc/surah_playback/surah_playback_bloc.dart';
import '../quran_route_args.dart';
import '../quran_reading_navigation.dart';
import '../widgets/quran_design.dart';
import '../widgets/quran_player_widgets.dart';
import '../widgets/quran_shimmer.dart';
import '../widgets/quran_sheets.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

class QuranReadingScreen extends StatelessWidget {
  const QuranReadingScreen({
    super.key,
    required this.args,
    this.contentService,
    this.tafsirService,
    this.readingTracker,
  });
  final QuranContentService? contentService;
  final QuranReaderService? tafsirService;

  /// Reports what is read; by default one on the app-wide repository.
  final QuranReadingTracker? readingTracker;
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
    child: _ReaderBody(
      args: args,
      tafsirService: tafsirService,
      readingTracker: readingTracker,
    ),
  );
}

class _ReaderBody extends StatefulWidget {
  const _ReaderBody({
    required this.args,
    this.tafsirService,
    this.readingTracker,
  });
  final SurahRouteArgs args;
  final QuranReaderService? tafsirService;
  final QuranReadingTracker? readingTracker;
  @override
  State<_ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends State<_ReaderBody> {
  late final QuranReadingSession _session =
      widget.args.readingSession ?? QuranReadingSession();
  final _seconds = ValueNotifier<int>(0);
  late final Timer _timer;
  // Reports what is read (POST /quran/reading/track); foreground time only.
  late final QuranReadingTracker _tracker =
      widget.readingTracker ??
      QuranReadingTracker(QuranReadingRepositoryImpl.shared);
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onHide: _tracker.pause,
    onShow: _tracker.resume,
  );
  bool _crossingSurah = false;
  int _bookmarkRevision = 0;
  bool _showTafsir = false;
  bool _tafsirBangla = true;
  int? _recordedAyah;
  // What "View in ayat" shows under each ayah; null follows the surah's
  // translation language.
  _AyatView? _ayatView;
  // Arabic zoom while a pinch is in progress (and until the bloc saves it).
  double? _pinchBase, _pinchScale;

  void _pinchUpdate(double factor) {
    _pinchBase ??= context.read<QuranTranslationBloc>().state.arabicFontScale;
    // 5% steps keep the text from reflowing on every pixel of movement.
    final scale = ((_pinchBase! * factor * 20).round() / 20).clamp(
      kMinArabicFontScale,
      kMaxArabicFontScale,
    );
    if (scale != _pinchScale) setState(() => _pinchScale = scale);
  }

  void _pinchEnd() {
    _pinchBase = null;
    final scale = _pinchScale;
    if (scale == null) return;
    final prefs = context.read<QuranTranslationBloc>();
    if (scale == prefs.state.arabicFontScale) {
      setState(() => _pinchScale = null);
    } else {
      // Cleared by the listener once the bloc holds the new scale.
      prefs.add(SetArabicFontScale(scale));
    }
  }

  _AyatView _ayatViewFor(QuranTranslationState prefs) =>
      _ayatView ??
      (prefs.surahLang == AppLanguage.bangla
          ? _AyatView.bangla
          : _AyatView.english);

  void _selectAyatView(_AyatView view) {
    setState(() => _ayatView = view);
    if (view == _AyatView.tafsir) return;
    context.read<QuranTranslationBloc>().add(
      SetSurahTranslationLang(
        view == _AyatView.bangla ? AppLanguage.bangla : AppLanguage.english,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _seconds.value = _session.elapsedSeconds,
    );
    _seconds.value = _session.elapsedSeconds;
    _lifecycle; // Starts listening.
    context.read<SurahPlaybackBloc>().add(SetActiveAyah(widget.args.ayahNo));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    // Leaving the reader (or crossing into another Surah) ends the session.
    _tracker.dispose();
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
        arguments: result.withReadingSession(_session),
      );
    }
  }

  Future<void> _turn(bool forward) async {
    if (_crossingSurah || !mounted) return;
    final reader = context.read<QuranReadingCubit>();
    final state = reader.state;
    if (state.loading || state.ayahs.isEmpty) return;
    if (forward && state.to < reader.lastAyah) {
      await reader.next();
      return;
    }
    if (!forward && state.from > reader.startAyah) {
      await reader.previous();
      return;
    }
    if (widget.args.paraNumber != null) return;

    setState(() => _crossingSurah = true);
    try {
      final next = await adjacentSurahArgs(
        service: reader.contentService,
        current: widget.args,
        session: _session,
        forward: forward,
      );
      if (!mounted) return;
      if (next == null) {
        setState(() => _crossingSurah = false);
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        RouteNames.quranSurahDetail,
        arguments: next,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open Surah. Try again.')),
        );
        setState(() => _crossingSurah = false);
      }
    }
  }

  Future<void> _menu(String action) async {
    final reader = context.read<QuranReadingCubit>();
    final prefs = context.read<QuranTranslationBloc>();
    if (action.startsWith('view:')) {
      final choice = action.substring('view:'.length);
      if (choice == 'off') {
        prefs.add(const SetShowTranslation(false));
        return;
      }
      _selectAyatView(_AyatView.values.byName(choice));
      if (!prefs.state.showTranslation) {
        prefs.add(const SetShowTranslation(true));
      }
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
                saved
                    ? AppText.readOf(context).quranSurahBookmarked
                    : AppText.readOf(context).quranSurahBookmarkRemoved,
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppText.of(context).quranAyahLoadFailed)),
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
        BlocListener<QuranTranslationBloc, QuranTranslationState>(
          listenWhen: (p, c) => p.arabicFontScale != c.arabicFontScale,
          listener: (context, state) {
            if (_pinchScale != null && _pinchBase == null) {
              setState(() => _pinchScale = null);
            }
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
            if (state.ayahs.isNotEmpty) {
              _tracker.show(
                state.ayahs.first.surahNumber,
                state.ayahs.first.ayahNumber,
                state.ayahs.last.ayahNumber,
              );
            }
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
            final arabicScale = _pinchScale ?? prefs.arabicFontScale;
            final ayatView = _ayatViewFor(prefs);
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
            return SafeArea(
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
                          IconButton(
                            key: const ValueKey('quran-back-button'),
                            tooltip: 'Back',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 32,
                              height: 40,
                            ),
                            onPressed: () async {
                              final popped = await Navigator.of(
                                context,
                              ).maybePop();
                              if (!popped && context.mounted) {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed(RouteNames.quranSurahs);
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: quranInk,
                            ),
                          ),
                          // Shrinks (with an ellipsis) rather than pushing
                          // the actions off narrow screens.
                          Flexible(
                            child: TextButton(
                              onPressed: _jump,
                              style: TextButton.styleFrom(
                                foregroundColor: context.inkColor(
                                  Colors.black87,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Page ${state.ayahs.isEmpty ? '–' : state.ayahs.first.pageNumber} ⌄',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: _jump,
                              child: Text(
                                context.localizedDigits(
                                  AppText.of(context).quranSurahChip.fill({
                                    'name':
                                        surah?.name ?? widget.args.surahName,
                                  }),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          _ReadingTimerPill(
                            seconds: _seconds,
                            label: appText.yourReadingTimeIs,
                            // Narrow phones drop the icon to fit the row.
                            compact: MediaQuery.sizeOf(context).width < 360,
                          ),
                          IconButton(
                            tooltip: 'Filter Quran',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 34,
                              height: 40,
                            ),
                            onPressed: _jump,
                            icon: const Icon(
                              Icons.tune,
                              size: 20,
                              color: quranInk,
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Quran actions',
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(32, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.more_vert, color: quranInk),
                            onSelected: _menu,
                            itemBuilder: (_) => [
                              _AyatViewMenuEntry(
                                value: ayatView,
                                active: prefs.showTranslation,
                              ),
                              for (final item in [
                                (
                                  'bookmark',
                                  Icons.bookmark_border,
                                  AppText.of(context).quranBookmarkSurah,
                                ),
                                (
                                  'text',
                                  Icons.text_fields,
                                  AppText.of(context).quranChangeText,
                                ),
                                (
                                  'share',
                                  Icons.share_outlined,
                                  AppText.of(context).quranShare,
                                ),
                                (
                                  'translate',
                                  Icons.translate,
                                  AppText.of(context).quranTranslateHeading,
                                ),
                                (
                                  'download',
                                  Icons.download_outlined,
                                  AppText.of(context).quranTajweedDownload,
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
                    const SizedBox(height: 6),
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
                        label: Text(
                          AppText.of(context).quranPageLoadFailedRetry,
                        ),
                      ),
                  ],
                ),
                page: state.loading && state.ayahs.isEmpty
                    ? const FullSurahShimmer()
                    : state.error && state.ayahs.isEmpty
                    ? QuranRetry(onRetry: () => reader.load())
                    : state.ayahs.isEmpty
                    ? Center(child: Text(AppText.of(context).quranNoAyahs))
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
                        busy: state.loading || _crossingSurah,
                        onPinchUpdate: _pinchUpdate,
                        onPinchEnd: _pinchEnd,
                        onNext:
                            state.to < reader.lastAyah ||
                                (widget.args.paraNumber == null &&
                                    widget.args.surahNo < 114)
                            ? () => _turn(true)
                            : null,
                        onPrevious:
                            state.from > reader.startAyah ||
                                (widget.args.paraNumber == null &&
                                    widget.args.surahNo > 1)
                            ? () => _turn(false)
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
                                ? AppText.of(context).quranCloseTafsir
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
                                            scale: arabicScale * 1.25,
                                            font: arabicFontById(
                                              prefs.arabicFontFamily,
                                            ),
                                            onTap: _showAyah,
                                          ),
                                        const SizedBox(height: 12),
                                        if (ayatView == _AyatView.tafsir)
                                          _AyahTafsir(
                                            ayah: ayah,
                                            bangla:
                                                prefs.surahLang ==
                                                AppLanguage.bangla,
                                            readerService: widget.tafsirService,
                                            fontScale:
                                                prefs.translationFontScale,
                                          )
                                        else
                                          Text(
                                            ayah
                                                    .translations[state
                                                        .translation]
                                                    ?.text ??
                                                'Translation unavailable for this ayah',
                                            style: TextStyle(
                                              fontSize:
                                                  15 *
                                                  prefs.translationFontScale,
                                              height: 1.6,
                                            ),
                                          ),
                                        Text(
                                          context.localizedDigits(
                                            AppText.of(
                                              context,
                                            ).quranVerseInfo.fill({
                                              'key': ayah.verseKey,
                                              'para': ayah.paraNumber,
                                              'page': ayah.pageNumber,
                                            }),
                                          ),
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
                                scale: arabicScale,
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

/// A compact rounded counter of this reading session's time, shown in the
/// reader's header next to the filter button.
class _ReadingTimerPill extends StatelessWidget {
  const _ReadingTimerPill({
    required this.seconds,
    required this.label,
    this.compact = false,
  });
  final ValueNotifier<int> seconds;
  final String label;

  /// Shows only the time, without the timer icon.
  final bool compact;

  static String _format(int total) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: seconds,
    builder: (context, value, _) => Tooltip(
      message: '$label ${value ~/ 60} min ${value % 60} sec',
      child: Container(
        key: const ValueKey('quran-reading-timer'),
        margin: const EdgeInsets.only(left: 4),
        padding: EdgeInsets.fromLTRB(compact ? 8 : 6, 4, compact ? 8 : 10, 4),
        decoration: BoxDecoration(
          color: context.surfaceColor(Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: quranBorder),
          boxShadow: [
            BoxShadow(
              color: quranInk.withValues(alpha: .08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) ...[
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: quranInk.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  size: 13,
                  color: quranInk,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              _format(value),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: quranInk,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// What "View in ayat" shows under each ayah.
enum _AyatView {
  english('English translation'),
  bangla('Bangla translation'),
  tafsir('Tafsir');

  const _AyatView(this.label);
  final String label;
}

/// "View in ayat" in the actions menu: tapping it drops down a choice of what
/// to show under each ayah. Picking one closes the menu with `view:<name>`;
/// "Back to page view" closes it with `view:off`.
class _AyatViewMenuEntry extends PopupMenuEntry<String> {
  const _AyatViewMenuEntry({required this.value, required this.active});
  final _AyatView value;

  /// Whether the reader is currently in "View in ayat".
  final bool active;

  @override
  double get height => kMinInteractiveDimension;

  @override
  bool represents(String? value) => false;

  @override
  State<_AyatViewMenuEntry> createState() => _AyatViewMenuEntryState();
}

class _AyatViewMenuEntryState extends State<_AyatViewMenuEntry> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InkWell(
        key: const ValueKey('quran-ayat-view-menu'),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.view_agenda_outlined, size: 19, color: quranInk),
              const SizedBox(width: 14),
              const Expanded(child: Text('View in ayat')),
              if (widget.active)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.check_circle, size: 16, color: quranOlive),
                ),
              AnimatedRotation(
                turns: _open ? .5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.expand_more, color: quranInk),
              ),
            ],
          ),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: !_open
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                // Its own Material so the radio tiles' ink shows on it.
                child: Material(
                  color: context.surfaceColor(quranPale),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: quranBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Text(
                          'Show under each ayah',
                          style: TextStyle(
                            fontSize: 12,
                            color: quranInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      RadioGroup<_AyatView>(
                        groupValue: widget.active ? widget.value : null,
                        onChanged: (view) {
                          if (view != null) {
                            Navigator.pop(context, 'view:${view.name}');
                          }
                        },
                        child: Column(
                          children: [
                            for (final view in _AyatView.values)
                              RadioListTile<_AyatView>(
                                key: ValueKey('quran-ayat-view-${view.name}'),
                                value: view,
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                activeColor: quranOlive,
                                title: Text(view.label),
                              ),
                          ],
                        ),
                      ),
                      if (widget.active)
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context, 'view:off'),
                          style: TextButton.styleFrom(
                            foregroundColor: quranInk,
                          ),
                          icon: const Icon(Icons.menu_book_outlined, size: 18),
                          label: const Text('Back to page view'),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    ],
  );
}

/// One ayah's tafsir, loaded on its own when it is shown.
class _AyahTafsir extends StatelessWidget {
  const _AyahTafsir({
    required this.ayah,
    required this.bangla,
    required this.fontScale,
    this.readerService,
  });
  final QuranAyah ayah;
  final bool bangla;
  final double fontScale;
  final QuranReaderService? readerService;

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey('tafsir-${ayah.verseKey}:$bangla'),
    create: (_) => TafsirBloc(
      readerService: readerService,
      tafsirResourceId: bangla
          ? banglaTafsirResourceId
          : englishTafsirResourceId,
    )..add(LoadTafsir(ayah.verseKey)),
    child: BlocBuilder<TafsirBloc, TafsirState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2, color: quranOlive),
          );
        }
        if (state.hasError) {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () =>
                  context.read<TafsirBloc>().add(LoadTafsir(ayah.verseKey)),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Could not load tafsir. Retry'),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tafsir',
              style: TextStyle(
                fontSize: 12,
                color: quranInk,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.text.isEmpty
                  ? 'No Tafsir available for this ayah'
                  : state.text,
              style: TextStyle(fontSize: 15 * fontScale, height: 1.6),
            ),
          ],
        );
      },
    ),
  );
}
