import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show FloatingHeaderSnapConfiguration;
import 'package:flutter/services.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import '../../data/services/quran_content_service.dart';
import '../../domain/juz_summary.dart';
import '../../domain/surah_summary.dart';
import '../quran_route_args.dart';
import 'quran_design.dart';
import 'quran_modal.dart';

const _sectionTitle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

class QuranFilterSheet extends StatefulWidget {
  const QuranFilterSheet({super.key, required this.initial, this.service});
  final SurahRouteArgs initial;
  final QuranContentService? service;
  @override
  State<QuranFilterSheet> createState() => _QuranFilterSheetState();
}

class _QuranFilterSheetState extends State<QuranFilterSheet>
    with TickerProviderStateMixin {
  late final _api = widget.service ?? QuranContentService.shared;
  List<SurahSummary> _surahs = [];
  List<JuzSummary> _paras = [];
  SurahSummary? _surah;
  JuzSummary? _para;
  int _ayah = 1;
  String _type = '';
  bool _loading = true, _error = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final results = await Future.wait<Object>([
        _api.loadSurahs(),
        _api.loadParas(),
      ]);
      if (!mounted) return;
      _surahs = [...results[0] as List<SurahSummary>]
        ..sort((a, b) => a.number.compareTo(b.number));
      _paras = [...results[1] as List<JuzSummary>]
        ..sort((a, b) => a.number.compareTo(b.number));
      _surah =
          _surahs
              .where((s) => s.number == widget.initial.surahNo)
              .firstOrNull ??
          _surahs.firstOrNull;
      _para = _paras
          .where((p) => p.number == widget.initial.paraNumber)
          .firstOrNull;
      _ayah = widget.initial.ayahNo.clamp(_first, _last);
      setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  int get _first => _para != null && _para!.startSurahNo == _surah?.number
      ? _para!.startAyah
      : 1;
  int get _last => _para != null && _para!.endSurahNo == _surah?.number
      ? _para!.endAyah
      : (_surah?.totalAyah ?? 1).clamp(1, 1000);
  bool _inPara(SurahSummary s) =>
      _para == null || _para!.surahs.any((p) => p.number == s.number);
  void _selectSurah(SurahSummary s) => setState(() {
    FocusScope.of(context).unfocus();
    _surah = s;
    _ayah = _first;
  });
  void _selectPara(JuzSummary p) => setState(() {
    _para = p;
    _type = '';
    _surah = _surahs.where((s) => s.number == p.startSurahNo).firstOrNull;
    _ayah = _first;
  });

  Future<void> _openSearch(List<SurahSummary> pool) async {
    final picked = await showDialog<SurahSummary>(
      context: context,
      builder: (_) =>
          _SurahSearchDialog(surahs: pool, selected: _surah?.number),
    );
    if (picked != null && mounted) _selectSurah(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error) return QuranRetry(onRetry: _load);
    if (_surahs.isEmpty || _paras.isEmpty) {
      return const Center(child: Text('No Quran filters available'));
    }
    final background = context.surfaceColor(Colors.white);
    final matches = _surahs
        .where(
          (s) =>
              _inPara(s) &&
              (_type.isEmpty ||
                  s.revelationPlace.toLowerCase().startsWith(_type)),
        )
        .toList();
    return SafeArea(
      top: false,
      child: Column(
        children: [
          const QuranSheetHeading('Filter Quran'),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Surah', style: _sectionTitle),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 5,
                          children: [
                            for (final item in [
                              ('', 'All Types'),
                              ('mec', 'Makki'),
                              ('med', 'Madani'),
                            ])
                              ChoiceChip(
                                label: Text(
                                  item.$1.isEmpty
                                      ? item.$2
                                      : '${item.$2} (${_surahs.where((s) => s.revelationPlace.toLowerCase().startsWith(item.$1)).length})',
                                ),
                                selected: _type == item.$1,
                                selectedColor: quranBorder,
                                showCheckmark: false,
                                shape: const StadiumBorder(),
                                side: const BorderSide(color: quranBorder),
                                labelStyle: const TextStyle(
                                  color: Colors.black87,
                                ),
                                onSelected: (_) =>
                                    setState(() => _type = item.$1),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // Slides under the pinned search bar while scrolling down
                // and floats back in (snapping) as soon as the user scrolls up.
                SliverPersistentHeader(
                  floating: true,
                  delegate: _SheetSectionDelegate(
                    height: 190,
                    background: background,
                    vsync: this,
                    collapsible: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 40,
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Juz / Para Carousel',
                                    style: _sectionTitle,
                                  ),
                                ),
                                if (_para != null)
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _para = null),
                                    child: const Text('All'),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _ParaCarousel(
                              paras: _paras,
                              initial: _para?.number,
                              selected: _para?.number,
                              onSelected: _selectPara,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SheetSectionDelegate(
                    height: 52,
                    background: background,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Search and Select Surah',
                              style: _sectionTitle,
                            ),
                          ),
                          IconButton.filledTonal(
                            key: const ValueKey('quran-filter-search'),
                            tooltip: 'Search Surah',
                            onPressed: matches.isEmpty
                                ? null
                                : () => _openSearch(matches),
                            style: IconButton.styleFrom(
                              backgroundColor: context.surfaceColor(quranPale),
                              foregroundColor: quranInk,
                            ),
                            icon: const Icon(Icons.search_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (matches.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No Surahs found')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    sliver: SliverList.builder(
                      itemCount: matches.length,
                      itemBuilder: (_, i) => _SurahRow(
                        surah: matches[i],
                        selected: _surah?.number == matches[i].number,
                        onTap: () => _selectSurah(matches[i]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            decoration: BoxDecoration(
              color: background,
              border: const Border(top: BorderSide(color: quranBorder)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Select Ayat', style: _sectionTitle),
                    const SizedBox(width: 12),
                    if (_surah != null)
                      Expanded(
                        child: Text(
                          'Selected: ${_surah!.number}. ${_surah!.name}',
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: quranInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                QuranAyahWheel(
                  key: ValueKey('${_surah?.number}:${_para?.number}'),
                  first: _first,
                  last: _last,
                  initial: _ayah,
                  onChanged: (n) => setState(() => _ayah = n),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(0, 50),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _surah == null
                            ? null
                            : () => Navigator.pop(
                                context,
                                SurahRouteArgs(
                                  surahNo: _surah!.number,
                                  surahName: _surah!.name,
                                  ayahNo: _ayah,
                                  paraNumber: _para?.number,
                                  paraStartAyah: _para == null ? null : _first,
                                  endAyah: _para == null ? null : _last,
                                ),
                              ),
                        style: FilledButton.styleFrom(
                          backgroundColor: quranOlive,
                          minimumSize: const Size(0, 50),
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An opaque section of the filter sheet's scroll view. Pinned sections keep
/// a fixed [height] and gain a shadow once content scrolls beneath them;
/// [collapsible] ones shrink to nothing, fading and sliding up under the
/// section above.
class _SheetSectionDelegate extends SliverPersistentHeaderDelegate {
  _SheetSectionDelegate({
    required this.height,
    required this.background,
    required this.child,
    this.collapsible = false,
    this.vsync,
  });
  final double height;
  final Color background;
  final Widget child;
  final bool collapsible;
  @override
  final TickerProvider? vsync;

  @override
  double get maxExtent => height;
  @override
  double get minExtent => collapsible ? 0 : height;

  @override
  FloatingHeaderSnapConfiguration? get snapConfiguration => collapsible
      ? FloatingHeaderSnapConfiguration(
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 260),
        )
      : null;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = collapsible ? (shrinkOffset / height).clamp(0.0, 1.0) : 0.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: background,
        boxShadow: overlapsContent && !collapsible
            ? [
                BoxShadow(
                  color: quranInk.withValues(alpha: .12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : const [],
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          minHeight: height,
          maxHeight: height,
          child: Opacity(
            opacity: 1 - t,
            child: Transform.scale(
              scale: 1 - .06 * t,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SheetSectionDelegate oldDelegate) => true;
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({
    required this.surah,
    required this.selected,
    required this.onTap,
  });
  final SurahSummary surah;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    // Each row owns its Material so its fill and ink stay inside the row
    // (and scroll with it) instead of painting on the sheet.
    child: Material(
      color: selected
          ? context.surfaceColor(quranPale)
          : context.surfaceColor(Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? quranOlive : quranBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: selected ? quranOlive : quranPale,
                child: Text(
                  '${surah.number}',
                  style: TextStyle(
                    color: selected ? Colors.white : quranOlive,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${surah.translation} · ${surah.totalAyah} ayahs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: quranInk),
                    ),
                  ],
                ),
              ),
              if (surah.nameArabic.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    surah.nameArabic,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Noorehuda',
                      fontSize: 18,
                      color: quranInk,
                    ),
                  ),
                ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check_circle, color: quranOlive, size: 20),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SurahSearchDialog extends StatefulWidget {
  const _SurahSearchDialog({required this.surahs, required this.selected});
  final List<SurahSummary> surahs;
  final int? selected;
  @override
  State<_SurahSearchDialog> createState() => _SurahSearchDialogState();
}

class _SurahSearchDialogState extends State<_SurahSearchDialog> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final matches = widget.surahs
        .where(
          (s) => '${s.number} ${s.name} ${s.translation} ${s.nameArabic}'
              .toLowerCase()
              .contains(query),
        )
        .toList();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      backgroundColor: context.surfaceColor(Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: quranBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: math.min(560, MediaQuery.sizeOf(context).height * .7),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Search Surah', style: _sectionTitle),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (q) => setState(() => _query = q),
                decoration: InputDecoration(
                  hintText: 'Name, number or meaning',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.cancel_outlined),
                        ),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: quranBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: quranOlive),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: quranBorder),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: matches.isEmpty
                  ? const Center(child: Text('No Surahs found'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: matches.length,
                      itemBuilder: (_, i) => _SurahRow(
                        surah: matches[i],
                        selected: matches[i].number == widget.selected,
                        onTap: () => Navigator.pop(context, matches[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParaCarousel extends StatefulWidget {
  const _ParaCarousel({
    required this.paras,
    required this.initial,
    required this.selected,
    required this.onSelected,
  });
  final List<JuzSummary> paras;
  final int? initial, selected;
  final ValueChanged<JuzSummary> onSelected;
  @override
  State<_ParaCarousel> createState() => _ParaCarouselState();
}

class _ParaCarouselState extends State<_ParaCarousel> {
  late final int _initialPage = widget.paras
      .indexWhere((p) => p.number == widget.initial)
      .clamp(0, widget.paras.length - 1);
  late final _controller = PageController(
    viewportFraction: .5,
    initialPage: _initialPage,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// One Surah by name, two joined, or the first and last of three or more.
  static String _surahLabel(JuzSummary p) {
    final names = p.surahs.map((s) => s.name).toList();
    if (names.length <= 2) return names.join(' & ');
    return '${names.first} – ${names.last}';
  }

  double get _page =>
      _controller.hasClients && _controller.position.haveDimensions
      ? _controller.page ?? _initialPage.toDouble()
      : _initialPage.toDouble();

  @override
  Widget build(BuildContext context) => PageView.builder(
    controller: _controller,
    itemCount: widget.paras.length,
    onPageChanged: (i) => widget.onSelected(widget.paras[i]),
    itemBuilder: (_, i) {
      final p = widget.paras[i];
      final selected = p.number == widget.selected;
      // The centred card is sharp; its neighbours shrink, fade and blur
      // the further they sit from the centre.
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final distance = (_page - i).abs().clamp(0.0, 1.0);
          final sigma = 2.5 * distance;
          return ImageFiltered(
            enabled: sigma > .05,
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: Opacity(
              opacity: 1 - .4 * distance,
              child: Transform.scale(scale: 1 - .16 * distance, child: child),
            ),
          );
        },
        child: GestureDetector(
          onTap: () {
            _controller.animateToPage(
              i,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            );
            widget.onSelected(p);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.all(5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? context.surfaceColor(quranPale)
                  : context.surfaceColor(Colors.white),
              border: Border.all(
                color: selected ? quranOlive : quranBorder,
                width: selected ? 1.6 : 1,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: selected ? quranOlive : quranPale,
                  child: Text(
                    '${p.number}',
                    style: TextStyle(
                      color: selected ? Colors.white : quranOlive,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    _surahLabel(p),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: quranOlive,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: quranOlive,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${p.startSurahNo}:${p.startAyah} – ${p.endSurahNo}:${p.endAyah}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class QuranAyahWheel extends StatefulWidget {
  const QuranAyahWheel({
    super.key,
    required this.first,
    required this.last,
    required this.initial,
    required this.onChanged,
  });
  final int first, last, initial;
  final ValueChanged<int> onChanged;
  @override
  State<QuranAyahWheel> createState() => _QuranAyahWheelState();
}

class _QuranAyahWheelState extends State<QuranAyahWheel> {
  late int _selected = widget.initial;
  late final _controller = FixedExtentScrollController(
    initialItem: widget.initial - widget.first,
  );
  @override
  void didUpdateWidget(QuranAyahWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial != _selected) {
      _selected = widget.initial.clamp(widget.first, widget.last);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToItem(_selected - widget.first);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 70,
    child: RotatedBox(
      quarterTurns: -1,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: 52,
        physics: const FixedExtentScrollPhysics(),
        diameterRatio: 12,
        perspective: .001,
        onSelectedItemChanged: (index) {
          final value = widget.first + index;
          if (value == _selected) return;
          setState(() => _selected = value);
          HapticFeedback.selectionClick();
          widget.onChanged(value);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.last - widget.first + 1,
          builder: (_, i) {
            final n = widget.first + i;
            return RotatedBox(
              quarterTurns: 1,
              child: Semantics(
                selected: n == _selected,
                label: 'Ayah $n',
                child: GestureDetector(
                  onTap: () => _controller.animateToItem(
                    i,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: n == _selected ? quranBorder : null,
                      border: Border.all(color: quranBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$n'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
