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
import 'package:google_fonts/google_fonts.dart';
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
  });
  final QuranContentService? contentService;
  final SurahRouteArgs args;
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => QuranReadingCubit(
          surahNo: args.surahNo,
          startAyah: args.paraNumber == null ? 1 : args.ayahNo,
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
    child: _ReaderBody(args: args),
  );
}

class _ReaderBody extends StatefulWidget {
  const _ReaderBody({required this.args});
  final SurahRouteArgs args;
  @override
  State<_ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends State<_ReaderBody> {
  final _elapsed = Stopwatch()..start();
  final _seconds = ValueNotifier<int>(0);
  late final Timer _timer;
  int _bookmarkRevision = 0;
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
    final controller = TextEditingController(text: '${reader.state.from}');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to ayah'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            helperText: '${reader.startAyah} – ${reader.lastAyah}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final n = int.tryParse(controller.text);
              if (n != null && n >= reader.startAyah && n <= reader.lastAyah) {
                Navigator.pop(context, n);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 400), controller.dispose);
    if (value != null && mounted) {
      context.read<SurahPlaybackBloc>().add(SetActiveAyah(value));
      await reader.load(from: value);
    }
  }

  Future<void> _showAyah(QuranAyah ayah) async {
    final state = context.read<QuranReadingCubit>().state;
    context.read<SurahPlaybackBloc>().add(SetActiveAyah(ayah.ayahNumber));
    final reciter = context.read<ReciterBloc>();
    final download = context.read<SurahAudioDownloadBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
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
          translation: state.translation,
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
        body: SafeArea(
          child: BlocBuilder<QuranReadingCubit, QuranReadingState>(
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
              return QuranReadingLayout(
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
                              onTap: () => Navigator.pushNamed(
                                context,
                                RouteNames.quranSurahs,
                              ),
                              child: Text(
                                'Surah:  ${surah?.name ?? widget.args.surahName}  ⌄',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Reader settings',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => showQuranReaderSettingsSheet(
                              context,
                              bloc: context.read<QuranTranslationBloc>(),
                            ),
                            icon: const Icon(
                              Icons.tune,
                              size: 20,
                              color: quranInk,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              size: 20,
                              color: quranInk,
                            ),
                            onSelected: (value) {
                              if (value == 'translation') {
                                context.read<QuranTranslationBloc>().add(
                                  SetShowTranslation(!prefs.showTranslation),
                                );
                              }
                              if (value == 'back') {
                                Navigator.maybePop(context);
                              }
                              if (value == 'jump') _jump();
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'translation',
                                child: Text(
                                  prefs.showTranslation
                                      ? 'Arabic reading view'
                                      : 'Show translations',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'jump',
                                child: Text('Go to ayah'),
                              ),
                              const PopupMenuItem(
                                value: 'back',
                                child: Text('Back'),
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
                        busy: state.loading,
                        onNext: state.to < reader.lastAyah ? reader.next : null,
                        onPrevious: state.from > reader.startAyah
                            ? reader.previous
                            : null,
                        footer: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: context.surfaceColor(Colors.white),
                            foregroundColor: quranInk,
                            side: const BorderSide(color: quranBorder),
                            elevation: 2,
                          ),
                          onPressed: () => openTafsirSheet(
                            context,
                            '${widget.args.surahNo}:${active.clamp(state.from, state.to)}',
                            prefs.surahLang == AppLanguage.bangla,
                          ),
                          child: Text(appText.viewQuranTafsir),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (opening)
                              Container(
                                padding: const EdgeInsets.only(top: 116),
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(
                                      'assets/images/quran/starting_sura_pattern.png',
                                    ),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      surah?.name ?? '',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.amiri(
                                        fontSize: 27,
                                        fontWeight: FontWeight.bold,
                                        color: quranOlive,
                                      ),
                                    ),
                                    Text(
                                      '${surah?.revelationPlace.toUpperCase()} • ${surah?.totalAyah} AYAT',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: quranOlive,
                                      ),
                                    ),
                                    if (state.bismillahPre ||
                                        widget.args.surahNo == 1)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        child: Image.asset(
                                          'assets/images/bismillah.png',
                                          height: 44,
                                          color: quranOlive,
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
