import '../widgets/quran_download_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tuhfatul_muslim/core/constants/app_route_observer.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import '../bloc/surah_list/surah_list_bloc.dart';
import '../bloc/juz_list/juz_list_bloc.dart';
import '../bloc/last_read/last_read_bloc.dart';
import '../bloc/offline_quran/offline_quran_bloc.dart';
import '../../data/services/quran_page_index.dart';
import '../quran_route_args.dart';
import '../quran_text.dart';
import '../widgets/quran_shimmer.dart';
import '../widgets/quran_design.dart';
import '../widgets/dashboard/quran_dashboard_header.dart' show QuranBackButton;

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

  Future<List<QuranPageStart>> _pages = QuranPageIndex.load();

  bool _matches(String text) =>
      text.toLowerCase().contains(_search.toLowerCase());

  /// A message in the list area that scrolls with the header and grows to
  /// fit, instead of overflowing when little space is left below it.
  static Widget _fill(Widget child) => CustomScrollView(
    slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
  );

  void _openReader(int surahNo, String surahName, [int ayahNo = 1]) =>
      Navigator.pushNamed(
        context,
        RouteNames.quranSurahDetail,
        arguments: SurahRouteArgs(
          surahNo: surahNo,
          surahName: surahName,
          ayahNo: ayahNo,
        ),
      );
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
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final t = QuranText.of(context);
    return QuranTabShell(
      onExit: () => _goToGlobalHome(context),
      child: Scaffold(
        backgroundColor: context.pageColor(Colors.white),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19),
            // The header, banner, tabs and search scroll away with the list,
            // so the list gets the whole screen on short phones too.
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          QuranBackButton(
                            tooltip: text.home,
                            onBack: () => _goToGlobalHome(context),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              text.hifjoQuranTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: quranInk,
                              ),
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
                              PopupMenuItem(
                                value: 'offline',
                                child: Text(t.tajweedDownload),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      BlocBuilder<LastReadBloc, LastReadState>(
                        builder: (context, state) {
                          final entry = state.entry;
                          return _LastReadCard(
                            title: text.lastReadLabel,
                            historyLabel: text.viewReadingHistory,
                            surahName: entry == null
                                ? text.quranReadButton
                                : t.surahName(entry.surahNo, entry.surahName),
                            ayahLine: entry == null
                                ? null
                                : '${text.ayahNoLabel}: ${t.n(entry.ayahNo)}',
                            // Continues where the user left off (the ayah
                            // after the last one read, when known).
                            onTap: () {
                              final target = state.target;
                              _openReader(
                                target?.surahNo ?? 1,
                                target?.surahName ?? '',
                                target?.ayahNo ?? 1,
                              );
                            },
                            onHistory: () => Navigator.pushNamed(
                              context,
                              RouteNames.quranReadingHistory,
                            ),
                          );
                        },
                      ),
                      BlocBuilder<OfflineQuranBloc, OfflineQuranState>(
                        builder: (context, state) {
                          if (state.status == OfflineQuranStatus.preparing) {
                            return LinearProgressIndicator(
                              value: state.progress,
                            );
                          }
                          if (state.status == OfflineQuranStatus.failed) {
                            return TextButton(
                              onPressed: () => context
                                  .read<OfflineQuranBloc>()
                                  .add(const PrepareOfflineQuran()),
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
                            t.surah,
                            t.para,
                            t.page,
                          ].indexed)
                            Expanded(
                              child: InkWell(
                                key: ValueKey('quran-home-tab-$i'),
                                onTap: () => setState(() => _tab = i),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _tab == i
                                            ? quranOlive
                                            : quranBorder,
                                        width: _tab == i ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: quranInk,
                                      fontWeight: _tab == i
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) =>
                            setState(() => _search = value.trim()),
                        decoration: InputDecoration(
                          hintText: _tab == 2
                              ? t.searchPage
                              : t.searchSurahOrPara,
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xff9aa2b5),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: quranOlive,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
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
                    ],
                  ),
                ),
              ],
              body: switch (_tab) {
                0 => _surahList(t),
                1 => _paraList(t),
                _ => _pageList(t),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _surahList(QuranText t) => BlocBuilder<SurahListBloc, SurahListState>(
    bloc: _surahs,
    builder: (context, state) {
      if (state.isLoading) return const SurahListShimmer();
      if (state.hasError) {
        return _fill(
          QuranRetry(
            offline: state.offline,
            onRetry: () => _surahs.add(const LoadSurahs()),
          ),
        );
      }
      final list = state.surahs
          .where(
            (s) => _matches(
              '${s.number} ${t.n(s.number)} ${s.name} ${s.nameArabic} '
              '${s.translation} ${t.surahName(s.number)}',
            ),
          )
          .toList();
      if (list.isEmpty) return _fill(Center(child: Text(t.noResults)));
      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, i) {
          final s = list[i];
          return QuranListRow(
            number: s.number,
            title: t.surahName(s.number, s.name),
            arabic: s.nameArabic,
            subtitle:
                '${t.revelationPlace(s.revelationPlace)}  ·  '
                '${t.ayahCount(s.totalAyah)}',
            onTap: () => _openReader(s.number, s.name),
          );
        },
      );
    },
  );

  Widget _paraList(QuranText t) => BlocBuilder<JuzListBloc, JuzListState>(
    bloc: _paras,
    builder: (context, state) {
      if (state.isLoading) return const SurahListShimmer();
      if (state.hasError) {
        return _fill(
          QuranRetry(
            offline: state.offline,
            onRetry: () => _paras.add(const LoadJuzList()),
          ),
        );
      }
      final list = state.juzs
          .where(
            (p) => _matches(
              '${p.number} ${t.n(p.number)} ${t.paraTitle(p.number)} '
              '${p.nameBangla} '
              '${p.surahs.map((s) => '${s.name} ${s.nameBangla}').join(' ')}',
            ),
          )
          .toList();
      if (list.isEmpty) return _fill(Center(child: Text(t.noResults)));
      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, i) {
          final p = list[i];
          final names = [
            for (final s in p.surahs)
              t.isBangla && s.nameBangla.isNotEmpty ? s.nameBangla : s.name,
          ];
          // One or two Surahs by name; more as "first – last".
          final surahs = names.length <= 2
              ? names.join(' & ')
              : '${names.first} – ${names.last}';
          return QuranListRow(
            number: p.number,
            title: t.paraTitle(p.number),
            subtitle: [
              if (surahs.isNotEmpty) surahs,
              t.ayahCount(p.versesCount),
            ].join('  ·  '),
            onTap: () => Navigator.pushNamed(
              context,
              RouteNames.quranJuzReader,
              arguments: p.number,
            ),
          );
        },
      );
    },
  );

  Widget _pageList(QuranText t) => FutureBuilder<List<QuranPageStart>>(
    future: _pages,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _fill(
          QuranRetry(
            onRetry: () => setState(() => _pages = QuranPageIndex.load()),
          ),
        );
      }
      if (!snapshot.hasData) return const SurahListShimmer();
      // English Surah names come from the Surah list once it has loaded.
      final english = {for (final s in _surahs.state.surahs) s.number: s.name};
      String nameOf(int surahNo) =>
          t.surahName(surahNo, english[surahNo] ?? t.surahTitle(t.n(surahNo)));
      final list = snapshot.requireData
          .where(
            (p) => _matches(
              '${p.page} ${t.n(p.page)} ${nameOf(p.surahNo)} '
              '${english[p.surahNo] ?? ''} ${t.paraTitle(p.paraNo)}',
            ),
          )
          .toList();
      if (list.isEmpty) return _fill(Center(child: Text(t.noResults)));
      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, i) {
          final p = list[i];
          return QuranListRow(
            key: ValueKey('quran-page-${p.page}'),
            number: p.page,
            title: t.pageTitle(p.page),
            subtitle:
                '${nameOf(p.surahNo)} · ${t.ayahLabel(p.ayahNo)}  ·  '
                '${t.paraTitle(p.paraNo)}',
            onTap: () =>
                _openReader(p.surahNo, english[p.surahNo] ?? '', p.ayahNo),
          );
        },
      );
    },
  );
}

/// The "Last Read" banner. Its height follows its text, and the Quran art
/// scales with the card's width, so it fits small and large phones alike.
class _LastReadCard extends StatelessWidget {
  const _LastReadCard({
    required this.title,
    required this.historyLabel,
    required this.surahName,
    required this.onTap,
    required this.onHistory,
    this.ayahLine,
  });

  final String title, historyLabel, surahName;
  final String? ayahLine;
  final VoidCallback onTap, onHistory;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final artWidth = bounds.maxWidth * .5;
      return InkWell(
        borderRadius: BorderRadius.circular(42),
        onTap: onTap,
        child: Container(
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
                right: 0,
                bottom: 0,
                width: artWidth,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/quran/Quran.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: InkWell(
                        onTap: onHistory,
                        child: Text(
                          '$historyLabel →',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Text keeps clear of the Quran art on the right.
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: artWidth * .6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/quran/cib-readme 1.png',
                                width: MediaQuery.textScalerOf(
                                  context,
                                ).scale(20),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  title,
                                  style: GoogleFonts.amiri(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            surahName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.amiri(
                              color: Colors.white,
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (ayahLine != null)
                            Text(
                              ayahLine!,
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
            ],
          ),
        ),
      );
    },
  );
}
