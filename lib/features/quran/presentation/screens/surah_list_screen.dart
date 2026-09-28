import '../widgets/quran_download_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islami_app_noorify/core/constants/app_route_observer.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import '../bloc/surah_list/surah_list_bloc.dart';
import '../bloc/juz_list/juz_list_bloc.dart';
import '../bloc/last_read/last_read_bloc.dart';
import '../bloc/offline_quran/offline_quran_bloc.dart';
import '../quran_route_args.dart';
import '../widgets/quran_shimmer.dart';
import '../widgets/quran_design.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});
  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> with RouteAware {
  final _surahs = SurahListBloc()..add(const LoadSurahs());
  final _paras = JuzListBloc()..add(const LoadJuzList());
  int _tab = 0;
  String _search = '';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() => context.read<LastReadBloc>().add(const LoadLastRead());
  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _surahs.close();
    _paras.close();
    super.dispose();
  }

  bool _matches(String text) =>
      text.toLowerCase().contains(_search.toLowerCase());
  void _goToGlobalHome(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      var poppedToHome = false;
      Navigator.of(context).popUntil((route) {
        if (route.settings.name == RouteNames.home) {
          poppedToHome = true;
          return true;
        }
        return route.isFirst;
      });
      if (poppedToHome) return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return QuranTabShell(
      child: Scaffold(
        backgroundColor: context.pageColor(Colors.white),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xffe5ece5),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        tooltip: text.home,
                        onPressed: () => _goToGlobalHome(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xff385c46),
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      text.hifjoQuranTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: quranInk,
                      ),
                    ),
                    const Icon(
                      Icons.expand_more,
                      color: Color(0xff385c46),
                      size: 20,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: text.bookmarksTitle,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        RouteNames.quranBookmarks,
                      ),
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Color(0xffeee5d5)),
                      ),
                      icon: const Icon(
                        Icons.bookmark_border,
                        size: 19,
                        color: quranInk,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: quranInk),
                      onSelected: (value) {
                        if (value == 'offline') {
                          showQuranDownload(
                            context,
                            bloc: context.read<OfflineQuranBloc>(),
                          );
                        } else {
                          Navigator.pushNamed(
                            context,
                            RouteNames.quranReadingHistory,
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'history',
                          child: Text(text.readingHistoryTitle),
                        ),
                        const PopupMenuItem(
                          value: 'offline',
                          child: Text('Tajweed / Download Quran'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                BlocBuilder<LastReadBloc, LastReadState>(
                  builder: (context, state) {
                    final entry = state.entry;
                    return InkWell(
                      borderRadius: BorderRadius.circular(42),
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteNames.quranSurahDetail,
                        arguments: SurahRouteArgs(
                          surahNo: entry?.surahNo ?? 1,
                          surahName: entry?.surahName ?? '',
                          ayahNo: entry?.ayahNo ?? 1,
                        ),
                      ),
                      child: Container(
                        height: 175,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(42),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xffa2af60), Color(0xff5c8169)],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Image.asset(
                                'assets/images/quran/Quran.png',
                                width: 205,
                              ),
                            ),
                            Positioned(
                              right: 24,
                              top: 12,
                              child: InkWell(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  RouteNames.quranReadingHistory,
                                ),
                                child: Text(
                                  '${text.viewReadingHistory} →',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 29,
                              top: 44,
                              right: 155,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        'assets/images/quran/cib-readme 1.png',
                                        width: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          text.lastReadLabel,
                                          style: GoogleFonts.amiri(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    entry?.surahName ?? text.quranReadButton,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.amiri(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  if (entry != null)
                                    Text(
                                      '${text.ayahNoLabel}: ${entry.ayahNo}',
                                      style: const TextStyle(
                                        color: Color(0xffe5ecd6),
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                BlocBuilder<OfflineQuranBloc, OfflineQuranState>(
                  builder: (context, state) {
                    if (state.status == OfflineQuranStatus.preparing) {
                      return LinearProgressIndicator(value: state.progress);
                    }
                    if (state.status == OfflineQuranStatus.failed) {
                      return TextButton(
                        onPressed: () => context.read<OfflineQuranBloc>().add(
                          const PrepareOfflineQuran(),
                        ),
                        child: Text(text.tryAgain),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    for (final (i, label) in [
                      text.tabSurah,
                      text.tabPara,
                      'Page',
                    ].indexed)
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _tab = i),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _tab == i ? quranOlive : quranBorder,
                                ),
                              ),
                            ),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: quranInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => _search = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search Surah Or Para',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff9aa2b5),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: quranOlive,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: quranBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: quranOlive),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _tab == 0
                      ? BlocBuilder<SurahListBloc, SurahListState>(
                          bloc: _surahs,
                          builder: (context, state) {
                            if (state.isLoading) {
                              return const SurahListShimmer();
                            }
                            if (state.hasError) {
                              return QuranRetry(
                                onRetry: () => _surahs.add(const LoadSurahs()),
                              );
                            }
                            final list = state.surahs
                                .where(
                                  (s) => _matches(
                                    '${s.number} ${s.name} ${s.nameArabic} ${s.translation}',
                                  ),
                                )
                                .toList();
                            if (list.isEmpty) {
                              return const Center(child: Text('No results'));
                            }
                            return ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final s = list[i];
                                return QuranListRow(
                                  number: s.number,
                                  title: s.name,
                                  arabic: s.nameArabic,
                                  subtitle:
                                      '${s.revelationPlace == 'meccan'
                                          ? 'Meccan'
                                          : s.revelationPlace == 'medinan'
                                          ? 'Medinian'
                                          : s.revelationPlace}  ·  ${s.totalAyah} ${text.ayahWord}',
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    RouteNames.quranSurahDetail,
                                    arguments: SurahRouteArgs(
                                      surahNo: s.number,
                                      surahName: s.name,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : _tab == 1
                      ? BlocBuilder<JuzListBloc, JuzListState>(
                          bloc: _paras,
                          builder: (context, state) {
                            if (state.isLoading) {
                              return const SurahListShimmer();
                            }
                            if (state.hasError) {
                              return QuranRetry(
                                onRetry: () => _paras.add(const LoadJuzList()),
                              );
                            }
                            final list = state.juzs
                                .where(
                                  (p) => _matches(
                                    '${p.number} ${p.nameBangla} ${p.surahs.map((s) => '${s.name} ${s.nameBangla}').join(' ')}',
                                  ),
                                )
                                .toList();
                            if (list.isEmpty) {
                              return const Center(child: Text('No results'));
                            }
                            return ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final p = list[i];
                                return QuranListRow(
                                  number: p.number,
                                  title: p.nameBangla,
                                  subtitle:
                                      '${p.startSurahNo}:${p.startAyah} – ${p.endSurahNo}:${p.endAyah}  ·  ${p.versesCount} ${text.ayahWord}',
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    RouteNames.quranJuzReader,
                                    arguments: p.number,
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Browse by Surah or Para. Page numbers are shown while reading; page browsing is coming soon.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
